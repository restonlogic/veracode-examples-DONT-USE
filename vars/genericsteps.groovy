#!/usr/bin/groovy

/**
 * Generic Jenkins pipeline steps that can be reused throughout the Jenkins server.
 * @author Andrew Jarombek
 * @since 6/22/2020
 */

/**
 * Checkout a repository into a standard 'repo' directory.  Reusing this function makes repository code locations
 * more predictable.
 * @param name The name of the git repository.
 * @param branch The branch to checkout.
 */
def checkoutRepo(String name, String branch) {
    dir("repos/$name") {
        git.basicClone(name, branch)
    }
}

/**
 * Generic script to use in the 'post' section of a declarative pipeline.
 * @param bodyTitle The title section of the email body.
 * @param bodyContent Additional content added to the body of the email.
 * @param jobName The name of the Jenkins job which triggered this email.
 * @param buildStatus Status of the Jenkins job build that triggered this email.
 * @param buildNumber Execution number of the Jenkins job build that triggered this email.
 * @param buildUrl URL of the Jenkins job build that triggered this email.
 */
def postScript(String bodyTitle, String bodyContent, String jobName, String buildStatus,
               String buildNumber, String buildUrl) {
    email.sendEmail(bodyTitle, bodyContent, jobName, buildStatus, buildNumber, buildUrl)
    cleanWs()
}

/**
 * Run a Shell script in a specific directory.  The result of the bash script determines the status of the build.
 * @param script The shell script to run.
 * @param directory The directory to run the shell script within.
 * @param failureStatus The pipeline status if the shell script returns a non-zero exit code.
 */
def shReturnStatus(String script, String directory = '.', String failureStatus = 'UNSTABLE') {
    dir(directory) {
        def status = sh (
            script: script,
            returnStatus: true
        )

        if (status >= 1) {
            currentBuild.result = failureStatus
        } else {
            currentBuild.result = "SUCCESS"
        }
    }
}

def checkoutGitRepository(path, url, branch, credentialsId = null, poll = true, timeout = 10, depth = 0){
    dir(path) {
        checkout(
            changelog:true,
            poll: poll,
            scm: [
                $class: 'GitSCM',
                branches: [[name: "*/${branch}"]],
            doGenerateSubmoduleConfigurations: false,
            extensions: [
                [$class: 'CheckoutOption', timeout: timeout],
                [$class: 'CloneOption', depth: depth, noTags: false, reference: '', shallow: depth > 0, timeout: timeout]],
            submoduleCfg: [],
            userRemoteConfigs: [[url: url, credentialsId: credentialsId]]]
        )
        sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
    }
}

def compareCommit(String dirPath) {
    sh """
        if [ ! -d "$dirPath" ]; then
            echo "Directory '$dirPath' not exists"
            exit 1
        fi
        if [ -z "\$GIT_COMMIT" ]; then
            echo "No current commit... fail"
            exit 1
        fi
        if [ -z "\$GIT_PREVIOUS_COMMIT" ]; then
            echo "No previous commit, files are changed!"
            exit 0
        fi
        # Check is files in given directory changed between commits
        CHANGED=`git diff --name-only \$GIT_PREVIOUS_COMMIT \$GIT_COMMIT $dirPath`
        if [ -z "\$CHANGED" ]; then
            echo "No changes dettected..."
            echo false > commandResult
        else
            echo "Directory changed. Continuing with the build"
            echo true > commandResult
        fi
    """
    def result = readFile('commandResult').trim()
    if( result == "false" ) {
        currentBuild.result = 'SUCCESS'
        return
    }
}

def getSecretString(String secretID) {
    def jenkinsCredentials = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials( com.cloudbees.plugins.credentials.common.StandardCredentials.class, Jenkins.instance, null, null );
    for (creds in jenkinsCredentials) {
      if(creds.id == secretID) {
          return (creds.getSecret())
      }
    }
}