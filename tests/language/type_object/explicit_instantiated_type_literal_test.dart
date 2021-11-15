// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "../static_type_helper.dart";

import "explicit_instantiated_type_literal_test.dart" as prefix;

// Tests that explicitly instantiated type objects work and are canonicalized
// correctly.

class C<T extends num> {}

Type type<T>() => T;

void main() {
  (C).expectStaticType<Exactly<Type>>();
  (C<int>).expectStaticType<Exactly<Type>>();

  Expect.identical(C<num>, C);
  Expect.identical(C<int>, C<int>);

  Expect.equals(C<int>, type<C<int>>());

  // Super-bounded types are valid.
  Expect.identical(C<dynamic>, C<dynamic>);
  Expect.equals(C<dynamic>, type<C<dynamic>>());

  (prefix.C).expectStaticType<Exactly<Type>>();
  (prefix.C<int>).expectStaticType<Exactly<Type>>();

  Expect.identical(prefix.C<num>, prefix.C);
  Expect.identical(prefix.C<int>, prefix.C<int>);

  Expect.equals(prefix.C<int>, type<prefix.C<int>>());

  // Super-bounded types are valid.
  Expect.identical(prefix.C<dynamic>, prefix.C<dynamic>);
  Expect.equals(prefix.C<dynamic>, type<prefix.C<dynamic>>());

  Expect.identical(C<int>, prefix.C<int>);

  (<T extends num>() {
    Expect.equals(C<T>, C<T>);
    Expect.equals(prefix.C<T>, prefix.C<T>);
  }<int>());
}
