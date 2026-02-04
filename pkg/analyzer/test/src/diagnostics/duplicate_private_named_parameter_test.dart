// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicatePrivateNamedParameterTest);
  });
}

@reflectiveTest
class DuplicatePrivateNamedParameterTest extends PubPackageResolutionTest {
  test_initializingFormal_initializingFormal() async {
    await assertErrorsInCode(
      r'''
class C {
  final String? _foo;
  C({required this._foo, required this._foo}) {}
}
''',
      [
        error(diag.unusedField, 26, 4),
        error(
          diag.duplicateFieldFormalParameter,
          71,
          4,
          contextMessages: [message(testFile, 51, 4)],
        ),
      ],
    );
  }

  test_initializingFormal_privateNamed() async {
    await assertErrorsInCode(
      r'''
class C {
  final String? _foo;
  C({required this._foo, String? _foo}) {}
}
''',
      [
        error(diag.unusedField, 26, 4),
        error(diag.privateNamedNonFieldParameter, 65, 4),
        error(
          diag.duplicateDefinition,
          65,
          4,
          contextMessages: [message(testFile, 51, 4)],
        ),
      ],
    );
  }

  test_initializingFormal_publicNamed() async {
    await assertErrorsInCode(
      r'''
class C {
  final String? _foo;
  C({required this._foo, String? foo}) {}
}
''',
      [
        error(diag.unusedField, 26, 4),
        error(
          diag.privateNamedParameterDuplicatePublicName,
          51,
          4,
          contextMessages: [message(testFile, 65, 3)],
        ),
      ],
    );
  }

  test_privateNamed_initializingFormal() async {
    await assertErrorsInCode(
      r'''
class C {
  final String? _foo;
  C({String? _foo, required this._foo}) {}
}
''',
      [
        error(diag.unusedField, 26, 4),
        error(diag.privateNamedNonFieldParameter, 45, 4),
        error(
          diag.duplicateDefinition,
          65,
          4,
          contextMessages: [message(testFile, 45, 4)],
        ),
      ],
    );
  }

  test_privatePositional_initializingFormal() async {
    await assertErrorsInCode(
      r'''
class C {
  final String? _foo;
  C(String _foo, {required this._foo}) {}
}
''',
      [
        error(diag.unusedField, 26, 4),
        error(
          diag.duplicateDefinition,
          64,
          4,
          contextMessages: [message(testFile, 43, 4)],
        ),
      ],
    );
  }

  test_publicInitializingFormal_privateInitializingFormal() async {
    await assertErrorsInCode(
      r'''
class C {
  final String? foo;
  final String? _foo;
  C({required this.foo, required this._foo}) {}
}
''',
      [
        error(diag.unusedField, 47, 4),
        error(
          diag.privateNamedParameterDuplicatePublicName,
          91,
          4,
          contextMessages: [message(testFile, 72, 3)],
        ),
      ],
    );
  }

  test_publicNamed_initializingFormal() async {
    await assertErrorsInCode(
      r'''
class C {
  final String? _foo;
  C({String? foo, required this._foo}) {}
}
''',
      [
        error(diag.unusedField, 26, 4),
        error(
          diag.privateNamedParameterDuplicatePublicName,
          64,
          4,
          contextMessages: [message(testFile, 45, 3)],
        ),
      ],
    );
  }

  test_publicPositional_initializingFormal() async {
    await assertErrorsInCode(
      r'''
class C {
  final String? _foo;
  C(String? foo, {required this._foo}) {}
}
''',
      [
        error(diag.unusedField, 26, 4),
        error(
          diag.privateNamedParameterDuplicatePublicName,
          64,
          4,
          contextMessages: [message(testFile, 44, 3)],
        ),
      ],
    );
  }
}
