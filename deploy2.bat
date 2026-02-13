@echo off
setlocal EnableDelayedExpansion

set NETWORK_NAME=mybridge

rem Check if the network '%NETWORK_NAME%' exists
docker network inspect %NETWORK_NAME% >nul 2>&1

if %errorlevel% neq 0 (
    echo Network '%NETWORK_NAME%' does not exist. Creating it...
    docker network create %NETWORK_NAME%
) else (
    echo Network '%NETWORK_NAME%' already exists.
)

rem Stop and remove existing containers and volumes
for /L %%i in (9, 1, 12) do (
    docker stop dfs-node-%%i >nul 2>&1
    docker rm dfs-node-%%i >nul 2>&1
    docker volume rm dfs-node-%%i-data >nul 2>&1
)

rem Skip building the image
echo Skipping image build step. Ensure the image is already built.

rem Deploy containers with port mappings and volumes
echo Deploying containers...
for /L %%i in (9, 1, 12) do (
    set /A PORT=8080 + %%i
    docker run -d --network %NETWORK_NAME% --name dfs-node-%%i -e CONTAINER_NAME=dfs-node-%%i -e HOST_PORT=!PORT! -e META_NODE_URL=http://dfs-meta-node:8080 -e RUNTIME_MODE=PRODUCT -p !PORT!:8081 -v dfs-node-%%i-data:/data dfs-node
)

echo Deployment completed!
endlocal
