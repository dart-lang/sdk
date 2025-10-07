// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateLocalVariableTest);
  });
}

@reflectiveTest
class CreateLocalVariableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createLocalVariable;

  Future<void> test_functionType_named() async {
    await resolveTestCode('''
typedef MY_FUNCTION(int p);
foo(MY_FUNCTION f) {}
void f() {
  foo(bar);
}
''');
    await assertHasFix('''
typedef MY_FUNCTION(int p);
foo(MY_FUNCTION f) {}
void f() {
  MY_FUNCTION bar;
  foo(bar);
}
''');
  }

  Future<void> test_functionType_named_generic() async {
    await resolveTestCode('''
typedef MY_FUNCTION<T>(T p);
foo(MY_FUNCTION<int> f) {}
void f() {
  foo(bar);
}
''');
    await assertHasFix('''
typedef MY_FUNCTION<T>(T p);
foo(MY_FUNCTION<int> f) {}
void f() {
  MY_FUNCTION<int> bar;
  foo(bar);
}
''');
  }

  Future<void> test_functionType_recordType() async {
    await resolveTestCode('''
void g((int, String) f) {}
void f() {
  g(x);
}
''');
    await assertHasFix('''
void g((int, String) f) {}
void f() {
  (int, String) x;
  g(x);
}
''');
  }

  Future<void> test_functionType_synthetic() async {
    await resolveTestCode('''
foo(f(int p)) {}
void f() {
  foo(bar);
}
''');
    await assertHasFix('''
foo(f(int p)) {}
void f() {
  Function(int p) bar;
  foo(bar);
}
''');
  }

  Future<void> test_read_prefixedIdentifier_identifier() async {
    await resolveTestCode('''
void f(C c) {
  c.test;
}

class C {}
''');
    await assertNoFix();
  }

  Future<void> test_read_prefixedIdentifier_prefix() async {
    await resolveTestCode('''
void f() {
  test.foo;
}
''');
    await assertNoFix();
  }

  Future<void> test_read_propertyAccess_propertyName() async {
    await resolveTestCode('''
void f(C c) {
  (c).test;
}

class C {}
''');
    await assertNoFix();
  }

  Future<void> test_read_typeAssignment() async {
    await resolveTestCode('''
void f() {
  int a = test;
  print(a);
}
''');
    await assertHasFix('''
void f() {
  int test;
  int a = test;
  print(a);
}
''');
  }

  Future<void> test_read_typeAssignment_recordType() async {
    await resolveTestCode('''
void f() {
  (int, int) a = b;
  print(a);
}
''');
    await assertHasFix('''
void f() {
  (int, int) b;
  (int, int) a = b;
  print(a);
}
''');
  }

  Future<void> test_read_typeCondition() async {
    await resolveTestCode('''
void f() {
  if (!test) {
    print(42);
  }
}
''');
    await assertHasFix('''
void f() {
  bool test;
  if (!test) {
    print(42);
  }
}
''');
  }

  Future<void> test_read_typeInvocationArgument() async {
    await resolveTestCode('''
void f() {
  g(test);
}
g(String p) {}
''');
    await assertHasFix('''
void f() {
  String test;
  g(test);
}
g(String p) {}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['String test;']);
    assertLinkedGroup(change.linkedEditGroups[1], ['test;', 'test);']);
  }

  Future<void> test_read_typeInvocationArgument_recordType() async {
    await resolveTestCode('''
void f() {
  g(x);
}
g((int, int) r) {}
''');
    await assertHasFix('''
void f() {
  (int, int) x;
  g(x);
}
g((int, int) r) {}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['(int, int) x;']);
    assertLinkedGroup(change.linkedEditGroups[1], ['x;', 'x);']);
  }

  Future<void> test_read_typeInvocationTarget() async {
    await resolveTestCode('''
void f() {
  test.add('hello');
}
''');
    await assertHasFix('''
void f() {
  var test;
  test.add('hello');
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['test;', 'test.add(']);
  }

  Future<void> test_withImport() async {
    newFile('$workspaceRootPath/pkg/lib/a/a.dart', '''
class A {}
''');
    newFile('$workspaceRootPath/pkg/lib/b/b.dart', '''
class B {}
''');
    newFile('$workspaceRootPath/pkg/lib/c/c.dart', '''
import 'package:pkg/a/a.dart';
import 'package:pkg/b/b.dart';

class C {
  C(A? a, B b);
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await resolveTestCode('''
import 'package:pkg/a/a.dart';
import 'package:pkg/c/c.dart';

void f() {
  A? a;
  new C(a, b);
}
''');
    await assertHasFix('''
import 'package:pkg/a/a.dart';
import 'package:pkg/b/b.dart';
import 'package:pkg/c/c.dart';

void f() {
  A? a;
  /*0*/B /*1*/b;
  new C(a, /*2*/b);
}
''');
    var groups = change.linkedEditGroups;
    expect(groups, hasLength(2));
    var typeGroup = groups[0];
    var typePositions = typeGroup.positions;
    expect(typePositions, hasLength(1));
    expect(typePositions[0].offset, parsedExpectedCode.positions[0].offset);
    var nameGroup = groups[1];
    var groupPositions = nameGroup.positions;
    expect(groupPositions, hasLength(2));
    expect(groupPositions[0].offset, parsedExpectedCode.positions[1].offset);
    expect(groupPositions[1].offset, parsedExpectedCode.positions[2].offset);
  }

  Future<void> test_write_assignment() async {
    await resolveTestCode('''
void f() {
  test = 42;
}
''');
    await assertHasFix('''
void f() {
  var test = 42;
}
''');
  }

  Future<void> test_write_assignment_compound() async {
    await resolveTestCode('''
void f() {
  test += 42;
}
''');
    await assertHasFix('''
void f() {
  int test;
  test += 42;
}
''');
  }

  Future<void> test_write_prefixedIdentifier_identifier() async {
    await resolveTestCode('''
void f(C c) {
  c.test = 0;
}

class C {}
''');
    await assertNoFix();
  }

  Future<void> test_write_prefixedIdentifier_prefix() async {
    await resolveTestCode('''
void f() {
  test.foo = 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_write_propertyAccess_propertyName() async {
    await resolveTestCode('''
void f(C c) {
  (c).test = 0;
}

class C {}
''');
    await assertNoFix();
  }
}
