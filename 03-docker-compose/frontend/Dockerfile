# ---------- base: install dependencies (shared by all stages) ----------
FROM node:24-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci

# ---------- dev: dev server with hot reload ----------
FROM base AS dev
COPY . .
EXPOSE 4200
CMD ["npx", "ng", "serve", "--host", "0.0.0.0", "--poll", "2000", "--proxy-config", "proxy.conf.json"]

# ---------- build: compile the production bundle ----------
FROM base AS build
COPY . .
RUN npx ng build --configuration production

# ---------- prod: serve static files with nginx ----------
FROM nginx:alpine AS prod
COPY --from=build /app/dist/frontend/browser /usr/share/nginx/html
EXPOSE 80