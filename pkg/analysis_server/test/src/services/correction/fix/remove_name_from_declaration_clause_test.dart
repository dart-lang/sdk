// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/error/ffi_code.g.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedImplementsFunctionTest);
    defineReflectiveTests(ExtendsDisallowedClassTest);
    defineReflectiveTests(ExtendsNonClassTest);
    defineReflectiveTests(ExtendsTypeAliasExpandsToTypeParameterTest);
    defineReflectiveTests(ImplementsDisallowedClassTest);
    defineReflectiveTests(ImplementsRepeatedTest);
    defineReflectiveTests(ImplementsSuperClassTest);
    defineReflectiveTests(ImplementsTypeAliasExpandsToTypeParameterTest);
    defineReflectiveTests(MixinOfDisallowedClassTest);
    defineReflectiveTests(MixinOfNonInterfaceTest);
    defineReflectiveTests(SubtypeOfFfiClassInExtendsTest);
    defineReflectiveTests(SubtypeOfFfiClassInImplementsTest);
    defineReflectiveTests(SubtypeOfFfiClassInWithTest);
    defineReflectiveTests(SubtypeOfStructClassInExtendsTest);
    defineReflectiveTests(SubtypeOfStructClassInImplementsTest);
    defineReflectiveTests(SubtypeOfStructClassInWithTest);
  });
}

@reflectiveTest
class DeprecatedImplementsFunctionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_oneName() async {
    await resolveTestCode('''
abstract class C implements Function {}
''');
    await assertHasFix('''
abstract class C {}
''');
  }
}

@reflectiveTest
class ExtendsDisallowedClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_extends() async {
    await resolveTestCode('''
class C extends String {}
''');
    await assertHasFix(
      '''
class C {}
''',
      errorFilter: (error) =>
          error.errorCode == CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
    );
  }
}

@reflectiveTest
class ExtendsNonClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

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
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

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
class ImplementsDisallowedClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_oneName() async {
    await resolveTestCode('''
class C implements String {}
''');
    await assertHasFix(
      '''
class C {}
''',
      errorFilter: (error) =>
          error.errorCode == CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
    );
  }

  Future<void> test_twoNames() async {
    await resolveTestCode('''
abstract class C implements String, List<int> {}
''');
    await assertHasFix(
      '''
abstract class C implements List<int> {}
''',
      errorFilter: (error) =>
          error.errorCode == CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
    );
  }
}

@reflectiveTest
class ImplementsRepeatedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

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
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

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
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

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
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_oneName() async {
    await resolveTestCode('''
abstract class C with String {}
''');
    await assertHasFix(
      '''
abstract class C {}
''',
      errorFilter: (error) =>
          error.errorCode == CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS,
    );
  }
}

@reflectiveTest
class MixinOfNonInterfaceTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

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
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
class C extends Double {}
''');
    await assertHasFix('''
import 'dart:ffi';
class C {}
''');
  }
}

@reflectiveTest
class SubtypeOfFfiClassInImplementsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
class C implements Double {}
''');
    await assertHasFix('''
import 'dart:ffi';
class C {}
''');
  }
}

@reflectiveTest
class SubtypeOfFfiClassInWithTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
class C with Double {}
''');
    await assertHasFix('''
import 'dart:ffi';
class C {}
''',
        errorFilter: (error) =>
            error.errorCode == FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH);
  }
}

@reflectiveTest
class SubtypeOfStructClassInExtendsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
class S extends Struct {
  external Pointer notEmpty;
}
class C extends S {}
''');
    await assertHasFix('''
import 'dart:ffi';
class S extends Struct {
  external Pointer notEmpty;
}
class C {}
''');
  }
}

@reflectiveTest
class SubtypeOfStructClassInImplementsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
class C implements Struct {}
''');
    await assertHasFix('''
import 'dart:ffi';
class C {}
''');
  }
}

@reflectiveTest
class SubtypeOfStructClassInWithTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NAME_FROM_DECLARATION_CLAUSE;

  Future<void> test_oneName() async {
    await resolveTestCode('''
import 'dart:ffi';
class S extends Struct {}
class C with S {}
''');
    await assertHasFix('''
import 'dart:ffi';
class S extends Struct {}
class C {}
''',
        errorFilter: (error) =>
            error.errorCode == FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH);
  }
}
