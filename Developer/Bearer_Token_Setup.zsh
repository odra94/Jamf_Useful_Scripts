#!/bin/zsh

################################################################################
# Jamf Pro API Bearer Token Authentication Script
# Script by: Oscar Reyes
#
# This script demonstrates how to authenticate with Jamf Pro API using
# OAuth2 client credentials to obtain a bearer token.
#
# SETUP INSTRUCTIONS:
# 1. Create an API client in Jamf Pro (Settings > System > API Roles and Clients)
# 2. Copy the client_id and client_secret from Jamf Pro
# 3. Replace the placeholder values below with your actual credentials
# 4. Replace YOUR_JAMF_INSTANCE with your Jamf Pro URL
################################################################################

# CONFIGURATION - Replace these values with your actual credentials
client_id="YOUR_CLIENT_ID_HERE"                    # Example: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
client_secret="YOUR_CLIENT_SECRET_HERE"            # Example: "aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890..."
url="https://YOUR_JAMF_INSTANCE.jamfcloud.com"     # Example: "https://company.jamfcloud.com" or "https://jamf.company.com"

# Variable declarations
bearerToken=""
tokenExpirationEpoch="0"

getBearerToken() {
	# Use proper OAuth2 client credentials format
	response=$(curl -s -X POST "$url/api/oauth/token" \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-d "client_id=$client_id" \
		-d "client_secret=$client_secret" \
		-d "grant_type=client_credentials")

	# Check if response contains an error
	if echo "$response" | grep -q '"error"'; then
		echo "Error: Authentication failed. Please check your client_id and client_secret."
		return 1
	fi

	# Check if response contains access_token
	if ! echo "$response" | grep -q '"access_token"'; then
		echo "Error: No access token in response. Authentication may have failed."
		return 1
	fi

	# Extract the access token (note: OAuth uses 'access_token', not 'token')
	bearerToken=$(echo "$response" | plutil -extract access_token raw -)

	# Extract expiration time (in seconds from now)
	expiresIn=$(echo "$response" | plutil -extract expires_in raw -)

	# Calculate expiration epoch time
	nowEpoch=$(date +"%s")
	tokenExpirationEpoch=$((nowEpoch + expiresIn))

	echo "Token expires in: $expiresIn seconds"
	echo "Token expiration epoch: $tokenExpirationEpoch"
	echo ""
}

checkTokenExpiration() {
    nowEpoch=$(date +"%s")
    if [[ $tokenExpirationEpoch -gt $nowEpoch ]]
    then
        echo "Token valid until epoch time: $tokenExpirationEpoch"
    else
        echo "No valid token available, getting new token"
        getBearerToken
    fi
}

invalidateToken() {
	responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" $url/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		echo "Token successfully invalidated"
		bearerToken=""
		tokenExpirationEpoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
		echo "Token already invalid"
	else
		echo "An unknown error occurred invalidating the token (HTTP $responseCode)"
	fi
}

################################################################################
# MAIN EXECUTION
################################################################################

# Get initial bearer token
getBearerToken

# Test token validity and make API calls
checkTokenExpiration
curl -s -H "Authorization: Bearer ${bearerToken}" $url/api/v1/jamf-pro-version -X GET
checkTokenExpiration

# Invalidate token when done
invalidateToken

# This call should fail since token was invalidated
curl -s -H "Authorization: Bearer ${bearerToken}" $url/api/v1/jamf-pro-version -X GET
