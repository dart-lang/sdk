// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateDefinitionTest);
    defineReflectiveTests(DuplicateDefinitionClassTest);
    defineReflectiveTests(DuplicateDefinitionEnumTest);
    defineReflectiveTests(DuplicateDefinitionExtensionTest);
    defineReflectiveTests(DuplicateDefinitionExtensionTypeTest);
    defineReflectiveTests(DuplicateDefinitionMixinTest);
    defineReflectiveTests(DuplicateDefinitionUnitTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DuplicateDefinitionClassTest extends PubPackageResolutionTest {
  test_instance_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
//    ^^^
// [context 1] The first definition of this name.
  int foo = 0;
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_field_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}

augment class A {
  augment abstract int foo;
}
''');
  }

  test_instance_field_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
//    ^^^
// [context 1] The first definition of this name.
// [context 2] The first definition of this name.
  int foo = 0;
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
  int foo = 0;
//    ^^^
// [diag.duplicateDefinition][context 2] The name 'foo' is already defined.
}
''');
  }

  test_instance_field_field_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
//    ^^^
// [context 1] The first definition of this name.
}

augment class A {
  int foo = 42;
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_field_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
//    ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_field_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
//    ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_fieldFinal_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final int foo = 0;
//          ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_fieldFinal_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final int foo = 0;
  set foo(int x) {}
}
''');
  }

  test_instance_fieldLateFinalInitializer_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  late final int foo = 1;
  set foo(_) {}
}
''');
  }

  test_instance_fieldLateFinalNoInitializer_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  late final int foo;
//               ^^^
// [context 1] The first definition of this name.
  set foo(_) {}
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo;
//        ^^^
// [context 1] The corresponding getter is declared here.
}

augment class C {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_instance_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_getter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

augment class C {
  augment int get foo;
}
''');
  }

  test_instance_getter_getter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
}

augment class C {
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get b => null;
//         ^
// [context 1] The first definition of this name.
  int? get b => 0;
//         ^
// [diag.duplicateDefinition][context 1] The name 'b' is already defined.
  void set b(int? value) {}
}
''');
  }

  test_instance_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_getter_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get b => null;
//         ^
// [context 1] The first definition of this name.
  void set b(int? value) {}
  int? get b => 0;
//         ^
// [diag.duplicateDefinition][context 1] The name 'b' is already defined.
}
''');
  }

  test_instance_getter_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get b => null;
  void set b(int? value) {}
//         ^
// [context 1] The first definition of this name.
  void set b(int? value) {}
//         ^
// [diag.duplicateDefinition][context 1] The name 'b' is already defined.
}
''');
  }

  test_instance_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_method_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

augment class A {
  augment void foo();
}
''');
  }

  test_instance_method_method_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
}

augment class A {
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  set foo(_) {}
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_setter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
}

augment class A {
  set foo(_) {}
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_operator_operator_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator +(int _) => 0;
}

augment class A {
  augment int operator +(int _);
}
''');
  }

  test_instance_operator_operator_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator +(int _) => 0;
//             ^
// [context 1] The first definition of this name.
}

augment class A {
  int operator +(int _) => 0;
//             ^
// [diag.duplicateDefinition][context 1] The name '+' is already defined.
}
''');
  }

  test_instance_primaryConstructor_requiredNamed_final_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C({required final int foo}) {
//                          ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_final_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(final int foo) {
//                ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_final_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(final int foo) {
  set foo(int x) {}
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_notDeclaring_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(int foo) {
  int get foo => 0;
  set foo(int x) {}
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_var_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(var int foo) {
//              ^^^
// [context 1] The first definition of this name.
  set foo(int x) {}
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(var int _);
//              ^
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_' isn't used.
''');
  }

  test_instance_primaryConstructor_requiredPositional_wildcard_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(var int _, var int _);
//              ^
// [context 1] The first definition of this name.
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_' isn't used.
//                         ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_' isn't used.
''');
  }

  test_instance_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void set foo(int _);
//         ^^^
// [context 1] The corresponding setter is declared here.
}

augment class C {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_instance_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void set b(int? value) {}
  int? get b => null;
//         ^
// [context 1] The first definition of this name.
  int? get b => 0;
//         ^
// [diag.duplicateDefinition][context 1] The name 'b' is already defined.
}
''');
  }

  test_instance_setter_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void set b(int? value) {}
