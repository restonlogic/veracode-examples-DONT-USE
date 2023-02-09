#!/usr/bin/groovy

/**
 * Pipeline step scripts used to test AWS Infrastructure.
 * @author Andrew Jarombek
 * @since 7/3/2020
 */

/**
 * Setup a Python environment to execute AWS infrastructure tests with boto3.
 * @param directory Directory containing the infrastructure tests.
 */
def setupEnvironment(String directory) {
    dir(directory) {
        sh '''
            set +e
            set -x
            python --version
            python -m pip --version

            sudo pip install pipenv
            pipenv --rm
            pipenv install
        '''
    }
}

/**
 * Execute the boto3 AWS infrastructure tests.
 * @param directory Directory containing the infrastructure tests.
 * @param testEnv Environment to test infrastructure for.
 */
def executeTests(String directory, String testEnv) {
    dir(directory) {
        try {
            def status = sh (
                script: "#!/bin/bash \n" +
                """
                    # The AWS SDK needs to know which region the infrastructure is in.
                    export AWS_DEFAULT_REGION=us-east-1
                    export TEST_ENV=$testEnv
                    
                    pipenv run python runner.py test_results.log
                    exit_status=\$?

                    cat test_results.log
                    exit \$exit_status
                """,
                returnStatus: true
            )

            if (status >= 1) {
                currentBuild.result = "UNSTABLE"
            } else {
                currentBuild.result = "SUCCESS"
            }
        } catch (Exception ex) {
            echo "Infrastructure Testing Failed"
            currentBuild.result = "FAILURE"
        }
    }
}

/**
 * Script to use in the 'post' section of a declarative pipeline for AWS infrastructure tests.
 * @param directory Directory containing the infrastructure tests.
 * @param bodyTitle The title section of the email body.
 * @param jobName The name of the Jenkins job which triggered this email.
 * @param buildStatus Status of the Jenkins job build that triggered this email.
 * @param buildNumber Execution number of the Jenkins job build that triggered this email.
 * @param buildUrl URL of the Jenkins job build that triggered this email.
 * @return
 */
def postScript(String directory, String bodyTitle, String jobName, String buildStatus, String buildNumber,
               String buildUrl) {
    def bodyContent = ""
    def testResultLog = ""

    dir(directory) {
        testResultLog = readFile "test_results.log"
    }

    testResultLog.split('\n').each {
        bodyContent += "<p style=\"font-family: Consolas,monaco,monospace\">$it</p>"
    }

    genericsteps.postScript(bodyTitle, bodyContent, jobName, buildStatus, buildNumber, buildUrl)
}