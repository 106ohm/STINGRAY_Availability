//=================================
// multidimensional array based on plain array

#ifndef __ARRAYMULTIDIMENSIONAL_H_INCLUDED__   // if .h hasn't been included yet...
#define __ARRAYMULTIDIMENSIONAL_H_INCLUDED__   //   #define this so the compiler knows it has been included

#include <assert.h>     /* assert */
#include <algorithm>    // std::for_each
#include <initializer_list>  // std::initializer_list
#include<iostream>
#include "debug.h" // print msg at debug mode
using namespace std;

// One dimensional array, no dynamic memory
template <class T, size_t MAXSIZE>
class Array1D {
public:
 // constructor
 Array1D(std::initializer_list<T> list): n(list.size()) {
   //assert(n<=MAXSIZE);
   //copy( list.begin() , list.end(), &a[0]);
   if( n<=MAXSIZE )
     copy( list.begin() , list.end(), &a[0]);
   else {
     copy( list.begin() , list.begin()+MAXSIZE, &a[0]);
     debug << "Warning: Length of initializer_list exceeds size of array: only first " << MAXSIZE << " elements are assigned to array, " << n-MAXSIZE << " elements are ignored." << endl;
   }
  };
 Array1D(unsigned nv): n(nv), a() {
    assert(n>=1 && n<=MAXSIZE);
    //for(unsigned i=0; i<n; i++)
    // a[i]=T();
  };
 Array1D(): n(0) {
  };
  // set array with list of values {value,value,...}
  void operator () (std::initializer_list<T> list) {  
    n=list.size();
    assert(n<=MAXSIZE);
    copy( list.begin() , list.end(), &a[0]);
  }

  // indexing (parenthesis operator)
  //  two of them (for const correctness)
  const T& operator () (unsigned i) const { 
    //    debug << "i=" << i << ", n=" << n << endl;
    assert(i>=0 && i<n);
    return a[i];
  };
  T& operator () (unsigned i)
  {
    assert(i>=0 && i<n);
    return a[i];
  };

  // indexing (-> operator)
  //  two of them (for const correctness)
  const T& Index(unsigned i) const { 
    //    debug << "i=" << i << ", n=" << n << endl;
    assert(i>=0 && i<n);
    return a[i];
  };
  T& Index(unsigned i)
  {
    assert(i>=0 && i<n);
    return a[i];
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
  // copy operator
  Array1D<T,MAXSIZE>& operator = (const Array1D<T,MAXSIZE>& other){
    n=other.n;
    //    debug << "*** n: "<< n << ", other.n:" << other.n << endl;
    assert(n<=MAXSIZE);
    for( unsigned i=0; i<n; i++ )
      a[i]=other.a[i];
    return *this;
  };

private:
  unsigned n; // actual size
  T a[MAXSIZE];

  // to prevent unwanted copying:
  //Array1D(const Array1D<T,MAXSIZE>&);
  //Array1D<T,MAXSIZE>& operator = (const Array1D<T,MAXSIZE>&);
};


// two dimensional array, no dynamic memory
template <class T, size_t MAXSIZE1, size_t MAXSIZE2>
class Array2D {
public:
  // constructor
  Array2D(std::initializer_list<std::initializer_list<T>> list): n1(list.size()), n2(list.begin()->size()) {
    assert((n1<=MAXSIZE1) &&
	   (n2<=MAXSIZE2));
    unsigned i=0;
    for (std::initializer_list<T> row : list) {
      unsigned j=0;
      for (T elem : row)
	a[i*n2+j++]=elem;
      assert(j==n2);
      i++;
    }
    assert(i==n1);
  };
Array2D(unsigned nv1, unsigned nv2): n1(nv1), n2(nv2), a() {
    assert((n1>=1 && n1<=MAXSIZE1) &&
	   (n2>=1 && n2<=MAXSIZE2));
};
 Array2D(): n1(0), n2(0) {
  };

