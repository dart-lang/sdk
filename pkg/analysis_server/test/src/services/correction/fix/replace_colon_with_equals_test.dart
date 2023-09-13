// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceColonWithEqualsDeprecatedTest);
    defineReflectiveTests(ReplaceColonWithEqualsObsoleteTest);
  });
}

@reflectiveTest
class ReplaceColonWithEqualsDeprecatedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_COLON_WITH_EQUALS;

  @override
  String get latestLanguageVersion => '2.19';

  Future<void> test_defaultFormalParameter() async {
    await resolveTestCode('''
void f({int x: 0}) {}
''');
    await assertHasFix('''
void f({int x = 0}) {}
''');
  }

  Future<void> test_superFormalParameter() async {
    await resolveTestCode('''
class A {
  String? a;
  A({this.a});
}
class B extends A {
  B({super.a : ''});
}
''');
    await assertHasFix('''
class A {
  String? a;
  A({this.a});
}
class B extends A {
  B({super.a = ''});
}
''');
  }
}

@reflectiveTest
class ReplaceColonWithEqualsObsoleteTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_COLON_WITH_EQUALS;

  Future<void> test_defaultFormalParameter() async {
    await resolveTestCode('''
void f({int x : 0}) {}
''');
    await assertHasFix('''
void f({int x = 0}) {}
''');
  }

  Future<void> test_superFormalParameter() async {
    await resolveTestCode('''
class A {
  String? a;
  A({this.a});
}
class B extends A {
  B({super.a: ''});
}
''');
    await assertHasFix('''
class A {
  String? a;
  A({this.a});
}
class B extends A {
  B({super.a = ''});
}
''');
  }
}
