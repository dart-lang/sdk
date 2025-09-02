// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictRawTypeTest);
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
    await assertNoErrorsInCode(r'''
void f(dynamic x) {
  print(x as List);
}
''');
  }

  test_asExpression_typeArgument() async {
    await assertNoErrorsInCode(r'''
void f(dynamic x) {
  print(x as List<List>);
}
''');
  }

  test_castPattern() async {
    await assertNoErrorsInCode(r'''
void f([(Object, )? l]) {
  var (_ as List, ) = l!;
}
''');
  }

  test_castPattern_typeArgument() async {
    await assertNoErrorsInCode(r'''
void f([(Object, )? l]) {
  var (_ as List<List>, ) = l!;
}
''');
  }

  test_constantPattern() async {
    // This is not considered a "strict raw type" here, but a "strict inference"
    // issue.
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
C f(int a) => C();
void g(C a) {}
''');
  }

  test_genericTypeArgument_extensionType_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
extension type E<T>(int i) {}

void f() {
  <List<E>>[];
}
''',
      [error(WarningCode.strictRawType, 50, 1)],
    );
  }

  test_genericTypeArgument_extensionType_withTypeArg() async {
    await assertNoErrorsInCode(r'''
extension type E<T>(int i) {}

void f() {
  <List<E<int>>>[];
}
''');
  }

  test_genericTypeArgument_extensionTypeImplements_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
extension type E(List<int> i) implements Iterable {}
''',
      [error(WarningCode.strictRawType, 41, 8)],
    );
  }

  test_genericTypeArgument_extensionTypeImplementsExtensionType_missingTypeArg() async {
    await assertErrorsInCode(
      r'''

extension type E<T>(Iterable<T> i) {}

extension type F(List<int> j) implements E {}
''',
      [error(WarningCode.strictRawType, 81, 1)],
    );
  }

  test_genericTypeArgument_extensionTypeRepresentationType_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
extension type E(List i) {}
''',
      [error(WarningCode.strictRawType, 17, 4)],
    );
  }

  test_genericTypeArgument_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
void f() {
  var a = <List>[];
}
''',
      [
        error(WarningCode.unusedLocalVariable, 17, 1),
        error(WarningCode.strictRawType, 22, 4),
      ],
    );
  }

  test_genericTypeArgument_withTypeArg() async {
    await assertErrorsInCode(
      r'''
void f() {
  var a = <List<int>>[];
}
''',
      [error(WarningCode.unusedLocalVariable, 17, 1)],
    );
  }

  test_instanceCreation() async {
    // This is not considered a "strict raw type" here, but a "strict inference"
    // issue.
    await assertNoErrorsInCode(r'''
var c = List.empty();
''');
  }

  test_isExpression() async {
    await assertNoErrorsInCode(r'''
void f(dynamic x) {
  print(x is List);
  print(x is List<dynamic>);
  print(x is List<List>);
}
''');
  }

  test_localVariable_extensionType_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
extension type E<T>(int i) {}
    
void f() {
  E e = E(1);
}
''',
      [
        error(WarningCode.strictRawType, 48, 1),
        error(WarningCode.unusedLocalVariable, 50, 1),
      ],
    );
  }

  test_localVariable_extensionType_withTypeArg() async {
    await assertErrorsInCode(
      r'''
extension type E<T>(int i) {}
    
void f() {
  E<int> e = E<int>(1);
}
''',
      [error(WarningCode.unusedLocalVariable, 55, 1)],
    );
  }

  test_localVariable_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
void f() {
  List a = [1, 2, 3];
}
''',
      [
        error(WarningCode.strictRawType, 13, 4),
        error(WarningCode.unusedLocalVariable, 18, 1),
      ],
    );
  }

  test_localVariable_withTypeArg() async {
    await assertNoErrorsInCode(r'''
void f() {
  List<Object> a = [1, 2, 3];
  print(a);
}
''');
  }

  test_mixinApplication_missing() async {
    await assertErrorsInCode(
      r'''
mixin class C<T> {}
class D = Object with C;
''',
      [error(WarningCode.strictRawType, 42, 1)],
    );
  }

  test_mixinApplication_withTypeArg() async {
    await assertNoErrorsInCode(r'''
