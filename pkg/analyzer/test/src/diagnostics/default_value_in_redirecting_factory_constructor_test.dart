// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueInRedirectingFactoryConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DefaultValueInRedirectingFactoryConstructorTest
    extends PubPackageResolutionTest {
  test_class_optionalNamed_defaultAugmentation_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int x = 0});
  factory A.foo({int x});
}

augment class A {
  augment factory A.foo({int x = 0}) = A;
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_class_optionalNamed_defaultAugmentation_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int x = 0});
  factory A.foo({int x}) = A;
//          ^^^
// [context 1] The redirecting factory is here.
}

augment class A {
  augment factory A.foo({int x = 0});
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_class_optionalNamed_defaultIntroductory_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int x = 0});
  factory A.foo({int x = 0});
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}

augment class A {
  augment factory A.foo({int x}) = A;
//                  ^^^
// [context 1] The redirecting factory is here.
}
''');
  }

  test_class_optionalNamed_defaultIntroductory_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int x = 0});
  factory A.foo({int x = 0}) = A;
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_class_optionalNamed_multipleCompleteFragments() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int x = 0});
  factory A.foo({int x = 0}) = A;
//          ^^^
// [context 1] The complete declaration is here.
}

augment class A {
  augment factory A.foo({int x}) = A;
//^^^^^^^
// [diag.constructorAlreadyComplete][context 1] The augmentation can't provide a body, initializers, or initializing formal or super formal parameters because the constructor is already complete.
}
''');
  }

  test_class_optionalPositional_defaultAugmentation_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int x = 0]);
  factory A.foo([int x]);
}

augment class A {
  augment factory A.foo([int x = 0]) = A;
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_class_optionalPositional_defaultAugmentation_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int x = 0]);
  factory A.foo([int x]) = A;
//          ^^^
// [context 1] The redirecting factory is here.
}

augment class A {
  augment factory A.foo([int x = 0]);
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_class_optionalPositional_defaultIntroductory_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int x = 0]);
  factory A.foo([int x = 0]);
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}

augment class A {
  augment factory A.foo([int x]) = A;
//                  ^^^
// [context 1] The redirecting factory is here.
}
''');
  }

  test_class_optionalPositional_defaultIntroductory_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int x = 0]);
  factory A.foo([int x = 0]) = A;
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_enum_optionalNamed_defaultAugmentation_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.foo({int x});
}

augment enum E {
  ;
  augment factory E.foo({int x = 0}) = EBox.foo;
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}

extension type EBox(E it) implements E {
  EBox.foo({int x = 0}) : this(E.v);
}
''');
  }

  test_enum_optionalNamed_defaultAugmentation_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.foo({int x}) = EBox.foo;
//          ^^^
// [context 1] The redirecting factory is here.
}

augment enum E {
  ;
  augment factory E.foo({int x = 0});
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}

extension type EBox(E it) implements E {
  EBox.foo({int x = 0}) : this(E.v);
}
''');
  }

  test_enum_optionalNamed_defaultIntroductory_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.foo({int x = 0});
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}

augment enum E {
  ;
  augment factory E.foo({int x}) = EBox.foo;
//                  ^^^
// [context 1] The redirecting factory is here.
}

extension type EBox(E it) implements E {
  EBox.foo({int x = 0}) : this(E.v);
}
''');
  }

  test_enum_optionalNamed_defaultIntroductory_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.foo({int x = 0}) = EBox.foo;
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}

extension type EBox(E it) implements E {
  EBox.foo({int x = 0}) : this(E.v);
}
''');
  }

  test_enum_optionalPositional_defaultAugmentation_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.foo([int x]);
}

augment enum E {
  ;
  augment factory E.foo([int x = 0]) = EBox.foo;
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}

extension type EBox(E it) implements E {
  EBox.foo([int x = 0]) : this(E.v);
}
''');
  }

  test_enum_optionalPositional_defaultAugmentation_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.foo([int x]) = EBox.foo;
//          ^^^
// [context 1] The redirecting factory is here.
}

augment enum E {
  ;
  augment factory E.foo([int x = 0]);
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}

extension type EBox(E it) implements E {
  EBox.foo([int x = 0]) : this(E.v);
}
''');
  }

  test_enum_optionalPositional_defaultIntroductory_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.foo([int x = 0]);
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}

augment enum E {
  ;
  augment factory E.foo([int x]) = EBox.foo;
//                  ^^^
// [context 1] The redirecting factory is here.
}

extension type EBox(E it) implements E {
  EBox.foo([int x = 0]) : this(E.v);
}
''');
  }

  test_enum_optionalPositional_defaultIntroductory_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.foo([int x = 0]) = EBox.foo;
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}

extension type EBox(E it) implements E {
  EBox.foo([int x = 0]) : this(E.v);
}
''');
  }

  test_extensionType_optionalNamed_defaultAugmentation_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A({int x = 0}) {
  factory A.foo({int x});
}

augment extension type A {
  augment factory A.foo({int x = 0}) = A;
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_extensionType_optionalNamed_defaultAugmentation_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A({int x = 0}) {
  factory A.foo({int x}) = A;
//          ^^^
// [context 1] The redirecting factory is here.
}

augment extension type A {
  augment factory A.foo({int x = 0});
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_extensionType_optionalNamed_defaultIntroductory_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A({int x = 0}) {
  factory A.foo({int x = 0});
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}

augment extension type A {
  augment factory A.foo({int x}) = A;
//                  ^^^
// [context 1] The redirecting factory is here.
}
''');
  }

  test_extensionType_optionalNamed_defaultIntroductory_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A({int x = 0}) {
  factory A.foo({int x = 0}) = A;
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_extensionType_optionalPositional_defaultAugmentation_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A([int x = 0]) {
  factory A.foo([int x]);
}

augment extension type A {
  augment factory A.foo([int x = 0]) = A;
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_extensionType_optionalPositional_defaultAugmentation_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A([int x = 0]) {
  factory A.foo([int x]) = A;
//          ^^^
// [context 1] The redirecting factory is here.
}

augment extension type A {
  augment factory A.foo([int x = 0]);
//                             ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }

  test_extensionType_optionalPositional_defaultIntroductory_redirectAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A([int x = 0]) {
  factory A.foo([int x = 0]);
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor][context 1] Default values aren't allowed in factory constructors that redirect to another constructor.
}

augment extension type A {
  augment factory A.foo([int x]) = A;
//                  ^^^
// [context 1] The redirecting factory is here.
}
''');
  }

  test_extensionType_optionalPositional_defaultIntroductory_redirectIntroductory() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A([int x = 0]) {
  factory A.foo([int x = 0]) = A;
//                     ^
// [diag.defaultValueInRedirectingFactoryConstructor] Default values aren't allowed in factory constructors that redirect to another constructor.
}
''');
  }
}
