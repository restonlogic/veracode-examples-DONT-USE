#!/usr/bin/groovy

/**
 * Functions used to kick of security / build scans for our services.
 */
import org.apache.commons.lang.RandomStringUtils

def zapScan(String uiEndpoint, String reportsDir) {
    String randomString = org.apache.commons.lang.RandomStringUtils.random(5, true, true)
    sh """
        #sudo docker stop zap >/dev/null 2>&1 || true
        #sudo docker rm zap >/dev/null 2>&1 || true
        mkdir -p reports
        chmod 777 reports
        sudo docker run --detach --name zap-$randomString -u zap  -p 8080:8080 -v $reportsDir:/zap/reports/:rw -i owasp/zap2docker-stable zap.sh -daemon -host 0.0.0.0 -port 8080  -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true -config api.disablekey=true
        sleep 30
        sudo docker exec zap-$randomString zap-cli --verbose quick-scan http://$uiEndpoint -l Low
        #sudo docker exec zap-$randomString zap-cli --verbose report -o $reportsDir/report.html --output-format html
        sudo docker stop zap-$randomString >/dev/null 2>&1 || true
        sudo docker rm zap-$randomString >/dev/null 2>&1 || true
    """
}

def katalon(String katalonAPIKEY) {
    sh """
        docker run -t -d --restart always --mount source=katalon-runtime-engines,target=/root/.katalon \
              -e SERVER_URL=https://analytics.katalon.com \
              -e KATALON_USERNAME=jalfaro@ttsiglobal.com \
              -e AGENT_NAME=my_docker_agent \
              -e TEAM_ID=238793 \
              -e KATALON_API_KEY=b36d51b9-f028-4ef5-a2a0-085f60086de0 \
              katalonstudio/agent:latest
    """
}

def selenium(String ui_endpoint_url, String selenium_endpoint_url, String dir) {
    sh """
        cd $dir
        ./mvnw clean test -Dhost=\"http://$ui_endpoint_url\" -Dhub=\"http://$selenium_endpoint_url\"
    """
}

def postman(String base_api_url, String api_folder) {
    sh """
        cd $dir
        echo "docker run -v ${PWD}/testing/API:/etc/newman public.ecr.aws/f5l4p8k6/postman/newman:5.2.3-alpine \
            run API.postman_collection.json \
          --env-var BASE_API_URL=$base_api_url  \
          --folder \"$api_folder\""
        docker run -v ${PWD}/testing/API:/etc/newman public.ecr.aws/f5l4p8k6/postman/newman:5.2.3-alpine \
            run API.postman_collection.json \
          --env-var BASE_API_URL=$base_api_url  \
          --folder "$api_folder"
    """
}

def sonarFrontend(String scanDir) {
    sh """
        cd $scanDir
        export SONAR_LB=\$(aws secretsmanager get-secret-value --secret-id /mgmt/sonarqube/alb_dns | jq -r '.SecretString')
        export SONARQUBE_URL="http://${SONAR_LB}"
        export SONARQUBE_ADMIN=\$(aws secretsmanager get-secret-value --secret-id /mgmt/sonarqube/username | jq -r '.SecretString')
        export SONARQUBE_PASS=\$(aws secretsmanager get-secret-value --secret-id /mgmt/sonarqube/password | jq -r '.SecretString')
        /tmp/sonar-scanner-4.6.2.2472-linux/bin/sonar-scanner \
            -Dsonar.host.url=$SONARQUBE_URL \
            -Dsonar.login=$SONARQUBE_ADMIN \
            -Dsonar.password=$SONARQUBE_PASS \
            -Dsonar.projectKey=${IMAGE_APP_TAG}:${LATEST_IMAGE_TAG} \
            -Dsonar.projectName=${IMAGE_APP_TAG}:${LATEST_IMAGE_TAG} \
            -Dsonar.sources=src \
            -Dsonar.language=js \
            -Dsonar.tests=. \
            -Dsonar.exclusions=src/**/*.spec.js \
            -Dsonar.test.inclusions=src/**/*.spec.js \
            -Dsonar.coverage.exclusions=src/**/*.spec.js,src/**/*.mock.js,node_modules/*,coverage/lcov-report/* \
            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
            -Dsonar.test.inclusions=**/*test*/**
    """
}

def sonarBackend(String scanDir) {
    sh """
        cd $scanDir
        export SONAR_LB=\$(aws secretsmanager get-secret-value --secret-id /mgmt/sonarqube/alb_dns | jq -r '.SecretString')
        export SONARQUBE_URL="http://${SONAR_LB}"
        export SONARQUBE_ADMIN=\$(aws secretsmanager get-secret-value --secret-id /mgmt/sonarqube/username | jq -r '.SecretString')
        export SONARQUBE_PASS=\$(aws secretsmanager get-secret-value --secret-id /mgmt/sonarqube/password | jq -r '.SecretString')
        tr -d '\r' < ./mvnw > mvnw
        bash ./mvnw -q -ntp clean package sonar:sonar \
            -Dsonar.host.url=$SONARQUBE_URL \
            -Dsonar.login=$SONARQUBE_ADMIN \
            -Dsonar.password=$SONARQUBE_PASS \
            -Dsonar.projectKey=${IMAGE_APP_TAG}:${LATEST_IMAGE_TAG} \
            -Dsonar.projectName=${IMAGE_APP_TAG}:${LATEST_IMAGE_TAG} \
            -Dsonar.sources=src/main/java \
            -Dsonar.language=java \
            -Dsonar.tests=. \
            -Dsonar.test.inclusions=**/*test*/** 
    """
}