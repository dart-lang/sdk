// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import "package:expect/expect.dart";

// Test that type variables are available in closures.

class A<T> {
  A();

  A.bar() {
    g() {
      new A<T>();
    }

    g();
  }

  foo() {
    g() {
      return new A<T>();
    }

    return g();
  }
}

class B<K> {
  makeBaz() {
    return (K key) async {
      return null;
    };
  }
}

typedef Future<Null> aBaz(int a);

main() {
  Expect.isTrue(new A<int>().foo() is A<int>);
  Expect.isTrue(new A<int>.bar().foo() is A<int>);
  Expect.isTrue(new B<int>().makeBaz() is aBaz);
}
