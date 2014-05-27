/** 
 * Implementation of the ActiveMessageC used in the node acting as
 * Base Station in the TPSN project. 
 * 
 * Basically, it is an intermediary between:
 * 1) the radio
 * 2) the other components in the TPSN project
 * 3) the serial interface
 * 
 * When it receives packet from the radio (lower layer) it does the following:
 * 1. If there are components wired to it, it pass the packet to 
 *    the component using the type of the message received.
 *    When the component returns the packet, it sends it to the serial port. 
 * 2. If there are no components wired to it that use the type of
 *    the message received, the packet is sent directly to the serial port. 
 * 
 * When it receives a packet coming from one upper component, then it 
 * makes a copy of the packet, sends the original to the radio, and 
 * the copy is sent to the serial port.
 * 
 * Leds. Green:  Packet to serial
 *       Yellow: failure/drop of a packet.
 * 
 * Usage at PC:
 * 
 *   java net.tinyos.tools.Listen -comm serial@/dev/ttyUSB1:iris
 * 
 * 
 * 
 * @author Barraza, Suarez
 * @modified Apr 15, 2014
 *
 */

#include <AM.h>
#include <Serial.h> 
#include <Timer.h>

#include "Beacon.h"  

module TPSN_Base_AMP {
  provides {
    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Receive as Snoop[uint8_t id];
  }