//         ^
// [context 1] The first definition of this name.
  int? get b => null;
  void set b(int? value) {}
//         ^
// [diag.duplicateDefinition][context 1] The name 'b' is already defined.
}
''');
  }

  test_instance_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(_) {}
//    ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_method_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
//    ^^^
// [context 1] The first definition of this name.
}

augment class A {
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void set foo(_) {}
//         ^^^
// [context 1] The first definition of this name.
  void set foo(_) {}
//         ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_setter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void set foo(_) {}
}

augment class C {
  augment void set foo(_);
}
''');
  }

  test_instance_setter_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void set b(int? value) {}
//         ^
// [context 1] The first definition of this name.
  void set b(int? value) {}
//         ^
// [diag.duplicateDefinition][context 1] The name 'b' is already defined.
  int? get b => null;
}
''');
  }

  test_instance_setter_setter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void set foo(_) {}
//         ^^^
// [context 1] The first definition of this name.
}

augment class C {
  void set foo(_) {}
//         ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int foo = 0;
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static final int foo = 0;
//                 ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_fieldLateFinalInitializer_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static late final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_fieldLateFinalNoInitializer_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static late final int foo;
//                      ^^^
// [context 1] The first definition of this name.
  static set foo(int x) {}
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
//               ^^^
// [context 1] The corresponding getter is declared here.
}

augment class A {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_getter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}

augment class A {
  augment static int get foo;
}
''');
  }

  test_static_getter_getter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
}

augment class A {
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_method_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}

augment class A {
  augment static void foo();
}
''');
  }

  test_static_method_method_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
}

augment class A {
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static set foo(_) {}
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void set foo(_) {}
//                ^^^
// [context 1] The corresponding setter is declared here.
}

augment class A {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(_) {}
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void set foo(_) {}
//                ^^^
// [context 1] The first definition of this name.
  static void set foo(_) {}
//                ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_setter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void set foo(_) {}
}

augment class A {
  augment static void set foo(_);
}
''');
  }

  test_static_setter_setter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void set foo(_) {}
//                ^^^
// [context 1] The first definition of this name.
}

augment class A {
  static void set foo(_) {}
//                ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }
}

@reflectiveTest
class DuplicateDefinitionEnumTest extends PubPackageResolutionTest {
  test_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo, foo
//^^^
// [context 1] The first definition of this name.
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int foo = 0;
//          ^^^
// [context 1] The first definition of this name.
  final int foo = 0;
//          ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_field_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int foo = 0;
//          ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_field_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int foo = 0;
//          ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_fieldFinal_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int foo = 0;
//          ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_fieldFinal_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int foo = 0;
  set foo(int x) {}
}
''');
  }

  test_instance_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get foo => 0;
}

augment enum E {;
  augment abstract final int foo;
}
''');
  }

  test_instance_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_getter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get foo => 0;
}

augment enum E {;
  augment int get foo;
}
''');
  }

  test_instance_getter_getter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
}

augment enum E {;
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_method_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo() {}
}

augment enum E {;
  augment void foo();
}
''');
  }

  test_instance_method_method_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
}

augment enum E {;
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  set foo(_) {}
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_primaryConstructor_requiredNamed_final_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E({required final int foo}) {
//                         ^^^
// [context 1] The first definition of this name.
  v(foo: 0);
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_final_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(final int foo) {
//               ^^^
// [context 1] The first definition of this name.
  v(0);
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_final_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(final int foo) {
  v(0);
  set foo(int x) {}
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_notDeclaring_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(int foo) {
  v(0);
  int get foo => 0;
  set foo(int x) {}
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_var_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(var int foo) {
//             ^^^
// [context 1] The first definition of this name.
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
  v(0);
  set foo(int x) {}
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(final int _) {
//               ^
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_' isn't used.
  v(0);
}
''');
  }

  test_instance_primaryConstructor_requiredPositional_wildcard_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(final int _, final int _) {
//               ^
// [context 1] The first definition of this name.
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_' isn't used.
//                            ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_' isn't used.
  v(0, 0);
}
''');
  }

  test_instance_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void set foo(int _) {}
//         ^^^
// [context 1] The corresponding setter is declared here.
}

augment enum E {;
  augment final int foo = 0;
//                  ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_instance_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  set foo(_) {}
//    ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void set foo(_) {}
//         ^^^
// [context 1] The first definition of this name.
  void set foo(_) {}
//         ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_setter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void set foo(_) {}
}

augment enum E {;
  augment void set foo(_);
}
''');
  }

  test_instance_setter_setter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void set foo(_) {}
//         ^^^
// [context 1] The first definition of this name.
}

augment enum E {;
  void set foo(_) {}
//         ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_constant_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo;
//^^^
// [context 1] The first definition of this name.
  static int foo = 0;
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_constant_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo;
//^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_constant_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo;
//^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_constant_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo;
  static set foo(_) {}
}
''');
  }

  test_static_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int foo = 0;
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static final int foo = 0;
//                 ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
//               ^^^
// [context 1] The corresponding getter is declared here.
}

