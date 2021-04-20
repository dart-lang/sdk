// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedFunctionAsTypeIdentifierTest);
  });
}

@reflectiveTest
class DeprecatedFunctionAsTypeIdentifierTest extends PubPackageResolutionTest {
  test_typedef() async {
    await assertErrorsInCode('''
typedef Function = int;
typedef F<Function> = int;
''', [
      error(ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 8, 8),
    ]);
  }

  test_extension() async {
    await assertErrorsInCode('''
extension Function on List {}
extension E<Function> on List<Function> {}    
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME, 10, 8),
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME, 42, 8),
    ]);
  }
}
