// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfStructClassInExtendsTest);
    defineReflectiveTests(SubtypeOfStructClassInImplementsTest);
    defineReflectiveTests(SubtypeOfStructClassInWithTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SubtypeOfStructClassInExtendsTest extends PubPackageResolutionTest {
  test_extends_struct() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class S extends Struct {
  external Pointer notEmpty;
}
final class C extends S {}
//                    ^
// [diag.subtypeOfStructClassInExtends] The class 'C' can't extend 'S' because 'S' is a subtype of 'Struct', 'Union', or 'AbiSpecificInteger'.
''');
  }

  test_extends_union() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class S extends Union {
  external Pointer notEmpty;
}
final class C extends S {}
//                    ^
// [diag.subtypeOfStructClassInExtends] The class 'C' can't extend 'S' because 'S' is a subtype of 'Struct', 'Union', or 'AbiSpecificInteger'.
''');
  }
}

@reflectiveTest
class SubtypeOfStructClassInImplementsTest extends PubPackageResolutionTest {
  test_implements_abi_specific_int() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
})
final class AbiSpecificInteger1 extends AbiSpecificInteger {
  const AbiSpecificInteger1();
}
final class AbiSpecificInteger4 implements AbiSpecificInteger1 {
//                                         ^^^^^^^^^^^^^^^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'AbiSpecificInteger' can't be implemented outside of its library because it's a base class.
// [diag.subtypeOfStructClassInImplements] The class 'AbiSpecificInteger4' can't implement 'AbiSpecificInteger1' because 'AbiSpecificInteger1' is a subtype of 'Struct', 'Union', or 'AbiSpecificInteger'.
  const AbiSpecificInteger4();
}
''');
  }

  test_implements_struct() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class S extends Struct {}
//          ^
// [diag.emptyStruct] The class 'S' can't be empty because it's a subclass of 'Struct'.
final class C implements S {}
//                       ^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Struct' can't be implemented outside of its library because it's a base class.
// [diag.subtypeOfStructClassInImplements] The class 'C' can't implement 'S' because 'S' is a subtype of 'Struct', 'Union', or 'AbiSpecificInteger'.
''');
  }

  test_implements_struct_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
import 'dart:ffi';
final class S extends Struct {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as lib1;
class C implements lib1.S {}
//                 ^^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Struct' can't be implemented outside of its library because it's a base class.
// [diag.finalClassImplementedOutsideOfLibrary] The class 'S' can't be implemented outside of its library because it's a final class.
// [diag.subtypeOfStructClassInImplements] The class 'C' can't implement 'S' because 'S' is a subtype of 'Struct', 'Union', or 'AbiSpecificInteger'.
''');
  }

  test_implements_union() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class S extends Union {}
//          ^
// [diag.emptyStruct] The class 'S' can't be empty because it's a subclass of 'Union'.
final class C implements S {}
//                       ^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Union' can't be implemented outside of its library because it's a base class.
// [diag.subtypeOfStructClassInImplements] The class 'C' can't implement 'S' because 'S' is a subtype of 'Struct', 'Union', or 'AbiSpecificInteger'.
''');
  }
}

@reflectiveTest
class SubtypeOfStructClassInWithTest extends PubPackageResolutionTest {
  test_with_struct() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class S extends Struct {}
//          ^
// [diag.emptyStruct] The class 'S' can't be empty because it's a subclass of 'Struct'.
final class C with S {}
//                 ^
// [diag.classUsedAsMixin] The class 'S' can't be used as a mixin because it's neither a mixin class nor a mixin.
// [diag.subtypeOfStructClassInWith] The class 'C' can't mix in 'S' because 'S' is a subtype of 'Struct', 'Union', or 'AbiSpecificInteger'.
''');
  }

  test_with_struct_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
import 'dart:ffi';
final class S extends Struct {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as lib1;

class C with lib1.S {}
//           ^^^^^^
// [diag.classUsedAsMixin] The class 'S' can't be used as a mixin because it's neither a mixin class nor a mixin.
// [diag.subtypeOfStructClassInWith] The class 'C' can't mix in 'S' because 'S' is a subtype of 'Struct', 'Union', or 'AbiSpecificInteger'.
''');
  }

  test_with_union() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class S extends Union {}
//          ^
// [diag.emptyStruct] The class 'S' can't be empty because it's a subclass of 'Union'.
final class C with S {}
//                 ^
// [diag.classUsedAsMixin] The class 'S' can't be used as a mixin because it's neither a mixin class nor a mixin.
// [diag.subtypeOfStructClassInWith] The class 'C' can't mix in 'S' because 'S' is a subtype of 'Struct', 'Union', or 'AbiSpecificInteger'.
''');
  }
}
