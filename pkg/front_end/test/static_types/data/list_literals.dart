// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

main() {
  /*cfe|dart2js.List<dynamic>*/
  /*cfe:nnbd.List<dynamic>!*/
  [];

  /*cfe|dart2js.List<int>*/
  /*cfe:nnbd.List<int!>!*/
  [/*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0];

  /*cfe|dart2js.List<num>*/
  /*cfe:nnbd.List<num!>!*/
  [
    /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0,
    /*cfe|dart2js.double*/ /*cfe:nnbd.double!*/ 0.5
  ];

  /*cfe|dart2js.List<Object>*/
  /*cfe:nnbd.List<Object!>!*/
  [
    /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0,
    /*cfe|dart2js.String*/ /*cfe:nnbd.String!*/ ''
  ];
}
