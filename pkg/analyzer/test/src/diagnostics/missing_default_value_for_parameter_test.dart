// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingDefaultValueForParameterTest);
    defineReflectiveTests(MissingDefaultValueForParameterWithAnnotationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MissingDefaultValueForParameterTest extends PubPackageResolutionTest {
  test_closure_nonNullable_named_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
var f = ({int a = 0}) {};
''');
  }

  test_closure_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
var f = ({int a}) {};
//            ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
''');
  }

  test_closure_nonNullable_positional_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
var f = ([int a = 0]) {};
''');
  }

  test_closure_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
var f = ([int a]) {};
//            ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
''');
  }

  test_constructor_externalFactory_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  external factory C({int a});
}
''');
  }

  test_constructor_externalFactory_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  external factory C([int a]);
}
''');
  }

  test_constructor_externalFactory_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  external factory C({int? a});
}
''');
  }

  test_constructor_factory_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  factory C({int a}) => C._();
//               ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
  C._();
}
''');
  }

  test_constructor_factory_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  factory C([int a]) => C._();
//               ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
  C._();
}
''');
  }

  test_constructor_factory_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  factory C({int? a}) => C._();
  C._();
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C({int a});
//       ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_noDefault_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C({int a});
//       ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.

  augment C({int a}) {}
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_super_hasDefault_explicit() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A({required int a});
}
class B extends A{
  B({super.a = 0});
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_super_hasDefault_fromSuper() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A({int a = 0});
}
class B extends A{
  B({super.a});
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_super_hasDefault_fromSuper_extensionType() async {
    await resolveTestCodeWithDiagnostics('''
extension type const E(int it) {}

class A {
  A({E a = const E(0)});
}

class B extends A {
  B({super.a});
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_super_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A({int? a});
}
class B extends A{
  B({int super.a});
//             ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_super_noDefault_fromSuper() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A({num a = 1.2});
}
class B extends A{
  B({int super.a});
//             ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_default_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C([int a]);

  augment C([int a = 0]) {}
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_default_introduction_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C([int a = 0]);

  augment C([int a]) {}
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C([int a]);
//       ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_noDefault_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C([int a]);
//       ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.

  augment C([int a]) {}
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_noDefault_primary_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class C([int x]) {
//           ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'x' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
  augment C([int x]);
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_super_hasDefault_explicit() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A(int a);
}
class B extends A{
  B([super.a = 0]);
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_super_hasDefault_fromSuper() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A([int a = 0]);
}
class B extends A{
  B([super.a]);
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_super_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A([int? a]);
}
class B extends A{
  B([int super.a]);
//             ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_super_noDefault_fromSuper() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A([num a = 1.2]);
}
class B extends A{
  B([int super.a]);
//             ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_constructor_generative_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C({int? a});
}
''');
  }

  test_constructor_generative_nullable_named_optional_noDefault_fieldFormal() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  int? f;
  C({this.f});
}
''');
  }

  test_constructor_generative_super_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int a;
  A({this.a = 0});
}

class B extends A {
  B({required super.a});
}

class C extends B {
  C({super.a});
//         ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_constructor_generative_super_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int? a;
  A({this.a});
}

class B extends A {
  B({required super.a});
}

class C extends B {
  C({super.a});
}
''');
  }

  test_constructor_redirectingFactory_nonNullable_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  factory A({int a}) = B;
}

class B implements A {
  B({int a = 0});
}
''');
  }

  test_constructor_redirectingFactory_nonNullable_named_optional_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A({int a = 0});
  factory A.redirect({int a});
  augment factory A.redirect({int a}) = A;
}
''');
  }

  test_constructor_redirectingFactory_nonNullable_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  factory A([int a]) = B;
}

class B implements A {
  B([int a = 0]);
}
''');
  }

  test_constructor_redirectingFactory_nonNullable_positional_optional_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A([int a = 0]);
  factory A.redirect([int a]);
  augment factory A.redirect([int a]) = A;
}
''');
  }

  test_constructor_redirectingFactory_nullable_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  factory A({int? a}) = B;
}

class B implements A {
  B({int? a});
}
''');
  }

  test_fieldFormalParameter_functionTyped_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  dynamic f;
  A(void this.f({int a, int? b}));
}
''');
  }

  test_fieldFormalParameter_functionTyped_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  dynamic f;
  A(void this.f([int a, int? b]));
}
''');
  }

  test_function_external_nonNullable_named_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
external void f({int a = 0});
''');
  }

  test_function_external_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
external void f({int a});
''');
  }

  test_function_external_nonNullable_named_required_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
external void f({required int a});
''');
  }

  test_function_external_nonNullable_positional_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
external void f([int a = 0]);
''');
  }

  test_function_external_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
external void f([int a]);
''');
  }

  test_function_external_nonNullable_positional_required_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
external void f(int a);
''');
  }

  test_function_external_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
external void f({int? a});
''');
  }

  test_function_external_nullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
external void f([int? a]);
''');
  }

  test_function_native_nonNullable_named_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
void f({int a = 0}) native;
//                  ^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
''');
  }

  test_function_native_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
void f({int a}) native;
//              ^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
''');
  }

  test_function_native_nonNullable_positional_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
void f([int a = 0]) native;
//                  ^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
''');
  }

  test_function_native_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
void f([int a]) native;
//              ^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
''');
  }

  test_function_nonNullable_named_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
void f({int a = 0}) {}
''');
  }

  test_function_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
void f({int a}) {}
//          ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
''');
  }

  test_function_nonNullable_named_optional_noDefault_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
void f({int a});
//          ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.

augment void f({int a}) {}
''');
  }

  test_function_nonNullable_named_required() async {
    await resolveTestCodeWithDiagnostics('''
