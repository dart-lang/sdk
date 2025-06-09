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
    defineReflectiveTests(CreateMixinLowercaseTest);
    defineReflectiveTests(CreateMixinLowercaseWithTest);
    defineReflectiveTests(CreateMixinPriorityTest);
    defineReflectiveTests(CreateMixinUppercaseTest);
    defineReflectiveTests(CreateMixinUppercaseWithTest);
  });
}

@reflectiveTest
class CreateMixinLowercaseTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_MIXIN_LOWERCASE;

  Future<void> test_lowercaseAssignment() async {
    await resolveTestCode('''
newName? a;
''');
    await assertHasFix('''
newName? a;

mixin newName {
}
''');
  }

  Future<void> test_multiple() async {
    await resolveTestCode(r'''
_$_newName? a;
''');
    await assertHasFix(r'''
_$_newName? a;

mixin _$_newName {
}
''');
  }

  Future<void> test_number() async {
    await resolveTestCode(r'''
_0newName? a;
''');
    await assertHasFix(r'''
_0newName? a;

mixin _0newName {
}
''');
  }

  Future<void> test_startWithDollarSign() async {
    await resolveTestCode(r'''
$newName? a;
''');
    await assertHasFix(r'''
$newName? a;

mixin $newName {
}
''');
  }

  Future<void> test_startWithUnderscore() async {
    await resolveTestCode('''
_newName? a;
''');
    await assertHasFix('''
_newName? a;

mixin _newName {
}
''');
  }

  Future<void> test_with() async {
    await resolveTestCode('''
class MyClass with myMixin {}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class CreateMixinLowercaseWithTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_MIXIN_LOWERCASE_WITH;

  Future<void> test_with() async {
    await resolveTestCode('''
class MyClass with myMixin {}
''');
    await assertHasFix('''
class MyClass with myMixin {}

mixin myMixin {
}
''');
  }
}

@reflectiveTest
class CreateMixinPriorityTest extends FixPriorityTest {
  Future<void> test_mixinFirst_class_lowercaseWith() async {
    await resolveTestCode('''
class Class with myMixin {}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_MIXIN_LOWERCASE_WITH,
      DartFixKind.CREATE_CLASS_LOWERCASE_WITH,
    ]);
  }

  Future<void> test_mixinFirst_class_with() async {
    await resolveTestCode('''
class Class with MyMixin {}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_MIXIN_UPPERCASE_WITH,
      DartFixKind.CREATE_CLASS_UPPERCASE_WITH,
    ]);
  }

  Future<void> test_mixinLast_class() async {
    await resolveTestCode('''
void f(M m) {}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_CLASS_UPPERCASE,
      DartFixKind.CREATE_MIXIN_UPPERCASE,
    ]);
  }

  Future<void> test_mixinLast_class_lowercase() async {
    await resolveTestCode('''
void f(newName m) {}
''');
    await assertFixPriorityOrder([
      DartFixKind.CREATE_CLASS_LOWERCASE,
      DartFixKind.CREATE_MIXIN_LOWERCASE,
    ]);
  }

  Future<void> test_mixinLast_import() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class A {}
''');
    await resolveTestCode('''
A? a;
''');
    await assertFixPriorityOrder([
      DartFixKind.IMPORT_LIBRARY_PROJECT1,
      DartFixKind.CREATE_MIXIN_UPPERCASE,
    ]);
  }
}

@reflectiveTest
class CreateMixinUppercaseTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_MIXIN_UPPERCASE;

  Future<void> test_hasUnresolvedPrefix() async {
    await resolveTestCode('''
void f() {
  prefix.Test v = null;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_inExtensionGetter() async {
    await resolveTestCode('''
void f(int i) => i.foo;

extension on int {
  int get foo => bar;
}
''');
    await assertNoFix();
  }

  Future<void> test_inLibraryOfPrefix() async {
    var libCode = r'''
class A {}
''';
    newFile('$testPackageLibPath/lib.dart', libCode);
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

mixin Test {
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

mixin Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }

  Future<void> test_instanceCreation_withNew() async {
    await resolveTestCode('''
void f() {
  new Test();
}
''');
    await assertNoFix();
  }

  Future<void> test_instanceCreation_withoutNew() async {
    await resolveTestCode('''
void f() {
  Test();
}
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

mixin Test {
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

mixin Test {
}
''',
      errorFilter: (error) {
        return error.diagnosticCode ==
            CompileTimeErrorCode.UNDEFINED_IDENTIFIER;
      },
    );
    assertLinkedGroup(change.linkedEditGroups[0], ['Test])', 'Test {']);
  }

  Future<void> test_prefixedIdentifier_identifier() async {
    await resolveTestCode('''
void f(C c) {
  c.test;
}

class C {}
''');
    await assertNoFix();
  }

  Future<void> test_prefixedIdentifier_prefix() async {
    await resolveTestCode('''
void f() {
  Test.value;
}
''');
    await assertHasFix('''
void f() {
  Test.value;
}

mixin Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test.value', 'Test {']);
  }

  Future<void> test_propertyAccess_property() async {
    await resolveTestCode('''
void f(C c) {
  (c).test;
}

class C {}
''');
    await assertNoFix();
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

mixin Test {
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }

  Future<void> test_with() async {
    await resolveTestCode('''
class MyClass with MyMixin {}
''');
    await assertNoFix();
  }

  Future<void> test_withStaticName() async {
    await resolveTestCode('''
var a = [Foo.bar];
''');
    await assertHasFix('''
var a = [Foo.bar];

mixin Foo {
}
''');
  }
}

@reflectiveTest
class CreateMixinUppercaseWithTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_MIXIN_UPPERCASE_WITH;

  Future<void> test_with() async {
    await resolveTestCode('''
class MyClass with MyMixin {}
''');
    await assertHasFix('''
class MyClass with MyMixin {}

mixin MyMixin {
}
''');
  }
}
