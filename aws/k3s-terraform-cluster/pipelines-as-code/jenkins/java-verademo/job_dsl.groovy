pipelineJob("microservice-pipelines/java-verademo") {
    description("pipeline to deploy java verademo")
    definition {
        cps {
            sandbox()
            script(readFileFromWorkspace("aws/k3s-terraform-cluster/pipelines-as-code/jenkins/java-verademo/Jenkinsfile.groovy"))
        }
    }
}
