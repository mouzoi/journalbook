#!/bin/bash -ex

SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

MAJOR=1
MINOR=1
REVISION=${MAJOR}.${MINOR}.`git rev-list --count HEAD`
if [ -f version ]; then
    VERSION=`cat version`
    REVISION=$(echo $VERSION|tr -d '\n')
fi

gcp-setup() {
    PROJECT_ID=XXXX
    SECRETS_PATH=secrets/

    [ -z  ${PROJECT_ID} ] && echo "Please set PROJECT_ID" && echo "exiting..." && exit -1

    if [ ! -z $(command -v gcloud) ]; then
        gcloud config set project ${PROJECT_ID}
        gcloud auth activate-service-account --key-file=${SECRETS_PATH}credentials.json --project ${PROJECT_ID}
        gcloud container clusters get-credentials dev-rapidfort-us-central1 --zone us-central1-a --project ${PROJECT_ID}
    fi

    export DOCKER_IMAGE_NAME=gcr.io/${PROJECT_ID}/backend
    gcloud auth configure-docker
}

stop() {
    DOCKER_IMAGE_ID=`docker images -a | grep ${DOCKER_IMAGE_NAME} | awk '{print $3}'`
    if [ ! -z ${DOCKER_IMAGE_ID} ]; then
        for i in $(docker ps -a | grep ${DOCKER_IMAGE_NAME}|awk '{print $1}')
            do
                docker stop $i
            done
    fi
}

clean() {
    for i in $(docker ps -a | grep ${DOCKER_IMAGE_NAME} | awk '{print $1}')
        do
            docker stop $i
            docker rm $i
        done

    for i in $(docker images | grep ${DOCKER_IMAGE_NAME} | awk '{print $3}')
        do
            docker rmi -f $i
        done | sort -u
}

build() {
    docker build -t "${DOCKER_IMAGE_NAME}:${REVISION}" -t "${DOCKER_IMAGE_NAME}:latest" .
}

 push() {
    docker push  ${DOCKER_IMAGE_NAME}:${REVISION}
    docker push  ${DOCKER_IMAGE_NAME}:latest
}

deploy() {
    build
    push
    helm template dev-backend backend \
    --set image.tag=${REVISION} \
    | kubectl apply -f -
}

undeploy() {
    helm template dev-backend backend \
    | kubectl delete -f -
}

shell() {
    docker run \
      --rm \
      -it \
      ${DOCKER_IMAGE_NAME}:${REVISION} \
      /bin/bash
}

run() {
    pushd app
        docker run --rm -d -p 6379:6379 --name redis-rejson redislabs/rejson:latest
        REDIS_HOST=localhost python3 main.py
    popd
}

case "${@}"
in
    ("build") build ;;
    ("clean") clean ;;
    ("push") push ;;
    ("shell") shell ;;
    ("deploy") deploy ;;
    ("undeploy") undeploy ;;
    ("stop") stop ;;
    ("run") run ;;
    (*) echo "$0 [ build | clean | stop | run | push | shell | deploy | undeploy ]" ;;
esac
