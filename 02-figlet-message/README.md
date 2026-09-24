# Objective

Create a simple script that runs inside a Docker container and uses Figlet to display custom messages in ASCII art. The goal is to practice creating a Dockerfile, installing dependencies inside an image, and running a custom application in a container.

# Exercice 02

## Step 01

Create a bash script:
```bash
touch script.sh
chmod +x script.sh
```

## Step 02

Create the Dockerfile:
```bash
touch Dockerfile
```

## Step 03

Builds a Docker image from the Dockerfile in the current directory and assigns it the name ascii.

- docker build — Builds a Docker image.
- -t ascii — Assigns the image the name/tag ascii.
- . — Uses the current directory as the build context.

```bash
docker build -t "ascii" .
```

## Step 04

We want to check what docker images we currently have built on our system

```bash
docker images
```

## Step 05

We want to run the image

```bash
docker run ascii:latest
```

## Step 06

Images are immutable.
To change it you have to edit the Dockerfile and then create a new image.
You may want to use a different tag.

```bash
docker build -t "ascii:different" .
```