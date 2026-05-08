// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateFieldFormalParameterTest);
  });
}

@reflectiveTest
class DuplicateFieldFormalParameterTest extends PubPackageResolutionTest {
  test_constructor_optional_named() async {
    await assertErrorsInCode(
      r'''
class A {
  int a;
  A({this.a = 0, this.a = 1});
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          41,
          1,
          contextMessages: [message(testFile, 29, 1)],
        ),
      ],
    );
  }

  test_constructor_optional_named_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  int _;
  A({this._ = 0, this._ = 1});
}
''',
      [
        error(diag.unusedField, 16, 1),
        error(diag.privateNamedParameterWithoutPublicName, 29, 1),
        error(
          diag.duplicateFieldFormalParameter,
          41,
          1,
          contextMessages: [message(testFile, 29, 1)],
        ),
        error(diag.privateNamedParameterWithoutPublicName, 41, 1),
      ],
    );
  }

  test_constructor_optional_named_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _;
  A({this._ = 0, this._ = 1});
}
''',
      [
        error(diag.unusedField, 60, 1),
        error(diag.experimentNotEnabled, 73, 1),
        error(diag.experimentNotEnabled, 85, 1),
        error(
          diag.duplicateFieldFormalParameter,
          85,
          1,
          contextMessages: [message(testFile, 73, 1)],
        ),
      ],
    );
  }

  test_constructor_optional_positional() async {
    await assertErrorsInCode(
      r'''
class A {
  int a;
  A([this.a = 0, this.a = 1]);
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          41,
          1,
          contextMessages: [message(testFile, 29, 1)],
        ),
      ],
    );
  }

  test_constructor_optional_positional_final() async {
    await assertErrorsInCode(
      r'''
class A {
  final x;
  A([this.x = 1, this.x = 2]) {}
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          43,
          1,
          contextMessages: [message(testFile, 31, 1)],
        ),
      ],
    );
  }

  test_constructor_optional_positional_final_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  final _;
  A([this._ = 1, this._ = 2]) {}
}
''',
      [
        error(diag.unusedField, 18, 1),
        error(
          diag.duplicateFieldFormalParameter,
          43,
          1,
          contextMessages: [message(testFile, 31, 1)],
        ),
      ],
    );
  }

  test_constructor_optional_positional_final_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  final _;
  A([this._ = 1, this._ = 2]) {}
}
''',
      [
        error(diag.unusedField, 62, 1),
        error(
          diag.duplicateFieldFormalParameter,
          87,
          1,
          contextMessages: [message(testFile, 75, 1)],
        ),
      ],
    );
  }

  test_constructor_optional_positional_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  int _;
  A([this._ = 0, this._ = 1]);
}
''',
      [
        error(diag.unusedField, 16, 1),
        error(
          diag.duplicateFieldFormalParameter,
          41,
          1,
          contextMessages: [message(testFile, 29, 1)],
        ),
      ],
    );
  }

  test_constructor_optional_positional_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _;
  A([this._ = 0, this._ = 1]);
}
''',
      [
        error(diag.unusedField, 60, 1),
        error(
          diag.duplicateFieldFormalParameter,
          85,
          1,
          contextMessages: [message(testFile, 73, 1)],
        ),
      ],
    );
  }

  test_constructor_required_named() async {
    await assertErrorsInCode(
      r'''
class A {
  int a;
  A({required this.a, required this.a});
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          55,
          1,
          contextMessages: [message(testFile, 38, 1)],
        ),
      ],
    );
  }

  test_constructor_required_named_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  int _;
  A({required this._, required this._});
}
''',
      [
        error(diag.unusedField, 16, 1),
        error(diag.privateNamedParameterWithoutPublicName, 38, 1),
        error(
          diag.duplicateFieldFormalParameter,
          55,
          1,
          contextMessages: [message(testFile, 38, 1)],
        ),
        error(diag.privateNamedParameterWithoutPublicName, 55, 1),
      ],
    );
  }

  test_constructor_required_named_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _;
  A({required this._, required this._});
}
''',
      [
        error(diag.unusedField, 60, 1),
        error(diag.experimentNotEnabled, 82, 1),
        error(diag.experimentNotEnabled, 99, 1),
        error(
          diag.duplicateFieldFormalParameter,
          99,
          1,
          contextMessages: [message(testFile, 82, 1)],
        ),
      ],
    );
  }

  test_constructor_required_positional() async {
    await assertErrorsInCode(
      r'''
class A {
  int a;
  A(this.a, this.a);
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          36,
          1,
          contextMessages: [message(testFile, 28, 1)],
        ),
      ],
    );
  }

  test_constructor_required_positional_final() async {
    await assertErrorsInCode(
      r'''
class A {
  final x;
  A(this.x, this.x) {}
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          38,
          1,
          contextMessages: [message(testFile, 30, 1)],
        ),
      ],
    );
  }

  test_constructor_required_positional_final_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  final _;
  A(this._, this._) {}
}
''',
      [
        error(diag.unusedField, 18, 1),
        error(
          diag.duplicateFieldFormalParameter,
          38,
          1,
          contextMessages: [message(testFile, 30, 1)],
        ),
      ],
    );
  }

  test_constructor_required_positional_final_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  final _;
  A(this._, this._) {}
}
''',
      [
        error(diag.unusedField, 62, 1),
        error(
          diag.duplicateFieldFormalParameter,
          82,
          1,
          contextMessages: [message(testFile, 74, 1)],
        ),
      ],
    );
  }

  test_constructor_required_positional_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int? _;
  A(this._, this._);
}
''',
      [
        error(diag.unusedField, 61, 1),
        error(
          diag.duplicateFieldFormalParameter,
          81,
          1,
          contextMessages: [message(testFile, 73, 1)],
        ),
      ],
    );
  }

  test_constructor_required_positional_primaryConstructor() async {
    await assertErrorsInCode(
      r'''
class A(this.f, this.f) {
  int f;
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          21,
          1,
          contextMessages: [message(testFile, 13, 1)],
        ),
      ],
    );
  }

  // TODO(pq): add more tests (https://github.com/dart-lang/sdk/issues/56092)
  test_constructor_required_positional_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  int? _;
  A(this._, this._);
}
''',
      [
        error(diag.unusedField, 17, 1),
        error(
          diag.duplicateFieldFormalParameter,
          37,
          1,
          contextMessages: [message(testFile, 29, 1)],
        ),
      ],
    );
  }

  test_primaryConstructor_optional_named() async {
    await assertErrorsInCode(
      r'''
class A({this.a = 0, this.a = 1}) {
  int a;
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          26,
          1,
          contextMessages: [message(testFile, 14, 1)],
        ),
      ],
    );
  }

  test_primaryConstructor_optional_positional() async {
    await assertErrorsInCode(
      r'''
class A([this.a = 0, this.a = 1]) {
  int a;
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          26,
          1,
          contextMessages: [message(testFile, 14, 1)],
        ),
      ],
    );
  }

  test_primaryConstructor_required_named() async {
    await assertErrorsInCode(
      r'''
class A({required this.a, required this.a}) {
  int a;
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          40,
          1,
          contextMessages: [message(testFile, 23, 1)],
        ),
      ],
    );
  }

  test_primaryConstructor_required_positional() async {
    await assertErrorsInCode(
      r'''
class A(this.a, this.a) {
  int a;
}
''',
      [
        error(
          diag.duplicateFieldFormalParameter,
          21,
          1,
          contextMessages: [message(testFile, 13, 1)],
        ),
      ],
    );
  }
}
