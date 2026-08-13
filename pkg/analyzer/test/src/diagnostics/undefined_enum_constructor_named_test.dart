// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedEnumConstructorNamedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedEnumConstructorNamedTest extends PubPackageResolutionTest {
  test_it() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named()
//  ^^^^^
// [diag.undefinedEnumConstructorNamed] The enum doesn't have a constructor named 'named'.
}
''');
  }
}
