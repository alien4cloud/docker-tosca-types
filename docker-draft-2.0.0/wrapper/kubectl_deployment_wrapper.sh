#!/bin/bash

# configuration
PREFIX=K8S_
KUBE_ADMIN_CONFIG_PATH=admin.conf

# local variables
K8S_VAR_1=1
K8S_VAR_2=2
K8S_VAR_3=3
K8S_VAR_4=4

KUBE_RESOURCE_DEPLOYMENT_CONFIG=$(cat <<-END
apiVersion: apps/v1beta1 # for versions before 1.7.0 use apps/v1beta1
kind: Deployment
metadata:
  name: containerdeploymentunit-mongo # Should generate a uniq name
spec:
  replicas: 1
  template:
    metadata:
      labels:
        anti_affinity_label: containerdeploymentunit-mongo
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: anti_affinity_label
                  operator: In
                  values:
                  - containerdeploymentunit_mongo_2
              topologyKey: kubernetes.io/hostname
      containers:
        - name: mongo
          image: mongo:latest
          resources:
            requests:
              memory: 512M
              cpu: 1.0
            limits:
              memory: 512M
              cpu: 1.0
          ports:
          - containerPort: 27017

END
)

function export_prefixed_variables(){
    VARIABLES_TMP_FILE=$(mktemp)

    (set -o posix ; set) | grep "^${PREFIX}" | while read -r key_value ; do
        _NAME=`echo ${key_value} | cut -d"=" -f1`
        _NAME_WITHOUT_PREFIX=${_NAME#*${PREFIX}}
        _VALUE=`echo ${key_value} | cut -d"=" -f2`
        
        # because 'while/loop' create a subshell we cannot easily export variables from here
        # that's why we generate a file and 'source' this file outside of the loop.
        echo "export ${_NAME_WITHOUT_PREFIX}=${_VALUE}" >> "${VARIABLES_TMP_FILE}"
    done

    source ${VARIABLES_TMP_FILE}

    # cleanup
    rm "${VARIABLES_TMP_FILE}"
}

function deploy_resource(){
    DEPLOYMENT_TMP_FILE=$(mktemp)
    
    # create resource deployment definition
    echo "${KUBE_RESOURCE_DEPLOYMENT_CONFIG}" > "${DEPLOYMENT_TMP_FILE}"

    # deploy
    kubectl --kubeconfig "${KUBE_ADMIN_CONFIG_PATH}" create -f "${DEPLOYMENT_TMP_FILE}"
    export DEPLOYMENT_STATUS=$?

    # cleanup
    rm "${DEPLOYMENT_TMP_FILE}"
}

function handle_error_and_exit(){
    if [ "${DEPLOYMENT_STATUS}" -eq 0 ]
    then
        exit 0
    else
        echo "Failed to deploy"
        exit "${DEPLOYMENT_STATUS}"
    fi
}

export_prefixed_variables
deploy_resource
handle_error_and_exit
