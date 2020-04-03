// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

main() {
  /*Null*/ null;
  /*cfe.bool*/ /*cfe:nnbd.bool!*/ true;
  /*cfe.bool*/ /*cfe:nnbd.bool!*/ false;
  /*cfe.String*/ /*cfe:nnbd.String!*/ 'foo';
  /*cfe.int*/ /*cfe:nnbd.int!*/ 42;
  /*cfe.double*/ /*cfe:nnbd.double!*/ 0.5;
  /*cfe.Symbol*/ /*cfe:nnbd.Symbol!*/ #main;
}
