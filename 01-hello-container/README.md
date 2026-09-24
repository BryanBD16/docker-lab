# Introduction to Docker

[The intro to Docker I wish I had when I started](https://www.youtube.com/watch?v=Ud7Npgi6x8E)

## Virtualization vs Containerization

### Virtualization

Virtualization uses a hypervisor to create and manage virtual machines (VMs) on a physical computer.

The hypervisor sits between the physical hardware and the virtual machines. It allocates resources such as CPU, RAM, storage, and networking to each VM.

Each VM behaves like an independent computer and contains its own operating system, libraries, and applications.

### Containerization

Runs isolated applications as containers that share the host operating system's kernel, making them lighter and faster than virtual machines.

## Main components

### Dockerfile

A text file containing the instructions used to build a Docker image.

### Images

A read-only template containing everything needed to run an application, such as the application code, dependencies, libraries, and configuration.

### Docker containers

Running instances of Docker images. Containers provide an isolated environment in which an application and its dependencies can run.

# Exercise 01

## Step 1

Install Docker :
```bash
sudo apt update
sudo apt install docker.io
docker --version
```

Note: On my system, docker.io conflicted with an existing containerd.io installation.

## Step 2

Runs a hello-world container to verify that Docker is working correctly. If the image is not available locally, Docker downloads it from a container registry, creates a container from the image, and runs it. The container displays a confirmation message and then exits.

```bash
docker run hello-world
```

