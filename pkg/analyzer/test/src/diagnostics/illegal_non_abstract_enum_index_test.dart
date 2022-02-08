// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalNonAbstractEnumIndexTest);
  });
}

@reflectiveTest
class IllegalNonAbstractEnumIndexTest extends PubPackageResolutionTest {
  test_class_field() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  int index = 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_NON_ABSTRACT_ENUM_INDEX, 41, 5),
    ]);
  }

  test_class_getter() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  int get index => 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_NON_ABSTRACT_ENUM_INDEX, 45, 5),
    ]);
  }

  test_class_getter_abstract() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  int get index;
}
''');
  }

  test_class_setter() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  set index(int _) {}
}
''');
  }

  test_enum_field() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int index = 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_NON_ABSTRACT_ENUM_INDEX, 26, 5),
    ]);
  }

  test_enum_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  int get index => 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_NON_ABSTRACT_ENUM_INDEX, 24, 5),
    ]);
  }

  test_enum_getter_abstract() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  int get index;
}
''');
  }

  test_enum_setter() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  set index(int _) {}
}
''');
  }

  test_mixin_field() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  int index = 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_NON_ABSTRACT_ENUM_INDEX, 24, 5),
    ]);
  }

  test_mixin_getter() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  int get index => 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_NON_ABSTRACT_ENUM_INDEX, 28, 5),
    ]);
  }

  test_mixin_getter_abstract() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  int get index;
}
''');
  }

  test_mixin_setter() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  set index(int _) {}
}
''');
  }
}