augment enum E {;
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_getter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
}

augment enum E {;
  augment static int get foo;
}
''');
  }

  test_static_getter_getter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
}

augment enum E {;
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_method_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
}

augment enum E {;
  augment static void foo();
}
''');
  }

  test_static_method_method_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
}

augment enum E {;
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static set foo(_) {}
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void set foo(_) {}
//                ^^^
// [context 1] The corresponding setter is declared here.
}

augment enum E {;
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(_) {}
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void set foo(_) {}
//                ^^^
// [context 1] The first definition of this name.
  static void set foo(_) {}
//                ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_setter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void set foo(_) {}
}

augment enum E {;
  augment static void set foo(_);
}
''');
  }

  test_static_setter_setter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void set foo(_) {}
//                ^^^
// [context 1] The first definition of this name.
}

augment enum E {;
  static void set foo(_) {}
//                ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }
}

@reflectiveTest
class DuplicateDefinitionExtensionTest extends PubPackageResolutionTest {
  test_extendedType_instance() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
  set foo(_) {}
  void bar() {}
}

extension E on A {
  int get foo => 0;
  set foo(_) {}
  void bar() {}
}
''');
  }

  test_extendedType_static() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static int get foo => 0;
  static set foo(_) {}
  static void bar() {}
}

extension E on A {
  static int get foo => 0;
  static set foo(_) {}
  static void bar() {}
}
''');
  }

  test_instance_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
//        ^^^
// [context 1] The corresponding getter is declared here.
}

augment extension E {
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_instance_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_getter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}

augment extension E {
  augment int get foo;
}
''');
  }

  test_instance_getter_getter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
}

augment extension E {
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_method_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

augment extension E {
  augment void foo();
}
''');
  }

  test_instance_method_method_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
}

augment extension E {
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  set foo(_) {}
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void set foo(int _) {}
//         ^^^
// [context 1] The corresponding setter is declared here.
}

augment extension E {
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_instance_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  set foo(_) {}
//    ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  void set foo(_) {}
//         ^^^
// [context 1] The first definition of this name.
  void set foo(_) {}
//         ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_setter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void set foo(_) {}
}

augment extension E {
  augment void set foo(_);
}
''');
  }

  test_instance_setter_setter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void set foo(_) {}
//         ^^^
// [context 1] The first definition of this name.
}

augment extension E {
  void set foo(_) {}
//         ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int foo = 0;
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static final int foo = 0;
//                 ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
//               ^^^
// [context 1] The corresponding getter is declared here.
}

augment extension E {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_getter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
}

augment extension E {
  augment static int get foo;
}
''');
  }

  test_static_getter_getter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
}

augment extension E {
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_method_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo() {}
}

augment extension E {
  augment static void foo();
}
''');
  }

  test_static_method_method_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
}

augment extension E {
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static set foo(_) {}
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void set foo(_) {}
//                ^^^
// [context 1] The corresponding setter is declared here.
}

augment extension E {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static set foo(_) {}
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
extension E on A {
  static void set foo(_) {}
//                ^^^
// [context 1] The first definition of this name.
  static void set foo(_) {}
//                ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_setter_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void set foo(_) {}
}

augment extension E {
  augment static void set foo(_);
}
''');
  }

  test_static_setter_setter_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void set foo(_) {}
//                ^^^
// [context 1] The first definition of this name.
}

augment extension E {
  static void set foo(_) {}
//                ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_unitMembers_extension() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
extension E on A {}
//        ^
// [context 1] The first definition of this name.
extension E on A {}
//        ^
// [diag.duplicateDefinition][context 1] The name 'E' is already defined.
''');
  }
}

