// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that the type inference for generic extension method invocations
/// properly accounts for the downward inference context.

import 'package:expect/static_type_helper.dart';

extension E on Object? {
  T f<T>(List<T> t) => t.first;
}

class C {
  T g<T>(List<T> t) => t.first;
}

main() {
  var string = '';
  context<int>(
      string.f(contextType([1])..expectStaticType<Exactly<List<int>>>()));
  context<int>(
      E(string).f(contextType([1])..expectStaticType<Exactly<List<int>>>()));

  var nullableString = '' as String?;
  context<int?>(nullableString
      ?.f(contextType([1])..expectStaticType<Exactly<List<int?>>>()));
  context<int?>(E(nullableString)
      ?.f(contextType([1])..expectStaticType<Exactly<List<int?>>>()));

  // And just to verify that the expectations above are reasonable, repeat the
  // same thing with an ordinary class:
  var c = C();
  context<int>(c.g(contextType([1])..expectStaticType<Exactly<List<int>>>()));
  var nullableC = C() as C?;
  context<int?>(
      nullableC?.g(contextType([1])..expectStaticType<Exactly<List<int?>>>()));
}