mixin class C<T> {}
class D = Object with C<int>;
''');
  }

  test_nonFunctionTypeAlias_explicitTypeArg() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
typedef List2<T> = List<T>;
void f(List2<int> a) {}
''');
  }

  test_nonFunctionTypeAlias_missingTypeArg() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode(
      '''
typedef List2<T> = List<T>;
void f(List2 a) {}
''',
      [error(WarningCode.strictRawType, 35, 5)],
    );
  }

  test_nonFunctionTypeAlias_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
@optionalTypeArgs
typedef List2<T> = List<T>;
void f(List2 a) {}
''');
  }

  test_objectPattern() async {
    // This is not considered a "strict raw type" here, but a "strict inference"
    // issue.
    await assertNoErrorsInCode(r'''
void f(Object o) {
  switch (o) {
    case List():
  }
}
''');
  }

  test_parameter_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
void f(List a) {}
''',
      [error(WarningCode.strictRawType, 7, 4)],
    );
  }

  test_returnType_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
List f(int a) => [1, 2, 3];
''',
      [error(WarningCode.strictRawType, 0, 4)],
    );
  }

  test_superclassWith_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
mixin class C<T> {}
class D extends Object with C {}
''',
      [error(WarningCode.strictRawType, 48, 1)],
    );
  }

  test_superclassWith_withTypeArg() async {
    await assertNoErrorsInCode(r'''
mixin class C<T> {}
class D extends Object with C<int> {}
''');
  }

  test_topLevelField_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
List a = [];
''',
      [error(WarningCode.strictRawType, 0, 4)],
    );
  }

  test_topLevelField_optionalTypeArg() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
C a = C();
C get g => C();
void set s(C a) {}
''');
  }

  test_topLevelField_withTypeArg() async {
    await assertNoErrorsInCode(r'''
List<int> a = [];
List<num> get g => [];
void set s(List<double> a) {}
''');
  }

  test_topLevelGetter_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
List get g => [];
''',
      [error(WarningCode.strictRawType, 0, 4)],
    );
  }

  test_topLevelSetter_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
void set s(List a) {}
''',
      [error(WarningCode.strictRawType, 11, 4)],
    );
  }

  test_typeAlias_classic_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
typedef T F1<T>(T _);
F1 func = (a) => a;
''',
      [error(WarningCode.strictRawType, 22, 2)],
    );
  }

  test_typeAlias_modern_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
typedef F1<T> = T Function(T);
F1 func = (a) => a;
''',
      [error(WarningCode.strictRawType, 31, 2)],
    );
  }

  test_typeAlias_modern_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class C {
  C();
  C.named();
}

var c = C();
var d = C.named();
''');
  }

  test_typeInExtendedType_anonymous_missing() async {
    await assertErrorsInCode(
      r'''
extension on List {}
''',
      [error(WarningCode.strictRawType, 13, 4)],
    );
  }

  test_typeInExtendedType_missing() async {
    await assertErrorsInCode(
      r'''
extension E on List {}
''',
      [error(WarningCode.strictRawType, 15, 4)],
    );
  }

  test_typeInExtendedType_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
extension E on C {}
extension on C {}
''');
  }

  test_typeInExtendedType_present() async {
    await assertNoErrorsInCode(r'''
extension E<T> on List<T> {}
extension F on List<int> {}
''');
  }

  test_typeInInterface_missing() async {
    await assertErrorsInCode(
      r'''
class C<T> {}
class D implements C {}
''',
      [error(WarningCode.strictRawType, 33, 1)],
    );
  }

  test_typeInInterface_withTypeArg() async {
    await assertNoErrorsInCode(r'''
class C<T> {}
class D implements C<int> {}
''');
  }

  test_typeInSuperclass_missing() async {
    await assertErrorsInCode(
      r'''
class C<T> {}
class D extends C {}
''',
      [error(WarningCode.strictRawType, 30, 1)],
    );
  }

  test_typeInSuperclass_withTypeArg() async {
    await assertNoErrorsInCode(r'''
class C<T> {}
class D extends C<int> {}
''');
  }

  test_typeParameterBound_missingTypeArg() async {
    await assertErrorsInCode(
      r'''
class C<T> {}
class D<T extends C> {}
''',
      [error(WarningCode.strictRawType, 32, 1)],
    );
  }

  test_typeParameterBound_withTypeArg() async {
    await assertNoErrorsInCode(r'''
class C<T> {}
class D<S, T extends C<S>> {}
''');
  }
}
