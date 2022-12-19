pipelineJob("Initialize System") {
    description("Pipeline Job for initializing the Jenkins server")
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
                scriptPath("aws/k3s-terraform-cluster/pipelines-as-code/jenkins/bootstrap/init/Jenkinsfile.groovy")
            }
        }
    }
}
