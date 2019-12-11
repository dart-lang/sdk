// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

main() {
  // ignore: unused_local_variable
  var a0 =
      /*cfe|dart2js.Map<dynamic,dynamic>*/
      /*cfe:nnbd.Map<dynamic,dynamic>!*/
      {};

  // ignore: unused_local_variable
  var a1 =
      /*cfe|dart2js.Set<int>*/
      /*cfe:nnbd.Set<int!>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0
  };

  // ignore: unused_local_variable
  var a2 =
      /*cfe|dart2js.Set<num>*/
      /*cfe:nnbd.Set<num!>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0,
    /*cfe|dart2js.double*/
    /*cfe:nnbd.double!*/
    0.5
  };

  // ignore: unused_local_variable
  var a3 =
      /*cfe|dart2js.Set<Object>*/
      /*cfe:nnbd.Set<Object!>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0,
    /*cfe|dart2js.String*/
    /*cfe:nnbd.String!*/
    ''
  };
}
