export GITHUB_USER=$(cat creds.json | jq -r '.githubUserName')
export GITHUB_EMAIL=$(cat creds.json | jq -r '.githubUserEmail')
export GITHUB_TOKEN=$(cat creds.json | jq -r '.githubPersonalAccessToken')
export DT_TENANT=$(cat creds.json | jq -r '.dynatraceTenant')
export DT_API_TOKEN=$(cat creds.json | jq -r '.dynatraceApiToken')
export JENKINS_PASSWORD=$(cat creds.json | jq -r '.jenkinsPassword')

export JENKINS_URL=$(kubectl -n cicd get svc jenkins -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
if [ "$JENKINS_URL" == "" ]; then
    echo "Service for Jenkins could not be found. Please make sure the service has been deployed."
    exit 1
fi


jobs=( "carts" "catalogue" "front-end" "orders" "payment" "queue-master" "shipping" "user" )
for i in "${jobs[@]}"
do
        echo "Creating a release branch for $i"
        curl -X POST "http://$JENKINS_URL:80/job/sockshop/job/create-release-branch/build" \
                --user "admin:$JENKINS_PASSWORD" \
                --data-urlencode json='{"parameter": [{"name":"SERVICE", "value":"'"$i"'"}]}'
done

sleep 120

#<trigger scan of all>
jobs=( "carts" "catalogue" "front-end" "orders" "payment" "queue-master" "shipping" "user" )
for i in "${jobs[@]}"
do
	echo "Triggering a pipeline scan for $i"
	curl -X POST "http://admin:$JENKINS_PASSWORD@$JENKINS_URL:80/job/sockshop/job/$i/build"
done
