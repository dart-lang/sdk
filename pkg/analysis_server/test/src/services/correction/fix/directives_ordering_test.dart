// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DirectivesOrderingBulkTest);
  });
}

@reflectiveTest
class DirectivesOrderingBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.directives_ordering;

  Future<void> test_single_file() async {
    await parseTestCode('''
import 'dart:io';
import 'dart:async';

File? f;
Future? a;
''');

    await assertHasFix('''
import 'dart:async';
import 'dart:io';

File? f;
Future? a;
''');
  }
}
