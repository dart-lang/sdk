// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsPrefixNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BuiltInIdentifierAsPrefixNameTest extends PubPackageResolutionTest {
  test_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as abstract;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
//                     ^^^^^^^^
// [diag.builtInIdentifierAsPrefixName] The built-in identifier 'abstract' can't be used as a prefix name.
''');
  }

  test_Function() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as Function;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
//                     ^^^^^^^^
// [diag.builtInIdentifierAsPrefixName] The built-in identifier 'Function' can't be used as a prefix name.
''');
  }

  test_inout() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as inout;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
//                     ^^^^^
// [diag.builtInIdentifierAsPrefixName] The built-in identifier 'inout' can't be used as a prefix name.
''');
  }

  test_inout_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
import 'dart:async' as inout;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
''');
  }

  test_out() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as out;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
//                     ^^^
// [diag.builtInIdentifierAsPrefixName] The built-in identifier 'out' can't be used as a prefix name.
''');
  }

  test_out_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
import 'dart:async' as out;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
''');
  }
}
