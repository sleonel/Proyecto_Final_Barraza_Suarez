/**
 * This file contains constants used in the receiver module of the beacon
 * and the structure of the message that is sent to the base station with
 * the information about the local time (time stamp) at which the beacon 
 * was received.
 * @author Barraza, Suarez.
 * @modified Apr 11, 2014
 */

#ifndef BEACON_RECEIVER_H
#define BEACON_RECEIVER_H

enum {

  
  // The active message type selected here can be any value above 127, as 
  // recommended in the TEP-4 (http://www.tinyos.net/tinyos-2.x/doc/txt/tep4.txt).
  REPORT_MSG = 129,   //Report message type 129=0x81
 
};

typedef nx_struct ReportMsg {
  nx_uint16_t nodeId; // node ID of the receiver (this node)
  nx_uint16_t bSeqNr; // beacon's sequence number
  nx_uint32_t bRadTStamp; // radio time stamp (local radio time) when the 
                          // beacon was received
} ReportMsg_t;   //the "_t" at the end is a usual convention meaning: "type"


#endif /* BEACON_RECEIVER_H */