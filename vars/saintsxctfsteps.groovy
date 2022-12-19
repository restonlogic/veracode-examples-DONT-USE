#!/usr/bin/groovy

/**
 * Jenkins pipeline steps used in SaintsXCTF pipelines.
 * @author Andrew Jarombek
 * @since 6/22/2020
 */

/**
 * Build a Docker image for the SaintsXCTF auth service.
 * @param subDir Subdirectory in the saints-xctf-auth repository to build the image from.
 * @param zipFilename AWS lambda function zip filename.
 * @param imageName Name of the Docker image to create.
 */
def buildImage(String subDir, String zipFilename, String imageName) {
    dir("repos/saints-xctf-auth/$subDir") {
        sh """
            sudo docker image build \
                -f ../Dockerfile \
                -t python-lambda-dist:latest \
                --network=host \
                --build-arg ZIP_FILENAME=$zipFilename .

            sudo docker image build -t $imageName:latest .
        """
    }
}

/**
 * Push a new Docker image to DockerHub.
 * @param imageName Name of a Docker image.
 * @param imageLabel Label to assign to the image.
 * @param isLatest Whether or not this label is the latest image version.
 */
def pushImage(String imageName, String imageLabel, boolean isLatest) {
    withCredentials([
        usernamePassword(
            credentialsId: 'ajarombek-docker-hub',
            passwordVariable: 'dockerPassword',
            usernameVariable: 'dockerUsername'
        )
    ]) {
        sh 'sudo docker login -u $dockerUsername -p $dockerPassword'
    }

    if (isLatest) {
        sh """
            sudo docker image tag $imageName:latest ajarombek/$imageName:latest
            sudo docker push ajarombek/$imageName:latest
        """
    }

    sh """
        sudo docker image tag $imageName:latest ajarombek/$imageName:$imageLabel
        sudo docker push ajarombek/$imageName:$imageLabel
    """
}

/**
 * Remove Docker images from the node this job is running on.
 * @param imageName Name of a Docker image.
 * @param imageLabel Label to assign to the image.
 * @param isLatest Whether or not this label is the latest image version.
 */
def cleanupImages(String imageName, String imageLabel, boolean isLatest) {
    if (isLatest) {
        sh "sudo docker image rm ajarombek/$imageName:latest"
    }

    sh """
        sudo docker image rm $imageName:latest
        sudo docker image rm ajarombek/$imageName:$imageLabel
        
        sudo docker image ls
    """
}