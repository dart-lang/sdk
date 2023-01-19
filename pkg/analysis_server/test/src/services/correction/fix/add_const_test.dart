// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddConst_NonConstGenerativeEnumConstructorTest);
    defineReflectiveTests(AddConst_PatternExpressionMustBeValidConst);
    defineReflectiveTests(AddConst_PreferConstConstructorsInImmutablesBulkTest);
    defineReflectiveTests(AddConst_PreferConstConstructorsInImmutablesTest);
    defineReflectiveTests(AddConst_PreferConstConstructorsBulkTest);
    defineReflectiveTests(AddConst_PreferConstConstructorsTest);
    defineReflectiveTests(
        AddConst_PreferConstLiteralsToCreateImmutablesBulkTest);
    defineReflectiveTests(AddConst_PreferConstLiteralsToCreateImmutablesTest);
  });
}

@reflectiveTest
class AddConst_NonConstGenerativeEnumConstructorTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_CONST;

  Future<void> test_named() async {
    await resolveTestCode('''
enum E {
  v.named();
  E.named();
}
''');
    await assertHasFix('''
enum E {
  v.named();
  const E.named();
}
''');
  }

  Future<void> test_unnamed() async {
    await resolveTestCode('''
enum E {
  v;
  E();
}
''');
    await assertHasFix('''
enum E {
  v;
  const E();
}
''');
  }
}

@reflectiveTest
class AddConst_PatternExpressionMustBeValidConst extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_CONST;

  @FailingTest(reason: "TODO(keertip): Add support in FixProcessor")
  Future<void> test_caseConst() async {
    await resolveTestCode('''
void f() {
  var m = 5;
  var x = 1;
  switch(m) {
    case x: break;
  }
''');

    await assertHasFix('''
void f() {
  var m = 5;
  const x = 1;
  switch(m) {
    case x: break;
  }
''');
  }

  @FailingTest(
      issue: "https://github.com/dart-lang/sdk/issues/50996",
      reason: "Waiting on issue to be resolved")
  Future<void> test_caseConstExpression() async {
    await resolveTestCode('''
void f() {
  var m = 5;
  switch(m) {
    case (5 * 5): break;
  }
''');

    await assertHasFix('''
void f() {
  var m = 5;
  switch(m) {
    case const (5 * 5): break;
  }
''');
  }

  @FailingTest(
      issue: "https://github.com/dart-lang/sdk/issues/50947",
      reason: "Waiting on issue to be resolved")
  Future<void> test_caseListConstExpression() async {
    await resolveTestCode('''
class A {}
void f() {
  var m = 5;
  switch(m) {
    case const List<A>: break;
  }
''');

    await assertHasFix('''
class A {}
void f() {
  var m = 5;
  switch(m) {
    case List<A>: break;
  }
''');
  }
}

@reflectiveTest
class AddConst_PreferConstConstructorsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_const_constructors;

  Future<void> test_noKeyword() async {
    writeTestPackageConfig(meta: true);
    await resolveTestCode(r'''
class C {
  const C([C c]);
}
var c = C(C());
''');
    await assertHasFix(r'''
class C {
  const C([C c]);
}
var c = const C(C());
''');
  }
}

@reflectiveTest
class AddConst_PreferConstConstructorsInImmutablesBulkTest
    extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_const_constructors_in_immutables;

  Future<void> test_multipleConstructors() async {
    writeTestPackageConfig(meta: true);
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class A {
  A();
  /// Comment.
  A.a();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class A {
  const A();
  /// Comment.
  const A.a();
}
''');
  }
}

@reflectiveTest
class AddConst_PreferConstConstructorsInImmutablesTest
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_CONST;

  @override
  String get lintCode => LintNames.prefer_const_constructors_in_immutables;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      meta: true,
    );
  }

  Future<void> test_default() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class A {
  A();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class A {
  const A();
}
''');
  }

  Future<void> test_default_withComment() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class A {
  /// Comment.
  A();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class A {
  /// Comment.
  const A();
}
''');
  }
}

@reflectiveTest
class AddConst_PreferConstConstructorsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_CONST;

  @override
  String get lintCode => LintNames.prefer_const_constructors;

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
    // handled by REPLACE_NEW_WITH_CONST
    await assertNoFix();
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

  Future<void> test_withConstList() async {
    await resolveTestCode('''
class C {
  const C(List<int> l);
}
void f() {
  var c = C(const <int>[]);
  print(c);
}
''');
    await assertHasFix('''
class C {
  const C(List<int> l);
}
void f() {
  var c = const C(<int>[]);
  print(c);
}
''');
  }
}

@reflectiveTest
class AddConst_PreferConstLiteralsToCreateImmutablesBulkTest
    extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_const_literals_to_create_immutables;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      meta: true,
    );
  }

  Future<void> test_map() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class C {
  final Map children;
  const C({required this.children});
}
void f() {
  var c = C(children: {
    1 : {}
  });
  print(c);
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class C {
  final Map children;
  const C({required this.children});
}
void f() {
  var c = C(children: const {
    1 : const {}
  });
  print(c);
}
''');
  }
}

@reflectiveTest
class AddConst_PreferConstLiteralsToCreateImmutablesTest
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_CONST;

  @override
  String get lintCode => LintNames.prefer_const_literals_to_create_immutables;
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      meta: true,
    );
  }

  Future<void> test_list() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class C {
  final List<C> children;
  const C({required this.children});
}
void f() {
  var c = C(children: []);
  print(c);
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class C {
  final List<C> children;
  const C({required this.children});
}
void f() {
  var c = C(children: const []);
  print(c);
}
''');
  }

  Future<void> test_list_list() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class C {
  const C(List<C> children);
}
C c = C([C(const [])]);
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class C {
  const C(List<C> children);
}
C c = C(const [C([])]);
''');
  }

  Future<void> test_map() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class C {
  final Map children;
  const C({required this.children});
}
void f() {
  var c = C(children: {});
  print(c);
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class C {
  final Map children;
  const C({required this.children});
}
void f() {
  var c = C(children: const {});
  print(c);
}
''');
  }

  Future<void> test_map_map() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class C {
  const C(Map<String, C> children);
}
C c = C({'c': C(const {})});
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class C {
  const C(Map<String, C> children);
}
C c = C(const {'c': C({})});
''');
  }

  Future<void> test_set() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class C {
  final Set<C> children;
  const C({required this.children});
}
void f() {
  var c = C(children: {});
  print(c);
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class C {
  final Set<C> children;
  const C({required this.children});
}
void f() {
  var c = C(children: const {});
  print(c);
}
''');
  }

  Future<void> test_set_set() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class C {
  const C(Set<C> children);
}
C c = C({C(const {})});
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class C {
  const C(Set<C> children);
}
C c = C(const {C({})});
''');
  }
}
