// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeVariableNullableTest);
  });
}

@reflectiveTest
class MakeVariableNullableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.makeVariableNullable;

  Future<void> test_fieldFormalParameter() async {
    await resolveTestCode('''
class C {
  String? s;
  C({String this.s});
}
''');
    await assertHasFix('''
class C {
  String? s;
  C({String? this.s});
}
''');
  }

  Future<void> test_fieldFormalParameter_functionTyped() async {
    await resolveTestCode('''
class C {
  String Function()? s;
  C({String this.s()});
}
''');
    await assertHasFix('''
class C {
  String Function()? s;
  C({String this.s()?});
}
''');
  }

  Future<void> test_fieldFormalParameter_untyped() async {
    await resolveTestCode('''
class C {
  String s;
  C({this.s});
}
''');
    await assertNoFix();
  }

  Future<void> test_functionTypedFormalParameter() async {
    await resolveTestCode('''
void f({String s()}) {}
''');
    await assertHasFix('''
void f({String s()?}) {}
''');
  }

  Future<void> test_lhsNotIdentifier() async {
    await resolveTestCode('''
void f(C c) {
  c.s = null;
}
class C {
  String s = '';
}
''');
    await assertNoFix();
  }

  Future<void> test_lhsNotLocalVariable() async {
    await resolveTestCode('''
var s = '';
void f() {
  s = null;
  print(s);
}
''');
    await assertNoFix();
  }

  Future<void> test_localVariable_initializedToNull() async {
    await resolveTestCode('''
void f() {
  String s = null;
  print(s);
}
''');
    await assertHasFix('''
void f() {
  String? s = null;
  print(s);
}
''');
  }

  Future<void> test_localVariable_initializedToNull_recordType() async {
    await resolveTestCode('''
void f() {
  (int, int) r = null;
  print(r);
}
''');
    await assertHasFix('''
void f() {
  (int, int)? r = null;
  print(r);
}
''');
  }

  Future<void> test_localVariable_type() async {
    await resolveTestCode('''
void f() {
  String s = '';
  s = null;
  print(s);
}
''');
    await assertHasFix('''
void f() {
  String? s = '';
  s = null;
  print(s);
}
''');
  }

  Future<void> test_localVariable_type_recordType() async {
    await resolveTestCode('''
void f() {
  ({int x, int y}) r = (x: 0, y: 0);
  r = null;
  print(r);
}
''');
    await assertHasFix('''
void f() {
  ({int x, int y})? r = (x: 0, y: 0);
  r = null;
  print(r);
}
''');
  }

  Future<void> test_localVariable_var() async {
    await resolveTestCode('''
void f() {
  var s = '';
  s = null;
  print(s);
}
''');
    await assertHasFix('''
void f() {
  String? s = '';
  s = null;
  print(s);
}
''');
  }

  Future<void> test_multipleVariables() async {
    await resolveTestCode('''
void f() {
  var s = '', t = '';
  s = null;
  print(s);
  print(t);
}
''');
    await assertNoFix();
  }

  Future<void> test_noKeywordOrType() async {
    await resolveTestCode('''
void f() {
  late var s = '';
  s = null;
  print(s);
}
''');
    await assertHasFix('''
void f() {
  late String? s = '';
  s = null;
  print(s);
}
''');
  }

  Future<void> test_positional() async {
    await resolveTestCode('''
void f([String s]) {}
''');
    await assertHasFix('''
void f([String? s]) {}
''');
  }

  Future<void> test_simpleFormalParameter() async {
    await resolveTestCode('''
void f({String s}) {}
''');
    await assertHasFix('''
void f({String? s}) {}
''');
  }

  Future<void> test_simpleFormalParameter_final() async {
    await resolveTestCode('''
void f({final String s}) {}
''');
    await assertHasFix('''
void f({final String? s}) {}
''');
  }

  Future<void> test_simpleFormalParameter_functionType() async {
    await resolveTestCode('''
void f({String Function() s}) {}
''');
    await assertHasFix('''
void f({String Function()? s}) {}
''');
  }

  Future<void> test_simpleFormalParameter_typeVariable() async {
    await resolveTestCode('''
void f<T>({T s}) {}
''');
    await assertHasFix('''
void f<T>({T? s}) {}
''');
  }

  Future<void> test_superParameter() async {
    await resolveTestCode('''
class C {
  C({String? s});
}
class D extends C {
  D({String super.s});
}
''');
    await assertHasFix('''
class C {
  C({String? s});
}
class D extends C {
  D({String? super.s});
}
''');
  }

  Future<void> test_superParameter_functionTyped() async {
    await resolveTestCode('''
class C {
  C({void s()?});
}
class D extends C {
  D({void super.s()});
}
''');
    await assertHasFix('''
class C {
  C({void s()?});
}
class D extends C {
  D({void super.s()?});
}
''');
  }
}
