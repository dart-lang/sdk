// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfStructClassInExtendsTest);
    defineReflectiveTests(SubtypeOfStructClassInImplementsTest);
    defineReflectiveTests(SubtypeOfStructClassInWithTest);
  });
}

@reflectiveTest
class SubtypeOfStructClassInExtendsTest extends PubPackageResolutionTest {
  test_extends() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S extends Struct {}
class C extends S {}
''', [
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS, 61, 1),
    ]);
  }
}

@reflectiveTest
class SubtypeOfStructClassInImplementsTest extends PubPackageResolutionTest {
  test_implements() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S extends Struct {}
class C implements S {}
''', [
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS, 64, 1),
    ]);
  }
}

@reflectiveTest
class SubtypeOfStructClassInWithTest extends PubPackageResolutionTest {
  test_with() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S extends Struct {}
class C with S {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 58, 1),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH, 58, 1),
    ]);
  }
}
