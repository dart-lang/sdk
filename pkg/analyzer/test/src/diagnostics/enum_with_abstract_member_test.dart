// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumWithAbstractMemberTest);
  });
}

@reflectiveTest
class EnumWithAbstractMemberTest extends PubPackageResolutionTest {
  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get foo;
//^^^^^^^^^^^^
// [diag.enumWithAbstractMember] 'foo' must have a method body because 'E' is an enum.
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo();
//^^^^^^^^^^^
// [diag.enumWithAbstractMember] 'foo' must have a method body because 'E' is an enum.
}
''');
  }

  test_method_hasEnumAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo();
//^^^^^^^^^^^
// [diag.enumWithAbstractMember] 'foo' must have a method body because 'E' is an enum.
}

augment enum E {}
''');
  }

  test_method_hasEnumAugmentation_withMethodDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
}

augment enum E {
  ;
  void foo();
//^^^^^^^^^^^
// [diag.enumWithAbstractMember] 'foo' must have a method body because 'E' is an enum.
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  set foo(int _);
//^^^^^^^^^^^^^^^
// [diag.enumWithAbstractMember] 'foo' must have a method body because 'E' is an enum.
}
''');
  }
}
