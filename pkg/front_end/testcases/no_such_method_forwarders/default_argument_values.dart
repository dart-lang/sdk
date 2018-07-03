// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the default argument values of noSuchMethod forwarder
// parameters are passed to noSuchMethod when the corresponding arguments aren't
// specified at the call site.

abstract class A {
  noSuchMethod(Invocation i) {
    if (i.memberName == #foo) {
      return i.namedArguments[#bar];
    } else if (i.memberName == #hest) {
      return i.positionalArguments[0];
    }
    return null;
  }

  // These shouldn't be turned into a noSuchMethod forwarder, because the
  // enclosing class is abstract.
  String foo({String bar = "baz"});
  int hest([int fisk = 42]);
}

class B extends A {
  // [B] should receive the noSuchMethod forwarders for [A.foo] and [A.hest],
  // and the default argument values in them should be passed into the
  // constructor of [Invocation].
}

main() {
  B b = new B();
  dynamic value;
  if ((value = b.foo()) != "baz") {
    throw "Unexpected value: '$value'; expected 'baz'.";
  }
  if ((value = b.hest()) != 42) {
    throw "Unexpected value: '$value'; expected '42'.";
  }
}
