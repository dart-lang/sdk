// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnusedImportBulkTest);
    defineReflectiveTests(RemoveUnusedImportMultiTest);
    defineReflectiveTests(RemoveUnusedImportTest);
  });
}

@reflectiveTest
class RemoveUnusedImportBulkTest extends BulkFixProcessorTest {
  @FailingTest(reason: 'multiple deletions conflict')
  Future<void> test_multipleOnSingleLine() async {
    // TODO(brianwilkerson) Remove test_multipleOnSingleLine_temporary when this
    //  test starts to pass.
    await resolveTestCode('''
import 'dart:collection'; import 'dart:math'; import 'dart:async';
void f() {}
''');
    await assertHasFix('''

void f() {}
''');
  }

  Future<void> test_multipleOnSingleLine_temporary() async {
    await resolveTestCode('''
import 'dart:collection'; import 'dart:math'; import 'dart:async';
void f() {}
''');
    await assertHasFix('''
import 'dart:math';
void f() {}
''');
  }

  Future<void> test_multipleUnused() async {
    await resolveTestCode('''
import 'dart:collection';
import 'dart:math';
import 'dart:async';
void f() {}
''');
    await assertHasFix('''
void f() {}
''');
    var details = processor.fixDetails;
    expect(details, hasLength(1));
    var fixes = details[0].fixes;
    expect(fixes, hasLength(1));
    expect(fixes[0].occurrences, 3);
  }

  Future<void> test_usedAndUnused() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:math' as math;
import 'dart:async';

var tau = math.pi * 2;

void f() {}
''');
    await assertHasFix('''
import 'dart:math' as math;

var tau = math.pi * 2;

void f() {}
''');
  }
}

@reflectiveTest
class RemoveUnusedImportMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_IMPORT_MULTI;

  Future<void> test_all_diverseImports() async {
    await resolveTestCode('''
import 'dart:math';
import 'dart:math';
import 'dart:async';
void f() {}
''');
    await assertHasFixAllFix(HintCode.UNUSED_IMPORT, '''
void f() {}
''');
  }

  Future<void> test_all_diverseImports2() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:math' as math;
import 'dart:async';

var tau = math.pi * 2;

void f() {}
''');
    await assertHasFixAllFix(HintCode.UNUSED_IMPORT, '''
import 'dart:math' as math;

var tau = math.pi * 2;

void f() {}
''');
  }

  @FailingTest(reason: 'multiple deletions conflict')
  Future<void> test_all_singleLine() async {
    // TODO(brianwilkerson) Remove test_multipleOnSingleLine_temporary when this
    //  test starts to pass.
    await resolveTestCode('''
import 'dart:math'; import 'dart:math'; import 'dart:math';
void f() {}
''');
    await assertHasFixAllFix(HintCode.UNUSED_IMPORT, '''

void f() {}
''');
  }

  Future<void> test_all_singleLine_temporary() async {
    await resolveTestCode('''
import 'dart:math'; import 'dart:math'; import 'dart:math';
void f() {}
''');
    await assertHasFixAllFix(HintCode.UNUSED_IMPORT, '''
import 'dart:math';
void f() {}
''');
  }

  Future<void> test_multipleOfSame_all() async {
    await resolveTestCode('''
import 'dart:math';
import 'dart:math';
import 'dart:math';
void f() {}
''');
    await assertHasFixAllFix(HintCode.UNUSED_IMPORT, '''
void f() {}
''');
  }
}

@reflectiveTest
class RemoveUnusedImportTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_IMPORT;

  Future<void> test_anotherImportOnLine() async {
    await resolveTestCode('''
import 'dart:math'; import 'dart:async';

void f(Completer f) {
  print(f);
}
''');
    await assertHasFix('''
import 'dart:async';

void f(Completer f) {
  print(f);
}
''');
  }

  Future<void> test_duplicateImport() async {
    await resolveTestCode('''
import 'dart:math';
import 'dart:math';

void f() {
  print(min(0, 1));
}
''');
    await assertHasFix('''
import 'dart:math';

void f() {
  print(min(0, 1));
}
''');
  }

  Future<void> test_severalLines() async {
    await resolveTestCode('''
import
  'dart:math';
void f() {
}
''');
    await assertHasFix('''
void f() {
}
''');
  }

  Future<void> test_single() async {
    await resolveTestCode('''
import 'dart:math';
void f() {
}
''');
    await assertHasFix('''
void f() {
}
''');
  }

  Future<void> test_unnecessaryImport() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:async' show Completer;
f(FutureOr<int> a, Completer<int> b) {}
''');
    await assertHasFix('''
import 'dart:async';
f(FutureOr<int> a, Completer<int> b) {}
''');
  }
}
