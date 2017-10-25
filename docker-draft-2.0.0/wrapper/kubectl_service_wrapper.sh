#!/bin/bash

# configuration
KUBE_ADMIN_CONFIG_PATH=admin.conf

KUBE_SERVICE_CONFIG=$(cat <<-END
apiVersion: v1
kind: Service
metadata:
  name: mongo-service # Should generate a uniq name
spec:
  ports:
  - name: mongo-docker-endpoint
    port: 3000
  type: NodePort
  selector:
    app: containerdeploymentunit_mongo # podname
END
)

function deploy_service(){
    SERVICE_CONFIG_TMP_FILE=$(mktemp)
    
    # create kube service config file
    echo "${KUBE_RESOURCE_DEPLOYMENT_CONFIG}" > "${SERVICE_CONFIG_TMP_FILE}"

    # get service name
    SERVICE_NAME=$(kubectl --kubeconfig "${KUBE_ADMIN_CONFIG_PATH}" describe -f "${SERVICE_CONFIG_TMP_FILE}" | grep "Name:" | sed -r 's/Name:[ ]*([a-zA-Z0-9\-]*)/\1/')

    # deploy service
    kubectl --kubeconfig "${KUBE_ADMIN_CONFIG_PATH}" create -f "${SERVICE_CONFIG_TMP_FILE}"
    SERVICE_DEPLOY_STATUS=$?

    # cleanup
    rm "${SERVICE_CONFIG_TMP_FILE}"

    if [ "${SERVICE_DEPLOY_STATUS}" -ne 0 ]
        echo "Failed to deploy service"
        exit "${SERVICE_DEPLOY_STATUS}"
    fi

    # get IP/PORT
    export SERVICE_IP=$(kubectl --kubeconfig "${KUBE_ADMIN_CONFIG_PATH}" get services "${SERVICE_NAME}" -o=jsonpath={.spec.clusterIP})
    # export SERVICE_PORT=$(kubectl --kubeconfig "${KUBE_ADMIN_CONFIG_PATH}" get services "${SERVICE_NAME}" -o=jsonpath={.spec.ports[0].port})
}

deploy_service
exit 0

