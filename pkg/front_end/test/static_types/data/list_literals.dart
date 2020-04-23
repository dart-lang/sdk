// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

main() {
  /*cfe.List<dynamic>*/
  /*cfe:nnbd.List<dynamic>!*/
  [];

  /*cfe.List<int>*/
  /*cfe:nnbd.List<int!>!*/
  [/*cfe.int*/ /*cfe:nnbd.int!*/ 0];

  /*cfe.List<num>*/
  /*cfe:nnbd.List<num!>!*/
  [
    /*cfe.int*/ /*cfe:nnbd.int!*/ 0,
    /*cfe.double*/ /*cfe:nnbd.double!*/ 0.5
  ];

  /*cfe.List<Object>*/
  /*cfe:nnbd.List<Object!>!*/
  [
    /*cfe.int*/ /*cfe:nnbd.int!*/ 0,
    /*cfe.String*/ /*cfe:nnbd.String!*/ ''
  ];
}
