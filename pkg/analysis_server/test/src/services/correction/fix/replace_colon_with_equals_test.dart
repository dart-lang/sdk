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
  FixKind get kind => DartFixKind.replaceColonWithEquals;

  @override
  String get testPackageLanguageVersion => '2.19';

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

  Future<void> test_wrongSeparatorForPositionalParameter() async {
    await resolveTestCode('''
void f(int a, [int b : 0]) {}
''');
    await assertHasFix('''
void f(int a, [int b = 0]) {}
''');
  }
}

@reflectiveTest
class ReplaceColonWithEqualsObsoleteTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.replaceColonWithEquals;

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
