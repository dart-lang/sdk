// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PathPubspecDoesNotExistTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PathPubspecDoesNotExistTest extends PubspecDiagnosticTest {
  test_dependencyPath_pubspecDoesNotExist() {
    newFolder('/foo');
    assertDiagnostics('''
name: sample
dependencies:
  foo:
    path: /foo
//        ^^^^
// [diag.pathPubspecDoesNotExist] The directory '/foo' doesn't contain a pubspec.
''');
  }

  test_dependencyPath_pubspecExists() {
    newFolder('/foo');
    newPubspecYamlFile('/foo', '''
name: foo
''');
    assertDiagnostics('''
name: sample
dependencies:
  foo:
    path: /foo
''');
  }
}
