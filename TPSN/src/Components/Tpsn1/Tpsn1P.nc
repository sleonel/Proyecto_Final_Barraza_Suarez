/**
 * Implementation of the L1 Node . 
 * The node turns on the red LED after booting. A timer is started. Every time
 * this timer fires, a packet is sent to L0, and the yellow led is 
 * toggled. 
 * The packet contains TPSN request and the ID of this node and a sequence number. 
 * packet called "Report TPSN message to node 0". This packet contains the information about
 * the TPSN  sequence number and the local time it was received. The report
 * packet is sent to the L0 node  directly, so the BS 
 * should be within 1-hop distance. The green LED toggles every time a 
 * "TPSN Report message" is sent.
 * TPSN request is receive form L2 Node, this save the time stamp, and report a message. whit the time stamp. 
 *  
 * 
 * 
 * 
 * @author Barraza, Suarez.
 * @modified Apr 4, 2014 
 */

#include <Timer.h>
#include "Tpsn1.h"
#include "Tpsn2.h"
#include "Beacon.h"
#include "TpsnReceiver0.h"

module Tpsn1P {
  uses interface Boot;
  uses interface Leds;
  uses interface SplitControl as AMControl; //Active Message Control
  uses interface Packet;
  uses interface AMSend as AMSendTo0;
  uses interface AMSend as AMSendTo2;
  uses interface Timer<TMilli> as Timer0;
  uses interface CorrectTime;
  uses interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
  uses interface Receive as ReceiveFrom0;
  uses interface Receive as ReceiveFrom2;
  uses interface LocalTime<TMilli> as LocalTime;
}
implementation {

 uint32_t Tpsn1_time_aux;   // 4 Bytes. for save temporarily time stamp from L2 node.
 
 uint32_t Delta_timeStamp1; // delta time between L1 and L0 nodes.
 
 bool Waiting_anserws;      // boolean from confirm a send packet.
 
 uint32_t  tpsn1_orginal_time; // time stamp from the radio received packet.
 
 uint32_t Tpsn1_RadioTimeStamp; // 4 Bytes. It contains the time stamp of the 
                                // last received TPSN request, as set by the radio (TPSN request to base node)
 
 uint32_t Tpsn2RadTStamp;      // 4 Bytes. It contains the time stamp of the 
                                // last received TPSN request, as set by the radio (TPSN report L2 node)
 
 uint16_t Tpsn2SeqNr;           // 2 Bytes. It contains the sequence number of 
                               // released packets.
 
  uint16_t counter;  // 2 Bytes. It contains the sequence number of 
  // released packets.
  message_t pktBuff; // many Bytes, packet buffer. This is not a pointer,
  // this is the allocation(space) a packet needs in memory. Functions related  
  // to packets access them via memory pointers / addresses, e.g.: &pktBuff
        enum {
  L0_ADD_Node = 0x000B, //address to Base node
  L2_ADD_Node = 0x0009  //address to L2 node
};

  event void Boot.booted() {
    counter = 0; //initialize counter
    call AMControl.start(); //start the radio module (ActiveMessageC)
    call Leds.led0On(); //turn on the red LED.
  }

  //radio
  event void AMControl.startDone(error_t err) {
    if(err == SUCCESS) {
      //if radio started normally, start a timer that will fire every 5 secs
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI_TPSN1);
    }
    else {
      //in case radio did not start normally, try again
      call AMControl.start();
    }
  }

  //radio 
  event void AMControl.stopDone(error_t err) {
    //radio was stopped. Do nothing. 
  }

  //timer reached its time limit (every 5 secs.)
  event void Timer0.fired() {
    //Declare first pointers and variables used in this function.
    Tpsn1Msg_t * Tpsn1Msg; // Pointer to a TPSN request to Base node in memory
                        // This is not an actual place/buffer in memory. 
 
    //Prepare and send packet.
    //First. Cast our packet (Tpsn1Msg_t) into a "TPSN request to Base node " type
    //       Refer to the packet by using the "Tpsn1Msg" pointer.
    Tpsn1Msg = (Tpsn1Msg_t * )(call Packet.getPayload(&pktBuff, sizeof(Tpsn1Msg_t)));
 
    //Check that the casting was ok. 
    if (Tpsn1Msg == NULL){
      // Casting failed for any reason, the pointer Tpsn1Msg is NULL. 
      // Do nothing and leave this function.
      return;
    } 
    
    //Otherwise, the pointer Tpsn1Msg is valid! Prepare packet!
    counter++; //increase counter
    
    Tpsn1Msg->nodeId = TOS_NODE_ID; //This is the ID of this node! 
    //This value is provided at install(flashing) time by the user.

    Tpsn1Msg->seqNr = counter; // Set the sequence number of this packet.
 
    // Send the packet. 
    // AMSend uses the memory address of the original packetBuffer, but
    // the size of the newly created BeaconMsg.  The destination address
    // is Base node, which is defined as L0_ADD_Node and it means that.
    call AMSendTo0.send(L0_ADD_Node, &pktBuff, sizeof(Tpsn1Msg_t)); 
   
  }


  // this event receive a packet from L0 and adjust the time to synchronize the time (base station)
  event void AMSendTo0.sendDone(message_t * msg, error_t err) {
  	
  	
    // This function comes with two arguments: a message pointer to the sent 
    // message and an error indicator informing whether the packet was sent
    // fine or had problems. We ignore the error information. 
    
    // Check if the sendDone corresponds to the packet sent by this
    // application (Tpsn1C). Check that the pointer msg points to pktBuff   
    if(&pktBuff == msg) {
    	if(call PacketTimeStampMilli.isValid(msg)){
    	
    		tpsn1_orginal_time= call PacketTimeStampMilli.timestamp(msg);
    		Waiting_anserws= TRUE;
		    // toggle the yellow LED
		      
     
		} else { 
		  	Waiting_anserws = FALSE;
		} 
    }
  }
  
