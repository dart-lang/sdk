// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnusedLocalVariableTest);
  });
}

@reflectiveTest
class RemoveUnusedLocalVariableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_LOCAL_VARIABLE;

  Future<void> test_inArgumentList() async {
    await resolveTestCode(r'''
main() {
  var v = 1;
  print(v = 2);
}
''');
    await assertHasFix(r'''
main() {
  print(2);
}
''');
  }

  Future<void> test_inArgumentList2() async {
    await resolveTestCode(r'''
main() {
  var v = 1;
  f(v = 1, 2);
}
void f(a, b) { }
''');
    await assertHasFix(r'''
main() {
  f(1, 2);
}
void f(a, b) { }
''');
  }

  Future<void> test_inArgumentList3() async {
    await resolveTestCode(r'''
main() {
  var v = 1;
  f(v = 1, v = 2);
}
void f(a, b) { }
''');
    await assertHasFix(r'''
main() {
  f(1, 2);
}
void f(a, b) { }
''');
  }

  Future<void> test_inDeclarationList() async {
    await resolveTestCode(r'''
main() {
  var v = 1, v2 = 3;
  v = 2;
  print(v2);
}
''');
    await assertHasFix(r'''
main() {
  var v2 = 3;
  print(v2);
}
''');
  }

  Future<void> test_inDeclarationList2() async {
    await resolveTestCode(r'''
main() {
  var v = 1, v2 = 3;
  print(v);
}
''');
    await assertHasFix(r'''
main() {
  var v = 1;
  print(v);
}
''');
  }

  Future<void> test_notInFunctionBody() async {
    await resolveTestCode(r'''
var a = [for (var v = 0;;) 0];
''');
    await assertNoFix();
  }

  Future<void> test_withReferences() async {
    await resolveTestCode(r'''
main() {
  var v = 1;
  v = 2;
}
''');
    await assertHasFix(r'''
main() {
}
''');
  }

  Future<void> test_withReferences_beforeDeclaration() async {
    // CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION
    verifyNoTestUnitErrors = false;
    await resolveTestCode(r'''
main() {
  v = 2;
  var v = 1;
}
''');
    await assertHasFix(r'''
main() {
}
''',
        errorFilter: (e) =>
            e.errorCode != CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION);
  }
}
