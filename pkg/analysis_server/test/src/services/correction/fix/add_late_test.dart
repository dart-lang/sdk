// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddLateTest);
  });
}

@reflectiveTest
class AddLateTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addLate;

  Future<void> test_changeInImportedLib() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {
  final String s;
}
''');
    await resolveTestCode('''
import 'a.dart';

void f(C c) {
  c.s = '';
}
''');
    await assertNoFix();
  }

  Future<void> test_changeInPart() async {
    newFile('$testPackageLibPath/a.dart', '''
part 'test.dart';

class C {
  final String s;
}
''');
    await resolveTestCode('''
part of 'a.dart';

void f(C c) {
  c.s = '';
}
''');
    await assertNoFix();
  }

  Future<void> test_final_implicitThis() async {
    await resolveTestCode('''
class A {
  final int v;
  final bool isEven = v.isEven;
  A(this.v);
}
''');
    await assertHasFix('''
class A {
  final int v;
  late final bool isEven = v.isEven;
  A(this.v);
}
''');
  }

  Future<void> test_type_implicitThis() async {
    await resolveTestCode('''
class A {
  final int v;
  bool isEven = v.isEven;
  A(this.v);
}
''');
    await assertHasFix('''
class A {
  final int v;
  late bool isEven = v.isEven;
  A(this.v);
}
''');
  }

  Future<void> test_var_implicitThis() async {
    await resolveTestCode('''
class A {
  final int v;
  var isEven = v.isEven;
  A(this.v);
}
''');
    await assertHasFix('''
class A {
  final int v;
  late var isEven = v.isEven;
  A(this.v);
}
''');
  }

  Future<void> test_withFinal() async {
    await resolveTestCode('''
class C {
  final String s;
}
''');
    await assertHasFix('''
class C {
  late final String s;
}
''');
  }

  Future<void> test_withFinalAssignedInConstructor() async {
    await resolveTestCode('''
class C {
  final String s;
  C() {
    s = '';
  }
}
''');
    await assertHasFix('''
class C {
  late final String s;
  C() {
    s = '';
  }
}
''', filter: (error) => error.diagnosticCode == diag.assignmentToFinal);
  }

  Future<void> test_withFinalAssignedInDeclaration() async {
    await resolveTestCode('''
class C {
  late final String s = '';
}

void f(C c) {
  c.s = '';
}
''');
    await assertNoFix();
  }

  Future<void> test_withFinalAssignedInLibrary() async {
    await resolveTestCode('''
class C {
  final String s;
}

void f(C c) {
  c.s = '';
}
''');
    await assertHasFix('''
class C {
  late final String s;
}

void f(C c) {
  c.s = '';
}
''', filter: (error) => error.diagnosticCode == diag.assignmentToFinal);
  }

  Future<void> test_withFinalStaticAssignedInConstructor() async {
    await resolveTestCode('''
class C {
  static final String s;
  C() {
    s = '';
  }
}
''');
    await assertHasFix('''
class C {
  static late final String s;
  C() {
    s = '';
  }
}
''', filter: (error) => error.diagnosticCode == diag.assignmentToFinal);
  }

  Future<void> test_withLate() async {
    await resolveTestCode('''
class C {
  late s;
}
''');
    await assertNoFix();
  }

  Future<void> test_withType() async {
    await resolveTestCode('''
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