@reflectiveTest
class DuplicateDefinitionExtensionTypeTest extends PubPackageResolutionTest {
  test_instance_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  int get foo => 0;
//        ^^^
// [context 1] The corresponding getter is declared here.
}

augment extension type E {
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
}
''');
  }

  test_instance_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  set foo(_) {}
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_representation_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
//                   ^^
// [context 1] The first definition of this name.
  int get it => 0;
//        ^^
// [diag.duplicateDefinition][context 1] The name 'it' is already defined.
}
''');
  }

  test_instance_representation_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
//                   ^^
// [context 1] The first definition of this name.
  void it() {}
//     ^^
// [diag.duplicateDefinition][context 1] The name 'it' is already defined.
}
''');
  }

  test_instance_representation_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  set it(int _) {}
}
''');
  }

  test_instance_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  void set foo(int _) {}
//         ^^^
// [context 1] The corresponding setter is declared here.
}

augment extension type E {
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
}
''');
  }

  test_instance_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  set foo(_) {}
//    ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  void set foo(_) {}
//         ^^^
// [context 1] The first definition of this name.
  void set foo(_) {}
//         ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int foo = 0;
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static final int foo = 0;
//                 ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int get foo => 0;
//               ^^^
// [context 1] The corresponding getter is declared here.
}

augment extension type E {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static set foo(_) {}
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static void set foo(_) {}
//                ^^^
// [context 1] The corresponding setter is declared here.
}

augment extension type E {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static set foo(_) {}
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static void set foo(_) {}
//                ^^^
// [context 1] The first definition of this name.
  static void set foo(_) {}
//                ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_unitMembers_extensionType() async {
    await resolveTestCodeWithDiagnostics('''
extension type E(int it) {}
//             ^
// [context 1] The first definition of this name.
extension type E(int it) {}
//             ^
// [diag.duplicateDefinition][context 1] The name 'E' is already defined.
''');
  }
}

@reflectiveTest
class DuplicateDefinitionMixinTest extends PubPackageResolutionTest {
  test_instance_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int foo = 0;
//    ^^^
// [context 1] The first definition of this name.
  int foo = 0;
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_field_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int foo = 0;
//    ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_field_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int foo = 0;
//    ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_fieldFinal_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  final int foo = 0;
//          ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_fieldFinal_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  final int foo = 0;
  set foo(int x) {}
}
''');
  }

  test_instance_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
//        ^^^
// [context 1] The corresponding getter is declared here.
}

augment mixin M {
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_instance_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
//        ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  int get foo => 0;
//        ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_method_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void foo() {}
}

augment mixin A {
  augment void foo();
}
''');
  }

  test_instance_method_method_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
}

augment mixin A {
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
//     ^^^
// [context 1] The first definition of this name.
  set foo(_) {}
//    ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void set foo(int _) {}
//         ^^^
// [context 1] The corresponding setter is declared here.
}

augment mixin M {
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_instance_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set foo(_) {}
//    ^^^
// [context 1] The first definition of this name.
  void foo() {}
//     ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_instance_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void set foo(_) {}
//         ^^^
// [context 1] The first definition of this name.
  void set foo(_) {}
//         ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int foo = 0;
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_field_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int foo = 0;
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static final int foo = 0;
//                 ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_fieldFinal_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_getter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
//               ^^^
// [context 1] The corresponding getter is declared here.
}

augment mixin M {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
//               ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static int get foo => 0;
//               ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {}
//            ^^^
// [context 1] The first definition of this name.
  static set foo(_) {}
//           ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_field_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void set foo(_) {}
//                ^^^
// [context 1] The corresponding setter is declared here.
}

augment mixin M {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_static_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(_) {}
//           ^^^
// [context 1] The first definition of this name.
  static void foo() {}
//            ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }

  test_static_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void set foo(_) {}
//                ^^^
// [context 1] The first definition of this name.
  static void set foo(_) {}
//                ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
}
''');
  }
}

