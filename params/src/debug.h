#ifndef __DEBUG_H_INCLUDED__   // if x.h hasn't been included yet...
#define __DEBUG_H_INCLUDED__   //   #define this so the compiler knows it has been included

#include <limits>
#include <iostream>
#include <iomanip>      // std::setw
 
/** Creating your own class for debugging, that can be expanded as needed when more debug functionality is required [ https://stackoverflow.com/questions/1389538/cancelling-stdcout-code-lines-using-preprocessor ]
*/
class MyDebug
{
  std::ostream & stream;
 public:
 MyDebug(std::ostream & s) : stream(s) {}
  template<typename T>
    MyDebug & operator<<(T const & item)
    {
#ifdef DEBUG
      stream << item;
#endif
      return *this;
    };
  /**
     Since manipulators are implemented as functions, if you want to accept manipulators as well (endl) you can add:
  */
  MyDebug & operator<<(std::ostream & (*pf)(std::ostream&))
    {
#ifdef DEBUG
      stream << pf;
#endif
      return *this;
    };
  /** 
      For all manipulator types (So that you don't have to overload for all manipulator types):
      Be careful with this last one, because that will also accept regular functions pointers.
  */
  template<typename R, typename P>
    MyDebug & operator<<(R const & (*pf)(P const &))
  {
#ifdef DEBUG
    stream << pf;
#endif
    return *this;
  };
};

/* class MyDebug to print numbers with full precision */
class MyDebugFullPrec
{
  std::ostream & stream;
 public:
 MyDebugFullPrec(std::ostream & s) : stream(s) {}
  template<typename T>
    MyDebugFullPrec & operator<<(T const & item)
    {
#ifdef DEBUG
      // change precision
      std::streamsize cprecision = std::cout.precision(); // current precision
      stream.precision(std::numeric_limits<double>::digits10+1); // set full precision      
      stream << item;
      stream.precision(cprecision); // reset precision to previous value
#endif
      return *this;
    };
  /**
     Since manipulators are implemented as functions, if you want to accept manipulators as well (endl) you can add:
  */
  MyDebugFullPrec & operator<<(std::ostream & (*pf)(std::ostream&))
    {
#ifdef DEBUG
      // change precision
      std::streamsize cprecision = std::cout.precision(); // current precision
      stream.precision(std::numeric_limits<double>::digits10+1); // set full precision
      stream << pf;
      stream.precision(cprecision); // reset precision to previous value
#endif
      return *this;
    };
  /** 
      For all manipulator types (So that you don't have to overload for all manipulator types):
      Be careful with this last one, because that will also accept regular functions pointers.
  */
  template<typename R, typename P>
    MyDebugFullPrec & operator<<(R const & (*pf)(P const &))
  {
#ifdef DEBUG
    // change precision
    std::streamsize cprecision = std::cout.precision(); // current precision
    stream.precision(std::numeric_limits<double>::digits10+1); // set full precision
    stream << pf;
    stream.precision(cprecision); // reset precision to previous value
#endif
    return *this;
  };
};

// to output debug info
static MyDebug debug(std::cout);
static MyDebugFullPrec debug_fullprec(std::cout);

#endif 
