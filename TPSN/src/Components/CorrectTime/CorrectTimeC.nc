/**
 * This module keeps the correct time, that is, the synchronized time, 
 * based on the actual local time at the node and on a correction to that 
 * time: deltaTime
 * It offers the interface CorrectTime, defined by us. This interface allows
 * to know the corrected local time, and to set a correct local time, by 
 * means of updating a deltaTime value.
 * @author Barraza, Suarez
 * @modified Apr 12, 2014
 */


configuration CorrectTimeC {
  // provides this interface to other modules, so they can 
  // ask and set the correct/adjusted time : synchronized time
  provides interface CorrectTime;

}

implementation {
  
  components MainC;
  components CorrectTimeP as App;
  components LocalTimeMilliC;  
  
  CorrectTime = App.CorrectTime;  //the provided interface is implemented 
                                  // by the module CorrectTimeP (called App)

  App.Boot -> MainC;
  App.LocalTime -> LocalTimeMilliC;
 
}