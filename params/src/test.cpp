#include "debug.h"

// params
#include "params.h"
	
// test
#include "test.h" // test functions


int main()
{
 
  debug << "********** Test **********" << std::endl << std::endl;
  
  test();

  return 0;
}

