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
import 'dart:collection' as pref;
main() {
  pref.HashMap s = null;
  LinkedHashMap f = null;
  print('\$s \$f');
}
''');
    await assertHasFix('''
import 'dart:collection' as pref;
main() {
  pref.HashMap s = null;
  pref.LinkedHashMap f = null;
  print('\$s \$f');
}
''');
  }

  Future<void> test_withExtension() async {
    addSource('/home/test/lib/lib.dart', '''
class C {}
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode('''
import 'lib.dart' as p;
void f(p.C c) {
  print(E.m());
}
''');
    await assertHasFix('''
import 'lib.dart' as p;
void f(p.C c) {
  print(p.E.m());
}
''');
  }

  Future<void> test_withTopLevelVariable() async {
    await resolveTestCode('''
import 'dart:math' as pref;
main() {
  print(pref.e);
  print(pi);
}
''');
    await assertHasFix('''
import 'dart:math' as pref;
main() {
  print(pref.e);
  print(pref.pi);
}
''');
  }
}
