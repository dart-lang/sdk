// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: avoid_positional_boolean_parameters

f(bool b) {
  return ['a', b ? 'c' : 'd', 'e']; // LINT
}

g(bool b) {
  return ['a', (b ? 'c' : 'd'), 'e']; // LINT
}

h(bool b) {
  return {'a' : 1, b ? 'c' : 'd' : 2, 'e' : 3}; // OK
}

i(bool b) {
  return {'a', b ? 'c' : 'd', 'e'}; // LINT
}

j(bool b) {
  return {'a', b ? 'c' : 'd', 'e'}; // LINT
}

k(bool b) {
  return {'a', ((b ? 'c' : 'd')), 'e'}; // LINT
}

l(Iterable<int> i) {
  return Map.fromIterable(i, key: (e) { // OK
    var result = e * 2;
    return result;
  }, value: (e) => e + 3);
}

m(Iterable<int> i) {
  return Map.fromIterable(i, key: (e) => e * 2, value: (e) { // OK
    var result = e  + 3;
    return result;
  });
}

n(Iterable<int> i) {
  var k = 3;
  return Map.fromIterable(i, key: (k) => k * 2, value: (v) => k); // OK
}

o(Iterable<int> i) {
  return Map.fromIterable(i, key: (e) => e * 2, value: (e) => e + 3); // OK
}
