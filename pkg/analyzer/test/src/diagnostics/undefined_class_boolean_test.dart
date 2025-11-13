// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedClassBooleanTest);
  });
}

@reflectiveTest
class UndefinedClassBooleanTest extends PubPackageResolutionTest {
  test_variableDeclaration() async {
    await assertErrorsInCode(
      '''
f() { boolean v; }
''',
      [
        error(diag.undefinedClassBoolean, 6, 7),
        error(diag.unusedLocalVariable, 14, 1),
      ],
    );
  }
}
