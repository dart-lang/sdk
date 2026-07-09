// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictRawTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class StrictRawTypeTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments, strictRawTypes: true),
    );
  }

  test_asExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(dynamic x) {
  print(x as List);
}
''');
  }

  test_asExpression_typeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(dynamic x) {
  print(x as List<List>);
}
''');
  }

  test_castPattern() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([(Object, )? l]) {
  var (_ as List, ) = l!;
}
''');
  }

  test_castPattern_typeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([(Object, )? l]) {
  var (_ as List<List>, ) = l!;
}
''');
  }

  test_constantPattern() async {
    // This is not considered a "strict raw type" here, but a "strict inference"
    // issue.
    await resolveTestCodeWithDiagnostics(r'''
void f(C<int> c) {
  switch (c) {
    case const C():
  }
}

class C<T> {
  const C();
}
''');
  }

  test_functionParts_optionalTypeArg() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
C f(int a) => C();
void g(C a) {}
''');
  }

  test_genericTypeArgument_extensionType_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E<T>(int i) {}

void f() {
  <List<E>>[];
//      ^
// [diag.strictRawType] The generic type 'E<dynamic>' should have explicit type arguments but doesn't.
}
''');
  }

  test_genericTypeArgument_extensionType_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E<T>(int i) {}

void f() {
  <List<E<int>>>[];
}
''');
  }

  test_genericTypeArgument_extensionTypeImplements_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(List<int> i) implements Iterable {}
//                                       ^^^^^^^^
// [diag.strictRawType] The generic type 'Iterable<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_genericTypeArgument_extensionTypeImplementsExtensionType_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''

extension type E<T>(Iterable<T> i) {}

extension type F(List<int> j) implements E {}
//                                       ^
// [diag.strictRawType] The generic type 'E<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_genericTypeArgument_extensionTypeRepresentationType_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(List i) {}
//               ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_genericTypeArgument_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var a = <List>[];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//         ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
}
''');
  }

  test_genericTypeArgument_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var a = <List<int>>[];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_instanceCreation() async {
    // This is not considered a "strict raw type" here, but a "strict inference"
    // issue.
    await resolveTestCodeWithDiagnostics(r'''
var c = List.empty();
''');
  }

  test_isExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(dynamic x) {
  print(x is List);
  print(x is List<dynamic>);
  print(x is List<List>);
}
''');
  }

  test_localVariable_extensionType_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E<T>(int i) {}
    
void f() {
  E e = E(1);
//^
// [diag.strictRawType] The generic type 'E<dynamic>' should have explicit type arguments but doesn't.
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'e' isn't used.
}
''');
  }

  test_localVariable_extensionType_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E<T>(int i) {}
    
void f() {
  E<int> e = E<int>(1);
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'e' isn't used.
}
''');
  }

  test_localVariable_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  List a = [1, 2, 3];
//^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_localVariable_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  List<Object> a = [1, 2, 3];
  print(a);
}
''');
  }

  test_mixinApplication_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class C<T> {}
class D = Object with C;
//                    ^
// [diag.strictRawType] The generic type 'C<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_mixinApplication_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class C<T> {}
class D = Object with C<int>;
''');
  }

  test_nonFunctionTypeAlias_explicitTypeArg() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics('''
typedef List2<T> = List<T>;
void f(List2<int> a) {}
''');
  }

  test_nonFunctionTypeAlias_missingTypeArg() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics('''
typedef List2<T> = List<T>;
void f(List2 a) {}
//     ^^^^^
// [diag.strictRawType] The generic type 'List2<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_nonFunctionTypeAlias_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';
@optionalTypeArgs
typedef List2<T> = List<T>;
void f(List2 a) {}
''');
  }

  test_objectPattern() async {
    // This is not considered a "strict raw type" here, but a "strict inference"
    // issue.
    await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case List():
  }
}
''');
  }

  test_parameter_default_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({List a = const []}) {}
//      ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_parameter_fieldFormal_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  Object a;
  C(List this.a);
//  ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
}
''');
  }

  test_parameter_functionTyped_parameter_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void a(List p)) {}
//            ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_parameter_functionTyped_returnType_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List a()) {}
//     ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_parameter_primaryDeclaring_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(final List a);
//            ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_parameter_simple_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List a) {}
//     ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_parameter_super_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  Object a;
  C(this.a);
}
class D extends C {
  D(List super.a);
//  ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
}
''');
  }

  test_returnType_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
List f(int a) => [1, 2, 3];
// [diag.strictRawType][column 1][length 4] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_superclassWith_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class C<T> {}
class D extends Object with C {}
//                          ^
// [diag.strictRawType] The generic type 'C<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_superclassWith_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class C<T> {}
class D extends Object with C<int> {}
''');
  }

  test_topLevelField_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
List a = [];
// [diag.strictRawType][column 1][length 4] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_topLevelField_optionalTypeArg() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
C a = C();
C get g => C();
void set s(C a) {}
''');
  }

  test_topLevelField_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
List<int> a = [];
List<num> get g => [];
void set s(List<double> a) {}
''');
  }

  test_topLevelGetter_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
List get g => [];
// [diag.strictRawType][column 1][length 4] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_topLevelSetter_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void set s(List a) {}
//         ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_typeAlias_classic_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T F1<T>(T _);
F1 func = (a) => a;
// [diag.strictRawType][column 1][length 2] The generic type 'F1<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_typeAlias_modern_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F1<T> = T Function(T);
F1 func = (a) => a;
// [diag.strictRawType][column 1][length 2] The generic type 'F1<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_typeAlias_modern_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
typedef T F1<T>(T _);
@optionalTypeArgs
typedef F2<T> = T Function(T);
F1 f1 = (a) => a;
F2 f2 = (a) => a;
''');
  }

  test_typeAlias_modern_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T F1<T>(T _);
typedef F2<T> = T Function(T);
typedef F3 = T Function<T>(T);
F1<int> f1 = (a) => a;
F2<int> f2 = (a) => a;
F3 f3 = <T>(T a) => a;
''');
  }

  test_typeInClassDeclaration_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
mixin class C<T> {}
class D extends C {}
class E extends Object with C {}
class F = Object with C;
class G implements C {}
''');
  }

  test_typeInConstructorName() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C();
  C.named();
}

var c = C();
var d = C.named();
''');
  }

  test_typeInExtendedType_anonymous_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
extension on List {}
//           ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_typeInExtendedType_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on List {}
//             ^^^^
// [diag.strictRawType] The generic type 'List<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_typeInExtendedType_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
extension E on C {}
extension on C {}
''');
  }

  test_typeInExtendedType_present() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E<T> on List<T> {}
extension F on List<int> {}
''');
  }

  test_typeInInterface_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}
class D implements C {}
//                 ^
// [diag.strictRawType] The generic type 'C<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_typeInInterface_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}
class D implements C<int> {}
''');
  }

  test_typeInSuperclass_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}
class D extends C {}
//              ^
// [diag.strictRawType] The generic type 'C<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_typeInSuperclass_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}
class D extends C<int> {}
''');
  }

  test_typeLiteral_raw() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var t = List;
  print(t);
}
''');
  }

  test_typeParameterBound_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}
class D<T extends C> {}
//                ^
// [diag.strictRawType] The generic type 'C<dynamic>' should have explicit type arguments but doesn't.
''');
  }

  test_typeParameterBound_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}
class D<S, T extends C<S>> {}
''');
  }
}
