// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationWithoutDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationWithoutDeclarationTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
augment class A {}
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
''');
  }

  test_class_augments_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {}
''');
  }

  test_class_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  augment A.named();
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_constructor_augments_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}

augment class A {
  augment A.foo();
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_constructor_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

augment class A {
  augment A.foo();
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceField_augments_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
}

augment class A {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
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

  test_class_instanceField_augments_instanceField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int foo = 0;
//          ^^^
// [context 1] The corresponding getter is induced by this declaration.
}

augment class A {
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_class_instanceField_augments_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
//        ^^^
// [context 1] The corresponding getter is declared here.
}

augment class A {
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_class_instanceField_augments_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
//    ^^^
// [context 1] The corresponding setter is declared here.
// [context 2] The complete declaration is here.
}

augment class A {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
// [diag.augmentationInducedSetterAlreadyComplete][context 2] The setter induced by this augmentation is complete, but the setter being augmented is already complete.
}
''');
  }

  test_class_instanceField_augments_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
}
augment class A {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceField_augments_staticField_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
}
augment class A {
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceField_augments_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}
augment class A {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceField_augments_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}
augment class A {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceField_augments_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
}
augment class A {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceField_final_augments_instanceField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int foo = 0;
}

augment class A {
  augment abstract final int foo;
}
''');
  }

  test_class_instanceField_final_augments_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

augment class A {
  augment abstract final int foo;
}
''');
  }

  test_class_instanceField_final_augments_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
//    ^^^
// [context 1] The corresponding setter is declared here.
}

augment class A {
  augment abstract final int foo;
//                           ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_class_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceGetter_augments_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
}

augment class A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceGetter_augments_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
}
augment class A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceGetter_augments_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}
augment class A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceGetter_augments_staticGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}
augment class A {
  augment int get foo;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceGetter_augments_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}
augment class A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceGetter_augments_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
}
augment class A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceMethod_augments_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
}

augment class A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
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

  test_class_instanceMethod_augments_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
}
augment class A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceMethod_augments_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}
augment class A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceMethod_augments_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}
augment class A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceMethod_augments_staticMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}
augment class A {
  augment void foo();
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceMethod_augments_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
}
augment class A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceSetter_augments_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.foo();
}

augment class A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceSetter_augments_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
}
augment class A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceSetter_augments_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}
augment class A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceSetter_augments_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}
augment class A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceSetter_augments_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
}
augment class A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_instanceSetter_augments_staticSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
}
augment class A {
  augment set foo(int _);
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  augment static int foo = 0;
//                   ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_staticField_augments_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
augment class A {
  augment static int foo = 0;
//                   ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticField_augments_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
augment class A {
  augment static int foo = 0;
//                   ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticField_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
augment class A {
  augment static int foo = 0;
//                   ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticField_augments_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
augment class A {
  augment static int foo = 0;
//                   ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticField_augments_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
}

augment class A {
  augment static abstract int foo;
}
''');
  }

  test_class_staticField_augments_staticField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static final int foo = 0;
//                 ^^^
// [context 1] The corresponding getter is induced by this declaration.
}

augment class A {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
}
''');
  }

  test_class_staticField_augments_staticGetter() async {
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

  test_class_staticField_augments_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
//           ^^^
// [context 1] The corresponding setter is declared here.
}

augment class A {
  augment static abstract int foo;
//                            ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_class_staticField_final_augments_staticField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static final int foo = 0;
}

augment class A {
  augment static abstract final int foo;
}
''');
  }

  test_class_staticField_final_augments_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}

augment class A {
  augment static abstract final int foo;
}
''');
  }

  test_class_staticField_final_augments_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _) {}
//           ^^^
// [context 1] The corresponding setter is declared here.
}

augment class A {
  augment static abstract final int foo;
//                                  ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
}
''');
  }

  test_class_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  augment static int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_staticGetter_augments_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
