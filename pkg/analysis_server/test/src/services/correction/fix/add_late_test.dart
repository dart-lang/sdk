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
    defineReflectiveTests(AddLatePreNnbdTest);
    defineReflectiveTests(AddLateTest);
  });
}

@reflectiveTest
class AddLatePreNnbdTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_LATE;

  Future<void> test_withFinal() async {
    await resolveTestUnit('''
class C {
  final String s;
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class AddLateTest extends FixProcessorTest {
  @override
  List<String> get experiments => [EnableString.non_nullable];

  @override
  FixKind get kind => DartFixKind.ADD_LATE;

  Future<void> test_withFinal() async {
    await resolveTestUnit('''
class C {
  final String s;
}
''');
    await assertHasFix('''
class C {
  final late String s;
}
''');
  }

  Future<void> test_withLate() async {
    await resolveTestUnit('''
class C {
  late s;
}
''');
    await assertNoFix();
  }

  Future<void> test_withType() async {
    await resolveTestUnit('''
class C {
  String s;
}
''');
    await assertHasFix('''
class C {
  late String s;
}
''');
  }
}
