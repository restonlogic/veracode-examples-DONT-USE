pipelineJob("set-folders") {
    description("Pipeline Job for setting the folder structure of the Jenkins server")
    definition {
        cpsScm {
            scm {
                git {
                    branch("main")
                    remote {
                        credentials("git-creds")
                        url("\${primary-repo}")
                    }
                }
                scriptPath("pipelines-as-code/jenkins/bootstrap/set-folders/Jenkinsfile.groovy")
            }
        }
    }
}