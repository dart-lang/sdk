// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

num numTopLevel = /*int!*/ 0;
int intTopLevel = /*int!*/ 0;
double doubleTopLevel = /*double!*/ 0.0;
dynamic dynamicTopLevel = /*int!*/ 0;

main() {
  /*num!*/ numTopLevel
      /*invoke: num!*/ +
      /*num!*/ numTopLevel;

  /*num!*/ numTopLevel
      /*invoke: num!*/ +
      /*int!*/ intTopLevel;

  /*num!*/ numTopLevel
      /*invoke: double!*/ +
      /*double!*/ doubleTopLevel;

  /*num!*/ numTopLevel
      /*invoke: num!*/ +
      /*as: num!*/ /*dynamic*/ dynamicTopLevel;

  /*int!*/ intTopLevel
      /*invoke: num!*/ +
      /*num!*/ numTopLevel;

  /*int!*/ intTopLevel
      /*invoke: int!*/ +
      /*int!*/ intTopLevel;

  /*int!*/ intTopLevel
      /*invoke: double!*/ +
      /*double!*/ doubleTopLevel;

  /*int!*/ intTopLevel
      /*invoke: num!*/ +
      /*as: num!*/ /*dynamic*/ dynamicTopLevel;

  /*double!*/ doubleTopLevel
      /*invoke: double!*/ +
      /*num!*/ numTopLevel;

  /*double!*/ doubleTopLevel
      /*invoke: double!*/ +
      /*int!*/ intTopLevel;

  /*double!*/ doubleTopLevel
      /*invoke: double!*/ +
      /*double!*/ doubleTopLevel;

  /*double!*/ doubleTopLevel
      /*invoke: double!*/ +
      /*as: num!*/ /*dynamic*/ dynamicTopLevel;

  /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ +
      /*num!*/ numTopLevel;

  /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ +
      /*int!*/ intTopLevel;

  /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ +
      /*double!*/ doubleTopLevel;

  /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ +
      /*dynamic*/ dynamicTopLevel;
}
