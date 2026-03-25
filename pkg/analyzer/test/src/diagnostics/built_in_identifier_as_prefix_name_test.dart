// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsPrefixNameTest);
  });
}

@reflectiveTest
class BuiltInIdentifierAsPrefixNameTest extends PubPackageResolutionTest {
  test_abstract() async {
    await assertErrorsInCode(
      '''
import 'dart:async' as abstract;
''',
      [
        error(diag.unusedImport, 7, 12),
        error(diag.builtInIdentifierAsPrefixName, 23, 8),
      ],
    );
  }

  test_Function() async {
    await assertErrorsInCode(
      '''
import 'dart:async' as Function;
''',
      [
        error(diag.unusedImport, 7, 12),
        error(diag.builtInIdentifierAsPrefixName, 23, 8),
      ],
    );
  }

  test_inout() async {
    await assertErrorsInCode(
      '''
import 'dart:async' as inout;
''',
      [
        error(diag.unusedImport, 7, 12),
        error(diag.builtInIdentifierAsPrefixName, 23, 5),
      ],
    );
  }

  test_inout_language310() async {
    await assertErrorsInCode(
      '''
// @dart = 3.10
import 'dart:async' as inout;
''',
      [error(diag.unusedImport, 23, 12)],
    );
  }

  test_out() async {
    await assertErrorsInCode(
      '''
import 'dart:async' as out;
''',
      [
        error(diag.unusedImport, 7, 12),
        error(diag.builtInIdentifierAsPrefixName, 23, 3),
      ],
    );
  }

  test_out_language310() async {
    await assertErrorsInCode(
      '''
// @dart = 3.10
import 'dart:async' as out;
''',
      [error(diag.unusedImport, 23, 12)],
    );
  }
}
