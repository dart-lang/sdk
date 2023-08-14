// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingParameterRequiredTest);
    defineReflectiveTests(AddMissingParameterRequiredTest_Workspace);
  });
}

@reflectiveTest
class AddMissingParameterRequiredTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_PARAMETER_REQUIRED;

  Future<void> test_constructor_named_hasOne() async {
    await resolveTestCode('''
class A {
  A.named(int a) {}
}
void f() {
  new A.named(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  A.named(int a, double d) {}
}
void f() {
  new A.named(1, 2.0);
}
''');
  }

  Future<void> test_constructor_unnamed_hasOne() async {
    await resolveTestCode('''
class A {
  A(int a) {}
}
void f() {
  new A(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  A(int a, double d) {}
}
void f() {
  new A(1, 2.0);
}
''');
  }

  Future<void> test_function_hasNamed() async {
    await resolveTestCode('''
test({int a = 0}) {}
void f() {
  test(1);
}
''');
    await assertHasFix('''
test(int i, {int a = 0}) {}
void f() {
  test(1);
}
''');
  }

  Future<void> test_function_hasOne() async {
    await resolveTestCode('''
test(int a) {}
void f() {
  test(1, 2.0);
}
''');
    await assertHasFix('''
test(int a, double d) {}
void f() {
  test(1, 2.0);
}
''');
  }

  Future<void> test_function_hasZero() async {
    await resolveTestCode('''
test() {}
void f() {
  test(1);
}
''');
    await assertHasFix('''
test(int i) {}
void f() {
  test(1);
}
''');
  }

  Future<void> test_function_hasZero_partOfName_noLibrary() async {
    await resolveTestCode('''
part of my_lib;
test() {}
void f() {
  test(1);
}
''');
    await assertNoFix();
  }

  Future<void> test_method_hasOne() async {
    await resolveTestCode('''
class A {
  test(int a) {}
  void f() {
    test(1, 2.0);
  }
}
''');
    await assertHasFix('''
class A {
  test(int a, double d) {}
  void f() {
    test(1, 2.0);
  }
}
''');
  }

  Future<void> test_method_hasZero() async {
    await resolveTestCode('''
class A {
  test() {}
  void f() {
    test(1);
  }
}
''');
    await assertHasFix('''
class A {
  test(int i) {}
  void f() {
    test(1);
  }
}
''');
  }
}

@reflectiveTest
class AddMissingParameterRequiredTest_Workspace
    extends AddMissingParameterRequiredTest {
  ChangeWorkspace? _workspace;

  @override
  Future<ChangeWorkspace> get workspace async {
    return _workspace ?? await super.workspace;
  }

  Future<void> test_function_inPackage_inWorkspace() async {
    final a = newFile('/home/aaa/lib/a.dart', 'void test() {}');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );

    _workspace = DartChangeWorkspace([
      await session,
      await sessionFor(a),
    ]);

    await resolveTestCode('''
import 'package:aaa/a.dart';

void f() {
  test(42);
}
''');

    await assertHasFix(
      'void test(int i) {}',
      target: '/home/aaa/lib/a.dart',
    );
  }

  Future<void> test_function_inPackage_outsideWorkspace() async {
    newFile('/home/bbb/lib/b.dart', 'void test() {}');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb'),
    );

    await resolveTestCode('''
import 'package:bbb/b.dart';

void f() {
  test(42);
}
''');
    await assertNoFix();
  }

  Future<void> test_method_inSdk() async {
    await resolveTestCode('''
void f() {
  42.abs(true);
}
''');
    await assertNoFix();
  }
}
