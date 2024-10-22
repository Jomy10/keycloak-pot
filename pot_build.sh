set -e

if [ "$1" = "" ] || [ "$2" = "" ]
then
    echo "Usage: sh pot_build.sh <hostname> <postgres-password>"
    return 1
fi

set -x

POT_NAME=keycloak
FREEBSD_VERSION=14.0

pot create \
    -p $POT_NAME \
    -b $FREEBSD_VERSION \
    -t single

# Copy init file
pot copy-in \
    -p $POT_NAME \
    -s pot_init.sh \
    -d /pot_init.sh

pot start $POT_NAME

pot exec -p $POT_NAME sh /pot_init.sh $1 $2

pot stop $POT_NAME

pot set-cmd -p $POT_NAME -c "service keycloak start --optimized"

pot snap -p $POT_NAME -r

