// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportAddShowTest);
  });
}

@reflectiveTest
class ImportAddShowTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.IMPORT_ADD_SHOW;

  Future<void> test_aliased() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  C operator +(C c) => this;
}
''');
    await resolveTestCode('''
import 'lib.dart' as l;

void f(l.C c) => c + c;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' as l show C, E;

void f(l.C c) => c + c;
''');
  }

  Future<void> test_extensionBinaryOperator() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  C operator +(C c) => this;
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c + c;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c + c;
''');
  }

  Future<void> test_extensionCallableEnabled() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  void call() {}
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c();
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c();
''');
  }

  Future<void> test_extensionGetter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  int get f => 7;
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c.f;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c.f;
''');
  }

  Future<void> test_extensionGetter_asPropertyAccess() async {
    newFile('$testPackageLibPath/lib.dart', '''
abstract class C {
  C get c;
}

extension E on C {
  int get f => 7;
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c.c.f;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c.c.f;
''');
  }

  Future<void> test_extensionGetter_inObjectPattern() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  int get f => 7;
}
''');
    await resolveTestCode('''
import 'lib.dart';

int f(C c) => switch (c) {
  C(:var f) => f,
};
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

int f(C c) => switch (c) {
  C(:var f) => f,
};
''');
  }

  Future<void> test_extensionGetter_inVariableDeclarationPattern() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  int get f => 7;
}
''');
    await resolveTestCode('''
import 'lib.dart';

int f(C c) {
  var C(:f) = c;
  return f;
}
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

int f(C c) {
  var C(:f) = c;
  return f;
}
''');
  }

  Future<void> test_extensionIndexOperator() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  int operator [](int index) => 7;
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c[7];
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c[7];
''');
  }

  Future<void> test_extensionIndexOperator_assignment() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  int operator []=(int index, int value) => 7;
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c[7] = 6;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c[7] = 6;
''');
  }

  Future<void> test_extensionMethod() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  void m() {}
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c.m();
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c.m();
''');
  }

  Future<void> test_extensionMethod_inCascade() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {
  void m() {}
}

extension E on C {
  void n() {}
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c..m()..n();
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c..m()..n();
''');
  }

  Future<void> test_extensionSetter_combo() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  int get f => 7;
  set f(int value) {}
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c.f += 7;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c.f += 7;
''');
  }

  Future<void> test_extensionSetter_nullAware() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  int? get f => 7;
  set f(int value) {}
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c.f ??= 7;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c.f ??= 7;
''');
  }

  Future<void> test_extensionSetter_simpleAssignment() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  set f(int value) {}
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => c.f = 7;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => c.f = 7;
''');
  }

  Future<void> test_extensionUnaryOperator() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  int operator ~() => 7;
}
''');
    await resolveTestCode('''
import 'lib.dart';

void f(C c) => ~c;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show C, E;

void f(C c) => ~c;
''');
  }

  Future<void> test_hasShow() async {
    await resolveTestCode('''
import 'dart:math' show pi;
void f() {
  pi;
}
''');
    await assertNoAssistAt('import ');
  }

  Future<void> test_hasUnresolvedIdentifier() async {
    await resolveTestCode('''
import 'dart:math';
void f(x) {
  pi;
  return x.foo();
}
''');
    await assertHasAssistAt('import ', '''
import 'dart:math' show pi;
void f(x) {
  pi;
  return x.foo();
}
''');
  }

  Future<void> test_mixinOnDirective() async {
    newFile('$testPackageLibPath/lib.dart', '''
mixin M {}
''');
    await resolveTestCode('''
import 'lib.dart';
void f(M m) {}
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show M;
void f(M m) {}
''');
  }

  Future<void> test_onDirective() async {
    await resolveTestCode('''
import 'dart:math';
void f() {
  pi;
  e;
  max(1, 2);
}
''');
    await assertHasAssistAt('import ', '''
import 'dart:math' show e, max, pi;
void f() {
  pi;
  e;
  max(1, 2);
}
''');
  }

  Future<void> test_onUri() async {
    await resolveTestCode('''
import 'dart:math';
void f() {
  pi;
  e;
  max(1, 2);
}
''');
    await assertHasAssistAt('art:math', '''
import 'dart:math' show e, max, pi;
void f() {
  pi;
  e;
  max(1, 2);
}
''');
  }

  Future<void> test_setter() async {
    newFile('$testPackageLibPath/lib.dart', '''
set s(int value) {}
''');
    await resolveTestCode('''
import 'lib.dart';

void f() => s = 7;
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show s;

void f() => s = 7;
''');
  }

  Future<void> test_setter_onDirective() async {
    newFile('$testPackageLibPath/a.dart', r'''
void set setter(int i) {}
''');
    await resolveTestCode('''
import 'a.dart';

void f() {
  setter = 42;
}
''');
    await assertHasAssistAt('import ', '''
import 'a.dart' show setter;

void f() {
  setter = 42;
}
''');
  }

  Future<void> test_typedefOnDirective() async {
    newFile('$testPackageLibPath/lib.dart', '''
typedef Cb = void Function();
''');
    await resolveTestCode('''
import 'lib.dart';
void f(Cb cb) {}
''');
    await assertHasAssistAt('import ', '''
import 'lib.dart' show Cb;
void f(Cb cb) {}
''');
  }

  Future<void> test_unresolvedUri() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import '/no/such/lib.dart';
''');
    await assertNoAssistAt('import ');
  }

  Future<void> test_unused() async {
    await resolveTestCode('''
import 'dart:math';
''');
    await assertNoAssistAt('import ');
  }
}
