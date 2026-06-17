// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConcreteClassWithAbstractMemberTest);
  });
}

@reflectiveTest
class ConcreteClassWithAbstractMemberTest extends PubPackageResolutionTest {
  test_abstract_field() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  abstract int? x;
//^^^^^^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'x' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_abstract_field_final() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  abstract final int? x;
//^^^^^^^^^^^^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'x' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_external_field() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int? x;
}
''');
  }

  test_external_field_final() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int? x;
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void foo();
//^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_method_hasClassAugmentation() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void foo();
//^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
}

augment class A {
}
''');
  }

  test_method_hasClassAugmentation_withMethodDeclaration() async {
    await resolveTestCodeWithDiagnostics('''
class A {}

augment class A {
  void foo();
//^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_noSuchMethod_interface() async {
    await resolveTestCodeWithDiagnostics('''
class I {
  noSuchMethod(v) => '';
}
class A implements I {
  foo();
//^^^^^^
// [diag.concreteClassWithAbstractMember] 'foo' must have a method body because 'A' isn't abstract.
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  set s(int i);
//^^^^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 's' must have a method body because 'A' isn't abstract.
}
''');
  }
}
