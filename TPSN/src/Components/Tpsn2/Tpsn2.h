/**
 * This file contains constants used in the :
 * TPSN request to L1 message module of the TPSN protocol
 * TPSN receive form L1 (report message) module of the TPSN protocol
 * and the structure of the message that is sent to the L1 node with
 * the information about the local time (time stamp) at which the TPSN request 
 * was received.
 * @author Barraza, Suarez
 * @modified Apr 11, 2014
 */

#ifndef TPSN2_H
#define TPSN2_H


enum {
  
  //  Recomendacion ="The active message type selected here can be any value above 127, as 
  // recommended in the TEP-4 (http://www.tinyos.net/tinyos-2.x/doc/txt/tep4.txt)"".
  Tpsn2_MSG = 146,  //TPSN Report message to L1 node  type 146=0x92
  
// The timer period in "milliseconds" used to send packets
  // 1 sec = 1024 "ms" 
  TIMER_PERIOD_MILLI_TPSN2 = 3072  // 5 secs = 5*1024 "ms"
};

typedef nx_struct Tpsn2Msg {
  nx_uint16_t nodeId; // node ID (unique number)
  nx_uint16_t seqNr; // packet's sequence number
} Tpsn2Msg_t;   //the "_t" at the end is a usual convention meaning: "type"

#endif /* TPSN2_H */