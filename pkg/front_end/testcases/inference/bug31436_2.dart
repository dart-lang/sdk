// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void block_test(List<Object> Function() g) {
  g = /*@returnType=List<Object>*/ () {
    return /*@typeArgs=Object*/ [3];
  };
  assert(g is List<Object> Function());
  assert(g is! List<int> Function());
  g(). /*@target=List.add*/ add("hello"); // No runtime error
  List<int> l = /*@typeArgs=int*/ [3];
  g = /*@returnType=List<int>*/ () {
    return l;
  };
  assert(/*@promotedType=() -> List<int>*/ g is List<Object> Function());
  assert(/*@promotedType=() -> List<int>*/ g is List<int> Function());
  try {
    /*@promotedType=() -> List<int>*/ g()
        . /*@target=List.add*/ add("hello"); // runtime error
    throw 'expected a runtime error';
  } on TypeError {}
  Object o = l;
  g = /*@returnType=List<int>*/ () {
    return o;
  }; // No implicit downcast on the assignment, implicit downcast on the return
  assert(/*@promotedType=() -> List<int>*/ g is List<Object> Function());
  assert(/*@promotedType=() -> List<int>*/ g is! List<int> Function());
  assert(/*@promotedType=() -> List<int>*/ g is! Object Function());
  /*@promotedType=() -> List<int>*/ g(); // No runtime error;
  o = 3;
  try {
    /*@promotedType=() -> List<int>*/ g(); // Failed runtime cast on the return type of f
    throw 'expected a runtime error';
  } on TypeError {}
}

void arrow_test(List<Object> Function() g) {
  g = /*@returnType=List<Object>*/ () => /*@typeArgs=Object*/ [3];
  assert(g is List<Object> Function());
  assert(g is! List<int> Function());
  g(). /*@target=List.add*/ add("hello"); // No runtime error
  List<int> l = /*@typeArgs=int*/ [3];
  g = /*@returnType=List<int>*/ () => l;
  assert(/*@promotedType=() -> List<int>*/ g is List<Object> Function());
  assert(/*@promotedType=() -> List<int>*/ g is List<int> Function());
  try {
    /*@promotedType=() -> List<int>*/ g()
        . /*@target=List.add*/ add("hello"); // runtime error
    throw 'expected a runtime error';
  } on TypeError {}
  Object o = l;
  g = /*@returnType=List<int>*/ () =>
      o; // No implicit downcast on the assignment, implicit downcast on the return
  assert(/*@promotedType=() -> List<int>*/ g is List<Object> Function());
  assert(/*@promotedType=() -> List<int>*/ g is! List<int> Function());
  assert(/*@promotedType=() -> List<int>*/ g is! Object Function());
  /*@promotedType=() -> List<int>*/ g(); // No runtime error;
  o = 3;
  try {
    /*@promotedType=() -> List<int>*/ g(); // Failed runtime cast on the return type of f
    throw 'expected a runtime error';
  } on TypeError {}
}
