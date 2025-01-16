// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_editable_arguments_tests.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditableArgumentsTest);
  });
}

@reflectiveTest
class EditableArgumentsTest extends SharedAbstractLspAnalysisServerTest
    with SharedEditableArgumentsTests {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(flutter: true);
  }
}
