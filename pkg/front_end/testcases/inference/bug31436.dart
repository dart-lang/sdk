// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void block_test(List<Object> Function() g) {
  g = () {
    return [3];
  };
  assert(g is List<Object> Function());
  assert(g is! List<int> Function());
  g().add("hello"); // No runtime error
  List<int> l = [3];
  g = () {
    return l;
  };
  assert(g is List<Object> Function());
  assert(g is List<int> Function());
  try {
    g().add("hello"); // runtime error
    throw 'expected a runtime error';
  } on TypeError {}
  Object o = l;
  g = () {
    return o;
  }; // No implicit downcast on the assignment, implicit downcast on the return
  assert(g is List<Object> Function());
  assert(g is! List<int> Function());
  assert(g is! Object Function());
  g(); // No runtime error;
  o = 3;
  try {
    g(); // Failed runtime cast on the return type of f
    throw 'expected a runtime error';
  } on TypeError {}
}

void arrow_test(List<Object> Function() g) {
  g = () => [3];
  assert(g is List<Object> Function());
  assert(g is! List<int> Function());
  g().add("hello"); // No runtime error
  List<int> l = [3];
  g = () => l;
  assert(g is List<Object> Function());
  assert(g is List<int> Function());
  try {
    g().add("hello"); // runtime error
    throw 'expected a runtime error';
  } on TypeError {}
  Object o = l;
  g = () =>
      o; // No implicit downcast on the assignment, implicit downcast on the return
  assert(g is List<Object> Function());
  assert(g is! List<int> Function());
  assert(g is! Object Function());
  g(); // No runtime error;
  o = 3;
  try {
    g(); // Failed runtime cast on the return type of f
    throw 'expected a runtime error';
  } on TypeError {}
}
