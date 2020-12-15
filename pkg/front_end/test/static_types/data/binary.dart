// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/

/*cfe:nnbd.library: nnbd=true*/

num numTopLevel = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
int intTopLevel = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
double doubleTopLevel = /*cfe.double*/ /*cfe:nnbd.double!*/ 0.0;
dynamic dynamicTopLevel = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;

main() {
  /*cfe.num*/ /*cfe:nnbd.num!*/ numTopLevel
      /*cfe.invoke: num*/ /*cfe:nnbd.invoke: num!*/ +
      /*cfe.num*/ /*cfe:nnbd.num!*/ numTopLevel;

  /*cfe.num*/ /*cfe:nnbd.num!*/ numTopLevel
      /*cfe.invoke: num*/ /*cfe:nnbd.invoke: num!*/ +
      /*cfe.int*/ /*cfe:nnbd.int!*/ intTopLevel;

  /*cfe.num*/ /*cfe:nnbd.num!*/ numTopLevel
      /*cfe.invoke: num*/ /*cfe:nnbd.invoke: double!*/ +
      /*cfe.double*/ /*cfe:nnbd.double!*/ doubleTopLevel;

  /*cfe.num*/ /*cfe:nnbd.num!*/ numTopLevel
      /*cfe.invoke: num*/ /*cfe:nnbd.invoke: num!*/ +
      /*cfe.as: num*/ /*cfe:nnbd.as: num!*/ /*dynamic*/ dynamicTopLevel;

  /*cfe.int*/ /*cfe:nnbd.int!*/ intTopLevel
      /*cfe.invoke: num*/ /*cfe:nnbd.invoke: num!*/ +
      /*cfe.num*/ /*cfe:nnbd.num!*/ numTopLevel;

  /*cfe.int*/ /*cfe:nnbd.int!*/ intTopLevel
      /*cfe.invoke: int*/ /*cfe:nnbd.invoke: int!*/ +
      /*cfe.int*/ /*cfe:nnbd.int!*/ intTopLevel;

  /*cfe.int*/ /*cfe:nnbd.int!*/ intTopLevel
      /*cfe.invoke: double*/ /*cfe:nnbd.invoke: double!*/ +
      /*cfe.double*/ /*cfe:nnbd.double!*/ doubleTopLevel;

  /*cfe.int*/ /*cfe:nnbd.int!*/ intTopLevel
      /*cfe.invoke: num*/ /*cfe:nnbd.invoke: num!*/ +
      /*cfe.as: num*/ /*cfe:nnbd.as: num!*/ /*dynamic*/ dynamicTopLevel;

  /*cfe.double*/ /*cfe:nnbd.double!*/ doubleTopLevel
      /*cfe.invoke: double*/ /*cfe:nnbd.invoke: double!*/ +
      /*cfe.num*/ /*cfe:nnbd.num!*/ numTopLevel;

  /*cfe.double*/ /*cfe:nnbd.double!*/ doubleTopLevel
      /*cfe.invoke: double*/ /*cfe:nnbd.invoke: double!*/ +
      /*cfe.int*/ /*cfe:nnbd.int!*/ intTopLevel;

  /*cfe.double*/ /*cfe:nnbd.double!*/ doubleTopLevel
      /*cfe.invoke: double*/ /*cfe:nnbd.invoke: double!*/ +
      /*cfe.double*/ /*cfe:nnbd.double!*/ doubleTopLevel;

  /*cfe.double*/ /*cfe:nnbd.double!*/ doubleTopLevel
      /*cfe.invoke: double*/ /*cfe:nnbd.invoke: double!*/ +
      /*cfe.as: num*/ /*cfe:nnbd.as: num!*/ /*dynamic*/ dynamicTopLevel;

  /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ +
      /*cfe.num*/ /*cfe:nnbd.num!*/ numTopLevel;

  /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ +
      /*cfe.int*/ /*cfe:nnbd.int!*/ intTopLevel;

  /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ +
      /*cfe.double*/ /*cfe:nnbd.double!*/ doubleTopLevel;

  /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ +
      /*dynamic*/ dynamicTopLevel;
}