augment class A {
  augment static int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                       ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticGetter_augments_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
augment class A {
  augment static int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                       ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticGetter_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
augment class A {
  augment static int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                       ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticGetter_augments_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
augment class A {
  augment static int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                       ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_staticMethod_augments_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
augment class A {
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                    ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticMethod_augments_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
augment class A {
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                    ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticMethod_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
augment class A {
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                    ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticMethod_augments_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
augment class A {
  augment static void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                    ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A {
  augment static set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_class_staticSetter_augments_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
augment class A {
  augment static set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                   ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticSetter_augments_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
augment class A {
  augment static set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                   ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticSetter_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
augment class A {
  augment static set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                   ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_class_staticSetter_augments_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
augment class A {
  augment static set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                   ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
augment enum A {}
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
''');
  }

  test_enum_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment const A.named();
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                ^^^^^
// [diag.unusedElement] The declaration 'A.named' isn't referenced.
}
''');
  }

  test_enum_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment final int foo = 0;
//                  ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_enum_instanceField_augments_staticField_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  const A();
  static int foo = 0;
}

augment enum A {;
  augment abstract int foo;
//                     ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
}
''');
  }

  test_enum_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_enum_instanceGetter_augments_staticGetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  const A();
  static int get foo => 0;
}

augment enum A {;
  augment int get foo;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_enum_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_enum_instanceMethod_augments_staticMethod_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  const A();
  static void foo() {}
}

augment enum A {;
  augment void foo();
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_enum_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_enum_instanceSetter_augments_staticSetter_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {
  v;
  const A();
  static set foo(int _) {}
}

augment enum A {;
  augment set foo(int _);
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
augment extension A {}
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
''');
  }

  test_extension_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A on int {}

augment extension A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_extension_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A on int {}

augment extension A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_extension_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A on int {}

augment extension A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
augment extension type A {}
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
''');
  }

  test_extensionType_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

augment extension type A {
  augment A.named() : this(0);
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_extensionType_hasPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
augment extension type A(int it) {}
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
//                      ^
// [diag.extensionTypeAugmentationSpecifiesRepresentationField] An extension type augmentation can't specify a representation field.
''');
  }

  test_extensionType_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

augment extension type A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_extensionType_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

augment extension type A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_extensionType_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

augment extension type A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
augment mixin A {}
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
''');
  }

  test_mixin_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}

augment mixin A {
  augment int foo = 0;
//            ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_mixin_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}

augment mixin A {
  augment int get foo => 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_mixin_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}

augment mixin A {
  augment void foo() {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_mixin_instanceMethod_augments_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void foo() {}
}

augment mixin A {
  augment void foo();
}
''');
  }

  test_mixin_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}

augment mixin A {
  augment set foo(int _) {}
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_topLevel_function() async {
    await resolveTestCodeWithDiagnostics(r'''
augment void foo() {}
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
''');
  }

  test_topLevel_function_augments_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo() {}

augment void foo();
''');
  }

  test_topLevel_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
augment int get foo => 0;
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
''');
  }

  test_topLevel_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
augment set foo(int _) {}
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
''');
  }

  test_topLevel_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
augment int foo = 0;
//          ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
''');
  }

  test_topLevel_variable_augments_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
int? get foo => 0;
//       ^^^
// [context 1] The corresponding getter is declared here.

augment abstract int? foo;
//                    ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
''');
  }

  test_topLevel_variable_augments_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int? _) {}
//  ^^^
// [context 1] The corresponding setter is declared here.

augment abstract int? foo;
//                    ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
''');
  }

  test_topLevel_variable_augments_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
int? foo = 0;

augment abstract int? foo;
''');
  }

  test_topLevel_variable_augments_variable_final() async {
    await resolveTestCodeWithDiagnostics(r'''
final int? foo = 0;
//         ^^^
// [context 1] The corresponding getter is induced by this declaration.

augment abstract int? foo;
//                    ^^^
// [diag.augmentationWithoutSetterDeclaration][context 1] This augmentation induces a setter, but no setter declaration named 'foo' exists to augment.
''');
  }

  test_topLevel_variable_final_augments_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
int? get foo => 0;

augment abstract final int? foo;
''');
  }

  test_topLevel_variable_final_augments_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
set foo(int? _) {}
//  ^^^
// [context 1] The corresponding setter is declared here.

augment abstract final int? foo;
//                          ^^^
// [diag.augmentationWithoutGetterDeclaration][context 1] This augmentation induces a getter, but no getter declaration named 'foo' exists to augment.
''');
  }

  test_topLevel_variable_final_augments_variable_final() async {
    await resolveTestCodeWithDiagnostics(r'''
final int? foo = 0;

augment abstract final int? foo;
''');
  }

  test_topLevel_variable_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
augment int foo = 0, bar = 0;
//          ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//                   ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
''');
  }

  test_topLevel_variable_multiple_oneMissing() async {
    await resolveTestCodeWithDiagnostics(r'''
int? bar = 0;

augment abstract int? foo, bar;
//                    ^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
''');
  }
}
