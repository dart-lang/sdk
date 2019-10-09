// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

main() {
  // ignore: unused_local_variable
  var a0 = /*Map<dynamic,dynamic>*/ {};

  // ignore: unused_local_variable
  var a1 =
      /*cfe|dart2js.Map<int,double>*/
      /*cfe:nnbd.Map<int!,double!>*/
      {/*int*/ 0: /*double*/ 0.5 };

  // ignore: unused_local_variable
  var a2 =
      /*cfe|dart2js.Map<double,int>*/
      /*cfe:nnbd.Map<double!,int!>*/
      {/*double*/ 0.5: /*int*/ 0 };

  // ignore: unused_local_variable
  var a3 =
      /*cfe|dart2js.Map<int,num>*/
      /*cfe:nnbd.Map<int!,num>*/
      {
    /*int*/ 0: /*double*/ 0.5,
    /*int*/ 1: /*int*/ 2
  };

  // ignore: unused_local_variable
  var a4 =
      /*cfe|dart2js.Map<num,double>*/
      /*cfe:nnbd.Map<num,double!>*/
      {
    /*int*/ 0: /*double*/ 0.5,
    /*double*/ 0.5: /*double*/ 0.5
  };

  // ignore: unused_local_variable
  var a5 = /*Map<num,num>*/ {
    /*int*/ 0: /*double*/ 0.5,
    /*double*/ 0.5: /*int*/ 0
  };

  // ignore: unused_local_variable
  var a6 =
      /*cfe|dart2js.Map<int,Object>*/
      /*cfe:nnbd.Map<int!,Object>*/
      {
    /*int*/ 0: /*double*/ 0.5,
    /*int*/ 1: /*String*/ ''
  };

  // ignore: unused_local_variable
  var a7 =
      /*cfe|dart2js.Map<Object,double>*/
      /*cfe:nnbd.Map<Object,double!>*/
      {
    /*int*/ 0: /*double*/ 0.5,
    /*String*/ '': /*double*/ 0.5
  };

  // ignore: unused_local_variable
  var a8 = /*Map<Object,Object>*/ {
    /*int*/ 0: /*double*/ 0.5,
    /*String*/ '': /*String*/ ''
  };
}
