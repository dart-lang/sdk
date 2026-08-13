// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedEnumConstructorUnnamedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedEnumConstructorUnnamedTest extends PubPackageResolutionTest {
  test_withArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v();
//^
// [diag.undefinedEnumConstructorUnnamed] The enum doesn't have an unnamed constructor.
  const E.named();
}
''');
  }

  test_withoutArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
//^
// [diag.undefinedEnumConstructorUnnamed] The enum doesn't have an unnamed constructor.
  const E.named();
}
''');
  }
}
