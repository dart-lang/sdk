// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests basic field promotion functionality when the feature is enabled.

// SharedOptions=--enable-experiment=inference-update-2

abstract class C {
  final int? _privateFinalField;
  final int? publicFinalField;
  int? _privateField;
  int? publicField;
  int? get _privateAbstractGetter;
  int? get publicAbstractGetter;
  int? get _privateConcreteGetter => 0;
  int? get publicConcreteGetter => 0;

  C(int? i)
      : _privateFinalField = i,
        publicFinalField = i;

  testPrivateFinalFieldThisAccess() {
    if (_privateFinalField != null) {
      var x = _privateFinalField;
      // `x` has type `int` so this is ok
      acceptsInt(x);
    }
  }
}

abstract class D extends C {
  D(super.i);

  testPrivateFinalFieldSuperAccess() {
    if (super._privateFinalField != null) {
      var x = super._privateFinalField;
      // `x` has type `int` so this is ok
      acceptsInt(x);
    }
  }
}

enum E {
  e1(null),
  e2(0);

  final int? _privateFinalFieldInEnum;
  const E(this._privateFinalFieldInEnum);
}

void acceptsInt(int x) {}

void testPrivateFinalField(C c) {
  if (c._privateFinalField != null) {
    var x = c._privateFinalField;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testPublicFinalField(C c) {
  if (c.publicFinalField != null) {
    var x = c.publicFinalField;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testPrivateField(C c) {
  if (c._privateField != null) {
    var x = c._privateField;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testPublicField(C c) {
  if (c.publicField != null) {
    var x = c.publicField;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testPrivateAbstractGetter(C c) {
  if (c._privateAbstractGetter != null) {
    var x = c._privateAbstractGetter;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testPublicAbstractGetter(C c) {
  if (c.publicAbstractGetter != null) {
    var x = c.publicAbstractGetter;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testPrivateConcreteGetter(C c) {
  if (c._privateConcreteGetter != null) {
    var x = c._privateConcreteGetter;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testPublicConcreteGetter(C c) {
  if (c.publicConcreteGetter != null) {
    var x = c.publicConcreteGetter;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testPrivateFinalFieldInEnum(E e) {
  if (e._privateFinalFieldInEnum != null) {
    var x = e._privateFinalFieldInEnum;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testPrivateFinalFieldGeneralPropertyAccess(C c) {
  // The analyzer uses a special data structure for `IDENTIFIER.IDENTIFIER`, so
  // we need to test the general case of property accesses as well.
  if ((c)._privateFinalField != null) {
    var x = (c)._privateFinalField;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

main() {}
