// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "implicit_new_or_const_generic_test.dart" as prefix;

// Test that const constructors with const arguments do not become const
// if not in a const context.

// This test uses a generic class cosntructor with no prefix,
// which requires new Dart 2 syntax.

main() {
  // Various valid object creation expressions.
  var x = 42; // non constant variable.

  // Various valid object creation expressions of a generic constructor.
  // (Requires inference to infer `<int>` for the invocations of `D`.)
  var instances = <Object>[
    new D(x),
    new D(42),
    const D(42),
    D(x),
    D(42),
    new D.named(x),
    new D.named(42),
    const D.named(42),
    D.named(x),
    D.named(42),
    new prefix.D(x),
    new prefix.D(42),
    const prefix.D(42),
    prefix.D(x),
    prefix.D(42),
    new prefix.D.named(x),
    new prefix.D.named(42),
    const prefix.D.named(42),
    prefix.D.named(x),
    prefix.D.named(42),
    new D<int>(x),
    new D<int>(42),
    const D<int>(42),
    D<int>(x),
    D<int>(42),
    new D<int>.named(x),
    new D<int>.named(42),
    const D<int>.named(42),
    D<int>.named(x),
    D<int>.named(42),
    new prefix.D<int>(x),
    new prefix.D<int>(42),
    const prefix.D<int>(42),
    prefix.D<int>(x),
    prefix.D<int>(42),
    new prefix.D<int>.named(x),
    new prefix.D<int>.named(42),
    const prefix.D<int>.named(42),
    prefix.D<int>.named(x),
    prefix.D<int>.named(42),
  ];

  const d42 = const D<int>(42);
  for (var i = 0; i < instances.length; i++) {
    var d = instances[i];
    Expect.equals(d42, d);
    if (i % 5 == 2) {
      // The cases of D(42) without "new" are all constant.
      Expect.identical(d42, d, "$i");
    } else {
      // The rest are not.
      Expect.notIdentical(d42, d, "$i");
    }
  }

  // Test instance creation with type parameters.
  new G<int>().testWithInt();
}

class D<T> {
  final T x;

  const D(this.x);
  const D.named(this.x);

  int get hashCode => x.hashCode;
  bool operator ==(Object other) => other is D<Object> && x == other.x;
}

class G<T> {
  // Tests creation of D<T> where T is a type variable.
  void testWithInt() {
    // Cannot create constants referencing T or x.
    var instances = [
      new D<T>(null),
      D<T>(null),
      new D<T>.named(null),
      D<T>.named(null),
      new prefix.D<T>(null),
      prefix.D<T>(null),
      new prefix.D<T>.named(null),
      prefix.D<T>.named(null),
    ];

    const dx = const D<int>(null);
    Expect.allDistinct([dx]..addAll(instances));
    for (var i = 0; i < instances.length; i++) {
      var d = instances[i];
      Expect.isTrue(d is D<T>);
      Expect.isTrue(d is! D<Null>);
      Expect.equals(dx, d, "$i");
    }
  }
}
