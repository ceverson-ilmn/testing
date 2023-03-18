#Get the SOURCE ProjectID
SOURCE_PROJECT_ID=$1
#Get the SOURCE DataID
SOURCE_DATA_ID=$2
#Get the SOURCE API Key
SOURCE_API_KEY=$3

#Get the DESTINATION ProjectID
DESTINATION_PROJECT_ID=$4
#Get the DESTINATION DataID
DESTINATION_DATA_ID=$5
#Get the DESTINATION API Key
DESTINATION_API_KEY=$6

date > output.txt
echo "Args successfully submitted" >> output.txt

#Make the SOURCE API request for temp storage access credentials
SOURCE_API_REQ=$(curl -sX 'POST' \
  'https://ica.illumina.com/ica/rest/api/projects/'$SOURCE_PROJECT_ID'/data/'$SOURCE_DATA_ID':createTemporaryCredentials' \
  -H 'accept: application/vnd.illumina.v3+json' \
  -H 'X-API-Key: '$SOURCE_API_KEY'' \
  -H 'Content-Type: application/vnd.illumina.v3+json' \
  -d '{"credentialsFormat": "RCLONE"}')

date >> output.txt
echo "Source request submitted" >> output.txt

#Parse the SOURCE KeyID
SOURCE_KEY_ID=$(echo $SOURCE_API_REQ | sed 's/.*access_key_id\"\:\"//g')
SOURCE_KEY_ID=$(echo $SOURCE_KEY_ID | sed 's/\"\,\"session_token.*//g')

#Parse the SOURCE Access Key
SOURCE_ACCESS_KEY=$(echo $SOURCE_API_REQ | sed 's/.*secret_access_key\"\:\"//g')
SOURCE_ACCESS_KEY=$(echo $SOURCE_ACCESS_KEY | sed 's/\"\,\"no_check_bucket.*//g')

#Parse the SOURCE Session Token
SOURCE_SESSION_TOKEN=$(echo $SOURCE_API_REQ | sed 's/.*session_token\"\:\"//g')
SOURCE_SESSION_TOKEN=$(echo $SOURCE_SESSION_TOKEN | sed 's/\"\,\"server_side_encryption.*//g')

#Parse the SOURCE filePathPrefix
SOURCE_FILEPATH=$(echo $SOURCE_API_REQ | sed 's/.*filePathPrefix\"\:\"//g')
SOURCE_FILEPATH=$(echo $SOURCE_FILEPATH | sed 's/\"\,\"storageType.*//g')

date >> output.txt
echo "Source request parsed" >> output.txt

#Make the SOURCE API request for temp storage access credentials
DESTINATION_API_REQ=$(curl -sX 'POST' \
  'https://ica.illumina.com/ica/rest/api/projects/'$DESTINATION_PROJECT_ID'/data/'$DESTINATION_DATA_ID':createTemporaryCredentials' \
  -H 'accept: application/vnd.illumina.v3+json' \
  -H 'X-API-Key: '$DESTINATION_API_KEY'' \
  -H 'Content-Type: application/vnd.illumina.v3+json' \
  -d '{"credentialsFormat": "RCLONE"}')

date >> output.txt
echo "Destination request submitted" >> output.txt

#Parse the SOURCE KeyID
DESTINATION_KEY_ID=$(sed 's/.*access_key_id\"\:\"//g' <<< $DESTINATION_API_REQ)
DESTINATION_KEY_ID=$(sed 's/\"\,\"session_token.*//g' <<< $DESTINATION_KEY_ID)
#Parse the SOURCE Access Key
DESTINATION_ACCESS_KEY=$(sed 's/.*secret_access_key\"\:\"//g' <<< $DESTINATION_API_REQ)
DESTINATION_ACCESS_KEY=$(sed 's/\"\,\"no_check_bucket.*//g' <<< $DESTINATION_ACCESS_KEY)
#Parse the SOURCE Session Token
DESTINATION_SESSION_TOKEN=$(sed 's/.*session_token\"\:\"//g' <<< $DESTINATION_API_REQ)
DESTINATION_SESSION_TOKEN=$(sed 's/\"\,\"server_side_encryption.*//g' <<< $DESTINATION_SESSION_TOKEN)
#Parse the SOURCE filePathPrefix                                                                                                                                
                                     
DESTINATION_FILEPATH=$(sed 's/.*filePathPrefix\"\:\"//g' <<< $DESTINATION_API_REQ)
DESTINATION_FILEPATH=$(sed 's/\"\,\"storageType.*//g' <<< $DESTINATION_FILEPATH)

date >> output.txt
echo "Destination request parsed" >> output.txt

#Construct the Rclone Config File for SOURCE
printf "[SOURCE]\ntype = s3\nprovider = AWS\naccess_key_id = "$SOURCE_KEY_ID"\nsecret_access_key = "$SOURCE_ACCESS_KEY"\n" > rclone_config.tmp
printf "region = us-east-1\nserver_side_encryption = AES256\nsession_token = "$SOURCE_SESSION_TOKEN"\nno_check_bucket = true" >> rclone_config.tmp

date >> output.txt
echo "Constructed rclone file for Source" >> output.txt

#Construct the Rclone Config File for DESTINATION
printf "\n\n[DESTINATION]\ntype = s3\nprovider = AWS\naccess_key_id = "$DESTINATION_KEY_ID"\nsecret_access_key = "$DESTINATION_ACCESS_KEY"\n" >> rclone_config.tmp
printf "region = us-east-1\nserver_side_encryption = AES256\nsession_token = "$DESTINATION_SESSION_TOKEN"\nno_check_bucket = true" >> rclone_config.tmp

date >> output.txt
echo "Constructed rclone file for Destination" >> output.txt

#Construct final command
FINAL_COMMAND="rclone -P --config rclone_config.tmp sync SOURCE:/\"$SOURCE_FILEPATH\" DESTINATION:/\"$DESTINATION_FILEPATH\""

date >> output.txt
echo "Final command constructed" >> output.txt

#Run final command
eval "$FINAL_COMMAND"

date >> output.txt
echo "Final command submitted" >> output.txt

#Done
exit
