/**
 * This file contains several constants used in the code and the structure
 * of the message sent by the beacon node. 
 * 
 * @author Barraza, Suarez
 * @modified Apr 4, 2014
 */

#ifndef BEACON_H
#define BEACON_H


enum {
  
  // The active message type selected here can be any value above 127, as 
  // recommended in the TEP-4 (http://www.tinyos.net/tinyos-2.x/doc/txt/tep4.txt).
  BEACON_MSG = 128,   //Beacon's message type 128=0x80
  
  // The timer period in "milliseconds" used to send packets
  // 1 sec = 1024 "ms" 
  TIMER_PERIOD_MILLI_BEACON = 5120  // 5 secs = 5*1024 "ms"
};

typedef nx_struct BeaconMsg {
  nx_uint16_t nodeId;  // node ID (unique number)
  nx_uint16_t seqNr; // packet's sequence number
} BeaconMsg_t;   //the "_t" at the end is a usual convention meaning: "type"


#endif /* BEACON_H */