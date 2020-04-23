// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

main() {
  // ignore: unused_local_variable
  var a0 =
      /*cfe.Map<dynamic,dynamic>*/
      /*cfe:nnbd.Map<dynamic,dynamic>!*/
      {};

  // ignore: unused_local_variable
  var a1 =
      /*cfe.Map<int,double>*/
      /*cfe:nnbd.Map<int!,double!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe.double*/
        /*cfe:nnbd.double!*/
        0.5
  };

  // ignore: unused_local_variable
  var a2 =
      /*cfe.Map<double,int>*/
      /*cfe:nnbd.Map<double!,int!>!*/
      {
    /*cfe.double*/
    /*cfe:nnbd.double!*/
    0.5:
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        0
  };

  // ignore: unused_local_variable
  var a3 =
      /*cfe.Map<int,num>*/
      /*cfe:nnbd.Map<int!,num!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    1:
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        2
  };

  // ignore: unused_local_variable
  var a4 =
      /*cfe.Map<num,double>*/
      /*cfe:nnbd.Map<num!,double!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe.double*/
    /*cfe:nnbd.double!*/
    0.5:
        /*cfe.double*/
        /*cfe:nnbd.double!*/
        0.5
  };

  // ignore: unused_local_variable
  var a5 =
      /*cfe.Map<num,num>*/
      /*cfe:nnbd.Map<num!,num!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe.double*/
    /*cfe:nnbd.double!*/
    0.5:
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        0
  };

  // ignore: unused_local_variable
  var a6 =
      /*cfe.Map<int,Object>*/
      /*cfe:nnbd.Map<int!,Object!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    1:
        /*cfe.String*/
        /*cfe:nnbd.String!*/
        ''
  };

  // ignore: unused_local_variable
  var a7 =
      /*cfe.Map<Object,double>*/
      /*cfe:nnbd.Map<Object!,double!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe.String*/
    /*cfe:nnbd.String!*/
    '':
        /*cfe.double*/
        /*cfe:nnbd.double!*/
        0.5
  };

  // ignore: unused_local_variable
  var a8 =
      /*cfe.Map<Object,Object>*/
      /*cfe:nnbd.Map<Object!,Object!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe.String*/
    /*cfe:nnbd.String!*/
    '':
        /*cfe.String*/
        /*cfe:nnbd.String!*/
        ''
  };
}
