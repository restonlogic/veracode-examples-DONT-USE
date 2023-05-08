#!/usr/bin/groovy
/**
 * Create a generic email with results from a Jenkins build.
 * @param bodyTitle The title section of the email body.
 * @param bodyContent Additional content added to the body of the email.
 * @param jobName The name of the Jenkins job which triggered this email.
 * @param buildStatus Status of the Jenkins job build that triggered this email.
 * @param buildNumber Execution number of the Jenkins job build that triggered this email.
 * @param buildUrl URL of the Jenkins job build that triggered this email.
 */
import jenkins.*
import jenkins.model.* 
import hudson.*
import hudson.model.*
def sendEmail(String bodyTitle, String bodyContent, String jobName, String buildStatus,
              String buildNumber, String buildUrl) {

    def statusColors = [
        SUCCESS: '#28a745',
        UNSTABLE: '#ffc107',
        FAILURE: '#dc3545',
        OTHER: '#bbb'
    ]

    def statusEmojis = [
        SUCCESS: '✅',
        UNSTABLE: '⚠️',
        FAILURE: '❌',
        OTHER: '❗'
    ]

    def subject = "${statusEmojis[buildStatus] ?: statusEmojis['OTHER']} $jobName Build #$buildNumber - $buildStatus"
    def body = """
        <body>
            <h1 style="font-family: Calibri, Arial, sans-serif">${bodyTitle}</h1>
            <p style="font-family: Calibri, Arial, sans-serif">
                Build 
                <a href="$buildUrl" style="font-weight: bold; color: #777;">$buildNumber</a> 
                Result:
                <strong style="color: ${statusColors[buildStatus] ?: statusColors['OTHER']}">
                    $buildStatus
                </strong>
                $bodyContent
            </p>
        </body>
    """

    emailext(
        subject: subject,
        body: body,
        to: "brandon.samuel@restonlogic.com",
        mimeType: 'text/html'
    )
}

def sendMattermost(String status, String message, String text, String channel, String endpoint) {

    //def mattermost = Jenkins.instance.getPlugin("mattermost")
    def mattermost_icon = "https://jenkins.io/images/logos/jenkins/jenkins.png"

    def statusColors = [
        start: '#8908D4',
        success: '#00f514',
        failure: '#e00707'
    ]

    def statusEmojis = [
        start: ':hatched_chick:',
        success: ':white_check_mark:',
        failure: ':x:'
    ]

    def chnl = channel ?: 'cicd-notifications'

    if(text != null && !text.isEmpty()) {
        mattermostSend(color: "${statusColors[status]}", icon: "$mattermost_icon", message: "${statusEmojis[status]} $message", text: "$text", channel: "$chnl", endpoint: "$endpoint")
    }
    else {
        mattermostSend(color: "${statusColors[status]}", icon: "$mattermost_icon", message: "${statusEmojis[status]} $message", channel: "$chnl", endpoint: "$endpoint")
    }
}