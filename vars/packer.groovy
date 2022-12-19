#!/usr/bin/groovy

/**
 * Functions used to create AMIs with Packer
 * @author Andrew Jarombek
 * @since 5/12/2019
 */

/**
 * Build an AMI on AWS based on a Packer template file
 * @param directory The directory path of the Packer template
 * @param filename The filename of the Packer template
 * @param repository Git repository that the Packer template exists in
 * @param branch Branch of the Git repository containing the proper Packer template
 */
def packerBuild(String directory, String filename, String repository, String branch) {
    stage("checkout") {
        cleanWs()

        // Perform a sparse checkout
        checkout([$class: 'GitSCM',
            branches: [[name: "*/$branch"]],
            doGenerateSubmoduleConfigurations: false,
            extensions: [
                [$class: 'SparseCheckoutPaths',
                 sparseCheckoutPaths: [[$class: 'SparseCheckoutPath', path: directory]]]
            ],
            submoduleCfg: [],
            userRemoteConfigs: [[
                credentialsId: 'ajarombek-github',
                url: "git@github.com:AJarombek/${repository}.git"
            ]]
        ])
    }
    stage("validate") {
        sh """
            packer --version
            packer validate $filename
        """
    }
    stage("build") {
        sh "packer build $filename"
    }
}