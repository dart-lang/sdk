// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateFieldFormalParameterTest);
  });
}

@reflectiveTest
class DuplicateFieldFormalParameterTest extends PubPackageResolutionTest {
  test_optional_named() async {
    await assertErrorsInCode(r'''
class A {
  int a;
  A({this.a = 0, this.a = 1});
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 41, 1,
          contextMessages: [message(testFile, 29, 1)]),
    ]);
  }

  test_optional_named_wildcard() async {
    await assertErrorsInCode(r'''
class A {
  int _;
  A({this._ = 0, this._ = 1});
}
''', [
      error(WarningCode.UNUSED_FIELD, 16, 1),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 29, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 41, 1,
          contextMessages: [message(testFile, 29, 1)]),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 41, 1),
    ]);
  }

  test_optional_named_wildcard_preWildcards() async {
    await assertErrorsInCode(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _;
  A({this._ = 0, this._ = 1});
}
''', [
      error(WarningCode.UNUSED_FIELD, 60, 1),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 73, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 85, 1,
          contextMessages: [message(testFile, 73, 1)]),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 85, 1),
    ]);
  }

  test_optional_positional() async {
    await assertErrorsInCode(r'''
class A {
  int a;
  A([this.a = 0, this.a = 1]);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 41, 1,
          contextMessages: [message(testFile, 29, 1)]),
    ]);
  }

  test_optional_positional_final() async {
    await assertErrorsInCode(r'''
class A {
  final x;
  A([this.x = 1, this.x = 2]) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 43, 1,
          contextMessages: [message(testFile, 31, 1)]),
    ]);
  }

  test_optional_positional_final_wildcard() async {
    await assertErrorsInCode(r'''
class A {
  final _;
  A([this._ = 1, this._ = 2]) {}
}
''', [
      error(WarningCode.UNUSED_FIELD, 18, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 43, 1,
          contextMessages: [message(testFile, 31, 1)]),
    ]);
  }

  test_optional_positional_final_wildcard_preWildcards() async {
    await assertErrorsInCode(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  final _;
  A([this._ = 1, this._ = 2]) {}
}
''', [
      error(WarningCode.UNUSED_FIELD, 62, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 87, 1,
          contextMessages: [message(testFile, 75, 1)]),
    ]);
  }

  test_optional_positional_wildcard() async {
    await assertErrorsInCode(r'''
class A {
  int _;
  A([this._ = 0, this._ = 1]);
}
''', [
      error(WarningCode.UNUSED_FIELD, 16, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 41, 1,
          contextMessages: [message(testFile, 29, 1)]),
    ]);
  }

  test_optional_positional_wildcard_preWildcards() async {
    await assertErrorsInCode(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _;
  A([this._ = 0, this._ = 1]);
}
''', [
      error(WarningCode.UNUSED_FIELD, 60, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 85, 1,
          contextMessages: [message(testFile, 73, 1)]),
    ]);
  }

  test_required_named() async {
    await assertErrorsInCode(r'''
class A {
  int a;
  A({required this.a, required this.a});
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 55, 1,
          contextMessages: [message(testFile, 38, 1)]),
    ]);
  }

  test_required_named_wildcard() async {
    await assertErrorsInCode(r'''
class A {
  int _;
  A({required this._, required this._});
}
''', [
      error(WarningCode.UNUSED_FIELD, 16, 1),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 38, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 55, 1,
          contextMessages: [message(testFile, 38, 1)]),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 55, 1),
    ]);
  }

  test_required_named_wildcard_preWildcards() async {
    await assertErrorsInCode(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _;
  A({required this._, required this._});
}
''', [
      error(WarningCode.UNUSED_FIELD, 60, 1),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 82, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 99, 1,
          contextMessages: [message(testFile, 82, 1)]),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 99, 1),
    ]);
  }

  test_required_positional() async {
    await assertErrorsInCode(r'''
class A {
  int a;
  A(this.a, this.a);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 36, 1,
          contextMessages: [message(testFile, 28, 1)]),
    ]);
  }

  test_required_positional_final() async {
    await assertErrorsInCode(r'''
class A {
  final x;
  A(this.x, this.x) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 38, 1,
          contextMessages: [message(testFile, 30, 1)]),
    ]);
  }

  test_required_positional_final_wildcard() async {
    await assertErrorsInCode(r'''
class A {
  final _;
  A(this._, this._) {}
}
''', [
      error(WarningCode.UNUSED_FIELD, 18, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 38, 1,
          contextMessages: [message(testFile, 30, 1)]),
    ]);
  }

  test_required_positional_final_wildcard_preWildcards() async {
    await assertErrorsInCode(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  final _;
  A(this._, this._) {}
}
''', [
      error(WarningCode.UNUSED_FIELD, 62, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 82, 1,
          contextMessages: [message(testFile, 74, 1)]),
    ]);
  }

  test_required_positional_preWildcards() async {
    await assertErrorsInCode(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int? _;
  A(this._, this._);
}
''', [
      error(WarningCode.UNUSED_FIELD, 61, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 81, 1,
          contextMessages: [message(testFile, 73, 1)]),
    ]);
  }

  // TODO(pq): add more tests (https://github.com/dart-lang/sdk/issues/56092)
  test_required_positional_wildcard() async {
    await assertErrorsInCode(r'''
class A {
  int? _;
  A(this._, this._);
}
''', [
      error(WarningCode.UNUSED_FIELD, 17, 1),
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 37, 1,
          contextMessages: [message(testFile, 29, 1)]),
    ]);
  }
}
