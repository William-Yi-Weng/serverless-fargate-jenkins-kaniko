#!/bin/sh -e

 /kaniko/executor     --dockerfile=/home/Dockerfile \
    --verbosity debug \
    --insecure \
    --skip-tls-verify \
    --force \
    --destination=${repository_url}/kaniko-artifact:latest

