# Sonoff DIY flasher

1. Put your firmware to upload in `files/firmware.bin`

2. Install `http-server`

    $ npm install

3. Prepare your network

  * Start a network with SSID 'sonoffDiy', WPA2 key '20170618sn'
	This must have access to the internet, and to the machine you 
	are running this code from.
  * Unplug your Sonoff Mini/DIY device
  * Add the supplied jumper to the DIY pin (GPIO16)
  * Plug the device back in
  * Wait for the blue LED to double-flash

4. Start the flash:

    $ ./flasher.sh