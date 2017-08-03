// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  static Aa() => Ab();
  static Ab() => Ac();
  static Ac() => throw "abc";
}

class B {
  static Ba() => Bb();
  static Bb() => Bc();
  static Bc() {
    try {
      A.Aa();
    } catch (e) {
      // This should produce a NoSuchMethodError.
      var trace = e.stackTrace;
    }
  }
}

main() {
  bool hasThrown = false;
  try {
    B.Ba();
  } catch (e, stackTrace) {
    hasThrown = true;
    var trace = stackTrace.toString();
    print(trace);
    Expect.isTrue(trace.contains("Bc"));
    Expect.isTrue(trace.contains("Bb"));
    Expect.isTrue(trace.contains("Ba"));
    Expect.isTrue(trace.contains("main"));
  }
  Expect.isTrue(hasThrown);
}
