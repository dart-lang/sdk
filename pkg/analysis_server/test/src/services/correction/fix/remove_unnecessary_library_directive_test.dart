// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryLibraryDirectiveTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryLibraryDirectiveTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_LIBRARY_DIRECTIVE;

  @override
  String get lintCode => LintNames.unnecessary_library_directive;

  Future<void> test_anotherDirectiveOnLine() async {
    await resolveTestCode('''
library foo; import 'dart:async';

void f(Completer f) {}
''');
    await assertHasFix('''
import 'dart:async';

void f(Completer f) {}
''');
  }

  Future<void> test_severalLines() async {
    await resolveTestCode('''
library
  one.two.three;
void f() {}
''');
    await assertHasFix('''
void f() {}
''');
  }

  Future<void> test_single() async {
    await resolveTestCode('''
library foo;
void f() {}
''');
    await assertHasFix('''
void f() {}
''');
  }
}
