// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests basic field promotion functionality when the feature is enabled.

import 'package:expect/static_type_helper.dart';

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
      _privateFinalField.expectStaticType<Exactly<int>>();
    }
  }
}

abstract class D extends C {
  D(super.i);

  testPrivateFinalFieldSuperAccess() {
    if (super._privateFinalField != null) {
      super._privateFinalField.expectStaticType<Exactly<int>>();
    }
  }
}

enum E {
  e1(null),
  e2(0);

  final int? _privateFinalFieldInEnum;
  const E(this._privateFinalFieldInEnum);
}

void testPrivateFinalField(C c) {
  if (c._privateFinalField != null) {
    c._privateFinalField.expectStaticType<Exactly<int>>();
  }
}

void testPublicFinalField(C c) {
  if (c.publicFinalField != null) {
    c.publicFinalField.expectStaticType<Exactly<int?>>();
  }
}

void testPrivateField(C c) {
  if (c._privateField != null) {
    c._privateField.expectStaticType<Exactly<int?>>();
  }
}

void testPublicField(C c) {
  if (c.publicField != null) {
    c.publicField.expectStaticType<Exactly<int?>>();
  }
}

void testPrivateAbstractGetter(C c) {
  if (c._privateAbstractGetter != null) {
    c._privateAbstractGetter.expectStaticType<Exactly<int>>();
  }
}

void testPublicAbstractGetter(C c) {
  if (c.publicAbstractGetter != null) {
    c.publicAbstractGetter.expectStaticType<Exactly<int?>>();
  }
}

void testPrivateConcreteGetter(C c) {
  if (c._privateConcreteGetter != null) {
    c._privateConcreteGetter.expectStaticType<Exactly<int?>>();
  }
}

void testPublicConcreteGetter(C c) {
  if (c.publicConcreteGetter != null) {
    c.publicConcreteGetter.expectStaticType<Exactly<int?>>();
  }
}

void testPrivateFinalFieldInEnum(E e) {
  if (e._privateFinalFieldInEnum != null) {
    e._privateFinalFieldInEnum.expectStaticType<Exactly<int>>();
  }
}

void testPrivateFinalFieldGeneralPropertyAccess(C c) {
  // The analyzer uses a special data structure for `IDENTIFIER.IDENTIFIER`, so
  // we need to test the general case of property accesses as well.
  if ((c)._privateFinalField != null) {
    (c)._privateFinalField.expectStaticType<Exactly<int>>();
  }
}

main() {}
