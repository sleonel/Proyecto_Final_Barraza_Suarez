/**
 * Interface to get and set my version of the corrected time.
 * @author Barraza Suarez
 * @modified Apr 12, 2014
 */

interface CorrectTime{
  
  /**
   * Set the corrected time with the time of a node of lower level
   * 
   * @param value the new corrected (synchronized) time
   */

  command void set(uint32_t value);

  /**
   * Get our corrected version of the local time. 
   * 
   * @return the correct (synchronized) local time
   */
  command uint32_t get();

  /**
   * Translate a local time value into the corrected (adjusted) time.
   * 
   * @param value the local hardware time you want to translate into the 
   *               corrected (adjusted, synchronized) time 
   */
  command uint32_t adjust(uint32_t value);
  
}