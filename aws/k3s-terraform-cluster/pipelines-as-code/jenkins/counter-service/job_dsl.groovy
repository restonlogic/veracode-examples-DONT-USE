pipelineJob("microservice-pipelines/counter-service") {
    description("pipeline to deploy counter service")
    definition {
        cps {
            sandbox()
            script(readFileFromWorkspace("aws/k3s-terraform-cluster/pipelines-as-code/jenkins/counter-service/Jenkinsfile.groovy"))
        }
    }
}
