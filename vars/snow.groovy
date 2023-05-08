#!/usr/bin/groovy
/**
 * Create change requests and incidents in servicenow
 */
import jenkins.*
import jenkins.model.* 
import hudson.*
import hudson.model.*

def changeRequest(String folder, String short_description, String description, String work_notes, String category, String type, String priority, String assigned_to, String impact, String urgency) {

    def secrets = load "${folder}/vars/secrets.groovy"
    def username = secrets.getSecretString('snow-username')
    def password = secrets.getSecretString('snow-password')
    def url = secrets.getSecretString('snow-url')
    def type = type ?: 'Standard'
    def category = category ?: 'DevOps'
    def priority = priority ?: '3'
    def impact = impact ?: '3'
    def urgency = urgency ?: '3'
    def assigned_to = assigned_to ?: 'DevOps System'

    sh """
        curl "$url/api/sn_chg_rest/change" \
        --request POST \
        --header "Accept: application/json" \
        --header "Content-Type: application/json" \
        --data-raw '{
        "short_description": "$short_description",
        "description": "$description",
        "work_notes": "$work_notes",
        "category": "$category",
        "type": "$type",
        "priority": "$priority",
        "assigned_to": "$assigned_to",
        "impact": "$impact",
        "urgency": "$urgency" }' \
        --user '$username':'$password'
    """
}