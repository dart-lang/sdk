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
        /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertBOf(
        /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertCOf(
        /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertDOf(
        /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertEOf(
        /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
  }
}

abstract class G<T> {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf(
        /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
    this.assertAOf(
        /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
    this.assertDOf(
        /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
    assertEOf(
        /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
  }
}

AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => null;

main() {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  /*@promotedType=none*/ assertAOf(
      /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
  assertBOf(
      /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
  assertCOf(
      /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
  C.assertBOf(
      /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
  C.assertCOf(
      /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);

  C c;
  /*@promotedType=none*/ c.assertAOf(
      /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
  /*@promotedType=none*/ c.assertDOf(
      /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);

  G<int> g;
  /*@promotedType=none*/ g.assertAOf(
      /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
  /*@promotedType=none*/ g.assertDOf(
      /*@typeArgs=Asserter<DartType>(DartType) -> void*/ [_isInt, _isString]);
}
