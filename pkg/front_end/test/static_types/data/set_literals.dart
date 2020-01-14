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
      /*cfe.Set<int>*/
      /*cfe:nnbd.Set<int!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0
  };

  // ignore: unused_local_variable
  var a2 =
      /*cfe.Set<num>*/
      /*cfe:nnbd.Set<num!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0,
    /*cfe.double*/
    /*cfe:nnbd.double!*/
    0.5
  };

  // ignore: unused_local_variable
  var a3 =
      /*cfe.Set<Object>*/
      /*cfe:nnbd.Set<Object!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0,
    /*cfe.String*/
    /*cfe:nnbd.String!*/
    ''
  };
}
