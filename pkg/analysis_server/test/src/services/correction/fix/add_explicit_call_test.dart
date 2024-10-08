// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddExplicitCallBulkTest);
    defineReflectiveTests(AddExplicitCallTest);
  });
}

@reflectiveTest
class AddExplicitCallBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.implicit_call_tearoffs;

  Future<void> test_singleFile() async {
    await resolveTestCode(r'''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() async {
  f(C());
  var c = Future.value(C());
  f(await c);
}
''');
    await assertHasFix(r'''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() async {
  f(C().call);
  var c = Future.value(C());
  f((await c).call);
}
''');
  }
}

@reflectiveTest
class AddExplicitCallTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_EXPLICIT_CALL;

  @override
  String get lintCode => LintNames.implicit_call_tearoffs;

  Future<void> test_passAwait() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() async {
  var c = Future.value(C());
  f(await c);
}
''');
    await assertHasFix('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() async {
  var c = Future.value(C());
  f((await c).call);
}
''');
  }

  Future<void> test_passCascade() async {
    await resolveTestCode('''
class C {
  void call() {}
  void something() {}
}
void f(void Function() a) {}
void g() {
  f(C()..something());
}
''');
    await assertHasFix('''
class C {
  void call() {}
  void something() {}
}
void f(void Function() a) {}
void g() {
  f((C()..something()).call);
}
''');
  }

  Future<void> test_passCast() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() {
  dynamic c = C();
  f(c as C);
}
''');
    await assertHasFix('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() {
  dynamic c = C();
  f((c as C).call);
}
''');
  }

  Future<void> test_passIndexed() async {
    await resolveTestCode('''
class C {
  void call() {}
}
class C2 {
  C operator [](int _) => C();
}
void f(void Function() a) {}
void g() {
  f(C2()[0]);
}
''');
    await assertHasFix('''
class C {
  void call() {}
}
class C2 {
  C operator [](int _) => C();
}
void f(void Function() a) {}
void g() {
  f(C2()[0].call);
}
''');
  }

  Future<void> test_passInList() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void f(List<void Function()> a) {}
void g() {
  f([C()]);
}
''');
    await assertHasFix('''
class C {
  void call() {}
}
void f(List<void Function()> a) {}
void g() {
  f([C().call]);
}
''');
  }

  Future<void> test_passInstanceCreation() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() {
  f(C());
}
''');
    await assertHasFix('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() {
  f(C().call);
}
''');
  }

  Future<void> test_passMethodInvocation() async {
    await resolveTestCode('''
class C {
  void call() {}
}
class C2 {
  C something() => C();
}
void f(void Function() a) {}
void g() {
  f(C2().something());
}
''');
    await assertHasFix('''
class C {
  void call() {}
}
class C2 {
  C something() => C();
}
void f(void Function() a) {}
void g() {
  f(C2().something().call);
}
''');
  }

  Future<void> test_passNullFallback() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() {
  C? c1;
  C c2= C();
  f(c1 ?? c2);
}
''');
    await assertHasFix('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() {
  C? c1;
  C c2= C();
  f((c1 ?? c2).call);
}
''');
  }

  Future<void> test_passVariable() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() {
  var c = C();
  f(c);
}
''');
    await assertHasFix('''
class C {
  void call() {}
}
void f(void Function() a) {}
void g() {
  var c = C();
  f(c.call);
}
''');
  }

  Future<void> test_passWithExplicitGeneric() async {
    await resolveTestCode('''
class C {
  void call<T>(T arg) {}
}
void f(void Function(int) a) {}
void g() {
  f(C()<int>);
}
''');
    await assertHasFix('''
class C {
  void call<T>(T arg) {}
}
void f(void Function(int) a) {}
void g() {
  f(C().call<int>);
}
''');
  }

  Future<void> test_passWithExplicitGenericIdentifier() async {
    await resolveTestCode('''
class C {
  void call<T>(T arg) {}
}
void f(void Function(int) a) {}
void g() {
  C c = C();
  f(c<int>);
}
''');
    await assertHasFix('''
class C {
  void call<T>(T arg) {}
}
void f(void Function(int) a) {}
void g() {
  C c = C();
  f(c.call<int>);
}
''');
  }

  Future<void> test_passWithImplicitGeneric() async {
    await resolveTestCode('''
class C {
  void call<T>(T arg) {}
}
void f(void Function(int) a) {}
void g() {
  f(C());
}
''');
    await assertHasFix('''
class C {
  void call<T>(T arg) {}
}
void f(void Function(int) a) {}
void g() {
  f(C().call);
}
''');
  }

  Future<void> test_passWithImplicitGenericIdentifier() async {
    await resolveTestCode('''
class C {
  void call<T>(T arg) {}
}
void f(void Function(int) a) {}
void g() {
  C c = C();
  f(c);
}
''');
    await assertHasFix('''
class C {
  void call<T>(T arg) {}
}
void f(void Function(int) a) {}
void g() {
  C c = C();
  f(c.call);
}
''');
  }

  Future<void> test_returnArgument() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void Function() f(C c) => c;
