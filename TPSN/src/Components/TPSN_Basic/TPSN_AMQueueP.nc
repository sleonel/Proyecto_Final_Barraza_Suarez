/**
 * The fair-share send queue for AM radio communication in the TPSN project
 *
 * @author Barraza, Suarez
 * @modified Apr 24, 2014 
 */ 

#include "AM.h"

configuration TPSN_AMQueueP {
  provides interface Send[uint8_t client];
}

implementation {
  enum {
    NUM_CLIENTS = uniqueCount(UQ_AMQUEUE_SEND)
  };
  
  components new AMQueueImplP(NUM_CLIENTS);
  components TPSN_ActiveMessageC;

  Send = AMQueueImplP;
  AMQueueImplP.AMSend -> TPSN_ActiveMessageC;
  AMQueueImplP.AMPacket -> TPSN_ActiveMessageC;
  AMQueueImplP.Packet -> TPSN_ActiveMessageC;
  
}