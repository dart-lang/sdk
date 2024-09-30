// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(String a, num x) {
  <String, dynamic>{?a: (x as int)};
  x..expectStaticType<Exactly<int>>();
}

test2(String? a, num x) {
  <String, dynamic>{?a: (x as int)};
  x..expectStaticType<Exactly<num>>();
}

test3(String a, bool b, num x) {
  if (b) {
    x as int;
  } else {
    <String, dynamic>{?a: (throw 0)};
    // Unreachable.
  }
  x..expectStaticType<Exactly<int>>();
}

test4(String? a, bool b, num x) {
  if (b) {
    x as int;
  } else {
    <String, dynamic>{?a: (throw 0)};
    // Reachable.
  }
  x..expectStaticType<Exactly<num>>();
}

test5(String? a) {
  return {?a: a..expectStaticType<Exactly<String>>()};
}

test6(String? a) {
  return {a: a..expectStaticType<Exactly<String?>>()};
}

extension E<X> on X {
  void expectStaticType<Y extends Exactly<X>>() {}
}

typedef Exactly<X> = X Function(X);

void expectThrows(void Function() f) {
  bool hasThrown;
  try {
    f();
    hasThrown = false;
  } catch (e) {
    hasThrown = true;
  }

  if (!hasThrown) {
    throw "Expected the function to throw an exception.";
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
}