''');
    await assertHasFix('''
class C {
  void call() {}
}
void Function() f(C c) => c.call;
''');
  }

  Future<void> test_returnAwait() async {
    await resolveTestCode('''
class C {
  void call() {}
}
Future<void Function()> f(Future<C> c) async => await c;
''');
    await assertHasFix('''
class C {
  void call() {}
}
Future<void Function()> f(Future<C> c) async => (await c).call;
''');
  }

  Future<void> test_returnCascade() async {
    await resolveTestCode('''
class C {
  void call() {}
  void other() {}
}
void Function() f() => C()..other();
''');
    await assertHasFix('''
class C {
  void call() {}
  void other() {}
}
void Function() f() => (C()..other()).call;
''');
  }

  Future<void> test_returnCast() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void Function() f(dynamic c) => c as C;
''');
    await assertHasFix('''
class C {
  void call() {}
}
void Function() f(dynamic c) => (c as C).call;
''');
  }

  Future<void> test_returnIndexed() async {
    await resolveTestCode('''
class C {
  void call() {}
}
class C2 {
  C operator [](int _) => C();
}
void Function() f() => C2()[0];
''');
    await assertHasFix('''
class C {
  void call() {}
}
class C2 {
  C operator [](int _) => C();
}
void Function() f() => C2()[0].call;
''');
  }

  Future<void> test_returnInList() async {
    await resolveTestCode('''
class C {
  void call() {}
}
List<void Function()> f() => [C()];
''');
    await assertHasFix('''
class C {
  void call() {}
}
List<void Function()> f() => [C().call];
''');
  }

  Future<void> test_returnInstanceCreation() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void Function() f() => C();
''');
    await assertHasFix('''
class C {
  void call() {}
}
void Function() f() => C().call;
''');
  }

  Future<void> test_returnMethodInvocation() async {
    await resolveTestCode('''
class C {
  void call() {}
}
class C2 {
  C something() => C();
}
void Function() f() => C2().something();
''');
    await assertHasFix('''
class C {
  void call() {}
}
class C2 {
  C something() => C();
}
void Function() f() => C2().something().call;
''');
  }

  Future<void> test_returnNullFallback() async {
    await resolveTestCode('''
class C {
  void call() {}
}
void Function() f(C? c1, C c2) => c1 ?? c2;
''');
    await assertHasFix('''
class C {
  void call() {}
}
void Function() f(C? c1, C c2) => (c1 ?? c2).call;
''');
  }

  Future<void> test_returnWithExplicitGeneric() async {
    await resolveTestCode('''
class C {
  void call<T>(T arg) {}
}
void Function(int) f() => C()<int>;
''');
    await assertHasFix('''
class C {
  void call<T>(T arg) {}
}
void Function(int) f() => C().call<int>;
''');
  }

  Future<void> test_returnWithExplicitGenericIdentifier() async {
    await resolveTestCode('''
class C {
  void call<T>(T arg) {}
}
void Function(int) f(C c) => c<int>;
''');
    await assertHasFix('''
class C {
  void call<T>(T arg) {}
}
void Function(int) f(C c) => c.call<int>;
''');
  }

  Future<void> test_returnWithImplicitGeneric() async {
    await resolveTestCode('''
class C {
  void call<T>(T arg) {}
}
void Function(int) f() => C();
''');
    await assertHasFix('''
class C {
  void call<T>(T arg) {}
}
void Function(int) f() => C().call;
''');
  }

  Future<void> test_returnWithImplicitGenericIdentifier() async {
    await resolveTestCode('''
class C {
  void call<T>(T arg) {}
}
void Function(int) f(C c) => c;
''');
    await assertHasFix('''
class C {
  void call<T>(T arg) {}
}
void Function(int) f(C c) => c.call;
''');
  }
}
