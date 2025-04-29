// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that a null-aware extension method invocation properly
// promotes its target to non-nullable.

import '../static_type_helper.dart';

class B {
  final C? _c;
  B(this._c);
}

class C {
  void method(Object? o) {}
  C operator +(Object? other) => this;
}

extension E on C {
  C extensionMethod(Object? o) => this;
  C get extensionProperty => this;
  set extensionProperty(Object? value) {}
  C? get nullableExtensionProperty => this;
  set nullableExtensionProperty(Object? value) {}
  C operator [](Object? index) => this;
  operator []=(Object? index, Object? value) {}
}

extension E2 on C {
  C? operator [](Object? index) => this;
  operator []=(Object? index, Object? value) {}
}

testVariable(C? c) {
  E(c)?.extensionMethod(c..expectStaticType<Exactly<C>>());
  E(c)?.extensionProperty.method(c..expectStaticType<Exactly<C>>());
  E(c)?.extensionProperty = c..expectStaticType<Exactly<C>>();
  E(c)?.extensionProperty += c..expectStaticType<Exactly<C>>();
  E(c)?.nullableExtensionProperty ??= c..expectStaticType<Exactly<C>>();
  E(c)?[c..expectStaticType<Exactly<C>>()].method(
    c..expectStaticType<Exactly<C>>(),
  );
  E(c)?[c..expectStaticType<Exactly<C>>()] = c..expectStaticType<Exactly<C>>();
  E(c)?[c..expectStaticType<Exactly<C>>()] += c..expectStaticType<Exactly<C>>();
  E2(c)?[c..expectStaticType<Exactly<C>>()] ??= c
    ..expectStaticType<Exactly<C>>();
}

testProperty(B b) {
  E(b._c)?.extensionMethod(b._c..expectStaticType<Exactly<C>>());
  E(b._c)?.extensionProperty.method(b._c..expectStaticType<Exactly<C>>());
  E(b._c)?.extensionProperty = b._c..expectStaticType<Exactly<C>>();
  E(b._c)?.extensionProperty += b._c..expectStaticType<Exactly<C>>();
  E(b._c)?.nullableExtensionProperty ??= b._c..expectStaticType<Exactly<C>>();
  E(b._c)?[b._c..expectStaticType<Exactly<C>>()].method(
    b._c..expectStaticType<Exactly<C>>(),
  );
  E(b._c)?[b._c..expectStaticType<Exactly<C>>()] = b._c
    ..expectStaticType<Exactly<C>>();
  E(b._c)?[b._c..expectStaticType<Exactly<C>>()] += b._c
    ..expectStaticType<Exactly<C>>();
  E2(b._c)?[b._c..expectStaticType<Exactly<C>>()] ??= b._c
    ..expectStaticType<Exactly<C>>();
}

main() {
  for (var value in [null, C()]) {
    testVariable(value);
    testProperty(B(value));
  }
}
