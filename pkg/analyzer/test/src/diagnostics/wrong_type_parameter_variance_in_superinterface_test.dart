// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongTypeParameterVarianceInSuperinterfaceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class WrongTypeParameterVarianceInSuperinterfaceTest
    extends PubPackageResolutionTest {
  test_class_extends_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
class A<X> {}
class B<X> extends A<F<X>> {}
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
''');
  }

  test_class_extends_function_parameterType_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F1<X> = void Function(X);
typedef F2<X> = void Function(F1<X>);
class A<X> {}
class B<X> extends A<F2<X>> {}
''');
  }

  test_class_extends_function_parameterType_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F1<X> = X Function();
typedef F2<X> = void Function(F1<X>);
class A<X> {}
class B<X> extends A<F2<X>> {}
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F2<X>>'.
''');
  }

  test_class_extends_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
class A<X> {}
class B<X> extends A<F<X>> {}
''');
  }

  test_class_extends_function_returnType_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F1<X> = void Function(X);
typedef F2<X> = F1<X> Function();
class A<X> {}
class B<X> extends A<F2<X>> {}
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F2<X>>'.
''');
  }

  test_class_extends_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<X> {}
class B<X> extends A<X> {}
''');
  }

  test_class_implements_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
class A<X> {}
class B<X> implements A<F<X>> {}
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
''');
  }

  test_class_implements_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
class A<X> {}
class B<X> implements A<F<X>> {}
''');
  }

  test_class_implements_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<X> {}
class B<X> implements A<X> {}
''');
  }

  test_class_with_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
mixin A<X> {}
class B<X> extends Object with A<F<X>> {}
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
''');
  }

  test_class_with_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
mixin A<X> {}
class B<X> extends Object with A<F<X>> {}
''');
  }

  test_class_with_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A<X> {}
class B<X> extends Object with A<X> {}
''');
  }

  test_classTypeAlias_extends_function_invariant() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function(X);
class A<X> {}
mixin M {}
class B<X> = A<F<X>> with M;
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
''');
  }

  test_classTypeAlias_extends_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
class A<X> {}
mixin M {}
class B<X> = A<F<X>> with M;
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
''');
  }

  test_classTypeAlias_extends_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
class A<X> {}
mixin M {}
class B<X> = A<F<X>> with M;
''');
  }

  test_classTypeAlias_extends_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<X> {}
mixin M {}
class B<X> = A<X> with M;
''');
  }

  test_classTypeAlias_implements_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
class A<X> {}
mixin M {}
class B<X> = Object with M implements A<F<X>>;
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
''');
  }

  test_classTypeAlias_implements_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
class A<X> {}
mixin M {}
class B<X> = Object with M implements A<F<X>>;
''');
  }

  test_classTypeAlias_implements_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<X> {}
mixin M {}
class B<X> = Object with M implements A<X>;
''');
  }

  test_classTypeAlias_with_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
mixin M<X> {}
class B<X> = Object with M<F<X>>;
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'M<F<X>>'.
''');
  }

  test_classTypeAlias_with_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
mixin M<X> {}
class B<X> = Object with M<F<X>>;
''');
  }

  test_classTypeAlias_with_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M<X> {}
class B<X> = Object with M<X>;
''');
  }

  test_enum_implements_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
class A<X> {}
enum E<X> implements A<F<X>> {
//     ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
  v
}
''');
  }

  test_enum_implements_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
class A<X> {}
enum E<X> implements A<F<X>> {
  v
}
''');
  }

  test_enum_implements_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<X> {}
enum E<X> implements A<X> {
  v
}
''');
  }

  test_enum_with_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
mixin A<X> {}
enum E<X> with A<F<X>> {
//     ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
  v
}
''');
  }

  test_enum_with_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
mixin A<X> {}
enum E<X> with A<F<X>> {
  v
}
''');
  }

  test_enum_with_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A<X> {}
enum E<X> with A<X> {
  v
}
''');
  }

  test_extensionType_contravariant() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
extension type B<T>(A<void Function(Object?)> it)
//               ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'T' can't be used contravariantly or invariantly in 'A<void Function(T)>'.
  implements A<void Function(T)> {}
''');
  }

  test_extensionType_covariant() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
extension type B<T>(A<Never Function()> it)
  implements A<T Function()> {}
''');
  }

  test_extensionType_invariant() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
extension type B<T>(A<Never Function(Object?)> it)
//               ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'T' can't be used contravariantly or invariantly in 'A<T Function(T)>'.
  implements A<T Function(T)> {}
''');
  }

  test_mixin_implements_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
class A<X> {}
mixin B<X> implements A<F<X>> {}
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
''');
  }

  test_mixin_implements_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
class A<X> {}
mixin B<X> implements A<F<X>> {}
''');
  }

  test_mixin_implements_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<X> {}
mixin B<X> implements A<X> {}
''');
  }

  test_mixin_on_function_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = void Function(X);
class A<X> {}
mixin B<X> on A<F<X>> {}
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<F<X>>'.
''');
  }

  test_mixin_on_function_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X> = X Function();
class A<X> {}
mixin B<X> on A<F<X>> {}
''');
  }

  test_mixin_on_withoutFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<X> {}
mixin B<X> on A<X> {}
''');
  }

  test_typeParameter_bound() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<X> {}
class B<X> extends A<void Function<Y extends X>()> {}
//      ^
// [diag.wrongTypeParameterVarianceInSuperinterface] 'X' can't be used contravariantly or invariantly in 'A<void Function<Y extends X>()>'.
''');
  }
}
