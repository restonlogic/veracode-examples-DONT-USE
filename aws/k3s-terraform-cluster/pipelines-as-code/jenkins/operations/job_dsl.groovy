pipelineJob("operation-pipelines/kubernetes-maintenance") {
    description("pipeline to conduct maintenance on kubernetes cluster.")
    triggers {
        cron('H/15 * * * *')
    }
    definition {
        cps {
            sandbox()
            script(readFileFromWorkspace("aws/k3s-terraform-cluster/pipelines-as-code/jenkins/operations/Jenkinsfile.groovy"))
        }
    }
}
