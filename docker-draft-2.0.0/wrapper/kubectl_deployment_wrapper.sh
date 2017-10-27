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
{
    "metadata" : {
      "name" : "apache-2-du-7861ea01-a281-436d-823b-ee4422ff4e01"
    },
    "apiVersion" : "apps/v1beta1",
    "kind" : "Deployment",
    "spec" : {
      "template" : {
        "metadata" : {
              "labels": { "apache":"k",
              "app":"apache-2-du-7861ea01-a281-436d-823b-ee4422ff4e01"
              }
        },
        "spec" : {
          "containers" : [ {
            "image" : "httpd:latest",
            "name" : "apache",
            "resources" : {
              "requests" : {
                "memory" : "128Mi",
                "cpu" : 1.0
              },
              "limits" : {
                "memory" : "128Mi",
                "cpu" : 1.0
              }
            },
            "ports" : [ {
              "containerPort" : 80
            } ]
          } ]
        }
      }
    }
  }

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
    DEPLOYMENT_ID=$(kubectl --kubeconfig "${KUBE_ADMIN_CONFIG_PATH}" create -f "${DEPLOYMENT_TMP_FILE}" | sed -r 's/deployment "([a-zA-Z0-9\-]*)" created/\1/')
    export DEPLOYMENT_STATUS=$?

    # cleanup
    rm "${DEPLOYMENT_TMP_FILE}"

    exit_if_error

    command="kubectl --kubeconfig "${KUBE_ADMIN_CONFIG_PATH}" get deployment ${DEPLOYMENT_ID} -o=jsonpath={.status.conditions[*].status}"

    wait_until_done_or_exit "$command" 20
}

function wait_until_done_or_exit {
  command=$1
  max_retries=$2

  retries=0
  cmd_output=$(echo $command | sh)
  cmd_code=$?
  while [ "${cmd_code}" -eq "0" ] && [ "${retries}" -lt "${max_retries}" ] ; do
    case "${cmd_output}" in 
    *False*)
      # At least one condition is not fulfil - keep going
      ;;
    *)
      # All conditions are fufilled
      echo "Success"
      break
      ;;
    esac

    echo "Waiting deployment ... (${retries}/${max_retries})"
    sleep 5
    retries=$((${retries}+1))
    cmd_output=$(echo $command | sh)
    cmd_code=$?
  done

  if [ "${retries}" -eq "${max_retries}" ] ; then
    echo "Exit with error while executing $command. Reached max retries (=$max_retries)"
    exit 1
  fi
}

function exit_if_error(){
    if [ "${DEPLOYMENT_STATUS}" -ne 0 ]
    then
        echo "Failed to deploy"
        exit "${DEPLOYMENT_STATUS}"
    fi
}

export_prefixed_variables
deploy_resource

exit 0
