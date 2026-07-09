// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationOfDifferentDeclarationKindTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationOfDifferentDeclarationKindTest
    extends PubPackageResolutionTest {
  test_class_augments_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {v}
//   ^
// [context 1] The declaration being augmented.
augment class A {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a enum with a class.
''');
  }

  test_class_augments_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A on int {}
//        ^
// [context 1] The declaration being augmented.
augment class A {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a extension with a class.
''');
  }

  test_class_augments_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
//             ^
// [context 1] The declaration being augmented.
augment class A {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a extension type with a class.
''');
  }

  test_class_augments_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}
//   ^^^
// [context 1] The declaration being augmented.
augment class foo {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a function with a class.
''');
  }

  test_class_augments_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
//      ^^^
// [context 1] The declaration being augmented.
augment class foo {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a getter with a class.
''');
  }

  test_class_augments_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
//    ^
// [context 1] The declaration being augmented.
augment class A {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a mixin with a class.
''');
  }

  test_class_augments_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}
//  ^^^
// [context 1] The declaration being augmented.
augment class foo {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a setter with a class.
''');
  }

  test_class_augments_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
int foo = 0;
//  ^^^
// [context 1] The declaration being augmented.
augment class foo {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a top level variable with a class.
''');
  }

  test_class_constructor_augments_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
}
augment class A {
  augment A.foo();
}
''');
  }

  test_class_constructor_augments_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
//           ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment A.foo();
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a field with a constructor.
}
''');
  }

  test_class_constructor_augments_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
//            ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment A.foo();
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a method with a constructor.
}
''');
  }

  test_class_instanceField_augments_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
augment class A {
  augment abstract int foo;
}
''');
  }

  test_class_instanceField_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment int foo = 0;
//            ^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a method with a field.
}
''');
  }

  test_class_instanceGetter_augments_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
augment class A {
  augment int get foo;
}
''');
  }

  test_class_instanceGetter_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a method with a getter.
}
''');
  }

  test_class_instanceMethod_augments_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
//    ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a field with a method.
}
''');
  }

  test_class_instanceMethod_augments_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
//        ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a getter with a method.
}
''');
  }

  test_class_instanceMethod_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
augment class A {
  augment void foo();
}
''');
  }

  test_class_instanceMethod_augments_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
//    ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a setter with a method.
}
''');
  }

  test_class_instanceSetter_augments_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
augment class A {
  augment set foo(int _);
}
''');
  }

  test_class_instanceSetter_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
//     ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a method with a setter.
}
''');
  }

  test_class_staticField_augments_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
//  ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static int foo = 0;
//                   ^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a constructor with a field.
}
''');
  }

  test_class_staticField_augments_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
//            ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static int foo = 0;
//                   ^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a method with a field.
}
''');
  }

  test_class_staticGetter_augments_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
//  ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static int get foo => 0;
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a constructor with a getter.
}
''');
  }

  test_class_staticGetter_augments_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
//            ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static int get foo => 0;
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a method with a getter.
}
''');
  }

  test_class_staticMethod_augments_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
//  ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a constructor with a method.
}
''');
  }

  test_class_staticMethod_augments_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
//           ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a field with a method.
}
''');
  }

  test_class_staticMethod_augments_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
//               ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a getter with a method.
}
''');
  }

  test_class_staticMethod_augments_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
//           ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a setter with a method.
}
''');
  }

  test_class_staticSetter_augments_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
//  ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static set foo(int _) {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a constructor with a setter.
}
''');
  }

  test_class_staticSetter_augments_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
//            ^^^
// [context 1] The declaration being augmented.
}
augment class A {
  augment static set foo(int _) {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a method with a setter.
}
''');
  }

  test_enum_augments_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
//    ^
// [context 1] The declaration being augmented.
augment enum A {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a class with a enum.
''');
  }

  test_enum_constant_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  void foo() {}
}
augment enum A {
  augment foo(),
//        ^^^
// [diag.constantVariableAugmentation] Variable augmentations can't be const.
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_enum_staticMethod_augments_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  foo
//^^^
// [context 1] The declaration being augmented.
}
augment enum A {;
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a field with a method.
}
''');
  }

  test_extension_augments_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
//    ^
// [context 1] The declaration being augmented.
augment extension A {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a class with a extension.
''');
  }

  test_extensionType_augments_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
//    ^
// [context 1] The declaration being augmented.
augment extension type A {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a class with a extension type.
''');
  }

  test_function_augments_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
//    ^
// [context 1] The declaration being augmented.
augment void A() {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a class with a function.
''');
  }

  test_mixin_augments_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
//    ^
// [context 1] The declaration being augmented.
augment mixin A {}
// [diag.augmentationOfDifferentDeclarationKind][column 1][length 7][context 1] Can't augment a class with a mixin.
''');
  }

  test_typedef_augments_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment typedef A = int;
// [diag.typedefAugmentation][column 1][length 7] Type aliases can't be augmented.
''');
  }

  test_variable_augments_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
//    ^
// [context 1] The declaration being augmented.
augment int A = 0;
//          ^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a class with a top level variable.
''');
  }

  test_variable_augments_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}
//   ^^^
// [context 1] The declaration being augmented.
augment int foo = 0;
//          ^^^
// [diag.augmentationOfDifferentDeclarationKind][context 1] Can't augment a function with a top level variable.
''');
  }
}
