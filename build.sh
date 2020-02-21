#!/bin/bash

GITHUB_REPOSITORY=$(jq -r .upstream_github_repo config.json)
DOCKER_PACKAGE_NAME=$(jq -r .package_name config.json)

echo "Package Information";
echo "Github Repository: $GITHUB_REPOSITORY";
echo "Docker Image: $DOCKER_PACKAGE_NAME";

# Clone Repository
[ ! -d "tmp" ] && mkdir -p "tmp";
[ ! -d "tmp/repo" ] && git clone $GITHUB_REPOSITORY tmp/repo;

# Fetch All The Branches
cd tmp/repo;
git branch -r | awk '{print $1}' | awk -F/ '{print "remote="$1"; branch="$2";" }' | while read l
do eval $l
    git checkout -b $branch $remote/$branch

    LAST_COMMIT=$(git log -n1 --format="%h")
    echo "Checked out Branch $branch";
    echo "Using Commit $LAST_COMMIT";

    cp ../../Dockerfile .
    cp ../../.dockerignore .
    cp ../../docker-entrypoint.sh .
    cp -r ../../bin .

    echo "Running Build"
    docker build -t $DOCKER_PACKAGE_NAME:$LAST_COMMIT .
    docker build -t $DOCKER_PACKAGE_NAME:$branch .

    echo "Pushing Images"
    docker push $DOCKER_PACKAGE_NAME:$LAST_COMMIT 
    docker push $DOCKER_PACKAGE_NAME:$branch

    echo "Build Finished for Branch $branch"
done
