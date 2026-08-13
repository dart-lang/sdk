// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PathNotPosixTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PathNotPosixTest extends PubspecDiagnosticTest {
  test_pathNotPosix_error() {
    newFolder('/foo');
    newPubspecYamlFile('/foo', '''
name: foo
''');
    assertDiagnostics(r'''
name: sample
version: 0.1.0
publish_to: none
dependencies:
  foo:
    path: \foo
//        ^^^^
// [diag.pathNotPosix] The path '\foo' isn't a POSIX-style path.
''');
  }
}
