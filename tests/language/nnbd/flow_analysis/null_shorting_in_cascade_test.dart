// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that null shorting that starts in a cascade section ends
// at the end of that cascade section. It specifically checks the behaviors of
// flow analysis, to make sure that the analyzer behavior is correct.

import '../../static_type_helper.dart';

class C<T> {
  final T _t; // Promotable
  T get t => _t; // Not promotable
  set t(Object? value) {}
  C(this._t);
}

class D {
  void f([Object? value]) {}
  D get d => this;
  D operator[](int index) => this;
  operator[]=(int index, Object? value) {}
}

class E {
  void f([Object? value]) {}
  E? operator[](int index) => null;
  operator[]=(int index, Object? value) {}
}

testMethodInvocation(C<D?> c, int? i) {
  // The null shorting for the method invocation `.._t?.f()` ends at the end of
  // the cascade section, therefore in the cascade section that follows, `.._t`
  // has static type `D?`.
  c.._t?.f().._t.expectStaticType<Exactly<D?>>();

  // The null shorting for the method invocation `..t?.f(i!)` ends at the end of
  // the cascade section, therefore in the cascade section that follows, `i` is
  // not promoted.
  c..t?.f(i!)..t?.f(i.expectStaticType<Exactly<int?>>());
}

testPropertyGet(C<D?> c, int? i) {
  // The null shorting for the property get `.._t?.d` ends at the end of the
  // cascade section, therefore in the cascade section that follows, `.._t` has
  // static type `D?`.
  c.._t?.d.f().._t.expectStaticType<Exactly<D?>>();

  // The null shorting for the property get `..t?.d` ends at the end of the
  // cascade section, therefore in the cascade section that follows, `i` is not
  // promoted.
  c..t?.d.f(i!)..t?.f(i.expectStaticType<Exactly<int?>>());
}

testPropertySet(C<D?> c, int? i) {
  // The null shorting for the property set `..t ??= i!` ends at the end of the
  // cascade section, therefore in the cascade section that follows, `i` is not
  // promoted.
  c..t ??= i!..t?.f(i.expectStaticType<Exactly<int?>>());
}

testIndexGet(C<D?> c, int? i) {
  // The null shorting for the index get `.._t?[0]` ends at the end of the
  // cascade section, therefore in the cascade section that follows, `.._t` has
  // static type `D?`.
  c.._t?[0].f().._t.expectStaticType<Exactly<D?>>();

  // The null shorting for the index get `..t?[0]` ends at the end of the
  // cascade section, therefore in the cascade section that follows, `i` is not
  // promoted.
  c..t?[0].f(i!)..t?.f(i.expectStaticType<Exactly<int?>>());
}

testIndexSet(C<E> c, int? i) {
  // The null shorting for the index set `..t?[0] ??= i!` ends at the end of the
  // cascade section, therefore in the cascade section that follows, `i` is not
  // promoted.
  c..t[0] ??= i!..t.f(i.expectStaticType<Exactly<int?>>());
}

main() {
  testMethodInvocation(C<D?>(D()), 0);
  testPropertyGet(C<D?>(D()), 0);
  testPropertySet(C<D?>(D()), 0);
  testIndexGet(C<D?>(D()), 0);
  testIndexSet(C<E>(E()), 0);
}