@reflectiveTest
class DuplicateDefinitionTest extends PubPackageResolutionTest {
  test_block_localFunction_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  void _() {}
//^^^^^^^^^^^
// [diag.deadCode] Dead code.
  int _(int _) => 42;
//^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
  String _(int _) => "42";
//^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_block_localFunction_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  void _() {}
//     ^
// [context 1] The first definition of this name.
// [context 2] The first definition of this name.
// [diag.unusedElement] The declaration '_' isn't referenced.
  int _(int _) => 42;
//    ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
// [diag.unusedElement] The declaration '_' isn't referenced.
  String _(int _) => "42";
//       ^
// [diag.duplicateDefinition][context 2] The name '_' is already defined.
// [diag.unusedElement] The declaration '_' isn't referenced.
}
''');
  }

  test_block_localVariable_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var a = 0;
//    ^
// [context 1] The first definition of this name.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  var a = 1;
//    ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_block_localVariable_localVariable_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var _ = 0;
  var _ = 1;
}
''');
  }

  test_block_localVariable_localVariable_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  var _ = 0;
//    ^
// [context 1] The first definition of this name.
  var _ = 1;
//    ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
}
''');
  }

  test_block_localVariable_patternVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var a = 0;
//    ^
// [context 1] The first definition of this name.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  var (a) = 1;
//     ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_block_localVariable_patternVariable_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var _ = 0;
  var (_) = 1;
}
''');
  }

  test_block_localVariable_patternVariable_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  var _ = 0;
  var (_) = 1;
}
''');
  }

  test_block_patternVariable_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a) = 1;
//     ^
// [context 1] The first definition of this name.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  var a = 0;
//    ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_block_patternVariable_patternVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a) = 0;
//     ^
// [context 1] The first definition of this name.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  var (a) = 1;
//     ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_catch() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  try {} catch (e, e) {}
//              ^
// [context 1] The first definition of this name.
//                 ^
// [diag.duplicateDefinition][context 1] The name 'e' is already defined.
// [diag.unusedCatchStack] The stack trace variable 'e' isn't used and can be removed.
}''');
  }

  test_catch_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {} catch (_, _) {}
//                 ^
// [diag.unusedCatchStack] The stack trace variable '_' isn't used and can be removed.
}''');
  }

  test_catch_wildcard_preWildCards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  try {} catch (_, _) {}
//              ^
// [context 1] The first definition of this name.
//                 ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
// [diag.unusedCatchStack] The stack trace variable '_' isn't used and can be removed.
}''');
  }

  test_emptyName() async {
    // Note: This code has two FunctionElements '() {}' with an empty name; this
    // tests that the empty string is not put into the scope (more than once).
    await resolveTestCodeWithDiagnostics(r'''
Map _globalMap = {
//  ^^^^^^^^^^
// [diag.unusedElement] The declaration '_globalMap' isn't referenced.
  'a' : () {},
  'b' : () {}
};
''');
  }

  test_for_initializers() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (int i = 0, i = 0; i < 5;) {}
//         ^
// [context 1] The first definition of this name.
//                ^
// [diag.duplicateDefinition][context 1] The name 'i' is already defined.
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_for_initializers_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (int _ = 0, _ = 0; ;) {}
}
''');
  }

  test_for_initializers_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  for (int _ = 0, _ = 0; ;) {}
//         ^
// [context 1] The first definition of this name.
//                ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
}
''');
  }

  test_getter_single() async {
    await resolveTestCodeWithDiagnostics('''
bool get a => true;
''');
  }

  test_parameters_constructor_field_first() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? a;
  A(this.a, int a);
//       ^
// [context 1] The first definition of this name.
//              ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
}
''');
  }

  test_parameters_constructor_field_first_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(this._, int _);
}
''');
  }

  test_parameters_constructor_field_first_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(this._, int _);
//       ^
// [context 1] The first definition of this name.
//              ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
}
''');
  }

  test_parameters_constructor_field_second() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? a;
  A(int a, this.a);
//      ^
// [context 1] The first definition of this name.
//              ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
}
''');
  }

  test_parameters_constructor_field_second_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(int _, this._);
}
''');
  }

  test_parameters_constructor_field_second_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(int _, this._);
//      ^
// [context 1] The first definition of this name.
//              ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
}
''');
  }

  test_parameters_constructor_super_first_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(this._);
}
class B extends A {
  B(super._, super._);
//                 ^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
}
''');
  }

  test_parameters_constructor_super_first_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(this._);
}
class B extends A {
  B(super._, super._);
//        ^
// [context 1] The first definition of this name.
//                 ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
}
''');
  }

  test_parameters_constructor_this_super_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x, y;
  A(this.x, [this.y = 0]);
}

