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

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf(
        /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertBOf(
        /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertCOf(
        /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertDOf(
        /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertEOf(
        /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
  }
}

abstract class G<T> {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf(
        /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
    this.assertAOf(
        /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
    this.assertDOf(
        /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertEOf(
        /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
  }
}

AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => null;

main() {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  assertAOf(
      /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
  assertBOf(
      /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
  assertCOf(
      /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
  C.assertBOf(
      /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
  C.assertCOf(
      /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);

  C c;
  c.assertAOf(
      /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
  c.assertDOf(
      /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);

  G<int> g;
  g.assertAOf(
      /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
  g.assertDOf(
      /*@typeArgs=<DartType>(DartType) -> void*/ [_isInt, _isString]);
}
