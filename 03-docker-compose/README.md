[Master Docker Compose the Way I Wish I Did – Docker for Newbs EP 2](https://www.youtube.com/watch?v=HGKfE-cn9y4)

# Objective

Run two web services in separate Docker containers and configure them to communicate correctly with each other using Docker Compose.

Docker Compose is a tool for defining and running multiple Docker containers as one application using a compose.yaml file.

A compose.yaml file describes the services that make up your application and how they should be configured and connected.

YAML is a human-readable format used to represent configuration and structured data. A .yaml file contains information organized with indentation and key-value pairs.

YAML itself has nothing specifically to do with Docker. Docker Compose simply uses YAML as its configuration format.

A Dockerfile is the recipe for creating an image.

An image is the packaged application/environment used to create a container.

A container is a running instance of an image.

Docker Compose adds another layer: Compose doesn't replace Dockerfiles, images, or containers. It orchestrates them.

# Exercise 03
## Step 01: MySQL Configuration
- Create the docker-compose.yml with the MySQL service
- Define environment variables (MYSQL_ROOT_PASSWORD, MYSQL_DATABASE, etc.)
- Configure volumes to persist data
- Add a healthcheck to verify MySQL is ready

```bash
# 1. Start containers
docker compose up -d

# 2. Wait 10 seconds, then check status
sleep 10
docker ps

# 3. Check logs
docker logs mysql-container
```

## Step 2: Angular Configuration
###  Generate the Angular project
```bash
npx @angular/cli@latest new frontend --style=css --ssr=false --skip-git

```
- --skip-git matters: you're already inside a git repo, and without it Angular creates a second repo inside yours.
- --ssr=false keeps it a simple client-side app.
- It runs npm install, which creates frontend/node_modules/. Your .gitignore already excludes that folder.

Check that it works outside Docker first:
```bash
cd frontend && npx ng serve
```
Open http://localhost:4200, confirm you see the Angular welcome page, then stop the server with Ctrl+C.

### Create frontend/.dockerignore
Without this file, COPY . . would copy hundreds of MB of your host's node_modules into the image. It's slow and can break things.

### Create frontend/Dockerfile (multi-stage with dev and prod targets)
What each part does:
- COPY package*.json then npm ci, before COPY . .: Docker caches layers, so dependencies are only reinstalled when package.json changes, not every time you edit code.
- --host 0.0.0.0: by default ng serve only listens on the container's own localhost, which your browser can't reach.
- --poll 2000: on a bind mount, file-change events often don't reach the container. Polling makes hot reload reliable.
- The prod stage has no Node at all, only nginx and the compiled files. That's the point of a multi-stage build: the final image is small.
- If ng build puts its output somewhere else, check the real path with ls frontend/dist/ after a local npx ng build and adjust the COPY --from=build line.

### Add the service to docker-compose.yaml
Put it under services:, at the same indentation as db::

The second volume is the tricky part. The bind mount ./frontend:/app hides everything the image put in /app, including the node_modules that npm ci installed. The anonymous volume /app/node_modules protects that one folder, so the container uses its own Linux-built packages.

Don't add depends_on: db yet. The frontend never talks to MySQL directly; that link comes in Step 3 through the backend.

### Test it
```bash
docker compose up -d --build frontend
docker compose logs -f frontend      # wait for "Local: http://localhost:4200/"
```
1. Open http://localhost:4200. You should see the same page as in 2.1, now served from the container.
2. Hot reload test: edit the template in frontend/src/app/ (app.html, or app.component.html on older versions), change some text and save. The browser should refresh by itself within a few seconds.
3. Prod target test (optional, shows the multi-stage build works):
```bash
docker build --target prod -t frontend-prod ./frontend
docker run --rm -p 8080:80 frontend-prod     # open http://localhost:8080
docker images | grep frontend                # compare image sizes
```

##  Step 3: the backend API and connecting the services. Your frontend and db are both running.

How the pieces will connect

Browser ──► localhost:4200 ──► [frontend container]  ng serve
                                   │  /api/* is forwarded by the dev proxy
                                   ▼
                               http://backend:3000  [backend container]  Express
                                   │  SQL
                                   ▼
                               db:3306              [mysql-container]
Inside the Compose network, containers reach each other by service name (db, backend), never localhost. Inside a container, localhost means that container itself.

### Create the backend project

From 03-docker-compose/:
```bash
mkdir backend && cd backend
npm init -y
npm install express mysql2
```
Then create backend/.dockerignore:
node_modules

### Create backend/server.js

### Create backend/Dockerfile
node --watch restarts the server whenever you save server.js. It's the backend version of hot reload.

### Add backend to docker-compose.yaml

Add it between db and frontend, with 2 spaces of indentation like the other services

Note that the backend uses MYSQL_USER, the limited app user, not root. That's why you created it.

### Test the backend on its own before touching Angular
```bash
docker compose config --services          # should show db, backend, frontend
docker compose up -d --build backend
docker compose logs backend               # expect "API listening on port 3000"

curl localhost:3000/api/health            # {"status":"ok"}
curl localhost:3000/api/tasks             # your 5 sample tasks as JSON
curl -X POST localhost:3000/api/tasks \
  -H 'Content-Type: application/json' \
  -d '{"title":"Created from curl"}'
curl localhost:3000/api/tasks             # the new task appears
```
Don't go further until these work. If there's a problem, it's easier to find here than through Angular.

### Make Angular forward /api to the backend

Create frontend/proxy.conf.json:
{
  "/api": {
    "target": "http://backend:3000",
    "secure": false
  }
}
The proxy runs inside the frontend container, which is why the target is backend and not localhost. It also avoids CORS: the browser only ever talks to localhost:4200.

In frontend/Dockerfile, add the proxy flag to the dev stage CMD:
CMD ["npx", "ng", "serve", "--host", "0.0.0.0", "--poll", "2000", "--proxy-config", "proxy.conf.json"]

### Show the tasks in Angular

Your project is Angular 22, which uses standalone components, signals and the @for template syntax. The code below follows that style.

frontend/src/app/app.config.ts: add provideHttpClient():
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(),
  ]
};

frontend/src/app/app.ts: replace the contents with:
import { Component, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { toSignal } from '@angular/core/rxjs-interop';

interface Task {
  id: number;
  title: string;
  description: string | null;
  is_completed: number;   // MySQL BOOLEAN comes back as 0 / 1
  priority: string;
  due_date: string | null;
}

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  private http = inject(HttpClient);
  // Relative URL → goes to localhost:4200/api/tasks → proxied to backend:3000
  protected readonly tasks = toSignal(this.http.get<Task[]>('/api/tasks'), { initialValue: [] });
}

frontend/src/app/app.html: replace the whole welcome page with:
<h1>Task Manager</h1>
<ul>
  @for (task of tasks(); track task.id) {
    <li>
      @if (task.is_completed) { ✅ } @else { ⬜ }
      <strong>{{ task.title }}</strong> ({{ task.priority }})
    </li>
  } @empty {
    <li>No tasks. Is the backend running?</li>
  }
</ul>
This new template no longer includes <router-outlet />, which is why RouterOutlet was removed from app.ts.

## Rebuild and test the whole stack

The CMD changed, so the frontend image has to be rebuilt:
```bash
docker compose up -d --build
docker compose ps        # all 3 up, db (healthy)
```
Open http://localhost:4200. You should see the 5 sample tasks and the one you created with curl. That shows the full chain works: browser → Angular → backend → MySQL.

## Clarifications

How to use it

The web app: open http://localhost:4200. You'll see the task list with ✅ or ⬜ for each task.

For now the page only reads tasks. To create, complete or delete one, call the API directly and then refresh the page:
### create
curl -X POST localhost:3000/api/tasks -H 'Content-Type: application/json' \
  -d '{"title":"My new task","priority":"high"}'
### mark task 2 as done
curl -X PUT localhost:3000/api/tasks/2 -H 'Content-Type: application/json' \
  -d '{"is_completed":true}'
### delete task 2
curl -X DELETE localhost:3000/api/tasks/2

Everyday commands (run from 03-docker-compose/)

You don't need to rebuild after editing code. Both source folders are bind-mounted into the containers:
- Save a file in frontend/src/ and the browser reloads.
- Save backend/server.js and node --watch restarts the API.

## In brief

All of these run from 03-docker-compose/, the folder that contains docker-compose.yaml.

Starting

docker compose up -d
This is the start command. It reads docker-compose.yaml and:
1. creates the network (so db, backend and frontend can find each other by name),
2. creates the volume if it doesn't exist yet,
3. builds images that don't exist yet,
4. creates the containers and starts them in the order set by depends_on (db → backend → frontend).

- -d ("detached") runs everything in the background and gives your terminal back. Without -d, the logs stay attached to your terminal and Ctrl+C stops all the containers.
- --build rebuilds the images first. You only need it after changing a Dockerfile or package.json.
- Adding a service name starts only that service, plus anything it depends_on. For example, docker compose up -d backend also starts db.

Stopping

There are two ways, and they're different:

docker compose down
Stops and removes the containers and the network. Your data is safe, because it lives in the mysql_data volume, which down doesn't touch. The next up -d creates new containers that reconnect to the same volume. This is the normal way to shut down.

docker compose stop
Only pauses. The containers still exist in a stopped state. Restart them with:
docker compose start
Use this pair when you just want to free up resources for a while.