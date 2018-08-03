// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

T f<T>() => null;

class B {
  void operator []=(int x, String y) {}
}

class C extends B {
  void operator []=(Object x, Object y) {}
  void h() {
    // Note: the index is inferred with an empty context due to issue 31336.
    super /*@target=B::[]=*/ [
        /*@typeArgs=dynamic*/ f()] = /*@typeArgs=String*/ f();
  }
}

main() {}
