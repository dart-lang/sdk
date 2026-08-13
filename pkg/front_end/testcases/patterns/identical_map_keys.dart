// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from co19/LanguageFeatures/Patterns/map_A04_t01

class C {
  const C();
}

const c1 = C();
const c2 = C();

String test1(Map map) {
  return switch (map) {
    {const C(): 1, const C(): 2} => "",
    {1: 1, 1: 2} => "",
    {c1: var a1, c2: final b1} => "",
    {3.14: var a2, 3.14: final b2} => "",
    {"x": var a3, "x": final b3} => "",
    _ => "default"
  };
}

void test2(Map map) {
  switch (map) {
    case {const C(): 1, const C(): 2}:
      break;
    case {1: 1, 1: 2}:
      break;
    case {c1: var a1, c2: final b1}:
    case {3.14: var a2, 3.14: final b2}:
      break;
    case {"x": var a3, "x": final b3}:
      break;
  }
}

void test3(Map map) {
  if (map case {const C(): 1, const C(): 2}) {
  }
  if (map case {1: 1, 1: 2}) {
  }
  if (map case {c1: var a1, c2: final b1}) {
  }
  if (map case {3.14: var a2, 3.14: final b2}) {
  }
  if (map case {"x": var a3, "x": final b3}) {
  }
}

test() {
  var {const C(): a, const C(): b} = {const C(): 1};
  var {1: c, 1: d} = {1: 2};
  final {c1: var a1, c2: final b1} = {c2: 2};
  final {3.14: var a2, 3.14: final b2} = {3.14: 1};
  final {"x": var a3, "x": final b3} = {"x": 1};
}