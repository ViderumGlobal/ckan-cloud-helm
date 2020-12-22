#!/usr/bin/env bash

if [ "${1}" == "install" ]; then
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh &&\
    chmod 700 get_helm.sh &&\
    ./get_helm.sh --version "${HELM_VERSION}" &&\
    helm version --client && rm ./get_helm.sh &&\
    helm init --client-only
    exit 0

elif [ "${1}" == "script" ]; then
    exit 0

elif [ "${1}" == "deploy" ]; then
    $HOME/bin/travis_ci_operator.sh github-update self master "
        cd charts_repository &&\
        git checkout ${TRAVIS_BRANCH} && git checkout master -- index.yaml && git commit -m. ;\
        sudo helm package ../ckan --version "${TRAVIS_TAG}" &&\
        sudo helm package ../efs --version "${TRAVIS_TAG}" &&\
        sudo helm package ../traefik --version "${TRAVIS_TAG}" &&\
        sudo helm package ../provisioning --version "${TRAVIS_TAG}" &&\
        sudo helm repo index --url https://raw.githubusercontent.com/datopian/ckan-cloud-helm/master/charts_repository/ . &&\
        cd .. &&\
        git stash &&\
        git checkout master &&\
        git stash apply &&\
        git add charts_repository/index.yaml \
                charts_repository/ckan-${TRAVIS_TAG}.tgz \
                charts_repository/efs-${TRAVIS_TAG}.tgz \
                charts_repository/traefik-${TRAVIS_TAG}.tgz \
                charts_repository/provisioning-${TRAVIS_TAG}.tgz
    " "upgrade helm chart repo to CKAN chart ${TRAVIS_TAG}"
    [ "$?" != "0" ] && exit 1
    if ! [ -z "${SLACK_TAG_NOTIFICATION_CHANNEL}" ] && ! [ -z "${SLACK_TAG_NOTIFICATION_WEBHOOK_URL}" ]; then
        ! curl -X POST \
               --data-urlencode "payload={\"channel\": \"#${SLACK_TAG_NOTIFICATION_CHANNEL}\", \"username\": \"CKAN Cloud\", \"text\": \"Released ckan-cloud-helm ${TRAVIS_TAG}\nhttps://github.com/ViderumGlobal/ckan-cloud-helm/releases/tag/${TRAVIS_TAG}\", \"icon_emoji\": \":female-technologist:\"}" \
               ${SLACK_TAG_NOTIFICATION_WEBHOOK_URL} && exit 1
    fi
    exit 0

fi

echo unexpected failure
exit 1
