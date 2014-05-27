/**
 * This file contains constants used in the receiver module of the TPSN protocol
 * and the structure of the message that is sent to the L1 node with
 * the information about the local time (time stamp) at which the TPSN request 
 * was received.
 * @author Barraza, Suarez
 * @modified Apr 11, 2014
 */

#ifndef TPSN_RECEIVER0_H
#define TPSN_RECEIVER0_H



enum {

  
  // The active message type selected here can be any value above 127, as 
  // recommended in the TEP-4 (http://www.tinyos.net/tinyos-2.x/doc/txt/tep4.txt).
  TPSN0_REPORT_MSG = 145,   //Report message type 145=0x91
};

typedef nx_struct Tpsn0_ReportMsg {
  nx_uint16_t nodeId; // node ID of the receiver (this node)
  nx_uint16_t Tpsn0SeqNr; // TPSN report  sequence number
  nx_uint32_t Tpsn0RadTStamp; // radio time stamp (local radio time) when the 
                          // TPSN request
} Tpsn0_ReportMsg_t;   //the "_t" at the end is a usual convention meaning: "type"


#endif /* TPSN_RECEIVER0_H */