class C extends A {
  final int _;
//          ^
// [diag.unusedField] The value of the field '_' isn't used.

  C(this._, super._, [super._]);
}
''');
  }

  test_parameters_functionTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void F(int a, double a);
//                 ^
// [context 1] The first definition of this name.
//                           ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
''');
  }

  test_parameters_functionTypeAlias_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void F(int _, double _);
''');
  }

  test_parameters_functionTypeAlias_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef void F(int _, double _);
//                 ^
// [context 1] The first definition of this name.
//                           ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
''');
  }

  test_parameters_genericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function(int a, double a);
//                            ^
// [context 1] The first definition of this name.
//                                      ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
''');
  }

  test_parameters_genericFunction_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function(int _, double _);
''');
  }

  test_parameters_genericFunction_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef F = void Function(int _, double _);
//                            ^
// [context 1] The first definition of this name.
//                                      ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
''');
  }

  test_parameters_localFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  f(int a, double a) {
//^
// [diag.unusedElement] The declaration 'f' isn't referenced.
//      ^
// [context 1] The first definition of this name.
//                ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
  };
}
''');
  }

  test_parameters_localFunction_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  g(int _, double _) {};
//^
// [diag.unusedElement] The declaration 'g' isn't referenced.
}
''');
  }

  test_parameters_localFunction_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  g(int _, double _) {};
//^
// [diag.unusedElement] The declaration 'g' isn't referenced.
//      ^
// [context 1] The first definition of this name.
//                ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
}
''');
  }

  test_parameters_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m(int a, double a) {
//      ^
// [context 1] The first definition of this name.
//                ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
  }
}
''');
  }

  test_parameters_method_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m(int _, double _) {
  }
}
''');
  }

  test_parameters_method_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  m(int _, double _) {
//      ^
// [context 1] The first definition of this name.
//                ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
  }
}
''');
  }

  test_parameters_primaryConstructor_field_simple() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int a, this.a) {
//          ^
// [context 1] The first definition of this name.
//                  ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
  int a;
}
''');
  }

  test_parameters_primaryConstructor_field_simple_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int _, this._) {
  int _;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
}
''');
  }

  test_parameters_primaryConstructor_simple_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this.a, int a) {
//           ^
// [context 1] The first definition of this name.
//                  ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
  int a;
}
''');
  }

  test_parameters_primaryConstructor_simple_field_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this._, int _) {
  int _;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
}
''');
  }

  test_parameters_primaryConstructor_simple_simple() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int a, int a) {}
//          ^
// [context 1] The first definition of this name.
//                 ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
''');
  }

  test_parameters_primaryConstructor_super_super() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this.a, this.b) {
  int a;
  int b;
}
class B(super.a, super.a) extends A {}
//            ^
// [context 1] The first definition of this name.
//                     ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
''');
  }

  test_parameters_primaryConstructor_this_super() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this.a, this.b) {
  int a;
  int b;
}
class C(this.x, super.x) extends A {
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
//           ^
// [context 1] The first definition of this name.
//                    ^
// [diag.duplicateDefinition][context 1] The name 'x' is already defined.
  final int x;
}
''');
  }

  test_parameters_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, double a) {}
//    ^
// [context 1] The first definition of this name.
//              ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
''');
  }

  test_parameters_topLevelFunction_synthetic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(,[]) {}
//^
// [diag.missingIdentifier] Expected an identifier.
//  ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  test_parameters_topLevelFunction_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int _, double _) {}
''');
  }

  test_parameters_topLevelFunction_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

f(int _, double _) {}
//    ^
// [context 1] The first definition of this name.
//              ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
''');
  }

  test_switchCase_localVariable_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f() {
  switch (0) {
    case 0:
      var a;
//        ^
// [context 1] The first definition of this name.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      var a;
//        ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');
  }

  test_switchDefault_localVariable_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  switch (0) {
    default:
      var a;
//        ^
// [context 1] The first definition of this name.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      var a;
//        ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');
  }

  test_switchDefault_localVariable_localVariable_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  switch (0) {
    default:
      var _;
//        ^
// [context 1] The first definition of this name.
      var _;
//        ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
  }
}
''');
  }

  test_switchDefault_localVariable_localVariable_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  switch (0) {
    default:
      var _;
      var _;
  }
}
''');
  }

  test_switchPatternCase_localVariable_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  switch (0) {
    case 0:
      var a;
//        ^
// [context 1] The first definition of this name.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      var a;
//        ^
// [diag.duplicateDefinition][context 1] The name 'a' is already defined.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');
  }

  test_switchPatternCase_localVariable_localVariable_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  switch (0) {
    case 0:
      var _;
      var _;
  }
}
''');
  }

  test_switchPatternCase_localVariable_localVariable_wildcard_preWildCards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  switch (0) {
    case 0:
      var _;
//        ^
// [context 1] The first definition of this name.
      var _;
//        ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
  }
}
''');
  }

  test_topLevel_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
var f = 1;
//  ^
// [context 1] The first definition of this name.
var f = 2;
//  ^
// [diag.duplicateDefinition][context 1] The name 'f' is already defined.
''');
  }

  test_topLevel_field_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
