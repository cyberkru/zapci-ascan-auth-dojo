#!/bin/bash

start=$(date +%s)
echo "URL zap: $PROXY_URL"
echo "DOJOURL: $DOJOURL"
echo "Target: $TARGET_URL"
echo "Login-URL: $LOGIN_URL"
#$USER_LOGIN
#$USER_PASSWORD

sleep 2

echo "ZAP is ready"

SESS=`curl -s --fail "$PROXY_URL/JSON/core/action/newSession"`
SESS=`curl -s --fail "$PROXY_URL/JSON/pscan/action/enableAllScanners"`
SESS=`curl -s --fail "$PROXY_URL/JSON/core/action/clearExcludedFromProxy"`

echo "Ready for testing"

#set maximum spider parameters
MAX=`curl "$PROXY_URL/JSON/spider/action/setOptionMaxDuration/?Integer=10"`
MAX_DEPTH=`curl -X GET "$PROXY_URL/JSON/spider/action/setOptionMaxDepth/?Integer=5"`
MAX_CHILD=`curl -X GET "$PROXY_URL/JSON/spider/action/setOptionMaxChildren/?Integer=10"`
MAX_ASCAN=`curl "$PROXY_URL/JSON/ascan/action/setOptionMaxScanDurationInMins/?Integer=10"`

echo "create context..."
sleep 1
CTX=`curl "$PROXY_URL/JSON/context/action/includeInContext/?contextName=Default+Context&regex=${TARGET_URL}.*"`
echo "$CTX"

echo "set form based login..."
sleep 1
FRM=`curl "$PROXY_URL/JSON/authentication/action/setAuthenticationMethod/?contextId=1&authMethodName=formBasedAuthentication&authMethodConfigParams=loginUrl=${LOGIN_URL}"`
echo "$FRM"

echo "create user..."
sleep 1
CUSER=`curl "$PROXY_URL/JSON/users/action/newUser/?contextId=1&name=Test+User"`
echo "$CUSER"

echo "add credential to user..."
sleep 1
CRED=`curl "$PROXY_URL/JSON/users/action/setAuthenticationCredentials/?contextId=1&userId=0&authCredentialsConfigParams=username=${USER_LOGIN}&password=${USER_PASSWORD}"`
echo "$CRED"

echo "enabling user..."
sleep 1
CUSER=`curl "$PROXY_URL/JSON/users/action/setUserEnabled/?contextId=1&userId=0&enabled=true"`
echo "$CUSER"

echo "force user..."
sleep 1
CUSER=`curl "$PROXY_URL/JSON/forcedUser/action/setForcedUser/?contextId=1&userId=0"`
echo "$CUSER"

echo "enabling force mode..."
sleep 1
CUSER=`curl "$PROXY_URL/JSON/forcedUser/action/setForcedUserModeEnabled/?boolean=true"`
echo "$CUSER"

echo "spider and scan..."
sleep 1
SPIDER=`curl "$PROXY_URL/JSON/spider/action/scan/?url=${TARGET_URL}&inScope=&contextName=Default+Context&&userId=0&subtreeOnly="`
echo "$SPIDER"
sleep 10
SCAN=`curl "$PROXY_URL/JSON/ascan/action/scan/?url=${TARGET_URL}&recurse=true&inScopeOnly=&scanPolicyName=&method=&postData=&contextId=1"`
echo "$SCAN"

#check status
echo "checking status..."
STATUS='"0"'
while [ "$STATUS" != '"100"' ]
do
STATUS=`curl --fail "$PROXY_URL/JSON/ascan/view/status/?scanId=0" 2> /dev/null | jq '.status'`
sleep 3
echo "current status: $STATUS of 100(%)...."

if [ -z "$STATUS" ]
then
 exit 1
fi

done

echo "generating report..."
sleep 5

#report
#curl --fail http://localhost:8090/OTHER/core/other/jsonreport/?formMethod=GET > report.json
result=`curl --fail "$PROXY_URL/OTHER/core/other/xmlreport/?formMethod=GET" > output/report.xml`
html=`curl --fail "$PROXY_URL/OTHER/core/other/htmlreport/?formMethod=GET" > output/report.html`

PRODID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token ${DOJOKEY}" --url "${DOJOURL}/api/v2/products/?limit=1000" | jq -c '[.results[] | select(.name | contains('\"${PRODNAME}\"'))][0] | .id')
EGID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token $DOJOKEY" --url "${DOJOURL}/api/v2/engagements/?limit=1000" | jq -c "[.results[] | select(.product == ${PRODID})][0] | .id")
curl -X POST --header "Content-Type:multipart/form-data" --header "Authorization:Token $DOJOKEY" -F "engagement=${EGID}" -F "scan_type=ZAP Scan" -F 'file=@./output/report.xml' --url "${DOJOURL}/api/v2/import-scan/"

end=$(date +%s)
echo "Scanning completed###################"
echo "Elapsed Time: $(($end-$start)) seconds"
