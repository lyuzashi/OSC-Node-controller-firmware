/* 
 Talking OSC over network with Bonjour discovery and DHCP support
 Work in progress
 
 Designed for Freetronics EtherTen
 
 Ben Patterson 2011
 
 Requires Arduino 0022 and the following external libraries 
 REMOVED: OSCClass http://www.makesomecode.com/2009/12/30/arduino-osc-iphone-and-dmx/
 Arduino Ethernet http://gkandl.com/software/arduino-ethernet
 Streaming http://arduiniana.org/libraries/streaming/
 Z_OSC http://arduino.cc/playground/Interfacing/MaxMSP
 
 
 Firmware for any device. EEPROM storage of config data. 
 
 1. Am I set up?
 2. Advertise as new generic NODE
 3. Provide HTML set up page that discovers other NODES that are not set up
 4. Indentify with flashing LED and button on device and web interface. 
     Advertise indentified device with another name.
 5. Allow user to link input and output pins to OSC addresses

 
*/
#include "SPI.h"
#include "Ethernet.h"
#include "OSCClass.h"
#include "EthernetDHCP.h"
#include "EthernetBonjour.h"
#include "Streaming.h"
#include "Z_OSC.h" 

int http_server_port = 80;
int osc_port         = 10000;
// Hosts listen on this port. Clients post messages to this port.

int led_1            = 6;

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
//  This MAC address is temporary. Final versions will have address written
//   to EEPROM for quick depolyment without recompiling source for each 
//   board. Routine may be written to set up MAC address over serial if
//   not found in EEPROM at boot. 

Server http_server(80);
//  Each node is a basic web server for configuration and possibly other features

boolean has_ip_address = false;



Z_OSCServer osc_server;
Z_OSCMessage *osc_incomming_message;
  

void setup(){
  // Setup debug over serial
  Serial.begin(9600);
  Serial.println("Starting sketch");
  
  // Acquire IP address with DHCP
  EthernetDHCP.begin(mac, 1);
  //  the second property set to 1 enables asynchronous IP lease management.
  //  This function is returned from imediately, no waiting for an IP address. 
 
  //http_server.begin();
  //  I'm not sure if this needs to be run after obtaining an IP
 
  EthernetBonjour.begin("node");
  //  This MDNS name needs to be unique for each node on the network
  //   usually this is achived by appending a number to each broadcast name
 
  EthernetBonjour.addServiceRecord("Switch Node._http", 80, MDNSServiceTCP);
  //  Advertise the HTTP server from this node.
  //  This service record should only be added to one node, 
  //   so it hosts the web interface. Begin by discovering other http nodes.
  //   Other nodes will be discovered and listed by the http hosting one.
  
  EthernetBonjour.addServiceRecord("Switch Node._osc", osc_port, MDNSServiceUDP);
  
 // char *osc_root        = "/node";
 // char *osc_addresses[] = {"/led1"};
  
  osc_server.sockOpen(osc_port);
  
  
}

void loop(){
  static DhcpState last_DHCP_state = DhcpStateNone;
  // Variable to keep track of DHCP state, begining with an unknow state
  
  DhcpState current_DHCP_state = EthernetDHCP.poll();
  // Poll the DHCP client module to check if the state has changed
  
  if(current_DHCP_state != last_DHCP_state){
    DHCP_state_has_changed(current_DHCP_state);
  }
  
  last_DHCP_state = current_DHCP_state;



  
  if(has_ip_address){
    
 
    
    EthernetBonjour.run();
    //  Run the Bonjour class every loop to keep it active
    
    if(osc_server.available()){
      osc_incomming_message = osc_server.getMessage();
      incomming_osc_messages();
      //analogWrite(led_1, 125);
      
    }
    
  }
}


void DHCP_state_has_changed(DhcpState new_DHCP_state) {
   switch (new_DHCP_state) {
      case DhcpStateDiscovering:
        Serial.println("Discovering DHCP servers.");
        break;
      case DhcpStateRequesting:
        Serial.println("Requesting DHCP lease.");
        break;
      case DhcpStateRenewing:
        Serial.println("Renewing DHCP lease.");
        break;
      case DhcpStateLeased: {
        Serial.println("Obtained DHCP lease");
        Serial << "IP address: " << ip_to_str(EthernetDHCP.ipAddress()) << endl;
        has_ip_address = true;
        break;
      }
    }
}

// IP formatting utility function from Arduino Ethernet library by Georg Kaindl
const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}


void incomming_osc_messages(){
  analogWrite(led_1,  osc_incomming_message->getInteger32(0) / 39 );
  // TODO: read incomming path, rather than accepting any number that comes our way
}
