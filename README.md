# Nuitka Cross-Compilation Container for Win-x64

This project make possible to compile python script for Windows in docker container.

## Requirement

- Docker on x64

## Environment in Container

- Debian Bullseye
- Wine v8.0.1
- Python 3.10.11

## How to try this out

```bash
git clone https://github.com/kniwase/NuitkaCrossCompilationContainer.git
cd ./NuitkaCrossCompilationContainer/sample
docker compose run --build sample
```
