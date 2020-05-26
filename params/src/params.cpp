
/*
  The starting code "#if... #endif" remove "Numerous warnings due to deprecated `register` keyword" [  https://github.com/ValveSoftware/source-sdk-2013/issues/258 ]
  This is in accordance with the standard: http://www.stroustrup.com/C++11FAQ.html#11
  On LLVM 5.1 __cplusplus is defined as 201103L and it works.
*/
#if __cplusplus > 199711L
#define register      // Deprecated in C++11.
#endif  // #if __cplusplus > 199711L

#include "params.h"

/* definition of the global variables */


// setup function
void setup () {

}

