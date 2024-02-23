// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FutureOrBaseTest);
  });
}

@reflectiveTest
class FutureOrBaseTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _check(dynamicType, 'dynamic');
  }

  test_futureOr() {
    void check(DartType S, String expected) {
      _check(futureOrNone(S), expected);
    }

    check(intNone, 'int');
    check(intQuestion, 'int?');

    check(dynamicType, 'dynamic');
    check(voidNone, 'void');

    check(neverNone, 'Never');
    check(neverQuestion, 'Never?');

    check(objectNone, 'Object');
    check(objectQuestion, 'Object?');
  }

  test_other() {
    _check(intNone, 'int');
    _check(intQuestion, 'int?');

    _check(objectNone, 'Object');
    _check(objectQuestion, 'Object?');
  }

  /// futureValueType(`void`) = `void`.
  test_void() {
    _check(voidNone, 'void');
  }

  void _check(DartType T, String expected) {
    var result = typeSystem.futureOrBase(T);
    expect(
      result.getDisplayString(),
      expected,
    );
  }
}