  // set array with list of values {value,value,...}
  void operator () (std::initializer_list<std::initializer_list<T>> list) {
    n1=list.size();
    n2=list.begin()->size();
    assert((n1<=MAXSIZE1) &&
	   (n2<=MAXSIZE2));
    unsigned i=0;
    for (std::initializer_list<T> row : list) {
      unsigned j=0;
      for (T elem : row)
	a[i*n2+j++]=elem;
      assert(j==n2);
      i++;
    }
    assert(i==n1);
  }

  // indexing (parenthesis operator)
  //  two of them (for const correctness)
  const T& operator () (unsigned i, unsigned j) const {  
    assert((i>=0 && i<n1) && 
	   (j>=0 && j<n2));
    return a[i*n2+j];
  };
  T& operator () (unsigned i, unsigned j)
  {
    assert((i>=0 && i<n1) && 
	   (j>=0 && j<n2));
    return a[i*n2+j];
  };

  // get dims
  unsigned size1() const { 
    return n1;
  };
  unsigned size2() const { 
    return n2;
  };
  // change dims
  void size1(unsigned nv) { 
    assert(nv>=1 && nv<=MAXSIZE1);
    n1=nv;
  };
  void size2(unsigned nv) { 
    assert(nv>=1 && nv<=MAXSIZE2);
    n2=nv;
  };
  void size(unsigned nv1, unsigned nv2) { 
    assert((nv1>=1 && nv1<=MAXSIZE1) &&
	   (nv2>=1 && nv2<=MAXSIZE2));
    n1=nv1;
    n2=nv2;
  };

  // copy constructor
  /*
    Array2D(const Array2D<T,MAXSIZE1,MAXSIZE2>& other) {
    n1=other.size1();
    n2=other.size2();
    assert((n1<=MAXSIZE1) &&
	   (n2<=MAXSIZE2));
    for( unsigned i=0; i<n1; i++ )
      for( unsigned j=0; j<n1; j++ )
	a[i,j]=other.a[i*n2+j];
    debug << "*** n1=" << n1 << ",n2="<< n2 << endl;
    };
  */
  
private:
  unsigned n1; // dim1 actual size
  unsigned n2; // dim2 actual size
  T a[MAXSIZE1*MAXSIZE2];

  // to prevent unwanted copying:
  Array2D(const Array2D<T,MAXSIZE1,MAXSIZE2>&);
  //Array2D<T,MAXSIZE1,MAXSIZE2>& operator = (const Array2D<T,MAXSIZE1,MAXSIZE2>&);
};



// three dimensional array, no dynamic memory
template <class T, size_t MAXSIZE1, size_t MAXSIZE2, size_t MAXSIZE3>
class Array3D {
public:
  // constructor
  Array3D(std::initializer_list<std::initializer_list<std::initializer_list<T>>> list): n1(list.size()), n2(list.begin()->size()), n3(list.begin()->begin()->size()) {
    assert((n1<=MAXSIZE1) &&
	   (n2<=MAXSIZE2) &&
	   (n3<=MAXSIZE3));
    unsigned i=0;
    for (std::initializer_list<std::initializer_list<T>> mat : list) {
      unsigned j=0;
      for (std::initializer_list<T> row : mat) {
	unsigned k=0;
	for (T elem : row) 
	  a[i*n2*n3+j*n3+k++]=elem;
	assert(k==n3);
	j++;
      }
      assert(j==n2);
      i++;
    };
    assert(i==n1);
  };
 Array3D(unsigned nv1, unsigned nv2, unsigned nv3): n1(nv1), n2(nv2), n3(nv3), a() {
    assert((n1>=1 && n1<=MAXSIZE1) &&
	   (n2>=1 && n2<=MAXSIZE2) &&
	   (n3>=1 && n3<=MAXSIZE3));
  };
  Array3D(): n1(0), n2(0), n3(0) {
  };

