// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedFieldTest extends PubspecDiagnosticTest {
  test_deprecated_author() {
    assertDiagnostics('''
name: sample
author: foo
// [diag.deprecatedField][column 1][length 6] The 'author' field is no longer used and can be removed.
''');
  }

  test_deprecated_authors() {
    assertDiagnostics('''
name: sample
authors:
// [diag.deprecatedField][column 1][length 7] The 'authors' field is no longer used and can be removed.
  - foo
  - bar
''');
  }

  test_deprecated_transformers() {
    assertDiagnostics('''
name: sample
transformers:
// [diag.deprecatedField][column 1][length 12] The 'transformers' field is no longer used and can be removed.
  - foo
''');
  }

  test_deprecated_web() {
    assertDiagnostics('''
name: sample
web: foo
// [diag.deprecatedField][column 1][length 3] The 'web' field is no longer used and can be removed.
''');
  }
}
