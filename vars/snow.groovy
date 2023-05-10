#!/usr/bin/groovy
/**
 * Create change requests and incidents in servicenow
 */
import jenkins.*
import jenkins.model.* 
import hudson.*
import hudson.model.*

def getSecretString(String secretID) {
    def jenkinsCredentials = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials( com.cloudbees.plugins.credentials.common.StandardCredentials.class, Jenkins.instance, null, null );
    for (creds in jenkinsCredentials) {
    if(creds.id == secretID){
        return (creds.getSecret())
        }
    }
}

def changeRequest(String short_description, String description, String work_notes, String category, String type, String priority, String assigned_to, String impact, String urgency) {

    def username = getSecretString('snow-usr')
    def password = getSecretString('snow-pwd')
    def url = getSecretString('snow-url')
    def types = type ?: 'Standard'
    def categorys = category ?: 'DevOps'
    def prioritys = priority ?: '3'
    def impacts = impact ?: '3'
    def urgencys = urgency ?: '3'
    def assigned_tos = assigned_to ?: 'DevOps System'
    def change = sh (returnStdout: true, script: """
        curl -s "$url/api/sn_chg_rest/change" --request POST --header "Accept: application/json" --header "Content-Type: application/json" --user '$username':'$password' \\
        --data-raw '{
        "short_description": "$short_description",
        "description": "$description",
        "work_notes": "$work_notes",
        "category": "$categorys",
        "type": "$types",
        "priority": "$prioritys",
        "assigned_to": "$assigned_tos",
        "impact": "$impacts",
        "urgency": "$urgencys" }' | jq -r '.result.sys_id.value'
    """).split()
    return change
}

def problem(String short_description, String description, String change_sys_id) {

    def username = getSecretString('snow-usr')
    def password = getSecretString('snow-pwd')
    def url = getSecretString('snow-url')
    def problem = sh (returnStdout: true, script: """
        curl -s "$url/api/now/table/problem" --request POST --header "Accept: application/json" --header "Content-Type: application/json" --user '$username':'$password' \\
        --data-raw '{
        "short_description": "$short_description",
        "description": "$description",
        "rfc": "$change_sys_id" }' | jq -r '.result.sys_id'
    """).split()
    return problem
}

def incident(String short_description, String description, String work_notes, String change_sys_id, String urgency, String impact, String caller_id) {

    def username = getSecretString('snow-usr')
    def password = getSecretString('snow-pwd')
    def url = getSecretString('snow-url')
    def impacts = impact ?: '3'
    def urgencys = urgency ?: '3'
    def caller_ids = caller_id ?: 'DevOps System'
    def incident = sh (returnStdout: true, script: """
        curl -s "$url/api/now/table/incident" --request POST --header "Accept: application/json" --header "Content-Type: application/json" --user '$username':'$password' \\
        --data-raw '{
        "short_description": "$short_description",
        "description": "$description",
        "work_notes": "$work_notes",
        "impact": "$impacts",
        "urgency": "$urgencys",
        "caller_id": "$caller_ids",
        "rfc": "$change_sys_id" }' | jq -r '.result.sys_id'
    """).split()
    return incident
}

def updateChange(String status, String change_sys_id) {

    def username = getSecretString('snow-usr')
    def password = getSecretString('snow-pwd')
    def url = getSecretString('snow-url')

    def statusState = [
        success: '3',
        failure: '0'
    ]

    def statusType = [
        success: 'Successful',
        failure: 'Unsuccessful'
    ]

    def statusMessage = [
        success: 'Change implemented successfully',
        failure: 'Change implemented unsuccessfully, please review problems & incidents to resolve issues.'
    ]

    def change = sh (returnStdout: true, script: """
        curl -s "$url/api/now/table/change_request/$change_sys_id" --request PUT --header "Accept: application/json" --header "Content-Type: application/json" --user '$username':'$password' \\
        --data-raw '{
        "state": "${statusState[status]}",
        "close_code": "${statusType[status]}",
        "close_notes": "${statusMessage[status]}"}'
    """).split()
    return change
}

def workNote(String note, String change_sys_id) {

    def username = getSecretString('snow-usr')
    def password = getSecretString('snow-pwd')
    def url = getSecretString('snow-url')

    sh (returnStdout: true, script: """
        curl -s "$url/api/now/table/change_request/$change_sys_id" --request PUT --header "Accept: application/json" --header "Content-Type: application/json" --user '$username':'$password' \\
        --data-raw '{
        "work_notes": "$note"
    """).split()
}