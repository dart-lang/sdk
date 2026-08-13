// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpectedOneSetTypeArgumentsTest);
  });
}

@reflectiveTest
class ExpectedOneSetTypeArgumentsTest extends PubPackageResolutionTest {
  test_multiple_type_arguments() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  <int, int, int>{2, 3};
//^^^^^^^^^^^^^^^
// [diag.expectedOneSetTypeArguments] Set literals require one type argument or none, but 3 were found.
}''');
  }
}
