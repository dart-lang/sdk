// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnusedImportTest);
    defineReflectiveTests(RemoveUnusedImportMultiTest);
  });
}

@reflectiveTest
class RemoveUnusedImportMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_IMPORT_MULTI;

  @override
  void setUp() {
    super.setUp();
    // TODO(dantup): Get these tests passing with either line ending.
    useLineEndingsForPlatform = false;
  }

  Future<void> test_all_diverseImports() async {
    await resolveTestCode('''
import 'dart:math';
import 'dart:math';
import 'dart:async';
main() {
}
''');
    await assertHasFixAllFix(HintCode.UNUSED_IMPORT, '''
main() {
}
''');
  }

  Future<void> test_all_diverseImports2() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:math' as math;
import 'dart:async';

var tau = math.pi * 2;

main() {
}
''');
    await assertHasFixAllFix(HintCode.UNUSED_IMPORT, '''
import 'dart:math' as math;

var tau = math.pi * 2;

main() {
}
''');
  }

  @FailingTest(reason: 'one unused import remains unremoved')
  Future<void> test_all_singleLine() async {
    await resolveTestCode('''
import 'dart:math'; import 'dart:math'; import 'dart:math';
main() {
}
''');
    await assertHasFixAllFix(HintCode.UNUSED_IMPORT, '''
main() {
}
''');
  }

  Future<void> test_multipleOfSame_all() async {
    await resolveTestCode('''
import 'dart:math';
import 'dart:math';
import 'dart:math';
main() {
}
''');
    await assertHasFixAllFix(HintCode.UNUSED_IMPORT, '''
main() {
}
''');
  }
}

@reflectiveTest
class RemoveUnusedImportTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_IMPORT;

  @override
  void setUp() {
    super.setUp();
    // TODO(dantup): Get these tests passing with either line ending.
    useLineEndingsForPlatform = false;
  }

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

main() {
  print(min(0, 1));
}
''');
    await assertHasFix('''
import 'dart:math';

main() {
  print(min(0, 1));
}
''');
  }

  Future<void> test_severalLines() async {
    await resolveTestCode('''
import
  'dart:math';
main() {
}
''');
    await assertHasFix('''
main() {
}
''');
  }

  Future<void> test_single() async {
    await resolveTestCode('''
import 'dart:math';
main() {
}
''');
    await assertHasFix('''
main() {
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
