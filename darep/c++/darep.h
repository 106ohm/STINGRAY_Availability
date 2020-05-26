#ifndef __DAREP_H_INCLUDED__   // if x.h hasn't been included yet...
#define __DAREP_H_INCLUDED__   //   #define this so the compiler knows it has been included

#include "array-multidimensional.h"

#include "Cpp/BaseClasses/SAN/Place.h"
#include "Cpp/BaseClasses/SAN/ExtendedPlace.h"
#include "Cpp/BaseClasses/BaseModelClass.h"

using namespace std;

// namespace for Join-Based Replication of SAN
namespace SANDAREP
{


// dummy class defined to avoid compilation error when "<dependency-related-state-variable>->Deps()" is used in SAN template of join-based replicated SAN
template <typename T>
class DummyDRSV {
public:
  DummyDRSV(): a() {}; // initialize to empty list
  T* Deps(unsigned int i) { return a(0); };
  Array1D<T*,1>* Deps(void) { return &a; };
private:
  Array1D<T*,1> a;
};


// the list of the different instances (Deps) of a dependency-related state variable (place) associated to a generic replica
template <typename T, size_t MAXDEPS>
class DRSTATEVAR : public Array1D<T*,MAXDEPS> {
public:
  DRSTATEVAR():
    Array1D<T*,MAXDEPS>() {};
  void Init(std::initializer_list<T*> list) {
    this->size(list.size());
    unsigned i=0;
    for (T* elem : list)
      (*this)(i++)=elem;
  }
  void Init2(std::initializer_list<T*> list) {
  }
  T* Deps(unsigned i) const {
    return (*this)(i);
  }
  Array1D<T*,MAXDEPS>* Deps(void) {
    return this;
  }
};


// array with n entries, one for each replica of the SAN template
template <typename T, size_t MAXNREP>
class REPS : public Array1D<T,MAXNREP> {
public:
  REPS():
    Array1D<T,MAXNREP>(MAXNREP) {};
  T* Index(unsigned i) { // overload Index() in order to access to each entry of REPS using operator ->
    return &(*this)(i);
  }
};
  

} // namespace for Join-Based Replication of SAN

#include "auto/darep_in.h"

#endif
