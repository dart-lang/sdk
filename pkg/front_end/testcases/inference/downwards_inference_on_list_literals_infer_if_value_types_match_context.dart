// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    assertAOf([_isInt, _isString]);
    assertBOf([_isInt, _isString]);
    assertCOf([_isInt, _isString]);
    assertDOf([_isInt, _isString]);
    assertEOf([_isInt, _isString]);
  }
}

abstract class G<T> {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf = throw '';
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf => throw '';

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf([_isInt, _isString]);
    this.assertAOf([_isInt, _isString]);
    this.assertDOf([_isInt, _isString]);
    assertEOf([_isInt, _isString]);
  }
}

AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf = throw '';
AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => throw '';

test() {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf = throw '';
  assertAOf([_isInt, _isString]);
  assertBOf([_isInt, _isString]);
  assertCOf([_isInt, _isString]);
  C.assertBOf([_isInt, _isString]);
  C.assertCOf([_isInt, _isString]);

  C c = throw '';
  c.assertAOf([_isInt, _isString]);
  c.assertDOf([_isInt, _isString]);

  G<int> g = throw '';
  g.assertAOf([_isInt, _isString]);
  g.assertDOf([_isInt, _isString]);
}

main() {}
