#!/bin/bash

set -e

if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
	EVENT_ACTION=$(jq -r ".action" "${GITHUB_EVENT_PATH}")
	if [[ "${EVENT_ACTION}" != "opened" ]]; then
		echo "No need to run analysis. It is already triggered by the push event."
		exit
	fi
fi

REPOSITORY_NAME=$(basename "${GITHUB_REPOSITORY}")

[[ ! -z ${INPUT_PASSWORD} ]] && SONAR_PASSWORD="${INPUT_PASSWORD}" || SONAR_PASSWORD=""

echo "input host: ${INPUT_HOST}" 
if [[ "${INPUT_FQDN}" == "https"*  ]]; then
  if [[ -z ${INPUT_HOST} ]]; then
   >&2 echo "HOST variable must be given when https protcol is used in fqdn"
   exit 1;
  fi
  if [[ -z ${INPUT_PORT} ]]; then
   >&2 echo "PORT variable must be given when https protocol is used in fqdn"
   exit 1;
  fi
  echo "" | openssl s_client -connect ${INPUT_HOST}:${INPUT_PORT} -showcerts 2>/dev/null | openssl x509 -out certfile.txt
  keytool -importcert -noprompt -alias server-cert -file certfile.txt -trustcacerts -keystore ./cacerts -storetype JKS -storepass changeme
  cat ./cacerts
fi

if [[ ! -f "${GITHUB_WORKSPACE}/sonar-project.properties" ]]; then
  [[ -z ${INPUT_PROJECTKEY} ]] && SONAR_PROJECTKEY="${REPOSITORY_NAME}" || SONAR_PROJECTKEY="${INPUT_PROJECTKEY}"
  [[ -z ${INPUT_PROJECTNAME} ]] && SONAR_PROJECTNAME="${REPOSITORY_NAME}" || SONAR_PROJECTNAME="${INPUT_PROJECTNAME}"
  [[ -z ${INPUT_PROJECTVERSION} ]] && SONAR_PROJECTVERSION="" || SONAR_PROJECTVERSION="${INPUT_PROJECTVERSION}"
  sonar-scanner \
    -Dsonar.host.url=${INPUT_FQDN} \
    -Dsonar.projectKey=${SONAR_PROJECTKEY} \
    -Dsonar.projectName=${SONAR_PROJECTNAME} \
    -Dsonar.projectVersion=${SONAR_PROJECTVERSION} \
    -Dsonar.projectBaseDir=${INPUT_PROJECTBASEDIR} \
    -Dsonar.login=${INPUT_LOGIN} \
    -Dsonar.password=${SONAR_PASSWORD} \
    -Dsonar.sources=. \
    -Dsonar.sourceEncoding=UTF-8 \
    -Djavax.net.ssl.trustStore=./cacerts
else
  sonar-scanner \
    -Dsonar.host.url=${INPUT_FQDN} \
    -Dsonar.projectBaseDir=${INPUT_PROJECTBASEDIR} \
    -Dsonar.login=${INPUT_LOGIN} \
    -Dsonar.password=${SONAR_PASSWORD} \
    -Djavax.net.ssl.trustStore=./cacerts
fi
