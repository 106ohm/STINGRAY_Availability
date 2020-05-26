//=================================
// multidimensional array based on plain array

#ifndef __ARRAYLIST_H_INCLUDED__   // if .h hasn't been included yet...
#define __ARRAYLIST_H_INCLUDED__   //   #define this so the compiler knows it has been included


#include <assert.h>     /* assert */
#include <algorithm>    // std::for_each
#include <initializer_list>  // std::initializer_list
#include <iostream>
using namespace std;


// One dimensional array, no dynamic memory
template <class T, size_t MAXSIZE>
  class Array1DList {
 protected:
  class Item {
  public:    
    T value; // the value
    unsigned next; // position (index) of the next element of the bidiretional list
    unsigned prev; // position (index) the previous element of the bidiretional list
    bool removed; // ==true if the entry has been removed from the list
  }; // Item class
  enum { nullind=MAXSIZE };
  unsigned n; // actual size of the array
  Item a[MAXSIZE];
  unsigned first; // the first element of the list

  // to prevent unwanted copying:
  //private:
  //Array1DList(const Array1DList<T,MAXSIZE>&);
  //Array1DList<T,MAXSIZE>& operator = (const Array1DList<T,MAXSIZE>&);
 public:  
  // the iterator class
  class Array1DList_iterator {
  public:
  Array1DList_iterator(Array1DList<T,MAXSIZE>& l, unsigned p)
    : list(l), pos(p) {};
    // Defining operator!=() for an iterator
    bool operator!=(const Array1DList_iterator & other) const {
      return !(pos==other.pos);
    };
    // Defining operator*() for an iterator
    T & operator*() {
      assert(pos>=0 && pos<list.n);
      return list(pos);
    };
    // Defining prefix operator++() for an iterator (e.g., ++iter)
    Array1DList_iterator & operator++() {
      pos=list.a[pos].next;
      return *this;
    };
  private:
    Array1DList<T,MAXSIZE>& list; // the list
    unsigned pos; // the position (index) of the current item of the list
  };
 
  // constructor
 Array1DList(const std::initializer_list<T> list): n(list.size()), first(0) {
    assert(n<=MAXSIZE);
    unsigned i=0;
    // set the values of each entry of the list
    for (T elem : list)
      a[i++].value=elem;
    // set the info about pointers and removed-entries
    a[0].prev=nullind;
    a[n-1].next=nullind;
    a[0].removed=false;
    for(i=1; i<n; i++){
      a[i].prev=i-1;
      a[i-1].next=i;
      a[i].removed=false;
    }
  };
 Array1DList(unsigned nv): n(nv), a(), first(0) {
    assert(n>=1 && n<=MAXSIZE);
    //for(unsigned i=0; i<n; i++)
    // a[i]=Item();
  };
  // empty list
 Array1DList(): n(0), first(0) {};

  // set array with list of values {value,value,...}
  void operator () (const std::initializer_list<T> list) {  
    n=list.size();
    assert(n<=MAXSIZE);
    unsigned i=0;
    // set the values of each entry of the list
    for (T elem : list)
      a[i++].value=elem;
    // set the info about pointers and removed-entries
    a[0].prev=nullind;
    a[n-1].next=nullind;
    a[0].removed=false;
    for(i=1; i<n; i++){
      a[i].prev=i-1;
      a[i-1].next=i;
      a[i].removed=false;
    }
  }

  // indexing (parenthesis operator)
  //  two of them (for const correctness)
  const T& operator () (unsigned i) const { 
    assert(i>=0 && i<n);
    return a[i].value;
  };
  T& operator () (unsigned i)
  {
    assert(i>=0 && i<n);
    return a[i].value;
  };

  // get dim
  unsigned size() const { 
    return n;
  };
  // change dim
  void size(unsigned nv) { 
    assert(nv>=1 && nv<=MAXSIZE);
    n=nv;
  };
  /* copy operator
  Array1DList<T,MAXSIZE>& operator = (const Array1DList<T,MAXSIZE>& other){
    if (this != &other) { // self-assignment check expected
      n=other.n;
      assert(n<=MAXSIZE);
      first=other.first;
      for( unsigned i=0; i<n; i++ )
	a[i]=other.a[i];
    }
    return *this;
  };
  */
  Array1DList_iterator begin() {
    return Array1DList_iterator(*this, first);
  };
  Array1DList_iterator end() {
    return Array1DList_iterator(*this, nullind);
  };
};
  

#endif // __ARRAYMULTIDIMENSIONAL_H_INCLUDED__ 
