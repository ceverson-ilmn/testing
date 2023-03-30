#Should be run with medium compute and enough storage to temporary store the run

date > output.txt
echo "Getting inputs" >> output.txt

#Get the BSSH run ID
RUN_ID=$1
#Get the BSSH API Key
BSSH_API=$2
#Get the DESTINATION ProjectID
DESTINATION_PROJECT_ID=$3
#Get the DESTINATION DataID
DESTINATION_DATA_ID=$4
#Get the DESTINATION API Key
DESTINATION_API_KEY=$5

date >> output.txt
echo "Making destination API temp credentials request" >> output.txt

#Make the DESTINATION API request for temp storage access credentials
DESTINATION_API_REQ=$(curl -sX 'POST' \
  'https://ica.illumina.com/ica/rest/api/projects/'$DESTINATION_PROJECT_ID'/data/'$DESTINATION_DATA_ID':createTemporaryCredentials' \
  -H 'accept: application/vnd.illumina.v3+json' \
  -H 'X-API-Key: '$DESTINATION_API_KEY'' \
  -H 'Content-Type: application/vnd.illumina.v3+json' \
  -d '{"credentialsFormat": "RCLONE"}')

date >> output.txt
echo "Parsing destination key id" >> output.txt

#Parse the DESTINATION KeyID
DESTINATION_KEY_ID=$(echo $DESTINATION_API_REQ | sed 's/.*access_key_id\"\:\"//g')
DESTINATION_KEY_ID=$(echo $DESTINATION_KEY_ID | sed 's/\"\,\"session_token.*//g')

date >> output.txt
echo "Parsing destination access key" >> output.txt

#Parse the DESTINATION Access Key
DESTINATION_ACCESS_KEY=$(echo $DESTINATION_API_REQ | sed 's/.*secret_access_key\"\:\"//g')
DESTINATION_ACCESS_KEY=$(echo $DESTINATION_ACCESS_KEY | sed 's/\"\,\"no_check_bucket.*//g')

date >> output.txt
echo "Parsing destination sesssion token" >> output.txt

#Parse the DESTINATION Session Token
DESTINATION_SESSION_TOKEN=$(echo $DESTINATION_API_REQ | sed 's/.*session_token\"\:\"//g')
DESTINATION_SESSION_TOKEN=$(echo $DESTINATION_SESSION_TOKEN | sed 's/\"\,\"server_side_encryption.*//g')

date >> output.txt
echo "Parsing destination filepath" >> output.txt

#Parse the DESTINATION filePathPrefix
DESTINATION_FILEPATH=$(echo $DESTINATION_API_REQ | sed 's/.*filePathPrefix\"\:\"//g')
DESTINATION_FILEPATH=$(echo $DESTINATION_FILEPATH | sed 's/\"\,\"storageType.*//g')

date >> output.txt
echo "Generating rclone config file for destination" >> output.txt

#Construct the Rclone Config File for DESTINATION
printf "\n\n[DESTINATION]\ntype = s3\nprovider = AWS\naccess_key_id = "$DESTINATION_KEY_ID"\nsecret_access_key = "$DESTINATION_ACCESS_KEY"\n" > rclone_config.tmp
printf "region = us-east-1\nserver_side_encryption = AES256\nsession_token = "$DESTINATION_SESSION_TOKEN"\nno_check_bucket = true" >> rclone_config.tmp

date >> output.txt
echo "Executing run download command from BSSH" >> output.txt


#Run BSSH bs cli download command
bs download run --concurrency=high --api-server "https://api.basespace.illumina.com" --access-token $BSSH_API --id $RUN_ID -o ./runfolder/$RUN_ID

date >> output.txt
echo "Constructing final upload command" >> output.txt

#Construct upload command
FINAL_COMMAND="rclone -P --config rclone_config.tmp copy ./runfolder/ DESTINATION:/\"$DESTINATION_FILEPATH\" --transfers 64"


date >> output.txt
echo "Executing upload command to destiantion folder in ICA" >> output.txt

#Run rclone copy command
eval "$FINAL_COMMAND"

date >> output.txt
echo "Script finished- exiting" >> output.txt

#Done
exit
