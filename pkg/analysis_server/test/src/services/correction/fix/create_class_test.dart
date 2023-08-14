// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateClassTest);
  });
}

@reflectiveTest
class CreateClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CLASS;

  Future<void> test_annotation() async {
    await resolveTestCode('''
@Test('a')
void f() {}
''');
    await assertHasFix('''
@Test('a')
void f() {}

class Test {
  const Test(String s);
}
''');
    assertLinkedGroup(
        change.linkedEditGroups[0], ["Test('", 'Test {', 'Test(S']);
  }

  Future<void> test_extends() async {
    await resolveTestCode('''
class MyClass extends BaseClass {}
''');
    await assertHasFix('''
class MyClass extends BaseClass {}

class BaseClass {
}
''');
  }

  Future<void> test_hasUnresolvedPrefix() async {
    await resolveTestCode('''
void f() {
  prefix.Test v = null;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_implements() async {
    await resolveTestCode('''
class MyClass implements BaseClass {}
''');
    await assertHasFix('''
class MyClass implements BaseClass {}

class BaseClass {
}
''');
  }

  Future<void> test_inLibraryOfPrefix() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class A {}
''');

    await resolveTestCode('''
import 'lib.dart' as lib;

void f() {
  lib.A? a = null;
  lib.Test? t = null;
  print('\$a \$t');
}
''');

    await assertHasFix('''
class A {}

class Test {
}
''', target: '$testPackageLibPath/lib.dart');
    expect(change.linkedEditGroups, hasLength(1));
  }

  Future<void> test_innerLocalFunction() async {
    await resolveTestCode('''
f() {
  g() {
    Test v = null;
    print(v);
  }
  g();
}
''');
    await assertHasFix('''
f() {
  g() {
    Test v = null;
    print(v);
  }
  g();
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }

  Future<void> test_instanceCreation_withConst() async {
    await resolveTestCode('''
void f() {
  const Test();
}
''');
    await assertHasFix('''
void f() {
  const Test();
}

class Test {
  const Test();
}
''');
  }

  Future<void> test_instanceCreation_withNew() async {
    await resolveTestCode('''
void f() {
  new Test();
}
''');
    await assertHasFix('''
void f() {
  new Test();
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test();', 'Test {']);
  }

  Future<void> test_instanceCreation_withoutKeyword_constContext() async {
    await resolveTestCode('''
const v = Test();
''');
    await assertHasFix('''
const v = Test();

class Test {
  const Test();
}
''', errorFilter: (e) {
      return e.errorCode == CompileTimeErrorCode.UNDEFINED_FUNCTION;
    });
  }

  Future<void> test_instanceCreation_withoutNew_fromFunction() async {
    await resolveTestCode('''
void f() {
  Test ();
}
''');
    await assertHasFix('''
void f() {
  Test ();
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test ()', 'Test {']);
  }

  Future<void> test_instanceCreation_withoutNew_fromMethod() async {
    await resolveTestCode('''
class A {
  void f() {
    Test ();
  }
}
''');
    await assertHasFix('''
class A {
  void f() {
    Test ();
  }
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test ()', 'Test {']);
  }

  Future<void> test_itemOfList() async {
    await resolveTestCode('''
void f() {
  var a = [Test];
  print(a);
}
''');
    await assertHasFix('''
void f() {
  var a = [Test];
  print(a);
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test];', 'Test {']);
  }

  Future<void> test_itemOfList_inAnnotation() async {
    await resolveTestCode('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
void f() {}
''');
    await assertHasFix('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
void f() {}

class Test {
}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.UNDEFINED_IDENTIFIER;
    });
    assertLinkedGroup(change.linkedEditGroups[0], ['Test])', 'Test {']);
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
void f() {
  Test v = null;
  print(v);
}
''');
    await assertHasFix('''
void f() {
  Test v = null;
  print(v);
}

class Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }

  Future<void> test_with() async {
    await resolveTestCode('''
class MyClass with BaseClass {}
''');
    await assertHasFix('''
class MyClass with BaseClass {}

class BaseClass {
}
''');
  }
}