  // set array with list of values {value,value,...}
  void operator () (std::initializer_list<std::initializer_list<std::initializer_list<T>>> list) {
    n1=list.size();
    n2=list.begin()->size();
    n3=list.begin()->begin()->size();
    assert((n1<=MAXSIZE1) &&
	   (n2<=MAXSIZE2) &&
	   (n3<=MAXSIZE3));
    unsigned i=0;
    for (std::initializer_list<std::initializer_list<T>> mat : list) {
      unsigned j=0;
      for (std::initializer_list<T> row : mat) {
	unsigned k=0;
	for (T elem : row) 
	  a[i*n2*n3+j*n3+k++]=elem;
	assert(k==n3);
	j++;
      }
      assert(j==n2);
      i++;
    };
    assert(i==n1);
  }


  // indexing (parenthesis operator)
  //  two of them (for const correctness)
  const T& operator () (unsigned i, unsigned j, unsigned k) const {  
    assert((i>=0 && i<n1) && 
	   (j>=0 && j<n2) && 
	   (k>=0 && k<n3));
    return a[i*n2*n3+j*n3+k];
  };
  T& operator () (unsigned i, unsigned j, unsigned k)
  {
    assert((i>=0 && i<n1) && 
	   (j>=0 && j<n2) && 
	   (k>=0 && k<n3));
    return a[i*n2*n3+j*n3+k];
  };

  // get dims
  unsigned size1() const { 
    return n1;
  };
  unsigned size2() const { 
    return n2;
  };
  unsigned size3() const { 
    return n3;
  };
  // change dims
  void size1(unsigned nv) { 
    assert(nv>=1 && nv<=MAXSIZE1);
    n1=nv;
  };
  void size2(unsigned nv) { 
    assert(nv>=1 && nv<=MAXSIZE2);
    n2=nv;
  };
  void size3(unsigned nv) { 
    assert(nv>=1 && nv<=MAXSIZE3);
    n3=nv;
  };
  void size(unsigned nv1, unsigned nv2, unsigned nv3) { 
    assert((nv1>=1 && nv1<=MAXSIZE1) &&
	   (nv2>=1 && nv2<=MAXSIZE2) &&
	   (nv3>=1 && nv3<=MAXSIZE3));    
    n1=nv1;
    n2=nv2;
    n3=nv3;
  };


private:
  unsigned n1; // dim1 actual size
  unsigned n2; // dim2 actual size
  unsigned n3; // dim3 actual size
  T a[MAXSIZE1*MAXSIZE2*MAXSIZE3];

  // to prevent unwanted copying:
  Array3D(const Array3D<T,MAXSIZE1,MAXSIZE2,MAXSIZE3>&);
  Array3D<T,MAXSIZE1,MAXSIZE2,MAXSIZE3>& operator = (const Array3D<T,MAXSIZE1,MAXSIZE2,MAXSIZE3>&);
};





// two dimensional array with variable size rows, no dynamic memory
template <class T, size_t MAXSIZE1, size_t MAXSIZE2>
class Array2D_VarSizeRow {
public:
  // constructor
  Array2D_VarSizeRow(std::initializer_list<std::initializer_list<T>> list): n1(list.size()) {
    assert(n1<=MAXSIZE1);
    //    debug << "n1=" << n1 << endl;

    unsigned i=0;
    for (std::initializer_list<T> row : list) {
      unsigned n=row.size();
      assert(n<=MAXSIZE2);
      n2[i]=n;
      //    debug << "n=" << n << endl;
      unsigned j=0;
      for (T elem : row) {
	a[i*MAXSIZE2+j++]=elem;
	//      debug << "elem=" << elem << endl;
      }
      assert(j==n);
      i++;
    }
    assert(i==n1);
  };
 Array2D_VarSizeRow(unsigned nv1, unsigned nv2): n1(nv1), n2{nv2}, a() {
    assert((nv1>=1 && nv1<=MAXSIZE1) &&
	   (nv2>=1 && nv2<=MAXSIZE2));
  };
 Array2D_VarSizeRow(): n1(0), n2() {
  };

