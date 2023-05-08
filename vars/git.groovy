#!/usr/bin/groovy
/**
 * Clone a repository and checkout a specific branch from my GitHub account.
 * @param repository The repository in my GitHub account to clone.
 * @param branch The branch to checkout once cloned.
 */
import jenkins.*
import jenkins.model.* 
import hudson.*
import hudson.model.*

def getSecretString(String secretID) {
    def jenkinsCredentials = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials( com.cloudbees.plugins.credentials.common.StandardCredentials.class, Jenkins.instance, null, null );
    for (creds in jenkinsCredentials) {
    if(creds.id == secretID){
        return (creds.getSecret())
        }
    }
}

def basicClone(String repository, String branch = 'main') {
    def gitURL = getSecretString('github-url')
    def gitORG = getSecretString('github-organization')
    checkout([
        $class: 'GitSCM',
        branches: [[name: "*/$branch"]],
        doGenerateSubmoduleConfigurations: false,
        extensions: [],
        submoduleCfg: [],
        userRemoteConfigs: [[
            credentialsId: 'GIT_TOKEN',
            url: "https://$gitURL/$gitORG/${repository}.git"
        ]]
    ])
}