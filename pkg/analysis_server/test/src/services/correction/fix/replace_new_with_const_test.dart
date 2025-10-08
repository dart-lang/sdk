// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceNewWithConstBulkTest);
    defineReflectiveTests(ReplaceNewWithConstTest);
  });
}

@reflectiveTest
class ReplaceNewWithConstBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_const_constructors;

  Future<void> test_singleFile() async {
    await resolveTestCode(r'''
class A {
  const A();
}
void f() {
  var a = new A();
  var b = new A();
}
''');
    await assertHasFix(r'''
class A {
  const A();
}
void f() {
  var a = const A();
  var b = const A();
}
''');
  }

  Future<void> test_singleFile_incomplete_promotableNew() async {
    await resolveTestCode(r'''
class A {
  const A({A? parent});
  const A.a();
}
void f() {
  var a = new A(
    parent: new A(),
  );
}
''');
    // The outer new should get promoted to const on a future fix pass.
    await assertHasFix(r'''
class A {
  const A({A? parent});
  const A.a();
}
void f() {
  var a = new A(
    parent: const A(),
  );
}
''');
  }

  Future<void> test_singleFile_incomplete_unnecessaryConst() async {
    await resolveTestCode(r'''
class A {
  const A({A? parent});
  const A.a();
}
void f() {
  var b = new A(
    parent: const A.a(),
  );
}
''');
    // The inner const is unnecessary and should get removed on a future fix pass.
    await assertHasFix(r'''
class A {
  const A({A? parent});
  const A.a();
}
void f() {
  var b = const A(
    parent: const A.a(),
  );
}
''');
  }
}

@reflectiveTest
class ReplaceNewWithConstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceNewWithConst;

  @override
  String get lintCode => LintNames.prefer_const_constructors;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_new() async {
    await resolveTestCode('''
class C {
  const C();
}
void f() {
  var c = new C();
  print(c);
}
''');
    await assertHasFix('''
class C {
  const C();
}
void f() {
  var c = const C();
  print(c);
}
''');
  }

  Future<void> test_noKeyword() async {
    await resolveTestCode('''
class C {
  const C();
}
void f() {
  var c = C();
  print(c);
}
''');
    // handled by ADD_CONST
    await assertNoFix();
  }

  Future<void> test_nonConstCallToLiteralConstructorUsingNew() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
var a = new A();
''');
    await assertHasFix('''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
var a = const A();
''');
  }
}
