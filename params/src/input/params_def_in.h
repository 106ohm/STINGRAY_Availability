/* Definition of data structures */

//#include "../params.h"

const short nMADs = 19;
const short nSamples = 144;

/* the difference between the temperature local to each DMA and the global temperature for each MAD at time 0 */
const Array1D<double, nMADs> temperatureDeltaInit({-3,-3,-3,-3,-3,-3,-3,-3,-3,3,3,3,3,3,3,3,3,3,3});

/* the variance of the difference between the temperature local to each DMA and the global temperature T0, for each MAD at time 0 
   a percentage of T0Var
*/
const Array1D<double, nMADs> temperatureCoeff({0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,
    1.1,1.1,1.1,1.1,1.1,1.1,1.1,1.1,1.1,1.1});
