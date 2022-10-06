// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/

/*cfe:nnbd.library: nnbd=true*/

method<T>(T t) {
  if (/*cfe.T*/ /*cfe:nnbd.T%*/ t is Iterable) {
    /*current: dynamic*/ for (var e
        in /*cfe.T & Iterable<dynamic>*/ /*cfe:nnbd.T% & Iterable<dynamic>!*/ t) {
      /*dynamic*/ e;
    }
  }
}
