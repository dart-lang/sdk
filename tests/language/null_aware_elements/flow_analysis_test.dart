// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=null-aware-elements

import '../static_type_helper.dart';

test1(String a, num x) {
  <dynamic, dynamic>{?a: (x as int)};
  //                 ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  x..expectStaticType<Exactly<int>>();
}

test2(String? a, num x) {
  <dynamic, dynamic>{?a: (x as int)};
  x..expectStaticType<Exactly<num>>();
}

test3(String a, bool b, num x) {
  if (b) {
    x as int;
  } else {
    <dynamic, dynamic>{?a: (throw 0)};
    //                 ^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

    // Unreachable.
  }
  x..expectStaticType<Exactly<int>>();
}

test4(String? a, bool b, num x) {
  if (b) {
    x as int;
  } else {
    <dynamic, dynamic>{?a: (throw 0)};
    // Reachable.
  }
  x..expectStaticType<Exactly<num>>();
}

test5(String? a) {
  return <dynamic, dynamic>{?a: a..expectStaticType<Exactly<String>>()};
}

test6(String? a) {
  return <dynamic, dynamic>{a: a..expectStaticType<Exactly<String?>>()};
}

expectThrows(void Function() f) {
  bool hasThrown = true;
  try {
    f();
    hasThrown = false;
  } catch (e) {}

  if (!hasThrown) {
    throw "Expected the function to throw.";
  }
}

main() {
  test1("", 0);

  test2("", 0);
  test2(null, 0);

  test3("", true, 0);
  expectThrows(() => test3("", false, 0));

  test4("", true, 0);
  expectThrows(() => test4("", false, 0));
  test4(null, true, 0);
  test4(null, false, 0);

  test5(null);
  test5("");

  test6(null);
  test5("");
}
