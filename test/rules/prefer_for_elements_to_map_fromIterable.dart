// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_expression_function_bodies

f(Iterable<int> i) {
  var k = 3;
  return Map.fromIterable(i, key: (k) => k * 2, value: (v) => k); // LINT
}

g(Iterable<int> i) {
  return Map.fromIterable(i, key: (k) => k * 2, value: (v) => 0); // LINT
}

h(Iterable<int> i) {
  var e = 2;
  return Map.fromIterable(i, key: (k) => k * e, value: (v) => v + e); // LINT
}

i(Iterable<int> i) {
  // Missing key
  return Map.fromIterable(i, value: (e) => e + 3); // OK
}

j(Iterable<int> i) {
  //Not map fromIterable
  return A.fromIterable(i, key: (e) => e * 2, value: (e) => e + 3); // OK
}

class A {
  A.fromIterable(i, {key, value});
}
