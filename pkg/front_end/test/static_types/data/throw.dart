// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

throwing() {
  /*cfe.<bottom>*/
  /*cfe:nnbd.Never*/
  throw
      /*cfe.String*/
      /*cfe:nnbd.String!*/
      'foo';
}

rethrowing() {
  try {} catch (_) {
    /*cfe.<bottom>*/
    /*cfe:nnbd.Never*/
    rethrow;
  }
}
