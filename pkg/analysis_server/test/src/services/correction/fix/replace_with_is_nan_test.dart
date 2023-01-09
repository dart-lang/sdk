// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithIsNanTest);
  });
}

@reflectiveTest
class ReplaceWithIsNanTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_IS_NAN;

  Future<void> test_alwaysFalse_leftSide() async {
    await resolveTestCode('''
bool f(double d) {
  return double.nan == d;
}
''');
    await assertHasFix('''
bool f(double d) {
  return d.isNaN;
}
''');
  }

  Future<void> test_alwaysFalse_leftSide_prefixExpression() async {
    await resolveTestCode('''
bool f(double d) {
  return double.nan == --d;
}
''');
    await assertHasFix('''
bool f(double d) {
  return (--d).isNaN;
}
''');
  }

  Future<void> test_alwaysFalse_rightSide() async {
    await resolveTestCode('''
bool f(double d) {
  return d == double.nan;
}
''');
    await assertHasFix('''
bool f(double d) {
  return d.isNaN;
}
''');
  }

  Future<void> test_alwaysFalse_rightSide_binaryExpression() async {
    await resolveTestCode('''
bool f(double d) {
  return d + 1 == double.nan;
}
''');
    await assertHasFix('''
bool f(double d) {
  return (d + 1).isNaN;
}
''');
  }

  Future<void> test_alwaysTrue_leftSide() async {
    await resolveTestCode('''
bool f(double d) {
  return double.nan != d;
}
''');
    await assertHasFix('''
bool f(double d) {
  return !d.isNaN;
}
''');
  }

  Future<void> test_alwaysTrue_leftSide_literal() async {
    await resolveTestCode('''
bool f() {
  return double.nan != 1;
}
''');
    await assertHasFix('''
bool f() {
  return !1.isNaN;
}
''');
  }

  Future<void> test_alwaysTrue_leftSide_postfixExpression() async {
    await resolveTestCode('''
bool f(double d) {
  return double.nan != d++;
}
''');
    await assertHasFix('''
bool f(double d) {
  return !(d++).isNaN;
}
''');
  }

  Future<void> test_alwaysTrue_rightSide() async {
    await resolveTestCode('''
bool f(double d) {
  return d != double.nan;
}
''');
    await assertHasFix('''
bool f(double d) {
  return !d.isNaN;
}
''');
  }

  Future<void> test_alwaysTrue_rightSide_indexExpression() async {
    await resolveTestCode('''
bool f(List<double> l) {
  return l[0] != double.nan;
}
''');
    await assertHasFix('''
bool f(List<double> l) {
  return !l[0].isNaN;
}
''');
  }

  Future<void> test_alwaysTrue_rightSide_methodInvocation() async {
    await resolveTestCode('''
bool f(double d) {
  return d.abs() != double.nan;
}
''');
    await assertHasFix('''
bool f(double d) {
  return !d.abs().isNaN;
}
''');
  }

  Future<void> test_alwaysTrue_rightSide_postfixExpression() async {
    await resolveTestCode('''
bool f(double d) {
  return d++ != double.nan;
}
''');
    await assertHasFix('''
bool f(double d) {
  return !(d++).isNaN;
}
''');
  }

  Future<void> test_alwaysTrue_rightSide_prefixedIdentifier() async {
    await resolveTestCode('''
bool f(double d) {
  return d.sign != double.nan;
}
''');
    await assertHasFix('''
bool f(double d) {
  return !d.sign.isNaN;
}
''');
  }

  Future<void> test_alwaysTrue_rightSide_propertyAccess() async {
    await resolveTestCode('''
bool f(double d) {
  return (d).sign != double.nan;
}
''');
    await assertHasFix('''
bool f(double d) {
  return !(d).sign.isNaN;
}
''');
  }
}
