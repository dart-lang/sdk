// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrivateOptionalParameterTest);
  });
}

@reflectiveTest
class PrivateOptionalParameterTest extends PubPackageResolutionTest {
  test_fieldFormal() async {
    await assertErrorsInCode(
      r'''
class A {
  int? _p;
  A({this._p = 0});
}
''',
      [error(WarningCode.unusedField, 17, 2)],
    );
  }

  test_nonConstructor() async {
    await assertErrorsInCode(
      '''
f({var _p}) {}
''',
      [error(ParserErrorCode.privateNamedNonFieldParameter, 7, 2)],
    );
  }

  test_nonFieldParameter() async {
    await assertErrorsInCode(
      '''
class C {
  C({int? _notField});
}
''',
      [error(ParserErrorCode.privateNamedNonFieldParameter, 20, 9)],
    );
  }

  test_withDefaultValue() async {
    await assertErrorsInCode(
      '''
f({_p = 0}) {}
''',
      [error(ParserErrorCode.privateNamedNonFieldParameter, 3, 2)],
    );
  }
}