int f = 1;
//  ^
// [context 1] The first definition of this name.
int get f => 7;
//      ^
// [diag.duplicateDefinition][context 1] The name 'f' is already defined.
''');
  }

  test_topLevel_field_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
int f = 1;
//  ^
// [context 1] The first definition of this name.
set f(int value) {}
//  ^
// [diag.duplicateDefinition][context 1] The name 'f=' is already defined.
''');
  }

  test_topLevel_fieldConst_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
const f = 0;
set f(_) {}
''');
  }

  test_topLevel_fieldFinal_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
final f = 1;
set f(int value) {}
''');
  }

  test_topLevel_fieldLateFinalInitializer_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
late final f = 1;
set f(int value) {}
''');
  }

  test_topLevel_fieldLateFinalNoInitializer_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
late final f;
//         ^
// [context 1] The first definition of this name.
set f(int value) {}
//  ^
// [diag.duplicateDefinition][context 1] The name 'f=' is already defined.
''');
  }

  test_topLevel_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
set f(int value) {}
//  ^
// [context 1] The first definition of this name.
set f(int value) {}
//  ^
// [diag.duplicateDefinition][context 1] The name 'f=' is already defined.
''');
  }

  test_topLevel_setter_setter_inPart() async {
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      testFile: r'''
part 'a.dart';
set f(int value) {}
//  ^
// [context 1] The first definition of this name.
''',
      a: r'''
part of 'test.dart';
set f(int value) {}
//  ^
// [diag.duplicateDefinition][context 1] The name 'f=' is already defined.
''',
    });
  }

  test_typeParameters_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T, T> {}
//      ^
// [context 1] The first definition of this name.
//         ^
// [diag.duplicateDefinition][context 1] The name 'T' is already defined.
''');
  }

  test_typeParameters_class_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<_, _> {}
''');
  }

  test_typeParameters_class_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A<_, _> {}
//      ^
// [context 1] The first definition of this name.
//         ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
''');
  }

  test_typeParameters_functionTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void F<T, T>();
//             ^
// [context 1] The first definition of this name.
//                ^
// [diag.duplicateDefinition][context 1] The name 'T' is already defined.
''');
  }

  test_typeParameters_functionTypeAlias_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void F<_, _>();
''');
  }

  test_typeParameters_functionTypeAlias_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef void F<_, _>();
//             ^
// [context 1] The first definition of this name.
//                ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
''');
  }

  test_typeParameters_genericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function<T, T>();
//                        ^
// [context 1] The first definition of this name.
//                           ^
// [diag.duplicateDefinition][context 1] The name 'T' is already defined.
''');
  }

  test_typeParameters_genericFunction_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function<_, _>();
''');
  }

  test_typeParameters_genericFunction_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef F = void Function<_, _>();
//                        ^
// [context 1] The first definition of this name.
//                           ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
''');
  }

  test_typeParameters_genericTypedef_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<T, T> = void Function();
//        ^
// [context 1] The first definition of this name.
//           ^
// [diag.duplicateDefinition][context 1] The name 'T' is already defined.
''');
  }

  test_typeParameters_genericTypedef_functionType_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<_, _> = void Function();
''');
  }

  test_typeParameters_genericTypedef_functionType_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef F<_, _> = void Function();
//        ^
// [context 1] The first definition of this name.
//           ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
''');
  }

  test_typeParameters_genericTypedef_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<T, T> = Map;
//        ^
// [context 1] The first definition of this name.
//           ^
// [diag.duplicateDefinition][context 1] The name 'T' is already defined.
''');
  }

  test_typeParameters_genericTypedef_interfaceType_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<_, _> = Map;
