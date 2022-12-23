@Library(['jenkins-library@main']) _
pipeline {
    agent any
    options {
        ansiColor('xterm')
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        buildDiscarder(
            logRotator(daysToKeepStr: '10', numToKeepStr: '5')
        )
    }
    stages {
        stage("Clean Workspace") {
            steps {
                script {
                    cleanWs()
                }
            }
        }

        stage("Checkout Repository") {
            steps {
                script {
                    gitopsOrgUrl = genericsteps.getSecretString('gitops-org-url')
                    repo = genericsteps.getSecretString('gitops-repo')
                    branch = genericsteps.getSecretString('gitops-branch')
                    repoFolder  = "/repos/${repo}"
                    genericsteps.checkoutGitRepository("${repoFolder}", "${gitopsOrgUrl}/${repo}.git", "${branch}", 'git-creds')
                }
            }
        }

        stage("Create Jobs") {
            steps {
                script {
                    build(job: 'set-folders', propagate: true, wait: true)

                    build(
                        job: 'seed-job',
                        propagate: true
                    )

                    build(job: 'set-folders', propagate: true, wait: true)
                }
            }
        }
    }
}