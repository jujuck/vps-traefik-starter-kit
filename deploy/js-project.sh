#Import Traefik variables
set -o allexport
source ../data/.env
set +o allexport

#Set variables sent by github action script
GITHUB_ACCOUNT_NAME=${1}
GITHUB_REPOSITORY_NAME=${2}
PROJECT_NAME=${3}
GITHUB_JSON_VARS=${4}
DB_NAME=`echo "$GITHUB_REPOSITORY_NAME" | sed 's/\-/\_/g'`

#Create projects directory if not exists
if [ ! -d "../../projects/" ]; then
  mkdir "../../projects"
fi

#Clone the repository if not exists
if [ ! -d "../../projects/$GITHUB_REPOSITORY_NAME" ]; then
  cd "../../projects/"
  git clone https://github.com/$GITHUB_ACCOUNT_NAME/$GITHUB_REPOSITORY_NAME
  cd -
fi

#Update main branch
cd "../../projects/$GITHUB_REPOSITORY_NAME"
git checkout main
git pull origin main

#print Github action vars to .env file project
if [ ! -d "../envs/" ]; then
  mkdir "../envs"
fi
#parse and write ENV vars for both front and backend
echo $GITHUB_JSON_VARS | jq 'to_entries[] | "\(.key)=\(.value)"' | sed 's/"//g' > ../envs/.env-$GITHUB_REPOSITORY_NAME
VITE_BACKEND_URL="https://$PROJECT_NAME-backend.$HOST"
echo VITE_BACKEND_URL=$VITE_BACKEND_URL > ./frontend/.env
echo $GITHUB_JSON_VARS | jq 'to_entries[] | "\(.key)=\(.value)"' | sed 's/"//g' >> ./frontend/.env

#Build and start Docker container with docker compose
GITHUB_REPOSITORY_NAME=$GITHUB_REPOSITORY_NAME \
PROJECT_NAME=$PROJECT_NAME \
DB_NAME=$DB_NAME \
docker compose -f docker-compose.prod.yml \
--env-file ../../traefik/data/.env up -d --build --remove-orphans --force-recreate