''');
  }

  test_typeParameters_genericTypedef_interfaceType_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef F<_, _> = Map;
//        ^
// [context 1] The first definition of this name.
//           ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
''');
  }

  test_typeParameters_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void m<T, T>() {}
//       ^
// [context 1] The first definition of this name.
//          ^
// [diag.duplicateDefinition][context 1] The name 'T' is already defined.
}
''');
  }

  test_typeParameters_method_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void m<_, _>() {}
}
''');
  }

  test_typeParameters_method_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  void m<_, _>() {}
//       ^
// [context 1] The first definition of this name.
//          ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
}
''');
  }

  test_typeParameters_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T, T>() {}
//     ^
// [context 1] The first definition of this name.
//        ^
// [diag.duplicateDefinition][context 1] The name 'T' is already defined.
''');
  }

  test_typeParameters_topLevelFunction_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<_, _>() {}
''');
  }

  test_typeParameters_topLevelFunction_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f<_, _>() {}
//     ^
// [context 1] The first definition of this name.
//        ^
// [diag.duplicateDefinition][context 1] The name '_' is already defined.
''');
  }
}

@reflectiveTest
class DuplicateDefinitionUnitTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
//    ^
// [context 1] The first definition of this name.
class B {}
class A {}
//    ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''');
  }

  test_class_augmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment class A {}
''');
  }

  test_class_library_part() async {
    var lib = getFile('$testPackageLibPath/lib.dart');
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      lib: r'''
part 'a.dart';

class A {}
//    ^
// [context 1] The first definition of this name.
''',
      a: r'''
part of 'lib.dart';

class A {}
//    ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''',
    });
  }

  test_class_part_part() async {
    var lib = getFile('$testPackageLibPath/lib.dart');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      lib: r'''
part 'a.dart';
part 'b.dart';
''',
      a: r'''
part of 'lib.dart';

class A {}
//    ^
// [context 1] The first definition of this name.
''',
      b: r'''
part of 'lib.dart';

class A {}
//    ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''',
    });
  }

  test_extension() async {
    await resolveTestCodeWithDiagnostics('''
extension A on int {}
//        ^
// [context 1] The first definition of this name.
extension B on int {}
extension A on int {}
//        ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''');
  }

  test_extension_library_part() async {
    var lib = getFile('$testPackageLibPath/lib.dart');
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      lib: r'''
part 'a.dart';

extension A on int {}
//        ^
// [context 1] The first definition of this name.
''',
      a: r'''
part of 'lib.dart';

extension A on int {}
//        ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''',
    });
  }

  test_extensionType() async {
    await resolveTestCodeWithDiagnostics('''
extension type A(int it) {}
//             ^
// [context 1] The first definition of this name.
extension type B(int it) {}
extension type A(int it) {}
//             ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''');
  }

  test_extensionType_library_part() async {
    var lib = getFile('$testPackageLibPath/lib.dart');
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      lib: r'''
part 'a.dart';

extension type A(int it) {}
//             ^
// [context 1] The first definition of this name.
''',
      a: r'''
part of 'lib.dart';

extension type A(int it) {}
//             ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''',
    });
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {}
//    ^
// [context 1] The first definition of this name.
mixin B {}
mixin A {}
//    ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''');
  }

  test_mixin_augmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
augment mixin A {}
''');
  }

  test_mixin_library_part() async {
    var lib = getFile('$testPackageLibPath/lib.dart');
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      lib: r'''
part 'a.dart';

mixin A {}
//    ^
// [context 1] The first definition of this name.
''',
      a: r'''
part of 'lib.dart';

mixin A {}
//    ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''',
    });
  }

  test_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
int foo = 0;
//  ^^^
// [context 1] The first definition of this name.
int foo = 42;
//  ^^^
// [diag.duplicateDefinition][context 1] The name 'foo' is already defined.
''');
  }

  test_topLevelVariable_topLevelVariable_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
int foo = 0;
augment abstract int foo;
''');
  }

  test_typedef_interfaceType() async {
    await resolveTestCodeWithDiagnostics('''
typedef A = List<int>;
//      ^
// [context 1] The first definition of this name.
typedef A = List<int>;
//      ^
// [diag.duplicateDefinition][context 1] The name 'A' is already defined.
''');
  }
}
