@Library(['jenkins-library@main']) _
pipeline {
    agent { label 'built-in' }
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

        // stage("Configure Snow Connection") {
        //     steps {
        //         script {
        //             def config = [
        //                         instanceUrl: env.SERVICENOW_INSTANCE,
        //                         toolId: env.SERVICENOW_USERNAME.id,
        //                         passwordCredentialsId: env.SERVICENOW_PASSWORD.id,
        //                         useOAuth: false
        //                     ]
        //         }
        //     }
        // }


        stage("Create Jobs") {
            steps {
                script {
                    build(job: 'set-folders', propagate: true, wait: true)

                    build(job: 'seed-job', propagate: true, wait: true)

                    build(job: 'set-folders', propagate: true, wait: true)
                }
            }
        }

        stage("Trigger Counter Service Pipeline") {
             when {
                 beforeAgent true
                 anyOf {
                     changeset "**/aws/k3s-terraform-cluster/microservices/counter-service/**"
                     changeset "**/aws/k3s-terraform-cluster/pipelines-as-code/jenkins/counter-service/**"
                     expression{env.BUILD_NUMBER == '1'}
                 }
             }
             steps {
               script {
                   build(job: 'microservice-pipelines/counter-service', propagate: true, wait: true)
               }
             }
        }
    }
}