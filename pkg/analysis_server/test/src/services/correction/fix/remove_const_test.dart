// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveConstTest);
  });
}

@reflectiveTest
class RemoveConstTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_constClass_firstClass() async {
    await resolveTestCode('''
const class C {}
''');
    await assertHasFix('''
class C {}
''');
  }

  Future<void> test_constClass_secondClass() async {
    await resolveTestCode('''
class A {}
const class B {}
''');
    await assertHasFix('''
class A {}
class B {}
''');
  }

  Future<void> test_constClass_withComment() async {
    await resolveTestCode('''
/// Comment.
const class C {}
''');
    await assertHasFix('''
/// Comment.
class C {}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49818')
  Future<void> test_constInitializedWithNonConstantValue() async {
    await resolveTestCode('''
var x = 0;
const y = x;
''');
    await assertHasFix('''
var x = 0;
final y = x;
''');
  }

  Future<void> test_explicitConst() async {
    await resolveTestCode('''
class A {
  A();
}
void f() {
  var a = const A();
  print(a);
}
''');
    await assertHasFix('''
class A {
  A();
}
void f() {
  var a = A();
  print(a);
}
''');
  }

  Future<void> test_implicitConst() async {
    await resolveTestCode('''
class A {
  A();
}
void f() {
  const a = A();
  print(a);
}
''');
    await assertNoFix(
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }
}
