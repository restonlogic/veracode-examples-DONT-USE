@Library(['jenkins-library@main']) _
def buildNumber = env.BUILD_NUMBER
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
                image      = "counter-service"
                env        = sh(script: "jq '.global_config.environment' -r manifest.json", returnStdout: true).trim()
                name       = sh(script: "jq '.global_config.name' -r manifest.json", returnStdout: true).trim()
                region     = sh(script: "jq '.global_config.region' -r manifest.json", returnStdout: true).trim()
                org        = sh(script: "jq '.global_config.organization' -r manifest.json", returnStdout: true).trim()
                acme_email = sh(script: "jq '.cluster_config.certmanager_email_address' -r manifest.json", returnStdout: true).trim()
                build_tag  = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                veracode_api_id = sh(script: "aws secretsmanager get-secret-value --region $region --secret-id /$name/$env/veracode-secrets --query SecretString --output text | jq -r '.\"veracode-api-id\"'",
                                  returnStdout: true).trim()
                veracode_api_key = sh(script: "aws secretsmanager get-secret-value --region $region --secret-id /$name/$env/veracode-secrets --query SecretString --output text | jq -r '.\"veracode-api-key\"'",
                                  returnStdout: true).trim()
                veracode_sca_key = sh(script: "aws secretsmanager get-secret-value --region $region --secret-id /$name/$env/veracode-secrets --query SecretString --output text | jq -r '.\"veracode-sca-key\"'",
                                  returnStdout: true).trim()
                ecr_repo_url   = sh(script: "aws secretsmanager get-secret-value --region $region --secret-id /$name/$env/ecr-repo/$image | jq -r '.SecretString'",
                                  returnStdout: true).trim()
                ecr_password   = sh(script: "aws ecr get-login-password --region $region", returnStdout: true).trim()
                ext_lb_dns     = sh(script: "aws elbv2 describe-load-balancers --names k3s-ext-lb-$env --region $region | jq -r '.LoadBalancers[].DNSName'",
                                  returnStdout: true).trim()
              sh """
                k3s_kubeconfig=/tmp/k3s_kubeconfig
                aws secretsmanager get-secret-value --secret-id k3s-kubeconfig-${name}-${env}-${org}-${env}-v2 --region $region | jq -r '.SecretString' > \$k3s_kubeconfig
                export KUBECONFIG=\$k3s_kubeconfig
                """
            }
          }
        }
      }

      stage("Veracode Static Code Analysis") {
        steps {
          script {
            dir("${projectDir}/microservices/$image") {
            sh """
            zip -r app.zip app
            """
            veracode applicationName: "${image}", createProfile: true, criticality: "Medium", debug: true, waitForScan: true, deleteincompletescan: 2, scanName: "counter-service-build-${buildNumber}", uploadIncludesPattern: 'app.zip', vid: "${veracode_api_id}", vkey: "${veracode_api_key}"
          }
        }
      }
    }
  
    //   stage("Veracode Software Composition Analysis") {
    //     steps {
    //       script {
    //         dir("${projectDir}/microservices/$image") {
    //             sh """
    //             cd app
    //             export SRCCLR_API_TOKEN=${veracode_sca_key}
    //             curl -sSL https://download.sourceclear.com/ci.sh | sh
    //             """
    //       }
    //     }
    //   }
    // }
    
      stage("Build Image") {
        steps {
          script {
            dir("${projectDir}/microservices/$image") {
                sh """
                docker build -t $ecr_repo_url:$buildNumber -t $ecr_repo_url:$build_tag -t $ecr_repo_url:$branch .
                """
          }
        }
      }
    }
    
      stage("Push Image to ECR") {
        steps {
          script {
            dir("${projectDir}/microservices/$image") {
                sh """
                docker login --password $ecr_password --username AWS $ecr_repo_url
                docker image push --all-tags $ecr_repo_url
                """
          }
        }
      }
    }

      stage("Prepare Kubernetes Namespace") {
        steps {
          script {
            dir("${projectDir}") {
              sh """
              kubectl create namespace $image --dry-run=client -o yaml | kubectl apply -f -
              kubectl create secret -n $image docker-registry regcred --docker-server=$ecr_repo_url --docker-username=AWS --docker-password=$ecr_password --docker-email=$acme_email --dry-run=client -o yaml | kubectl apply -f -
              """
          }
        }
      }
    }

      stage("Generate Kubernetes manifests") {
        steps {
          script {
            dir("${projectDir}") {
              sh """
              make -f pipelines-as-code/jenkins/Makefile generate-manifests \
                      serviceName=$image \
                      environment=$env \
                      portNumber=8080 \
                      imageName=$ecr_repo_url \
                      imageTag=$build_tag \
                      nameSpace=$image \
                      pathPrefix="/$image" \
                      repoFolder=${projectDir}
              """
          }
        }
      }
    }
  
      stage("Deploy Manifests") {
        steps {
          script {
            dir("${projectDir}") {
              sh """
              kubectl apply -f ${image}.yaml
              kubectl apply -f ingress.yaml
              """
          }
        }
      }
    }

    stage("Healthcheck") {
      steps {
        dir("${projectDir}") {
          sh """
            bash -c 'while [[ "\$(curl -s -o /dev/null -w ''%{http_code}'' http://${ext_lb_dns}/${image}/)" != "200" ]]; do echo "waiting for $image healtheck to pass, sleeping.";\\sleep 5; done; echo "$image url: http://${ext_lb_dns}/${image}/"'
          """
        }
      }
    }

    stage("Clean Workspace") {
        steps {
          script {
            cleanWs()
            sh """
            docker rmi -f \$(docker images -q $ecr_repo_url:*)
            """
          }
        }
    }
  }
}