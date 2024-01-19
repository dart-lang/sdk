// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateConstructorTest);
    defineReflectiveTests(CreateConstructorMixinTest);
  });
}

@reflectiveTest
class CreateConstructorMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR;

  Future<void> test_named() async {
    await resolveTestCode('''
mixin M {}

void f() {
  new M.named();
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class CreateConstructorTest extends FixProcessorTest {
  static final _text200 = 'x' * 200;

  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR;

  Future<void> test_inLibrary_insteadOfSyntheticDefault() async {
    var a = newFile('$testPackageLibPath/a.dart', '''
/// $_text200
class A {}
''').path;
    await resolveTestCode('''
import 'a.dart';

void f() {
  new A.named(1, 2.0);
}
''');
    await assertHasFix('''
/// $_text200
class A {
  A.named(int i, double d);
}
''', target: a);
  }

  Future<void> test_inLibrary_named() async {
    var a = newFile('$testPackageLibPath/a.dart', '''
/// $_text200
class A {}
''').path;
    await resolveTestCode('''
import 'a.dart';

void f() {
  new A(1, 2.0);
}
''');
    await assertHasFix('''
/// $_text200
class A {
  A(int i, double d);
}
''', target: a);
  }

  Future<void> test_inPart_partOfName_noLibrary() async {
    await resolveTestCode('''
part of my_lib;

class A {}

void f() {
  A(0);
}
''');
    await assertNoFix();
  }

  Future<void> test_insteadOfSyntheticDefault() async {
    await resolveTestCode('''
class A {
  int field = 0;

  method() {}
}
void f() {
  new A(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  int field = 0;

  A(int i, double d);

  method() {}
}
void f() {
  new A(1, 2.0);
}
''');
  }

  Future<void> test_mixin() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
mixin M {}
void f() {
  new M(3);
}
''');
    await assertNoFix();
  }

  Future<void> test_named() async {
    await resolveTestCode('''
class A {
  method() {}
}
void f() {
  new A.named(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  A.named(int i, double d);

  method() {}
}
void f() {
  new A.named(1, 2.0);
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['named(int ', 'named(1']);
  }

  Future<void> test_named_emptyClassBody() async {
    await resolveTestCode('''
class A {}
void f() {
  new A.named(1);
}
''');
    await assertHasFix('''
class A {
  A.named(int i);
}
void f() {
  new A.named(1);
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['named(int ', 'named(1']);
  }

  Future<void> test_undefined_enum_constructor_named() async {
    await resolveTestCode('''
enum E {
  c.x();
  const E.y();
}
''');
    await assertHasFix('''
enum E {
  c.x();
  const E.y();

  const E.x();
}
''', matchFixMessage: "Create constructor 'E.x'");
  }

  Future<void> test_undefined_enum_constructor_unnamed() async {
    await resolveTestCode('''
enum E {
  c;
  const E.x();
}
''');
    await assertHasFix('''
enum E {
  c;
  const E.x();

  const E();
}
''', matchFixMessage: "Create constructor 'E'");
  }

  Future<void> test_undefined_enum_constructor_unnamed_parameters() async {
    await resolveTestCode('''
enum E {
  c(1);
  const E.x();
}
''');
    await assertHasFix('''
enum E {
  c(1);
  const E.x();

  const E(int i);
}
''');
  }
}
