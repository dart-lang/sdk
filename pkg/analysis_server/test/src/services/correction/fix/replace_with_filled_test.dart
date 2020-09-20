// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithFilledTest);
  });
}

@reflectiveTest
class ReplaceWithFilledTest extends FixProcessorTest {
  @override
  List<String> get experiments => [EnableString.non_nullable];

  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_FILLED;

  Future<void> test_nonNullableElements() async {
    await resolveTestUnit('''
var l = new List<int>(3);
''');
    await assertNoFix();
  }

  Future<void> test_nonNullableElements_inferred() async {
    await resolveTestUnit('''
List<int> l = List(3);
''');
    await assertNoFix();
  }

  Future<void> test_nullableElements() async {
    await resolveTestUnit('''
var l = new List<int?>(3);
''');
    await assertHasFix('''
var l = new List<int?>.filled(3, null, growable: false);
''');
  }

  Future<void> test_nullableElements_inferred() async {
    await resolveTestUnit('''
List<int?> l = List(5);
''');
    await assertHasFix('''
List<int?> l = List.filled(5, null, growable: false);
''');
  }

  Future<void> test_trailingComma() async {
    await resolveTestUnit('''
var l = List<int?>(3,);
''');
    await assertHasFix('''
var l = List<int?>.filled(3, null, growable: false,);
''');
  }
}
