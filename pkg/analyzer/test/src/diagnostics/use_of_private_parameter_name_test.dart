// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfPrivateParameterNameTest);
  });
}

@reflectiveTest
class UseOfPrivateParameterNameTest extends PubPackageResolutionTest {
  test_andVoidLhsError() async {
    await assertErrorsInCode(
      '''
class C {
  int? _x;
  C({this._x});
}
void f() {
  C(_x: 123);
}
''',
      [
        error(diag.unusedField, 17, 2),
        error(
          diag.useOfPrivateParameterName,
          54,
          2,
          messageContains: ["'_x'", "'x'"],
        ),
      ],
    );
  }
}
