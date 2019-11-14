// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

main() {
  /*Null*/ null;
  /*cfe|dart2js.bool*/ /*cfe:nnbd.bool!*/ true;
  /*cfe|dart2js.bool*/ /*cfe:nnbd.bool!*/ false;
  /*cfe|dart2js.String*/ /*cfe:nnbd.String!*/ 'foo';
  /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 42;
  /*cfe|dart2js.double*/ /*cfe:nnbd.double!*/ 0.5;
  /*cfe|dart2js.Symbol*/ /*cfe:nnbd.Symbol!*/ #main;
}
