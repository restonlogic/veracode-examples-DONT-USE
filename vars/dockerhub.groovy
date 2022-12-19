#!/usr/bin/groovy

/**
 * Jenkins pipeline steps used with Dockerhub.
 * @author Andrew Jarombek
 * @since 10/3/2020
 */

/**
 * Authenticate with my Dockerhub account.
 */
def auth() {
    withCredentials([
        usernamePassword(
            credentialsId: 'ajarombek-docker-hub',
            passwordVariable: 'dockerPassword',
            usernameVariable: 'dockerUsername'
        )
    ]) {
        sh 'sudo docker login -u $dockerUsername -p $dockerPassword'
    }
}

/**
 * Push a Docker image to my Dockerhub account.
 * @param imageName Name of the Docker image.
 * @param imageLabel Label (version) given to the Docker image.
 */
def pushImage(String imageName, String imageLabel = 'latest') {
    sh """
        sudo docker image tag $imageName:latest ajarombek/$imageName:$imageLabel
        sudo docker push ajarombek/$imageName:$imageLabel
    """
}