



gcloud config set compute/region $REGION

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export PROJECT_NUMBER

gcloud services enable apigateway.googleapis.com
gcloud services enable servicemanagement.googleapis.com
gcloud services enable servicecontrol.googleapis.com --project=$PROJECT_ID
gcloud services enable serviceusage.services.enable --project=$PROJECT_ID
gcloud services enable cloudfunctions.googleapis.com --project=$PROJECT_ID


PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export PROJECT_NUMBER

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"



sleep 20

git clone https://github.com/GoogleCloudPlatform/nodejs-docs-samples.git

cd nodejs-docs-samples/functions/helloworld/helloworldGet

sleep 60

gcloud functions deploy helloGET --runtime nodejs14 --trigger-http --allow-unauthenticated --region $REGION

sleep 60

gcloud functions deploy helloGET --runtime nodejs14 --trigger-http --allow-unauthenticated --region $REGION

gcloud functions describe helloGET --region $REGION


curl -v https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET

cd ~


cat > openapi2-functions.yaml <<EOF_END
# openapi2-functions.yaml
swagger: '2.0'
info:
  title: API_ID description
  description: Sample API on API Gateway with a Google Cloud Functions backend
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user
      operationId: hello
      x-google-backend:
        address: https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET
      responses:
       '200':
          description: A successful response
          schema:
            type: string
EOF_END

export API_ID="hello-world-$(cat /dev/urandom | tr -dc 'a-z' | fold -w ${1:-8} | head -n 1)"

sed -i "s/API_ID/${API_ID}/g" openapi2-functions.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" openapi2-functions.yaml


export API_ID="hello-world-$(cat /dev/urandom | tr -dc 'a-z' | fold -w ${1:-8} | head -n 1)"
echo $API_ID



gcloud api-gateway apis create "hello-world-api"  --project=$PROJECT_ID

gcloud api-gateway api-configs create hello-world-config \
  --api=$API_ID --openapi-spec=openapi2-functions.yaml \
  --project=$PROJECT_ID --backend-auth-service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com

gcloud api-gateway gateways create hello-gateway \
  --api=$API_ID --api-config=hello-world-config \
  --location=$REGION --project=$PROJECT_ID






gcloud alpha services api-keys create --display-name="quicklab"  
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=quicklab") 
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)") 
echo $API_KEY


MANAGED_SERVICE=$(gcloud api-gateway apis list --format json | jq -r .[0].managedService | cut -d'/' -f6)
echo $MANAGED_SERVICE

gcloud services enable $MANAGED_SERVICE


cat > openapi2-functions2.yaml <<EOF_END
# openapi2-functions.yaml
swagger: '2.0'
info:
  title: API_ID description
  description: Sample API on API Gateway with a Google Cloud Functions backend
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user
      operationId: hello
      x-google-backend:
        address: https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET
      security:
        - api_key: []
      responses:
       '200':
          description: A successful response
          schema:
            type: string
securityDefinitions:
  api_key:
    type: "apiKey"
    name: "key"
    in: "query"
EOF_END


sed -i "s/API_ID/${API_ID}/g" openapi2-functions2.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" openapi2-functions2.yaml




gcloud api-gateway api-configs create hello-config \
  --display-name="Hello Config" \
  --api=$API_ID \
  --openapi-spec=openapi2-functions2.yaml \
  --project=$PROJECT_ID \
  --backend-auth-service-account=$PROJECT_ID@$PROJECT_ID.iam.gserviceaccount.com	



gcloud api-gateway gateways update hello-gateway \
  --api=$API_ID --api-config=hello-config \
  --location=$REGION --project=$PROJECT_ID


gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"


gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_ID@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"



MANAGED_SERVICE=$(gcloud api-gateway apis list --format json | jq -r --arg api_id "$API_ID" '.[] | select(.name | endswith($api_id)) | .managedService' | cut -d'/' -f6)
echo $MANAGED_SERVICE

gcloud services enable $MANAGED_SERVICE


export GATEWAY_URL=$(gcloud api-gateway gateways describe hello-gateway --location $REGION --format json | jq -r .defaultHostname)
curl -sL $GATEWAY_URL/hello

curl -sL -w "\n" $GATEWAY_URL/hello?key=$API_KEY





