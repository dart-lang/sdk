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
    defineReflectiveTests(ChangeTypeAnnotationTest);
  });
}

@reflectiveTest
class ChangeTypeAnnotationTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CHANGE_TYPE_ANNOTATION;

  Future<void> test_generic() async {
    await resolveTestCode('''
f() {
  String v = <int>[];
  print(v);
}
''');
    await assertHasFix('''
f() {
  List<int> v = <int>[];
  print(v);
}
''');
  }

  Future<void> test_multipleVariables() async {
    await resolveTestCode('''
f() {
  String a, b = '';
  print('\$a \$b');
}
''');
    await assertNoFix();
  }

  Future<void> test_notVariableDeclaration() async {
    await resolveTestCode('''
f() {
  String v;
  v = 42;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_privateType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  _B b => _B();
}
class _B {}
''');

    await resolveTestCode('''
import 'package:test/a.dart';

f(A a) {
  String v = a.b();
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_recordType_from() async {
    await resolveTestCode(r'''
f() {
  (String, String) v = ('a', 'b').$1;
  print(v);
}
''');
    await assertHasFix(r'''
f() {
  String v = ('a', 'b').$1;
  print(v);
}
''');
  }

  Future<void> test_recordType_to() async {
    await resolveTestCode('''
f() {
  String v = ('a', 'b');
  print(v);
}
''');
    await assertHasFix('''
f() {
  (String, String) v = ('a', 'b');
  print(v);
}
''');
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
f() {
  String v = 'abc'.length;
  print(v);
}
''');
    await assertHasFix('''
f() {
  int v = 'abc'.length;
  print(v);
}
''');
  }

  Future<void> test_synthetic_implicitCast() async {
    createAnalysisOptionsFile(implicitCasts: false);
    await resolveTestCode('''
int foo =
''');
    await assertNoFix(
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.INVALID_ASSIGNMENT;
      },
    );
  }
}
