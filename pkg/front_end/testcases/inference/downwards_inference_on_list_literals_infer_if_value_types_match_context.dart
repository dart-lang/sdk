// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class DartType {}

typedef void Asserter<T>(T type);
typedef Asserter<T> AsserterBuilder<S, T>(S arg);

Asserter<DartType> _isInt;
Asserter<DartType> _isString;

abstract class C {
  static AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
  static AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf =>
      null;

  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  /*@topType=dynamic*/ method(
      AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    /*@target=C::assertAOf*/ assertAOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    assertBOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    assertCOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    /*@target=C::assertDOf*/ assertDOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    assertEOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  }
}

abstract class G<T> {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  /*@topType=dynamic*/ method(
      AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    /*@target=G::assertAOf*/ assertAOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    this. /*@target=G::assertAOf*/ assertAOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    this. /*@target=G::assertDOf*/ assertDOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
    assertEOf(
        /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  }
}

AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => null;

test() {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  assertAOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  assertBOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  assertCOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  C.assertBOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  C.assertCOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);

  C c;
  c. /*@target=C::assertAOf*/ assertAOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  c. /*@target=C::assertDOf*/ assertDOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);

  G<int> g;
  g. /*@target=G::assertAOf*/ assertAOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
  g. /*@target=G::assertDOf*/ assertDOf(
      /*@typeArgs=(DartType) -> void*/ [_isInt, _isString]);
}

main() {}
