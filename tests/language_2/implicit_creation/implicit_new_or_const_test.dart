// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "implicit_new_or_const_test.dart" as prefix;

// Test that const constructors with const arguments do not become const
// if not in a const context.

main() {
  // Various valid object creation expressions.
  var x = 42; // non constant variable.

  var instances = <Object>[
    new C(x),
    new C(42),
    const C(42),
    C(x),
    C(42),
    new C.named(x),
    new C.named(42),
    const C.named(42),
    C.named(x),
    C.named(42),
    new prefix.C(x),
    new prefix.C(42),
    const prefix.C(42),
    prefix.C(x),
    prefix.C(42),
    new prefix.C.named(x),
    new prefix.C.named(42),
    const prefix.C.named(42),
    prefix.C.named(x),
    prefix.C.named(42),
  ];

  // Test that the correct ones are constant, and the rest are not.
  const c42 = const C(42); // Reference constant.

  for (var i = 0; i < instances.length; i++) {
    var c = instances[i];
    Expect.equals(c42, c);
    if (i % 5 == 2) {
      Expect.identical(c42, c, "$i");
    } else {
      Expect.notIdentical(c42, c, "$i");
    }
  }
}

class C {
  final Object x;

  const C(this.x);
  const C.named(this.x);

  int get hashCode => x.hashCode;
  bool operator ==(Object other) => other is C && x == other.x;
}
