// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/
main() {
  // ignore: unused_local_variable
  var a0 =
      /*Map<dynamic,dynamic>!*/
      {};

  // ignore: unused_local_variable
  var a1 =
      /*Map<int!,double!>!*/
      {
    /*int!*/
    0:
        /*double!*/
        0.5
  };

  // ignore: unused_local_variable
  var a2 =
      /*Map<double!,int!>!*/
      {
    /*double!*/
    0.5:
        /*int!*/
        0
  };

  // ignore: unused_local_variable
  var a3 =
      /*Map<int!,num!>!*/
      {
    /*int!*/
    0:
        /*double!*/
        0.5,
    /*int!*/
    1:
        /*int!*/
        2
  };

  // ignore: unused_local_variable
  var a4 =
      /*Map<num!,double!>!*/
      {
    /*int!*/
    0:
        /*double!*/
        0.5,
    /*double!*/
    0.5:
        /*double!*/
        0.5
  };

  // ignore: unused_local_variable
  var a5 =
      /*Map<num!,num!>!*/
      {
    /*int!*/
    0:
        /*double!*/
        0.5,
    /*double!*/
    0.5:
        /*int!*/
        0
  };

  // ignore: unused_local_variable
  var a6 =
      /*Map<int!,Object!>!*/
      {
    /*int!*/
    0:
        /*double!*/
        0.5,
    /*int!*/
    1:
        /*String!*/
        ''
  };

  // ignore: unused_local_variable
  var a7 =
      /*Map<Object!,double!>!*/
      {
    /*int!*/
    0:
        /*double!*/
        0.5,
    /*String!*/
    '':
        /*double!*/
        0.5
  };

  // ignore: unused_local_variable
  var a8 =
      /*Map<Object!,Object!>!*/
      {
    /*int!*/
    0:
        /*double!*/
        0.5,
    /*String!*/
    '':
        /*String!*/
        ''
  };
}