  // set array with list of values {value,value,...}
  void operator () (std::initializer_list<std::initializer_list<T>> list) {
    n1=list.size();
    assert(n1<=MAXSIZE1);
    unsigned i=0;
    for (std::initializer_list<T> row : list) {
      unsigned n=row.size();
      assert(n<=MAXSIZE2);
      n2[i]=n;
      unsigned j=0;
      for (T elem : row)
	a[i*MAXSIZE2+j++]=elem;
      assert(j==n);
      i++;
    }
    assert(i==n1);
  };

  // indexing (parenthesis operator)
  //  two of them (for const correctness)
  const T& operator () (unsigned i, unsigned j) const {
    assert((i>=0 && i<n1) && 
	   (j>=0 && j<n2[i]));
    return a[i*MAXSIZE2+j];
  };
  T& operator () (unsigned i, unsigned j)
  {
    assert((i>=0 && i<n1) && 
	   (j>=0 && j<n2[i]));
    return a[i*MAXSIZE2+j];
  };

  // get dims
  unsigned size1() const { 
    return n1;
  };
  unsigned size2(unsigned i) const { 
    assert(i>=0 && i<n1);
    return n2[i];
  };
  // change dims
  void size1(unsigned nv) { 
    assert(nv>=1 && nv<=MAXSIZE1);
    n1=nv;
  };
  void size2(unsigned i, unsigned nv) { 
    assert(i>=0 && i<n1 &&
	   nv>=0 && nv<=MAXSIZE2);
    n2[i]=nv;
  };
  void size(unsigned nv1, unsigned i, unsigned nv2) { 
    assert((nv1>=1 && nv1<=MAXSIZE1) &&
	   (i>=0 && i<nv1) &&
	   (nv2>=1 && nv2<=MAXSIZE2));
    n1=nv1;
    n2[i]=nv2;
  };

private:
  unsigned n1; // dim1 actual size
  unsigned n2[MAXSIZE1]; // dim2 actual size of each row
  T a[MAXSIZE1*MAXSIZE2];

  // to prevent unwanted copying:
  Array2D_VarSizeRow(const Array2D_VarSizeRow<T,MAXSIZE1,MAXSIZE2>&);
  //Array2D_VarSizeRow<T,MAXSIZE1,MAXSIZE2>& operator = (const Array2D_VarSizeRow<T,MAXSIZE1,MAXSIZE2>&);
};





// three dimensional array, no dynamic memory
template <class T, size_t MAXSIZE1, size_t MAXSIZE2, size_t MAXSIZE3>
class Array3D_VarSizeRow {
public:
  // constructor
 Array3D_VarSizeRow(std::initializer_list<std::initializer_list<std::initializer_list<T>>> list): n1(list.size()) {
    assert(n1<=MAXSIZE1);

    unsigned i=0;
    for (std::initializer_list<std::initializer_list<T>> mat : list) { // i
      unsigned nv2=mat.size();
      assert(nv2<=MAXSIZE2);
      n2[i]=nv2;
      unsigned j=0;
      for (std::initializer_list<T> row : mat) { // j
	unsigned nv3=row.size();
	assert(nv3<=MAXSIZE3);
	n3[i*MAXSIZE2+j]=nv3;
	unsigned k=0;
	for (T elem : row) // k
	  a[i*MAXSIZE2*MAXSIZE3+j*MAXSIZE3+k++]=elem;
	assert(k==nv3);
	j++;
      } // j
      assert(j==nv2);
      i++;
    } // i
    assert(i==n1);
  };
 Array3D_VarSizeRow(unsigned nv1, unsigned nv2, unsigned nv3): n1(nv1), n2(nv2), n3(nv3), a() {
    assert((n1>=1 && n1<=MAXSIZE1) &&
	   (n2>=1 && n2<=MAXSIZE2) &&
	   (n3>=1 && n3<=MAXSIZE3));
  };
 Array3D_VarSizeRow(): n1(0), n2{0}, n3{0} {
  };

