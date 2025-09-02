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
    defineReflectiveTests(CreateClassLowercaseTest);
    defineReflectiveTests(CreateClassLowercaseWithTest);
    defineReflectiveTests(CreateClassPriorityTest);
    defineReflectiveTests(CreateClassUppercaseTest);
    defineReflectiveTests(CreateClassUppercaseWithTest);
  });
}

@reflectiveTest
class CreateClassLowercaseTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CLASS_LOWERCASE;

  Future<void> test_instanceMethod_noFix() async {
    await resolveTestCode('''
class C {}

String? f(C c) => c.foo();
''');
    await assertNoFix();
  }

  Future<void> test_lowercaseAssignment() async {
    await resolveTestCode('''
void f() {
  var _ = newName();
}
''');
    await assertHasFix('''
void f() {
  var _ = newName();
}

class newName {
}
''');
  }

  Future<void> test_multiple() async {
    await resolveTestCode(r'''
void f() {
  var _ = _$_newName();
}
''');
    await assertHasFix(r'''
void f() {
  var _ = _$_newName();
}

class _$_newName {
}
''');
  }

  Future<void> test_number() async {
    await resolveTestCode(r'''
void f() {
  var _ = _0newName();
}
''');
    await assertHasFix(r'''
void f() {
  var _ = _0newName();
}

class _0newName {
}
''');
  }

  Future<void> test_prefix() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await resolveTestCode('''
import 'lib.dart' as lib;

String? f() => lib.foo();
''');
    await assertHasFix('''

class foo {
}
''', target: '$testPackageLibPath/lib.dart');
  }

  Future<void> test_startWithDollarSign() async {
    await resolveTestCode(r'''
void f() {
  var _ = $newName();
}
''');
    await assertHasFix(r'''
void f() {
  var _ = $newName();
}

class $newName {
}
''');
  }

  Future<void> test_startWithUnderscore() async {
    await resolveTestCode('''
void f() {
  var _ = _newName();
}
''');
    await assertHasFix('''
void f() {
  var _ = _newName();
}

class _newName {
}
''');
  }
}

@reflectiveTest
class CreateClassLowercaseWithTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CLASS_LOWERCASE_WITH;

  Future<void> test_with() async {
    await resolveTestCode('''
class MyClass with baseMixin {}
''');
    await assertHasFix('''
class MyClass with baseMixin {}

class baseMixin {
}
''');
  }
}

@reflectiveTest
class CreateClassPriorityTest extends FixPriorityTest {
  Future<void> test_classFirst_function() async {
    await resolveTestCode('''
void f() {
  var _ = NewName();
}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_CLASS_UPPERCASE,
      DartFixKind.CREATE_FUNCTION,
    ]);
  }

  Future<void> test_classFirst_method() async {
    await resolveTestCode('''
class A {
  void m() {
    var _ = NewName();
  }
}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_CLASS_UPPERCASE,
      DartFixKind.CREATE_METHOD,
    ]);
  }

  Future<void> test_classFirst_mixin() async {
    await resolveTestCode('''
void f(M m) {}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_CLASS_UPPERCASE,
      DartFixKind.CREATE_MIXIN_UPPERCASE,
    ]);
  }

  Future<void> test_classFirst_mixin_lowercase() async {
    await resolveTestCode('''
void f(newName m) {}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_CLASS_LOWERCASE,
      DartFixKind.CREATE_MIXIN_LOWERCASE,
    ]);
  }

  Future<void> test_classLast_function() async {
    await resolveTestCode('''
void f() {
  var _ = newName();
}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_FUNCTION,
      DartFixKind.CREATE_CLASS_LOWERCASE,
    ]);
  }

  Future<void> test_classLast_imports() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/export.dart', '''
export 'lib.dart';
''');
    // This example project doesn't have to make sense, only demonstrate the
    // priorities
    newFile('$testPackageLibPath/src/inner.dart', '''
class A {}
''');
    await resolveTestCode('''
A? a;
''');
    await assertFixPriorityOrder([
      DartFixKind.IMPORT_LIBRARY_PROJECT1,
      DartFixKind.IMPORT_LIBRARY_PROJECT2,
      DartFixKind.IMPORT_LIBRARY_PROJECT3,
      DartFixKind.CREATE_CLASS_UPPERCASE,
    ]);
  }

  Future<void> test_classLast_method() async {
    await resolveTestCode('''
class A {
  void m() {
    var _ = newName();
  }
}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_METHOD,
      DartFixKind.CREATE_CLASS_LOWERCASE,
    ]);
  }

  Future<void> test_classLast_mixin_lowercaseWith() async {
    await resolveTestCode('''
class Class with myMixin {}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_MIXIN_LOWERCASE_WITH,
      DartFixKind.CREATE_CLASS_LOWERCASE_WITH,
    ]);
  }

  Future<void> test_classLast_mixin_with() async {
    await resolveTestCode('''
class Class with MyMixin {}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_MIXIN_UPPERCASE_WITH,
      DartFixKind.CREATE_CLASS_UPPERCASE_WITH,
    ]);
  }
}

@reflectiveTest
class CreateClassUppercaseTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CLASS_UPPERCASE;

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
    assertLinkedGroup(change.linkedEditGroups[0], [
      "Test('",
      'Test {',
      'Test(S',
    ]);
  }

  Future<void> test_class_instanceMember() async {
    await resolveTestCode('''
class A {
}

void f() {
  int _ = A().Test;
}
''');
    await assertNoFix();
  }

  Future<void> test_class_staticMember() async {
    await resolveTestCode('''
class A {
}

void f() {
  int _ = A.Test;
}
''');
    await assertNoFix();
  }

  Future<void> test_classContainingWith() async {
    await resolveTestCode('''
class B extends A with M {}

mixin M {}
''');
    await assertHasFix('''
class B extends A with M {}

class A {
}

mixin M {}
''');
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
    await assertHasFix(
      '''
const v = Test();

class Test {
  const Test();
}
''',
      errorFilter: (e) {
        return e.diagnosticCode == CompileTimeErrorCode.undefinedFunction;
      },
    );
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

  Future<void> test_instanceMethod_noFix() async {
    await resolveTestCode('''
class C {}

String? f(C c) => c.Foo();
''');
    await assertNoFix();
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
    await assertHasFix(
      '''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
void f() {}

class Test {
}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedIdentifier;
      },
    );
    assertLinkedGroup(change.linkedEditGroups[0], ['Test])', 'Test {']);
  }

  Future<void> test_prefix() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await resolveTestCode('''
import 'lib.dart' as lib;

String? f() => lib.Foo();
''');
    await assertHasFix('''

class Foo {
}
''', target: '$testPackageLibPath/lib.dart');
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

  Future<void> test_startWithUnderscore() async {
    await resolveTestCode('''
void f() {
  var _ = _NewName();
}
''');
    await assertHasFix('''
void f() {
  var _ = _NewName();
}

class _NewName {
}
''');
  }

  Future<void> test_with() async {
    await resolveTestCode('''
class MyClass with BaseClass {}
''');
    await assertNoFix();
  }

  Future<void> test_withStaticName() async {
    await resolveTestCode('''
var a = [Foo.bar];
''');
    await assertHasFix('''
var a = [Foo.bar];

class Foo {
}
''');
  }
}

@reflectiveTest
class CreateClassUppercaseWithTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CLASS_UPPERCASE_WITH;

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
