#if !defined(__SAN_FUNCTIONS_H_INCLUDED__) && !defined(TEST)   // if x.h hasn't been included yet...
#define __SAN_FUNCTIONS_H_INCLUDED__   //   #define this so the compiler knows it has been included

#include "Cpp/BaseClasses/SAN/ExtendedPlace.h"
#include "Cpp/BaseClasses/BaseModelClass.h"
//#include "SAN_circular-queue.h"

const double TWOPI=2*M_PI;

// variance from the base function (for updateVar1Temperature0 and updateVar0Temperature0 )
// 0<=T0Var<=1
const double T0Var = 0.6;

// variance from the base function (for updateVar1DewPoint and updateVar0DewPoint)
// 0<=DPVar<=1
const double DPVar = 0.6;

// variance from the base function (for updateVar1Temperature  and updateVar0Temperature)
// 0<=TVar<=1
const double TVar = 0.3;

/* Update Temperature0 as a function of current Temperature0 and of the variance T0Var,
   using the derivative of trend function, when new temperature does not meet the trend and changes the derivative sign
   t: interval of time [0,t]
   t1: time of last update
   t2: current time
*/
template <typename T>
inline void updateVar1Temperature0(T* Temperature0, double t1, double t2, double t, double t0coeff){
  double derivative=-TWOPI/t*cos(TWOPI*t2/t);
  // 0<=T0Var<=1
  Temperature0->Mark() = (2-1.0/(1.0-T0Var))*t0coeff*derivative*(t2-t1) + Temperature0->Mark();
  // t0var>=1
  // Temperature0->Mark() = (1-1.0/t0var)*(1.0-t0var)*T0Coeff1*derivative*(t2-t1) + Temperature0->Mark();
}

/* Update Temperature0 as a function of current Temperature0 and of the variance T0Var,
   using the derivative of trend function, when new temperature meets the trend and does not change the derivative sign
   t: interval of time [0,t]
   t1: time of last update
   t2: current time
*/
template <typename T>
inline void updateVar0Temperature0(T* Temperature0, double t1, double t2, double t, double t0coeff){
  double derivative=-TWOPI/t*cos(TWOPI*t2/t);
  // 0<=t0var<=1
  Temperature0->Mark() = (1.0/(1.0-T0Var))*t0coeff*derivative*(t2-t1) + Temperature0->Mark();
  // t0var>=1
  // Temperature0->Mark() = (1-1.0/t0var)*(1.0+t0var)*T0Coeff0*derivative*(t2-t1) + Temperature0->Mark();
}

/* Update Temperature as a function of current Temperature and of the variance TVar,
   using the derivative of trend function, when new temperature does not meet the trend and changes the derivative sign
   t: interval of time [0,t]
   t1: time of last update
   t2: current time
*/
template <typename T>
inline void updateVar1Temperature(T* Temperature, double temperature0diff, double t1, double t2, double t, double tcoeff){
  Temperature->Mark() = (2-1.0/(1.0-TVar))*tcoeff*temperature0diff + Temperature->Mark();
}


/* Update Temperature as a function of current Temperature and derivative of trend function, , when new temperature meets the trend and does not change the derivative sign
   t: interval of time [0,t]
   t1: time of last update
   t2: current time
*/
template <typename T>
inline void updateVar0Temperature(T* Temperature, double temperature0diff, double t1, double t2, double t, double tcoeff){
  Temperature->Mark() = (1.0/(1.0-TVar))*tcoeff*temperature0diff + Temperature->Mark();
}


/* Update the Humidity as a function of temperature and dewpoint,
   using the Magnus-Tetens approximation
*/
template <typename T>
inline void updateHumidity(T* Humidity, double temperature, double dewpoint){
    double a = 17.27;
    double b = 237.7;

    if( temperature<=dewpoint )
      Humidity->Mark() = 1;
    else
      Humidity->Mark() = exp(a*b*(dewpoint-temperature)/((dewpoint+b)*(b+temperature)));
}

/* Update dew point
   dew point does not meet the trend and changes the derivative sign
   t: interval of time [0,t]
   t1: time of last update
   t2: current time
*/
template <typename T>
inline void updateVar1DewPoint(T* DewPoint, double temperature, double t1, double t2, double t, double dpcoeff){
  double derivative=-TWOPI/t*cos(TWOPI*t2/t);
  double dewpoint = (2-1.0/(1.0-DPVar))*dpcoeff*derivative*(t2-t1) + DewPoint->Mark();
if( dewpoint>temperature )
    DewPoint->Mark()=temperature;
  else
    DewPoint->Mark()=dewpoint;
}