  // set array with list of values {value,value,...}
  void operator () (std::initializer_list<std::initializer_list<std::initializer_list<T>>> list) {
    n1=list.size();
    assert(n1<=MAXSIZE1);

    unsigned i=0;
    for (std::initializer_list<std::initializer_list<T>> mat : list) {
      unsigned nv2=mat.size();
      assert(nv2<=MAXSIZE2);
      n2[i]=nv2;
      unsigned j=0;
      for (std::initializer_list<T> row : mat) {
	unsigned nv3=row.size();
	assert(nv3<=MAXSIZE3);
	n3[i*MAXSIZE2+j]=nv3;
	unsigned k=0;
	for (T elem : row) // k 
	  a[i*MAXSIZE2*MAXSIZE3+j*MAXSIZE3+k++]=elem;
	assert(k==nv3);
	j++;
      } // j
      assert(j==nv2);
      i++;
    } // i
    assert(i==n1);
  };

  // indexing (parenthesis operator)
  //  two of them (for const correctness)
  const T& operator () (unsigned i, unsigned j, unsigned k) const {  
    assert((i>=0 && i<n1) && 
	   (j>=0 && j<n2[i]) && 
	   (k>=0 && k<n3[i*MAXSIZE2+j]));
    return a[i*MAXSIZE2*MAXSIZE3+j*MAXSIZE3+k];
  };
  T& operator () (unsigned i, unsigned j, unsigned k)
  {
    assert((i>=0 && i<n1) && 
	   (j>=0 && j<n2[i]) && 
	   (k>=0 && k<n3[i*MAXSIZE2+j]));
    return a[i*MAXSIZE2*MAXSIZE3+j*MAXSIZE3+k];
  };

  // get dims
  unsigned size1() const { 
    return n1;
  };
  unsigned size2(unsigned i) const {
    assert(i>=0 && i<n1);
    return n2[i];
  };
  unsigned size3(unsigned i, unsigned j) const { 
    assert(i>=0 && i<n1 &&
	   j>=0 && j<n2[i]);
    return n3[i*MAXSIZE2+j];
  };
  // change dims
  void size1(unsigned nv) { 
    assert(nv>=1 && nv<=MAXSIZE1);
    n1=nv;
  };
  void size2(unsigned i, unsigned nv) { 
    assert(i>=0 && i<n1 &&
	   nv>=1 && nv<=MAXSIZE2);
    n2[i]=nv;
  };
  void size3(unsigned i, unsigned j, unsigned nv) { 
    assert((i>=0 && i<n1) &&
	   (j>=0 && j<n2[i]) &&
	   (nv>=1 && nv<=MAXSIZE3));
    n3[i*MAXSIZE2+j]=nv;
  };
  void size(unsigned nv1, unsigned i, unsigned nv2, unsigned j, unsigned nv3) { 
    assert((nv1>=1 && nv1<=MAXSIZE1) &&
	   (i>=0 && i<nv1) &&
	   (nv2>=1 && nv2<=MAXSIZE2) &&
	   (j>=0 && j<nv2) &&
	   (nv3>=1 && nv3<=MAXSIZE3));
    n1=nv1;
    n2[i]=nv2;
    n3[i*MAXSIZE2+j]=nv3;
  };

private:
  unsigned n1; // dim1 actual size
  unsigned n2[MAXSIZE1]; // dim2 actual size of each row
  unsigned n3[MAXSIZE1*MAXSIZE2]; // dim3 actual size of each 3-th dimension
  T a[MAXSIZE1*MAXSIZE2*MAXSIZE3];

  // to prevent unwanted copying:
  Array3D_VarSizeRow(const Array3D<T,MAXSIZE1,MAXSIZE2,MAXSIZE3>&);
  //Array3D_VarSizeRow<T,MAXSIZE1,MAXSIZE2,MAXSIZE3>& operator = (const Array3D_VarSizeRow<T,MAXSIZE1,MAXSIZE2,MAXSIZE3>&);
};



#endif // __ARRAYMULTIDIMENSIONAL_H_INCLUDED__ 
