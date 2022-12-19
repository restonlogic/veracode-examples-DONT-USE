@Library(['jenkins-library@main']) _

pipeline {
    agent any
    options {
        ansiColor('xterm')
        timeout(time: 1, unit: 'HOURS')
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
        stage("Reset Folders") {
            steps {
                script {
                    build job: 'single-seed-job', parameters: [
                        string(name: 'job_dsl_path', value: 'pipelines-as-code/jenkins/folders/dsl.groovy')
                    ]
                }
            }
        }
    }
}