// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryPrefixTest);
  });
}

@reflectiveTest
class ImportLibraryPrefixTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PREFIX;

  Future<void> test_withClass() async {
    await resolveTestCode('''
import 'dart:collection' as prefix;

void f(prefix.HashMap a, HashMap b) {}
''');
    await assertHasFix('''
import 'dart:collection' as prefix;

void f(prefix.HashMap a, prefix.HashMap b) {}
''');
  }

  Future<void> test_withExtension() async {
    newFile('$testPackageLibPath/a.dart', '''
extension E on int {
  static int foo() => 0;
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

void f() {
  prefix.E.foo();
  E.foo();
}
''');
    await assertHasFix('''
import 'a.dart' as prefix;

void f() {
  prefix.E.foo();
  prefix.E.foo();
}
''');
  }

  Future<void> test_withTopLevelVariable() async {
    await resolveTestCode('''
import 'dart:math' as prefix;

void f() {
  prefix.e;
  pi;
}
''');
    await assertHasFix('''
import 'dart:math' as prefix;

void f() {
  prefix.e;
  prefix.pi;
}
''');
  }
}
