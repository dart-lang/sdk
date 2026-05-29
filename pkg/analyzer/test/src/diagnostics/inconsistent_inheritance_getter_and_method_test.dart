// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentInheritanceGetterAndMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InconsistentInheritanceGetterAndMethodTest
    extends PubPackageResolutionTest {
  test_class_augmentationChain_declaresFieldInAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(String _) {}
}

abstract interface class I {
  int get foo => 1;
}

class C extends A implements I {}

augment class C {
  int foo = 2;
//    ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'I') and also a method (from 'A').
}
''');
  }

  test_class_augmentationChain_declaresGetterInAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(String _) {}
}

abstract interface class I {
  int get foo => 1;
}

class C extends A implements I {}

augment class C {
  int get foo => 2;
//        ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'I') and also a method (from 'A').
}
''');
  }

  test_class_augmentationChain_declaresGetterInAugmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {
  void foo(String _) {}
}

abstract interface class I {
  int get foo => 1;
}

class C extends A implements I {}
''',
      b: r'''
part of 'a.dart';

augment class C {
  int get foo => 2;
//        ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'I') and also a method (from 'A').
}
''',
    });
  }

  test_class_augmentationChain_declaresGetterInIntroduction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(String _) {}
}

abstract interface class I {
  int get foo => 1;
}

class C extends A implements I {
  int get foo => 2;
//        ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'I') and also a method (from 'A').
}

augment class C {}
''');
  }

  test_class_augmentationChain_declaresMethodInAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(String _) {}
}

abstract interface class I {
  int get foo => 1;
}

class C extends A implements I {}

augment class C {
  void foo(String _) {}
//     ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'I') and also a method (from 'A').
}
''');
  }

  test_class_augmentationChain_declaresNoMember() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(String _) {}
}

abstract interface class I {
  int get foo => 1;
}

abstract class C extends A implements I {}
//             ^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'I') and also a method (from 'A').

augment abstract class C {}
''');
  }

  test_class_implements_getter_implements_method_declaresField() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
abstract class C implements A, B {
  int foo = 0;
//    ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'A') and also a method (from 'B').
}
''');
  }

  test_class_implements_getter_implements_method_declaresGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
abstract class C implements A, B {
  int get foo => 0;
//        ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'A') and also a method (from 'B').
}
''');
  }

  test_class_implements_getter_implements_method_declaresMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
abstract class C implements A, B {
  int foo() => 0;
//    ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'A') and also a method (from 'B').
}
''');
  }

  test_class_implements_getter_implements_method_declaresNoMember() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
abstract class C implements A, B {}
//             ^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'A') and also a method (from 'B').
''');
  }

  test_class_implements_method_implements_getter_declaresNoMember() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int foo();
}
abstract class B {
  int get foo;
}
abstract class C implements A, B {}
//             ^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'B') and also a method (from 'A').
''');
  }

  test_class_with_getter_implements_method_declaresMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract interface class I {
  String foo();
}

mixin M {
  int get foo => 42;
}

abstract class C with M implements I {
  String foo() => 'C';
//       ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'M') and also a method (from 'I').
}
''');
  }

  test_classTypeAlias_extends_getter_with_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class S {
  int get foo => 0;
}

mixin M {
  int foo() => 0;
}

class C = S with M;
//    ^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'S') and also a method (from 'M').
''');
  }

  test_classTypeAlias_extends_getter_with_method_with_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class S {
  int get foo => 0;
}

mixin M1 {
  int foo() => 0;
}

mixin M2 {
  int get foo => 0;
}

class C = S with M1, M2;
//    ^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'S') and also a method (from 'M1').
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'M2') and also a method (from 'M1').
''');
  }

  test_mixin_implements_getter_implements_method_declaresNoMember() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M implements A, B {}
//    ^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'A') and also a method (from 'B').
''');
  }

  test_mixin_implements_method_implements_getter_declaresNoMember() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int foo();
}
abstract class B {
  int get foo;
}
mixin M implements A, B {}
//    ^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'B') and also a method (from 'A').
''');
  }

  test_mixin_on_getter_implements_method_declaresField() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M on A implements B {
  int foo = 0;
//    ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'A') and also a method (from 'B').
}
''');
  }

  test_mixin_on_getter_implements_method_declaresGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M on A implements B {
  int get foo => 0;
//        ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'A') and also a method (from 'B').
}
''');
  }

  test_mixin_on_getter_implements_method_declaresMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M on A implements B {
  int foo() => 0;
//    ^^^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'A') and also a method (from 'B').
}
''');
  }

  test_mixin_on_getter_method_declaresNoMember() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M on A, B {}
//    ^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'A') and also a method (from 'B').
''');
  }

  test_mixin_on_method_getter_declaresNoMember() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int foo();
}
abstract class B {
  int get foo;
}
mixin M on A, B {}
//    ^
// [diag.inconsistentInheritanceGetterAndMethod] 'foo' is inherited as a getter (from 'B') and also a method (from 'A').
''');
  }
}
