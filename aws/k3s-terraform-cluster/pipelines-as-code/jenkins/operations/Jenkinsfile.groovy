@Library(['jenkins-library@main']) _
def buildNumber = env.BUILD_NUMBER
def buildUrl = env.BUILD_URL
def change_sys_id
def incident_sys_id
pipeline {
    agent { label 'built-in' }
    options {
        ansiColor('xterm')
        disableConcurrentBuilds()
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(
            logRotator(daysToKeepStr: '10', numToKeepStr: '5')
        )
    }

  stages {
      stage("Checkout Repository") {
          steps {
              script {
                gitopsOrgUrl = genericsteps.getSecretString('gitops-org-url')
                repo = genericsteps.getSecretString('gitops-repo')
                branch = genericsteps.getSecretString('gitops-branch')
                repoFolder  = "/repos/${repo}"
                projectDir  = "${repoFolder}/aws/k3s-terraform-cluster"
                genericsteps.checkoutGitRepository("${repoFolder}", "${gitopsOrgUrl}/${repo}.git", "${branch}", 'git-creds')
              }
          }
      }
      
      stage ("Pre-Build Setup") {
        steps {
          script {
            dir("${projectDir}") {
              sh """
                echo "Setting env variables"
                """
                env        = sh(script: "jq '.global_config.environment' -r manifest.json", returnStdout: true).trim()
                name       = sh(script: "jq '.global_config.name' -r manifest.json", returnStdout: true).trim()
                region     = sh(script: "jq '.global_config.region' -r manifest.json", returnStdout: true).trim()
                org        = sh(script: "jq '.global_config.organization' -r manifest.json", returnStdout: true).trim()
                build_tag  = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
              sh """
                k3s_kubeconfig=/tmp/k3s_kubeconfig
                aws secretsmanager get-secret-value --secret-id k3s-kubeconfig-${name}-${env}-${org}-${env}-v2 --region $region | jq -r '.SecretString' > \$k3s_kubeconfig
                export KUBECONFIG=\$k3s_kubeconfig
                """
            }
          }
        }
      }

    stage("Create Service Now Change Request") {
        steps {
          script {
            dir("${repoFolder}") {
            change_sys_id = snow.changeRequest("Operations Maintenance Job ${buildNumber}: Running maintenance jobs on kubernetes cluster k3s-${name}-${region}-${env}", "Operations maintenance pipeline is currently running, Link to build: ${buildUrl}", "Operations Maintenance Job ${buildNumber} has started, Link to Job: ${buildUrl}, Commit Hash: ${build_tag}, Kubernetes Cluster: k3s-${name}-${region}-${env}, Environment: ${env}, Region: ${region}", null, null, null, null, null, null)
          }
        }
      }
    }

    stage("Clean up node objects") {
        steps {
          script {
            try {
              dir("${projectDir}/scripts") {
              snow.workNote("Cleaning up kubernetes node objects", "${change_sys_id[0]}")
              sh """
              bash ./cleanup_node_objects.sh
              """
              snow.workNote("Stage Cleanup node objects ran successfully", "${change_sys_id[0]}")
              snow.updateChange("success", "${change_sys_id[0]}")
              }
            }
            catch (Exception e) {
              echo "Exception occured: " + e.toString()
              incident_sys_id = snow.incident("Operations Maintenance Job ${buildNumber}: Failure cleaning up kubernetes node objects on kubernetes cluster k3s-${name}-${region}-${env}", "Clean up node objects failed to run, the error was ${e.toString()}. Link to build: ${buildUrl}, Commit Hash: ${build_tag}, Kubernetes Cluster: k3s-${name}-${region}-${env}, Environment: ${env}, Region: ${region}", "Please review error logs and node objects in cluster k3s-${name}-${region}-${env}", "${change_sys_id[0]}", null, null, null)
              snow.workNote("Failed to cleanup node objects: created incident ${incident_sys_id}, please fix issue.", "${change_sys_id[0]}")
              snow.updateChange("failure", "${change_sys_id[0]}")
              error(e.toString())
            }
          }
        }
      }
    
    stage("Clean Workspace") {
        steps {
          script {
            cleanWs()
        }
      }
    }
  }
}