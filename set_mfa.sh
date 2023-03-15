#!/bin/bash

AWS_CRED=/home/$USER/.aws/credentials

read -p "Enter MFA code: " MFA_CODE

# Check if MFA serial number exists in AWS credentials file
if ! grep -q "mfa_serial" $AWS_CRED; then
  echo "MFA serial number not found in credentials file, importing from AWS..."
  MFA_SERIAL=$(aws iam list-mfa-devices --query 'MFADevices[0].SerialNumber' --output text)
  echo "mfa_serial = $MFA_SERIAL" >> $AWS_CRED
else
  MFA_SERIAL=$(grep "mfa_serial" $AWS_CRED | cut -d "=" -f 2 | sed -e 's/^[[:space:]]*//')
fi

# Check if aws_security_token exists in AWS credentials file
if ! grep -q "aws_security_token" $AWS_CRED; then
  echo "aws_security_token = " >> $AWS_CRED
fi

SESSION_TOKEN=$(aws sts get-session-token --serial-number $MFA_SERIAL --token-code $MFA_CODE --duration-seconds 1800 | jq -r '.Credentials.SessionToken')

sed -i "s|^aws_security_token.*$|aws_security_token = $SESSION_TOKEN|" $AWS_CRED

echo "Updated $AWS_CRED with new session token."
