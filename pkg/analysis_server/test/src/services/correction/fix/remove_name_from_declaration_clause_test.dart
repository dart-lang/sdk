// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedImplementsFunctionTest);
    defineReflectiveTests(ExtendsDisallowedClassTest);
    defineReflectiveTests(ExtendsNonClassTest);
    defineReflectiveTests(ExtendsTypeAliasExpandsToTypeParameterTest);
    defineReflectiveTests(ImplementsDeprecatedImplementTest);
    defineReflectiveTests(ImplementsDeprecatedSubclassTest);
    defineReflectiveTests(ImplementsDisallowedClassTest);
    defineReflectiveTests(ImplementsRepeatedTest);
    defineReflectiveTests(ImplementsSuperClassTest);
    defineReflectiveTests(ImplementsTypeAliasExpandsToTypeParameterTest);
    defineReflectiveTests(MixinOfDisallowedClassTest);
    defineReflectiveTests(MixinOfNonInterfaceTest);
    defineReflectiveTests(SubtypeOfFfiClassInExtendsTest);
    defineReflectiveTests(SubtypeOfFfiClassInImplementsTest);
    defineReflectiveTests(SubtypeOfStructClassInExtendsTest);
    defineReflectiveTests(SubtypeOfStructClassInWithTest);
  });
}

@reflectiveTest
class DeprecatedImplementsFunctionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
// @dart = 2.19
abstract class C implements Function {}
''');
    await assertHasFix('''
// @dart = 2.19
abstract class C {}
''');
  }
}

@reflectiveTest
class ExtendsDisallowedClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_extends() async {
    await resolveTestCode('''
class C extends String {}
''');
    await assertHasFix('''
class C {}
''');
  }
}

@reflectiveTest
class ExtendsNonClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_extends() async {
    await resolveTestCode('''
class C extends dynamic {}
''');
    await assertHasFix('''
class C {}
''');
  }
}

@reflectiveTest
class ExtendsTypeAliasExpandsToTypeParameterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_extends() async {
    await resolveTestCode('''
typedef T<int> = int;
class C extends T {}
''');
    await assertHasFix('''
typedef T<int> = int;
class C {}
''');
  }
}

@reflectiveTest
class ImplementsDeprecatedImplementTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_deprecatedExtends() async {
    newFile('$testPackageLibPath/a.dart', '''
@Deprecated.implement()
class A {}
''');
    await resolveTestCode('''
import 'a.dart';
class B implements A {}
''');
    await assertHasFix('''
import 'a.dart';
class B {}
''');
  }
}

@reflectiveTest
class ImplementsDeprecatedSubclassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_deprecatedSubclass_withExtends() async {
    newFile('$testPackageLibPath/a.dart', '''
@Deprecated.subclass()
class A {}
''');
    await resolveTestCode('''
import 'a.dart';
class B extends A {}
''');
    await assertHasFix('''
import 'a.dart';
class B {}
''');
  }

  Future<void> test_deprecatedSubclass_withImplements() async {
    newFile('$testPackageLibPath/a.dart', '''
@Deprecated.subclass()
class A {}
''');
    await resolveTestCode('''
import 'a.dart';
class B implements A {}
''');
    await assertHasFix('''
import 'a.dart';
class B {}
''');
  }
}

@reflectiveTest
class ImplementsDisallowedClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
class C implements String {}
''');
    await assertHasFix('''
class C {}
''');
  }

  Future<void> test_twoNames() async {
    await resolveTestCode('''
abstract class C implements String, List<int> {}
''');
    await assertHasFix('''
abstract class C implements List<int> {}
''');
  }
}

@reflectiveTest
class ImplementsRepeatedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
class A {}
class C implements A, A {}
''');
    await assertHasFix('''
class A {}
class C implements A {}
''');
  }
}

@reflectiveTest
class ImplementsSuperClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
class A {}
class C extends A implements A {}
''');
    await assertHasFix('''
class A {}
class C extends A {}
''');
  }
}

@reflectiveTest
class ImplementsTypeAliasExpandsToTypeParameterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
typedef T<X> = X;
class C implements T {}
''');
    await assertHasFix('''
typedef T<X> = X;
class C {}
''');
  }
}

@reflectiveTest
class MixinOfDisallowedClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
abstract class C with String {}
''');
    await assertHasFix('''
abstract class C {}
''');
  }
}

@reflectiveTest
class MixinOfNonInterfaceTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
mixin M on dynamic {}
''');
    await assertHasFix('''
mixin M {}
''');
  }
}

@reflectiveTest
class SubtypeOfFfiClassInExtendsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
final class C extends Double {}
''');
    await assertHasFix('''
import 'dart:ffi';
final class C {}
''');
  }
}

@reflectiveTest
class SubtypeOfFfiClassInImplementsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
final class C implements Double {}
''');
    await assertHasFix('''
import 'dart:ffi';
final class C {}
''');
  }
}

@reflectiveTest
class SubtypeOfStructClassInExtendsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
final class S extends Struct {
  external Pointer notEmpty;
}
final class C extends S {}
''');
    await assertHasFix('''
import 'dart:ffi';
final class S extends Struct {
  external Pointer notEmpty;
}
final class C {}
''');
  }
}

@reflectiveTest
class SubtypeOfStructClassInWithTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeNameFromDeclarationClause;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
final class S extends Struct {}
final class C with S {}
''');
    await assertHasFix(
      '''
import 'dart:ffi';
final class S extends Struct {}
final class C {}
''',
      filter: (error) =>
          error.diagnosticCode == diag.subtypeOfStructClassInWith,
    );
  }
}
