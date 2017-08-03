// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_foreach`

void f(Object o) {}

void foo() {
  final myList = [];
  for (final a in myList) { // LINT
    f(a);
  }
}

void foo2() {
  for (final a in []) { //LINT
    (f(a));
  }
}

Function func() => null;

void foo3() {
  for (final a in <int>[1]) { //LINT
    func()(a);
  }
}

class WithMethods {
  void f(Object o) {}

  void foo() {
    final myList = [];
    for (final a in myList) { // LINT
      f(a);
    }
  }
}

class WithThirdPartyMethods {
  WithMethods x;

  void foo() {
    final myList = [];
    for (final a in myList) { // LINT
      x.f(a);
    }
  }
}

class WithElementInTarget {
  List<WithMethods> myList;

  void good() {
    for (final x in myList) { // OK because x is the target
      x.f(x);
    }
  }

  void good2() {
    for (final x in myList) { // OK because x is in the target
      myList[myList.indexOf(x)].f(x);
    }
  }
}

class WithStaticMethods {
  static void f(Object o) {}

  void foo() {
    final myList = [];
    for (final a in myList) { // LINT
      WithStaticMethods.f(a);
    }
  }
}
