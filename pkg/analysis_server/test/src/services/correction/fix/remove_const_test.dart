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
