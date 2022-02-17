# Dry-run the mirroring command
m1=$1
m2=$2

if [ $# -ne 2 ]; then
   echo "Kindly provide source and destination registry details"
   exit 1
fi

if [ ! -f mapping.txt ]
then
    echo "File does not exist. Kindly ensure mapping.txt file exists."
    exit
fi

# Filter out the required images from mapping
cat mapping.txt | cut -d"=" -f2 | cut -d"/" -f3- > images.txt

# Mirror the images using Skopeo
while read p; do skopeo copy --src-tls-verify=false --dest-ts-verify=false --authfile pull-secret.json docker://$m1/$p docker://$m2/$p; done < images.txt

rm -rf images.txt
