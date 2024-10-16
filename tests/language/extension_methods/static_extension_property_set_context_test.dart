// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that type inference supplies the proper context for the right hand
/// side of a property set that refers to an extension method.

import 'package:expect/static_type_helper.dart';

extension E on Object? {
  set s1(int i) {}
  set s2(int? i) {}
}

class C {
  set s3(int i) {}
  set s4(int? i) {}
}

main() {
  var string = '';
  context<num>(string.s1 = contextType(1)..expectStaticType<Exactly<int>>());
  context<num>(E(string).s1 = contextType(1)..expectStaticType<Exactly<int>>());
  context<num?>(string.s2 = contextType(1)..expectStaticType<Exactly<int?>>());
  context<num?>(
      E(string).s2 = contextType(1)..expectStaticType<Exactly<int?>>());

  var nullableString = '' as String?;
  context<num?>(
      nullableString?.s1 = contextType(1)..expectStaticType<Exactly<int>>());
  context<num?>(
      E(nullableString)?.s1 = contextType(1)..expectStaticType<Exactly<int>>());
  context<num?>(
      nullableString?.s2 = contextType(1)..expectStaticType<Exactly<int?>>());
  context<num?>(E(nullableString)?.s2 = contextType(1)
    ..expectStaticType<Exactly<int?>>());

  // And just to verify that the expectations above are reasonable, repeat the
  // same thing with an ordinary class:
  var c = C();
  context<num>(c.s3 = contextType(1)..expectStaticType<Exactly<int>>());
  context<num?>(c.s4 = contextType(1)..expectStaticType<Exactly<int?>>());
  var nullableC = C() as C?;
  context<num?>(
      nullableC?.s3 = contextType(1)..expectStaticType<Exactly<int>>());
  context<num?>(
      nullableC?.s4 = contextType(1)..expectStaticType<Exactly<int?>>());
}
