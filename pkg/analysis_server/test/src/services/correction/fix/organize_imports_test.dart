// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OrganizeImportsTest);
  });
}

@reflectiveTest
class OrganizeImportsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ORGANIZE_IMPORTS;

  @override
  String get lintCode => LintNames.directives_ordering;

  Future<void> test_organizeImports() async {
    await resolveTestCode('''
//ignore_for_file: unused_import
import 'dart:io';

import 'dart:async';

void main(Stream<String> args) { }
''');
    await assertHasFix('''
//ignore_for_file: unused_import
import 'dart:async';
import 'dart:io';

void main(Stream<String> args) { }
''');
  }
}
