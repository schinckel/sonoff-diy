# Sonoff DIY Flasher

A tool to help automate applying a new firmware to a Sonoff DIY device.

1. Put your firmware to upload in `files/firmware.bin`

2. Install an HTTP server that will be able to serve the file. Note that python's `http.server` module appears to fail when attempting to serve the file, although that may have been that I did not leave it long enough.

        $ npm install

3. Prepare your network

  * Start a network with SSID `sonoffDiy`, WPA2 key `20170618sn`
	This must have access to the internet, and to the machine you 
	are running this code from.
  * Unplug your Sonoff Mini/DIY device
  * Add the supplied jumper to the DIY pin (GPIO16)
  * Plug the device back in
  * Wait for the blue LED to double-flash

4. Start the flash:

        $ ./flasher.sh

This should then run to completeion. Please let me know if you have any issues: I only had one Sonoff DIY device, and have already flashed that one, so was unable to try the automated process.