// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class DartType {}

typedef void Asserter<T>(T type);
typedef Asserter<T> AsserterBuilder<S, T>(S arg);

Asserter<DartType> _isInt = throw '';
Asserter<DartType> _isString = throw '';

abstract class C {
  static AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf =
      throw '';
  static AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf =>
      throw '';

  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf = throw '';
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf => throw '';

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    /*@target=C.assertAOf*/ assertAOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    assertBOf(/*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    assertCOf(/*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    /*@target=C.assertDOf*/ assertDOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    assertEOf(/*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  }
}

abstract class G<T> {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf = throw '';
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf => throw '';

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    /*@target=G.assertAOf*/ assertAOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    this. /*@target=G.assertAOf*/ assertAOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    this. /*@target=G.assertDOf*/ assertDOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    assertEOf(/*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  }
}

AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf = throw '';
AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => throw '';

test() {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf = throw '';
  assertAOf(/*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  assertBOf(/*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  assertCOf(/*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  C.assertBOf(/*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  C.assertCOf(/*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);

  C c = throw '';
  c. /*@target=C.assertAOf*/ assertAOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  c. /*@target=C.assertDOf*/ assertDOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);

  G<int> g = throw '';
  g. /*@target=G.assertAOf*/ assertAOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  g. /*@target=G.assertDOf*/ assertDOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
}

main() {}