/* Update dew point
   dew point does meets the trend and does not change the derivative sign
   t: interval of time [0,t]
   t1: time of last update
   t2: current time
*/
template <typename T>
inline void updateVar0DewPoint(T* DewPoint, double temperature, double t1, double t2, double t, double dpcoeff){
  double derivative=-TWOPI/t*cos(TWOPI*t2/t);
  double dewpoint = (1.0/(1.0-DPVar))*dpcoeff*derivative*(t2-t1) + DewPoint->Mark();
  if( dewpoint>temperature )
    DewPoint->Mark()=temperature;
  else
    DewPoint->Mark()=dewpoint;
}


/* Update dew point  
*/
template <typename T>
  inline void updateDewPoint(T* Temperature, T* Humidity, T* DewPoint){
  // Compute the dew point using the Magnus-Tetens approximation
  
  double a = 17.27;
  double b = 237.7;
  
  double alpha = (a*Temperature->Mark())/(b+Temperature->Mark()) + log(Humidity->Mark());
    
  DewPoint->Mark() = (b*alpha)/(a-alpha);
}


/* /\* compute connection failure rate */
/* *\/ */
/* template <typename T> */
/* inline double failureRate(int i, T* HumidityAtMAD){ */
/*   // TODO */
/*   return 1; */
/* } */

/* /\* compute connection recovery rate */
/* *\/ */
/* template <typename T> */
/* inline double recoveryRate(int i, T* HumidityAtMAD){ */
/*   // TODO */
/*   return 1; */
/* } */

// functions related to Algorithm 1

template <typename T>
inline bool Alg1LogicOn(T* TemperatureAtMAD, T* DewPoint, double delta1, double delta2){
  if ( (TemperatureAtMAD->Mark() <= DewPoint->Mark()+delta1 &&
	TemperatureAtMAD->Mark() <= delta2 )
     )
    return true;
  else
    return false;
}


template <typename T>
inline bool Alg1LogicOff(T* TemperatureAtMAD, T* DewPoint, double delta1, double delta2){
  if (TemperatureAtMAD->Mark()>DewPoint->Mark()+delta1 || TemperatureAtMAD->Mark() > delta2 )
    return true;
  else
    return false;
}

// functions related to Algorithm 2

template <typename T>
inline bool Alg2LogicOn(T* TemperatureAtMAD, double delta2){
  if (TemperatureAtMAD->Mark() <= delta2)
    return true;
  else
    return false;
}

template <typename T>
inline bool Alg2LogicOff(T* TemperatureAtMAD, double delta2){
  if (TemperatureAtMAD->Mark() > delta2)
    return true;
  else
    return false;
}

// functions that manage NotWorking DASV

template <typename T, size_t MAXDEPS>
inline void incNW(Array1D<T*,MAXDEPS>* NotWorking){
  short n = NotWorking->size();
  for (short i=0; i<n; ++i){
    NotWorking->Index(i)->Mark() ++;
  }
}

template <typename T, size_t MAXDEPS>
inline void decNW(Array1D<T*,MAXDEPS>* NotWorking){
  short n = NotWorking->size();
  for (short i=0; i<n; ++i){
    if (NotWorking->Index(i)->Mark()>0)
      NotWorking->Index(i)->Mark() --;
  }
}

template <typename T, size_t MAXDEPS>
inline void partial1incNW(Array1D<T*,MAXDEPS>* NotWorking){
  short n = NotWorking->size();
  for (short i=0; i<n/3; ++i){
    NotWorking->Index(i)->Mark() ++;
  }
}

template <typename T, size_t MAXDEPS>
inline void partial1decNW(Array1D<T*,MAXDEPS>* NotWorking){
  short n = NotWorking->size();
  for (short i=0; i<n/3; ++i){
    if (NotWorking->Index(i)->Mark()>0)
      NotWorking->Index(i)->Mark() --;
  }
}

template <typename T, size_t MAXDEPS>
inline void partial2incNW(Array1D<T*,MAXDEPS>* NotWorking){
  short n = NotWorking->size();
  for (short i=0; i<2*n/3; ++i){
    NotWorking->Index(i)->Mark() ++;
  }
}

template <typename T, size_t MAXDEPS>
inline void partial2decNW(Array1D<T*,MAXDEPS>* NotWorking){
  short n = NotWorking->size();
  for (short i=0; i<2*n/3; ++i){
    if (NotWorking->Index(i)->Mark()>0)
      NotWorking->Index(i)->Mark() --;
  }
}

#endif 