//receive TPSN report form L0 (base)
event message_t * ReceiveFrom0.receive(message_t *msg, void *payload, uint8_t len){
    //Pointer declaration
    Tpsn0_ReportMsg_t * Tpsn1Msg; // Pointer to a report message
    
 
    // Check if the packet length and the time stamp are valid 
    if (len == sizeof(Tpsn0_ReportMsg_t) && Waiting_anserws){
      //Check passed! Cast the payload pointer to report message
      Tpsn1Msg = (Tpsn0_ReportMsg_t*)payload;
      if (Tpsn1Msg->Tpsn0SeqNr == counter){
	      // Get the sequence number of the TPSN report 
	      //Tpsn1SeqNr = Tpsn1Msg->Tpsn0SeqNr;
	      // Get the radio time stamp of the packet and make the correction 
	      
	      Tpsn1_time_aux= Tpsn1Msg->Tpsn0RadTStamp;
	      Delta_timeStamp1= Tpsn1_time_aux-tpsn1_orginal_time;
	      // due to a time synchronization protocol (if any exists).
	      
	      call CorrectTime.set(call LocalTime.get()+ Delta_timeStamp1); 
	     
	      call Leds.led1Toggle();
          
          }
          
      // Get the current time at this level (application) with the 
      // respective correction due to the time synchronization protocol.
      // Compare to the radio time stamp! 
     
      
      // Now, as other nodes will try to send at this exact moment, packets can 
      // collide and the BaseStation will not be able to detect them correctly.
      // To avoid this we wait a random time between 0 and 1 second using 
      // the TimerWait timer.   
     
    }
    // We now give back the received msg buffer. 
    return msg; 
  }  
  
  
  
 //this event receive a packet from L2 node and cast the sequence number and stamp the time in the packet.
 //report 
   event message_t * ReceiveFrom2.receive(message_t *msg, void *payload, uint8_t len){
    //Pointer declaration
    Tpsn2Msg_t* Tpsn2Msg; // Pointer to a YPSN report
    Tpsn1_ReportMsg_t* Tpsn2rMsg;
    // Check if the packet length and the time stamp are valid 
    if ((len == sizeof(Tpsn2Msg_t))&&(call PacketTimeStampMilli.isValid(msg))) {
      //Check passed! Cast the payload pointer to TPSN request
      Tpsn2Msg = (Tpsn2Msg_t*)payload;
     
      // Get the sequence number of the TPSN request
      Tpsn2SeqNr = Tpsn2Msg->seqNr;
      // Get the radio time stamp of the packet and make the correction 
      // due to a time synchronization protocol (if any exists).
      Tpsn2RadTStamp = call CorrectTime.adjust(call PacketTimeStampMilli.timestamp(msg)); 
      
    
      // Get the current time at this level (application) with the 
      // respective correction due to the time synchronization protocol.
      // Compare to the radio time stamp! 
      
      // Now, as other nodes will try to send at this exact moment, packets can 
      // collide and the BaseStation will not be able to detect them correctly.
      // To avoid this we wait a random time between 0 and 1 second using 
      // the TimerWait timer.   
       //value between 0 and 1024 "ms"
        //Set timer to wait this value


   //Declare first pointers and variables used in this function.
	
	
     // Pointer to a report message in memory
                        // This is not an actual place/buffer in memory. 

    //Prepare and send packet.
    //First. Cast our packet (Tpsn1_ReportMsg_t) into a "TPSN report message" type
    //       Refer to the packet by using the "rMsg" pointer.
    Tpsn2rMsg = (Tpsn1_ReportMsg_t * )(call Packet.getPayload(&pktBuff, sizeof(Tpsn1_ReportMsg_t)));
 
    //Check that the casting was ok. 
    if (Tpsn2rMsg == NULL){
      // Casting failed for any reason, the pointer Tpsn2rMsg is NULL. 
      // Do nothing and leave this function.
      return msg;
    }  
 
    //Otherwise, the pointer Tpsn2rMsg is valid! Prepare packet!
 
    Tpsn2rMsg->nodeId  = TOS_NODE_ID;     // This ID of this node (installed value) 
    Tpsn2rMsg->Tpsn2SeqNr  = Tpsn2SeqNr;     // Set last TPSN request sequence

    // Set the radio and application time stamps for the last beacon 
    // The idea is to compare these two values (which should be close)
    Tpsn2rMsg->Tpsn2RadTStamp = Tpsn2RadTStamp; 
       // Send the packet. 
    // AMSend uses the memory address of the original packetBuffer, but
    // the size of the newly created Tpsn2rMsg.  The destination address
    // is _2_NODE, which is defined as 0x0009.
   
    call AMSendTo2.send(L2_ADD_Node, &pktBuff, sizeof(Tpsn1_ReportMsg_t));
   
    }
    // We now give back the received "msg" buffer. 
    return msg; 
  }


  //timer to send the report 
 
 
  event void AMSendTo2.sendDone(message_t * msg, error_t err) {
    // We ignore the "err" value.
    // Check if the sendDone corresponds to the sent packet by this
    // application. Check that the pointer msg points to pktBuff   
    if(&pktBuff == msg) {
      // Check passed! This sendDone belongs to the pktBuff we sent, so we 
      // are sure the transmission has finished.
      call Leds.led1Toggle(); // toggle the green LED
    }
  }
  
  

	

	
}