void f({required int a}) {}
''');
  }

  test_function_nonNullable_positional_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
void f([int a = 0]) {}
''');
  }

  test_function_nonNullable_positional_optional_default_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
void f([int a]);

augment void f([int a = 0]) {}
''');
  }

  test_function_nonNullable_positional_optional_default_introduction() async {
    await resolveTestCodeWithDiagnostics('''
void f([int a = 0]);

augment void f([int a]) {}
''');
  }

  test_function_nonNullable_positional_optional_default_middleAugmentation() async {
    await resolveTestCodeWithDiagnostics('''
void f([int a]);

augment void f([int a = 0]);

augment void f([int a]) {}
''');
  }

  test_function_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
void f([int a]) {}
//          ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
''');
  }

  test_function_nonNullable_positional_optional_noDefault_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
void f([int a]);
//          ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.

augment void f([int a]) {}
''');
  }

  test_function_nonNullable_positional_required() async {
    await resolveTestCodeWithDiagnostics('''
void f(int a) {}
''');
  }

  test_function_nullable_named_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
void f({int? a = 0}) {}
''');
  }

  test_function_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
void f({int? a}) {}
''');
  }

  test_function_nullable_named_required() async {
    await resolveTestCodeWithDiagnostics('''
void f({required int? a}) {}
''');
  }

  test_function_nullable_positional_optional_default() async {
    await resolveTestCodeWithDiagnostics('''
void f([int? a = 0]) {}
''');
  }

  test_function_nullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
void f([int? a]) {}
''');
  }

  test_function_nullable_positional_required() async {
    await resolveTestCodeWithDiagnostics('''
void f(int? a) {}
''');
  }

  test_functionTypeAlias_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
typedef void F({int a, int? b});
''');
  }

  test_functionTypeAlias_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
typedef void F([int a, int? b]);
''');
  }

  test_functionTypedFormalParameter_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
void f(void p({int a, int? b})) {}
''');
  }

  test_functionTypedFormalParameter_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
void f(void p([int a, int? b])) {}
''');
  }

  test_genericFunctionType_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
void f(void Function({int a, int? b}) p) {}
''');
  }

  test_genericFunctionType_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
void f(void Function([int a, int? b]) p) {}
''');
  }

  test_genericFunctionType_positional_optional2() async {
    await resolveTestCodeWithDiagnostics('''
void f(void Function([int, int?]) p) {}
''');
  }

  test_method_abstract_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
abstract class C {
  void foo({int a});
}
''');
  }

  test_method_abstract_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
abstract class C {
  void foo([int a]);
}
''');
  }

  test_method_abstract_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
abstract class C {
  void foo({int? a});
}
''');
  }

  test_method_abstract_potentiallyNonNullable_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A<T> {
  void foo({T a});
}
''');
  }

  test_method_abstract_potentiallyNonNullable_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A<T extends Object?> {
  void foo([T a]);
}
''');
  }

  test_method_external_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  external void foo({int a});
}
''');
  }

  test_method_external_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  external void foo([int a]);
}
''');
  }

  test_method_external_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  external void foo({int? a});
}
''');
  }

  test_method_external_potentiallyNonNullable_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  external void foo({T a});
}
''');
  }

  test_method_external_potentiallyNonNullable_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A<T extends Object?> {
  external void foo([T a]);
}
''');
  }

  test_method_native_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo({int a}) native;
//                  ^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
}
''');
  }

  test_method_native_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo([int a]) native;
//                  ^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
}
''');
  }

  test_method_native_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo({int? a}) native;
//                   ^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
}
''');
  }

  test_method_native_potentiallyNonNullable_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  void foo({T a}) native;
//                ^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
}
''');
  }

  test_method_native_potentiallyNonNullable_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A<T extends Object?> {
  void foo([T a]) native;
//                ^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
}
''');
  }

  test_method_nonNullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo({int a}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_method_nonNullable_named_optional_noDefault_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo({int a});
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.

  augment void foo({int a}) {}
}
''');
  }

  test_method_nonNullable_positional_optional_default_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo([int a]);

  augment void foo([int a = 0]) {}
}
''');
  }

  test_method_nonNullable_positional_optional_default_introduction() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo([int a = 0]);

  augment void foo([int a]) {}
}
''');
  }

  test_method_nonNullable_positional_optional_default_middleAugmentation() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo([int a]);

  augment void foo([int a = 0]);

  augment void foo([int a]) {}
}
''');
  }

  test_method_nonNullable_positional_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo([int a]) {}
//              ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_method_nonNullable_positional_optional_noDefault_augmentation() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo([int a]);
//              ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.

  augment void foo([int a]) {}
}
''');
  }

  test_method_nullable_named_optional_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void foo({int? a}) {}
}
''');
  }

  test_method_potentiallyNonNullable_named_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A<T extends Object?> {
  void foo({T a}) {}
//            ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_method_potentiallyNonNullable_positional_optional() async {
    await resolveTestCodeWithDiagnostics('''
class A<T extends Object?> {
  void foo([T a]) {}
//            ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_super_forward_wildcards() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int x, y;
  A(this.x, [this.y = 0]);
}

class C extends A {
  final int c;
  C(this.c, super._, [super._]);
}
''');
  }
}

@reflectiveTest
class MissingDefaultValueForParameterWithAnnotationTest
    extends PubPackageResolutionTest {
  test_method_withAnnotation() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class C {
  // ignore: deprecated_member_use
  void foo({@required int a}) {}
//                        ^
// [diag.missingDefaultValueForParameterWithAnnotation] With null safety, use the 'required' keyword, not the '@required' annotation.
}
''');
  }
}
