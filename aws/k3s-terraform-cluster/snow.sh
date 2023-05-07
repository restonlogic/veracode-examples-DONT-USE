#/bin/bash

sys_id=$(curl "https://dev154568.service-now.com/api/now/table/sys_user?sysparm_limit=1&user_name=devops.system" \
--request GET \
--header "Accept:application/json" \
--user 'admin':'RmV$7y!fP6zW' | jq -r '.result[].sys_id')

curl "https://dev154568.service-now.com/api/now/table/sys_user/a0e11bb23ba32300b200655593efc491" \
--request PUT \
--data '{user_password: "whattheheckkk", "sysparm_input_display_value": "true"}' \
--header "Content-Type: application/json" \
--user 'admin':'RmV$7y!fP6zW'

curl "https://dev154568.service-now.com/api/sn_devops/devops/onboarding/tool" \
--request POST \
--data '{
  "tools":[{
    "name": "JenkinsAutomation",
    "type": "Jenkins",
    "url": "http://k3s-ext-lb-mgmt-bce8785d06d9d767.elb.us-east-1.amazonaws.com/jenkins/",
    "username": "admin",
    "password": "xTAgGuVMz4CgAj4J",
    "useMidServer": false 
  }],
  "credentials" : {
    "name": "devops.system",
    "password": "whattheheckkk"
  }
}' \
--header "Content-Type: application/json" \
--user 'admin':'RmV$7y!fP6zW'

curl "https://dev154568.service-now.com/api/sn_devops/devops/onboarding/status?id=IBE0001007" \
--request GET \
--header "Accept:application/json" \
--user 'admin':'RmV$7y!fP6zW'

curl "https://dev154568.service-now.com/api/sn_chg_rest/change" \
--request POST \
--header "Accept: application/json" \
--header "Content-Type: application/json" \
--data-raw '{
  "short_description": "Replace a faulty switch",
  "description": "One of our network switches is malfunctioning and needs to be replaced.",
  "work_notes": "This is an automated CR generated from Jenkins, please review infromation below:",
  "close_code": "Successful",
  "close_notes": "Veracode vulnerability scan ran successfully for application and all tests passing as expected",
  "state": "3.0",
  "phase_state": "Closed",
  "category": "DevOps",
  "type": "Standard",
  "priority": "3",
  "assigned_to": "DevOps System",
  "impact": "3",
  "urgency": "3" }' \
--user 'admin':'RmV$7y!fP6zW'


curl "https://dev154568.service-now.com/api/sn_chg_rest/change/a86d556b97e2251017f0f901f053af34" \
--request PATCH \
--header "Accept: application/json" \
--header "Content-Type: application/json" \
--data-raw '{
  "state": "0" }' \
--user 'admin':'RmV$7y!fP6zW'