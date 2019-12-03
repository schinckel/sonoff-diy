#! /bin/bash

# TODO: Look for files/firmware.bin and complain if it's not there.

# Start our HTTP server as early as possible.
node_modules/.bin/http-server files -s & 
HTTP_PID=$(echo $!)
echo -e "\033[32m✓\033[0m Started an HTTP server on port 8080."

FIRMWARE='files/firmware.bin'
SHA256SUM=$(shasum -a 256 files/firmware.bin | cut -d ' ' -f 1)

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

curl http://${NAME}.local:8081/zeroconf/unlock_ota \
	-X POST \
	--data "{
		\"deviceid\": \"${DEVICE_ID}\",
		\"data\":{}
	}"

if [ $? -eq 0 ]
then
  echo -e "\033[32m✓\033[0m Unlocked OTA mode"
else
  echo -e "\033[31m⚠︎\033[0m Could not unlock OTA mode" >&2
  kill $HTTP_PID
  echo -e "\033[32m✓\033[0m Stopped HTTP server."
  exit 2
fi

# Flash firmware

echo "⋯ Attempting to update firmware OTA"

curl http://${NAME}.local:8081/zeroconf/ota_flash \
	-X POST \
	--data "{
		\"deviceid\": \"${DEVICE_ID}\",
		\"data\":{
			\"downloadURL\": \"http://$(hostname):8080/firmware.bin\",
			\"sha256sum\":\"${SHA256SUM}\"
		}
	}"

if [ $? -eq 0 ]
then
  echo -e "\033[32m✓\033[0m Successfully updated firmware"
else
  echo "\033[31m⚠︎\033[0m Could not update firmware" >&2
  kill $HTTP_PID
  echo -e "\033[32m✓\033[0m Stopped HTTP server."
  exit 3
fi
	
kill $HTTP_PID

echo -e "\033[32m✓\033[0m Stopped HTTP server."
echo -e "😀 Have a nice day"