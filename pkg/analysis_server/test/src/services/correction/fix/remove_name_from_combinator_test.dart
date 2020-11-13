// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveNameFromCombinatorTest);
  });
}

@reflectiveTest
class RemoveNameFromCombinatorTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_COMBINATOR;

  Future<void> test_duplicateHiddenName_last() async {
    await resolveTestCode('''
import 'dart:math' hide cos, sin, sin;

main() {
  print(min(0, 1));
}
''');
    await assertHasFix('''
import 'dart:math' hide cos, sin;

main() {
  print(min(0, 1));
}
''');
  }

  Future<void> test_duplicateHiddenName_middle() async {
    await resolveTestCode('''
import 'dart:math' hide cos, cos, sin;

main() {
  print(min(0, 1));
}
''');
    await assertHasFix('''
import 'dart:math' hide cos, sin;

main() {
  print(min(0, 1));
}
''');
  }

  @failingTest
  Future<void> test_duplicateHiddenName_only_last() async {
    // It appears that the hint does not detect names that are duplicated across
    // multiple combinators.
    await resolveTestCode('''
import 'dart:math' hide cos, sin hide sin;

main() {
  print(min(0, 1));
}
''');
    await assertHasFix('''
import 'dart:math' hide cos, sin;

main() {
  print(min(0, 1));
}
''');
  }

  @failingTest
  Future<void> test_duplicateHiddenName_only_middle() async {
    // It appears that the hint does not detect names that are duplicated across
    // multiple combinators.
    await resolveTestCode('''
import 'dart:math' hide cos hide cos hide sin;

main() {
  print(min(0, 1));
}
''');
    await assertHasFix('''
import 'dart:math' hide cos hide sin;

main() {
  print(min(0, 1));
}
''');
  }

  Future<void> test_duplicateShownName_last() async {
    await resolveTestCode(
      '''
import 'dart:math' show cos, sin, sin;

f(x) {
  print(cos(x) + sin(x));
}
''',
    );
    await assertHasFix('''
import 'dart:math' show cos, sin;

f(x) {
  print(cos(x) + sin(x));
}
''');
  }

  Future<void> test_duplicateShownName_middle() async {
    await resolveTestCode('''
import 'dart:math' show cos, cos, sin;

f(x) {
  print(cos(x) + sin(x));
}
''');
    await assertHasFix('''
import 'dart:math' show cos, sin;

f(x) {
  print(cos(x) + sin(x));
}
''');
  }

  Future<void> test_undefinedHiddenName_first() async {
    await resolveTestCode('''
import 'dart:math' hide aaa, sin, tan;

f(x) {
  print(cos(x));
}
''');
    await assertHasFix('''
import 'dart:math' hide sin, tan;

f(x) {
  print(cos(x));
}
''');
  }

  Future<void> test_undefinedHiddenName_last() async {
    await resolveTestCode('''
import 'dart:math' hide cos, sin, xxx;

f(x) {
  print(tan(x));
}
''');
    await assertHasFix('''
import 'dart:math' hide cos, sin;

f(x) {
  print(tan(x));
}
''');
  }

  Future<void> test_undefinedHiddenName_middle() async {
    await resolveTestCode('''
import 'dart:math' hide cos, mmm, tan;

f(x) {
  print(sin(x));
}
''');
    await assertHasFix('''
import 'dart:math' hide cos, tan;

f(x) {
  print(sin(x));
}
''');
  }

  Future<void> test_undefinedHiddenName_only_first() async {
    await resolveTestCode('''
import 'dart:math' hide aaa hide cos, sin;

main() {
  print(min(0, 1));
}
''');
    await assertHasFix('''
import 'dart:math' hide cos, sin;

main() {
  print(min(0, 1));
}
''');
  }

  Future<void> test_undefinedHiddenName_only_last() async {
    await resolveTestCode('''
import 'dart:math' hide cos, sin hide aaa;

main() {
  print(min(0, 1));
}
''');
    await assertHasFix('''
import 'dart:math' hide cos, sin;

main() {
  print(min(0, 1));
}
''');
  }

  Future<void> test_undefinedHiddenName_only_middle() async {
    await resolveTestCode('''
import 'dart:math' hide cos hide aaa hide sin;

main() {
  print(min(0, 1));
}
''');
    await assertHasFix('''
import 'dart:math' hide cos hide sin;

main() {
  print(min(0, 1));
}
''');
  }

  Future<void> test_undefinedHiddenName_only_only() async {
    await resolveTestCode('''
import 'dart:math' hide aaa;
var c = sin(0.3);
''');
    await assertHasFix('''
import 'dart:math';
var c = sin(0.3);
''');
  }

  Future<void> test_undefinedHiddenName_only_only_withAs() async {
    await resolveTestCode('''
import 'dart:math' as math hide aaa;
var c = math.sin(0.3);
''');
    await assertHasFix('''
import 'dart:math' as math;
var c = math.sin(0.3);
''');
  }

  Future<void> test_undefinedShownName_first() async {
    await resolveTestCode('''
import 'dart:math' show aaa, sin, tan;

f(x) {
  print(sin(x) + tan(x));
}
''');
    await assertHasFix('''
import 'dart:math' show sin, tan;

f(x) {
  print(sin(x) + tan(x));
}
''');
  }

  Future<void> test_undefinedShownName_last() async {
    await resolveTestCode('''
import 'dart:math' show cos, sin, xxx;

f(x) {
  print(cos(x) + sin(x));
}
''');
    await assertHasFix('''
import 'dart:math' show cos, sin;

f(x) {
  print(cos(x) + sin(x));
}
''');
  }

  Future<void> test_undefinedShownName_middle() async {
    await resolveTestCode('''
import 'dart:math' show cos, mmm, tan;

f(x) {
  print(cos(x) + tan(x));
}
''');
    await assertHasFix('''
import 'dart:math' show cos, tan;

f(x) {
  print(cos(x) + tan(x));
}
''');
  }

  Future<void> test_unusedShownName_first() async {
    await resolveTestCode('''
import 'dart:math' show cos, sin, tan;

f(x) {
  print(sin(x) + tan(x));
}
''');
    await assertHasFix('''
import 'dart:math' show sin, tan;

f(x) {
  print(sin(x) + tan(x));
}
''');
  }

  Future<void> test_unusedShownName_last() async {
    await resolveTestCode('''
import 'dart:math' show cos, sin, tan;

f(x) {
  print(cos(x) + sin(x));
}
''');
    await assertHasFix('''
import 'dart:math' show cos, sin;

f(x) {
  print(cos(x) + sin(x));
}
''');
  }

  Future<void> test_unusedShownName_middle() async {
    await resolveTestCode('''
import 'dart:math' show cos, sin, tan;

f(x) {
  print(cos(x) + tan(x));
}
''');
    await assertHasFix('''
import 'dart:math' show cos, tan;

f(x) {
  print(cos(x) + tan(x));
}
''');
  }
}
