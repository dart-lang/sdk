// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that a null-aware extension method invocation is properly
// treated as unreachable when the target has type `Null`.

import '../static_type_helper.dart';

class C {
  void method(Object? o) {}
  C operator +(Object? other) => this;
}

extension E on Null {
  C extensionMethod(Object? o) => C();
  C get extensionProperty => C();
  set extensionProperty(Object? value) {}
  C? get nullableExtensionProperty => C();
  set nullableExtensionProperty(Object? value) {}
  C operator [](Object? index) => C();
  operator []=(Object? index, Object? value) {}
}

extension E2 on C {
  C? operator [](Object? index) => C();
  operator []=(Object? index, Object? value) {}
}

testLiteralNull() {
  int? i = 0; // Promotes to non-null.
  i.expectStaticType<Exactly<int>>();
  E(null)?.extensionMethod(i = null);
  i.expectStaticType<Exactly<int>>();
  E(null)?.extensionProperty.method(i = null);
  i.expectStaticType<Exactly<int>>();
  E(null)?.extensionProperty = i = null;
  i.expectStaticType<Exactly<int>>();
  E(null)?.extensionProperty += i = null;
  i.expectStaticType<Exactly<int>>();
  E(null)?.nullableExtensionProperty ??= i = null;
  i.expectStaticType<Exactly<int>>();
  E(null)?[i = null].method(i = null);
  i.expectStaticType<Exactly<int>>();
  E(null)?[i = null] = i = null;
  i.expectStaticType<Exactly<int>>();
  E(null)?[i = null] += i = null;
  i.expectStaticType<Exactly<int>>();
  E2(null)?[i = null] ??= i = null;
  i.expectStaticType<Exactly<int>>();
}

testNullVariable(Null n) {
  int? i = 0; // Promotes to non-null.
  i.expectStaticType<Exactly<int>>();
  E(n)?.extensionMethod(i = null);
  i.expectStaticType<Exactly<int>>();
  E(n)?.extensionProperty.method(i = null);
  i.expectStaticType<Exactly<int>>();
  E(n)?.extensionProperty = i = null;
  i.expectStaticType<Exactly<int>>();
  E(n)?.extensionProperty += i = null;
  i.expectStaticType<Exactly<int>>();
  E(n)?.nullableExtensionProperty ??= i = null;
  i.expectStaticType<Exactly<int>>();
  E(n)?[i = null].method(i = null);
  i.expectStaticType<Exactly<int>>();
  E(n)?[i = null] = i = null;
  i.expectStaticType<Exactly<int>>();
  E(n)?[i = null] += i = null;
  i.expectStaticType<Exactly<int>>();
  E2(n)?[i = null] ??= i = null;
  i.expectStaticType<Exactly<int>>();
}

main() {
  testLiteralNull();
  testNullVariable(null);
}