  uses {
    interface Boot;
    interface Leds;

    // Radio
    interface SplitControl as RadioControl;
    interface AMSend as RadioAMSend[uint8_t id];
    interface Receive as RadioReceive[uint8_t id];
    interface Receive as RadioSnoop[uint8_t id];
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;

    //Serial
    interface SplitControl as SerialControl;
    interface AMSend as SerialAMSend[am_id_t id];
    interface Packet as SerialPacket;
    interface AMPacket as SerialAMPacket;

  }
}
implementation {

  //Declare constants
  enum {
    SERIAL_QUEUE_LEN = 10
  };

  //Declare variables
  message_t serialQueueBufs[SERIAL_QUEUE_LEN]; //array of packet buffers
  message_t * serialQueue[SERIAL_QUEUE_LEN]; //array of pointers
  uint8_t serialIn, serialOut;
  bool serialBusy, serialFull;
  message_t msgBuff; //message buffer
  message_t * mBuff; //pointer to message buffer


  //Declare C-functions and tasks before using them. Later, implement them. 
  message_t * enqueueToSerial(message_t * msg);

  task void serialSendTask();

  // after booting
  event void Boot.booted() {
    uint8_t i;
    // pointer points to msgBuffer.
    mBuff = &msgBuff; 
    // fill arrays
    for(i = 0; i < SERIAL_QUEUE_LEN; i++) {
      serialQueue[i] = &serialQueueBufs[i];
    }
    serialIn = serialOut = 0;
    serialBusy = FALSE;
    serialFull = TRUE; // not ready to use serial    

    call RadioControl.start(); //turn on radio
    call SerialControl.start(); //turn on serial
    
    call Leds.led0On();  // turn ON red led 
  }

  //radio
  event void RadioControl.startDone(error_t error) {
    if(error != SUCCESS) 
      call RadioControl.start(); //try again 
  }

  //serial
  event void SerialControl.startDone(error_t error) {
    if(error == SUCCESS) 
      serialFull = FALSE; // ready to use serial
    else 
      call SerialControl.start(); //try again
  }

  event void RadioControl.stopDone(error_t error) {
  }
  event void SerialControl.stopDone(error_t error) {
  }

  //----- RadioReceive (used interface) -----
  event message_t * RadioReceive.receive[uint8_t id](message_t * msg, void 
      * payload, uint8_t len) {
    message_t * ret = msg;
    // signal upper component about this receive and hope it 
    // gives back the same msg, otherwise we will sent garbage data to serial
    ret = signal Receive.receive[id](msg, payload, len);
    // enqueue the returned msg into the serial
    return enqueueToSerial(ret);
  }

  // ---- Receive (provided interface) --------
  // When we want to signal a reception via this interface we just do 
  // it with "signal Receive.receive(...)", as we do in RadioReceive.receive. 
  // We use "default" handler to catch unconnected interfaces (parameterized
  // by the id) of our provided interface "Receive". It is what an imaginary
  // "upper component" would do as default. 
  default event message_t * Receive.receive[uint8_t id](message_t * msg, void 
      * payload, uint8_t len) {
    return msg; //do nothing, just give back the msg pointer.
  }

  //----- RadioSnoop (used interface) -----
  event message_t * RadioSnoop.receive[uint8_t id](message_t * msg, void 
      * payload, uint8_t len) {
    message_t * ret = msg;
    // signal upper component about this snoop and hope it 
    // gives back the same msg, otherwise we will sent garbage data to serial
    ret = signal Snoop.receive[id](msg, payload, len);
    // enqueue the returned msg into the serial
    return enqueueToSerial(ret);
  }

  // ---- Snoop (provided interface) --------
  // When we want to signal a reception via this interface we just do 
  // it with "signal Snoop.receive(...)", as we do in RadioSnoop.receive. 
  // We use "default" handler to catch unconnected interfaces (parameterized
  // by the id) of our provided interface "Snoop". It is what an imaginary
  // "upper component" would do as default. 
  default event message_t * Snoop.receive[uint8_t id](message_t * msg, void 
      * payload, uint8_t len) {
    return msg; //do nothing, just give back the msg pointer.
  }


  //put in queue to the serial port
  message_t * enqueueToSerial(message_t * msg) {
    message_t * ret = msg;

    atomic {
      if( ! serialFull) {
        ret = serialQueue[serialIn];
        serialQueue[serialIn] = msg;

        serialIn++;
        //circular buffer array 
        if(serialIn >= SERIAL_QUEUE_LEN) 
          serialIn = 0;

        if(serialIn == serialOut) 
          serialFull = TRUE; //buffer array is full   

        if( ! serialBusy) {
          post serialSendTask();
          serialBusy = TRUE;
        }
      }
      else {
        call Leds.led2Toggle(); //fail 
      }
    }
    return ret;
  }

  //send packets in the queue to the serial port
  task void serialSendTask() {
    uint8_t len;
    am_id_t id;
    am_addr_t addr, src;
    message_t * msg;
    am_group_t grp;
    
    //if queue to serial is empty, leave this task.
    atomic if(serialIn == serialOut && ! serialFull) {
      serialBusy = FALSE;
      return;
    }

    msg = serialQueue[serialOut];
    len = call RadioPacket.payloadLength(msg); // Important!
    id = call RadioAMPacket.type(msg);
    addr = call RadioAMPacket.destination(msg);
    src = call RadioAMPacket.source(msg);
    grp = call RadioAMPacket.group(msg);
    call SerialPacket.clear(msg);
    call SerialAMPacket.setSource(msg, src);
    call SerialAMPacket.setGroup(msg, grp);

    if (call SerialAMSend.send[id](addr, serialQueue[serialOut], len) != SUCCESS){
      call Leds.led2Toggle(); // yellow: fail
      post serialSendTask();  //repost if it could not start sending
    } //otherwise wait for the sendDone
  }

  event void SerialAMSend.sendDone[am_id_t id](message_t * msg,
      error_t error) {
    if(error != SUCCESS) {
      call Leds.led2Toggle(); //fail 
    } else {
      atomic if(msg == serialQueue[serialOut]) {
        serialOut++;
        //circular buffer array 
        if(serialOut >= SERIAL_QUEUE_LEN) 
          serialOut = 0;
        if(serialFull) 
          serialFull = FALSE;
        call Leds.led1Toggle(); //toggle green led on serial success.
      }
    }
    //always try to send again, perhaps there are more packets in the queue
    post serialSendTask();
  }



  //----- AMSend (provided interface) -----
  command error_t AMSend.cancel[uint8_t id](message_t * msg) {
    return call RadioAMSend.cancel[id](msg); //bypass
  }

  command error_t AMSend.send[uint8_t id](am_addr_t addr, message_t * msg,
      uint8_t len) {
    return call RadioAMSend.send[id](addr, msg, len); //bypass
  }

  command void * AMSend.getPayload[uint8_t id](message_t * msg, uint8_t len) {
    return call RadioAMSend.getPayload[id](msg, len); //bypass
  }

  command uint8_t AMSend.maxPayloadLength[uint8_t id]() {
    return call RadioAMSend.maxPayloadLength[id](); //bypass
  }
  
  // We use "default" handler to catch unconnected interfaces (parameterized
  // by the id) of our provided interface "AMSend". It is what an imaginary
  // "upper component" would do as default. 
  default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t error){
    //do nothing
  }

  //----- RadioAMSend (used interface) ----
  event void RadioAMSend.sendDone[uint8_t id](message_t * msg, error_t error) {
    // if packet was successfully sent by this layer, then make a 
    // copy and send it to the serial. 
    if (error == SUCCESS){
      // prepare buffer that will contain the copy
      void * payloadMsg = NULL;
      void * payloadMBuff = NULL;
      uint8_t len = 0;
      uint8_t i = 0;
 
      call RadioPacket.clear(mBuff); //clear my message buffer

      //set PL-length in mBuff
      len = call RadioPacket.payloadLength(msg);
      call RadioPacket.setPayloadLength(mBuff, len); //Important!

      //get PL-pointers
      payloadMsg = call RadioPacket.getPayload(msg, len); 
      payloadMBuff = call RadioPacket.getPayload(mBuff, len);
 
      //check payload pointers are ok
      if ((payloadMsg!=NULL)&&(payloadMBuff!=NULL)){
        
        //vars
        uint8_t * byteSrcPtr;
        uint8_t * byteDstPtr;
        uint8_t byteVal;
 
        //copy AM fields
        call RadioAMPacket.setDestination(mBuff, call RadioAMPacket
            .destination(msg));
        call RadioAMPacket.setGroup(mBuff, call RadioAMPacket.group(msg));
        call RadioAMPacket.setSource(mBuff, call RadioAMPacket.source(msg));
        call RadioAMPacket.setType(mBuff, call RadioAMPacket.type(msg));
        
	
        //get byte-pointers to payload start position in msg and in mBuff  
        byteSrcPtr = (uint8_t*)payloadMsg;
        byteDstPtr = (uint8_t*)payloadMBuff;
        //copy bytes
        for(i = 0; i < len; i++) {
          byteVal = *byteSrcPtr; //extract byte from msg
          *byteDstPtr = byteVal; //insert byte in mBuff
          byteSrcPtr++; //move pointer to next byte;
          byteDstPtr++; //move pointer to next byte;          
        }	
        
        //Special behavior:
        // If the packet is a BeaconMsg and its timestamp is valid,
        // add extra bytes at the end with the time at which it was sent. 
        if ((call RadioAMPacket.type(msg) == BEACON_MSG)&&
              call PacketTimeStampMilli.isValid(msg)){
          //cast byteDst Pointer  in mBuff into a unit32_t pointer
          nx_uint32_t * tsPtr = (nx_uint32_t *)byteDstPtr; //casting
          *tsPtr = call PacketTimeStampMilli.timestamp(msg); //insert value
          //increase length of mBuff payload by the size of the added timestamp
          call RadioPacket.setPayloadLength(mBuff, (uint8_t)(len + sizeof(nx_uint32_t)));                   
        }
 
 
        //enqueue copy of the message to serial and store the returned buffer pointer
        mBuff = enqueueToSerial(mBuff);
      }
    }
 
    //now signal the sendDone to upper components  
    signal AMSend.sendDone[id](msg, error); //bypass
  }

}