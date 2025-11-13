// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
      [error(diag.unusedField, 17, 2)],
    );
  }

  test_nonConstructor() async {
    await assertErrorsInCode(
      '''
f({var _p}) {}
''',
      [error(diag.privateNamedNonFieldParameter, 7, 2)],
    );
  }

  test_nonFieldParameter() async {
    await assertErrorsInCode(
      '''
class C {
  C({int? _notField});
}
''',
      [error(diag.privateNamedNonFieldParameter, 20, 9)],
    );
  }

  test_noPublicName_nonIdentifier() async {
    await assertErrorsInCode(
      '''
class C {
  int? _123;
  C({this._123}) {}
}
''',
      [
        error(diag.unusedField, 17, 4),
        error(diag.privateNamedParameterWithoutPublicName, 33, 4),
      ],
    );
  }

  test_noPublicName_preFeature() async {
    await assertErrorsInCode(
      '''
// @dart=3.10
class C {
  int? _123;
  C({this._123}) {}
}
''',
      [
        error(diag.unusedField, 31, 4),
        error(diag.experimentNotEnabledOffByDefault, 47, 4),
      ],
    );
  }

  test_noPublicName_reservedWord() async {
    await assertErrorsInCode(
      '''
class C {
  int? _for;
  C({this._for}) {}
}
''',
      [
        error(diag.unusedField, 17, 4),
        error(diag.privateNamedParameterWithoutPublicName, 33, 4),
      ],
    );
  }

  test_noPublicName_stillPrivate() async {
    await assertErrorsInCode(
      '''
class C {
  int? __extraPrivate;
  C({this.__extraPrivate}) {}
}
''',
      [
        error(diag.unusedField, 17, 14),
        error(diag.privateNamedParameterWithoutPublicName, 43, 14),
      ],
    );
  }

  test_noPublicName_wildcard() async {
    await assertErrorsInCode(
      '''
class C {
  int? _;
  C({this._}) {}
}
''',
      [
        error(diag.unusedField, 17, 1),
        error(diag.privateNamedParameterWithoutPublicName, 30, 1),
      ],
    );
  }

  test_withDefaultValue() async {
    await assertErrorsInCode(
      '''
f({_p = 0}) {}
''',
      [error(diag.privateNamedNonFieldParameter, 3, 2)],
    );
  }
}
