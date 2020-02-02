#! /bin/bash

# TODO: Look for files/firmware.bin and complain if it's not there.

# Start our HTTP server as early as possible.
node_modules/.bin/http-server files &
HTTP_PID=$(echo $!)
echo -e "\033[32m✓\033[0m Started an HTTP server on port 8080."

FIRMWARE='files/firmware.bin'
SHA256SUM=$(shasum -a 256 $FIRMWARE | cut -d ' ' -f 1)

# TODO: Use our spinner in the places where we wait.
SPINNER='⋮⋰⋯⋱'

# We want to stop our mDNS query after 1 second: the device should be there
# already.
function timeout() {
	_ALARM=$(perl -e 'alarm shift; exec @ARGV' "$@") ;
	echo $_ALARM
}

echo -e "⋯ Looking for Sonoff devices on the network."

NAME=$(timeout 1 dns-sd -B _ewelink._tcp | grep _ewelink._tcp. | head -n 1 | awk '{print $NF}')

# If we don't have a $NAME here, we need to exit!
if [ "$NAME" = "" ]; then
	echo -e "\033[31m⚠︎\033[0m Unable to find a Sonoff DIY device on the network."
	kill $HTTP_PID
	echo -e "\033[32m✓\033[0m Stopped HTTP server."
	exit 1
fi

DEVICE_ID=$(echo $NAME | cut -d '_' -f 2)

echo -e "\033[32m✓\033[0m Found a Sonoff DIY device with id \033[34m${DEVICE_ID}\033[0m"

# Unlock OTA mode.

echo "⋯ Attempting to unlock OTA mode"

OTA_UNLOCK=$(curl http://${NAME}.local:8081/zeroconf/ota_unlock \
	-X POST \
	--data "{
		\"deviceid\": \"${DEVICE_ID}\",
		\"data\":{}
	}" | jq .error)

if [ $OTA_UNLOCK -eq 0 ]
then
  echo -e "\033[32m✓\033[0m Unlocked OTA mode"
else
  echo -e "\033[31m⚠︎\033[0m Could not unlock OTA mode" >&2
  echo $OTA_UNLOCK
  kill $HTTP_PID
  echo -e "\033[32m✓\033[0m Stopped HTTP server."
  exit 2
fi

# DEBUG

curl http://${NAME}.local:8081/zeroconf/info \
	-X POST \
	--data "{
		\"deviceid\": \"${DEVICE_ID}\",
		\"data\":{}
	}" | jq .

# Flash firmware

echo "⋯ Attempting to update firmware OTA"
IP_ADDRESS=$(ping $(hostname) -c 1 | grep 'bytes from .*:' | cut -d ' ' -f 4 | cut -d ':' -f 1)
OTA_UPDATE=$(curl http://${NAME}.local:8081/zeroconf/ota_flash \
	-X POST \
	--data "{
		\"deviceid\": \"${DEVICE_ID}\",
		\"data\":{
			\"downloadURL\": \"http://$IP_ADDRESS:8080/firmware.bin\",
			\"sha256sum\":\"${SHA256SUM}\"
		}
	}" | jq .error)

if [ $OTA_UPDATE -eq 0 ]
then
  echo -e "\033[32m✓\033[0m Successfully started updating firmware"
else
  echo "\033[31m⚠︎\033[0m Could not update firmware" >&2
  echo $OTA_UPDATE
  kill $HTTP_PID
  echo -e "\033[32m✓\033[0m Stopped HTTP server."
  exit 3
fi

# We need to watch the logs from the HTTP server and look for a POST to /api/device/otaFlash

sleep 30

kill $HTTP_PID

echo -e "\033[32m✓\033[0m Stopped HTTP server."
echo -e "😀 Have a nice day"