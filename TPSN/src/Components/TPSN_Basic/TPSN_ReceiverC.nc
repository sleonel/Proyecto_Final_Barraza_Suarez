/**
 * Use this component as the AMReceiverC in the TPSN project. 
 * 
 * @author Barraza, Suarez.
 * @modified Apr 23, 2014
 */

#include "AM.h"

generic configuration TPSN_ReceiverC(am_id_t amId) {
  provides {
    interface Receive;
    interface Packet;
    interface AMPacket;
  }
}

implementation {
  components TPSN_ActiveMessageC as AMC;

  //export PROVIDED interfaces
  Receive  = AMC.Receive[amId];
  Packet   = AMC.Packet;
  AMPacket = AMC.AMPacket;
}