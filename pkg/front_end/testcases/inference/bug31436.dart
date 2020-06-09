// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void block_test() {
  List<Object> Function() g;
  g = /*@ returnType=List<Object*>* */ () {
    return /*@ typeArgs=Object* */ [3];
  };
  assert(g is List<Object> Function());
  assert(g is! List<int> Function());
  g(). /*@target=List.add*/ add("hello"); // No runtime error
  List<int> l = /*@ typeArgs=int* */ [3];
  g = /*@ returnType=List<int*>* */ () {
    return l;
  };
  assert(g is List<Object> Function());
  assert(g is List<int> Function());
  try {
    g(). /*@target=List.add*/ add("hello"); // runtime error
    throw 'expected a runtime error';
  } on TypeError {}
  Object o = l;
  g = /*@ returnType=List<Object*>* */ () {
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

void arrow_test() {
  List<Object> Function() g;
  g = /*@ returnType=List<Object*>* */ () => /*@ typeArgs=Object* */ [3];
  assert(g is List<Object> Function());
  assert(g is! List<int> Function());
  g(). /*@target=List.add*/ add("hello"); // No runtime error
  List<int> l = /*@ typeArgs=int* */ [3];
  g = /*@ returnType=List<int*>* */ () => l;
  assert(g is List<Object> Function());
  assert(g is List<int> Function());
  try {
    g(). /*@target=List.add*/ add("hello"); // runtime error
    throw 'expected a runtime error';
  } on TypeError {}
  Object o = l;
  g = /*@ returnType=List<Object*>* */ () =>
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

main() {
  block_test();
  arrow_test();
}
