// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantDefaultValueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantDefaultValueTest extends PubPackageResolutionTest {
  test_constructor_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int y = 0;
  A({x = y}) {}
//       ^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.implicitThisReferenceInInitializer] The instance member 'y' can't be accessed in an initializer.
}
''');
  }

  test_constructor_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int y = 0;
  A([x = y]) {}
//       ^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.implicitThisReferenceInInitializer] The instance member 'y' can't be accessed in an initializer.
}
''');
  }

  test_dotShorthand_issue60962() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

void f([A a = .new()]) {}
//            ^^^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
''');
  }

  test_enum_issue49097() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const foo = A();
  static const bar = A();
  const A();
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

enum E {
  v(f: A.foo);
  final A f;
  const E({this.f = A.bar});
}
''');
  }

  test_function_named() async {
    await resolveTestCodeWithDiagnostics(r'''
int y = 0;
f({x = y}) {}
//     ^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
''');
  }

  test_function_named_constList() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = const [0, 1]}) {}
''');
  }

  test_function_named_constList_elements_listLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = const [0, [1]]}) {}
''');
  }

  test_function_named_constRecord() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = const (0, 1)}) {}
''');
  }

  test_function_named_constRecord_namedFields_listLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = const (0, foo: [1])}) {}
''');
  }

  test_function_named_constRecord_positionalFields_listLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = const (0, [1])}) {}
''');
  }

  test_function_named_record_namedFields_integerLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = (a: 0, b: 1)}) {}
''');
  }

  test_function_named_record_namedFields_listLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = (a: 0, b: [1])}) {}
//                    ^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
''');
  }

  test_function_named_record_namedFields_listLiteral_const() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = (a: 0, b: const [1])}) {}
''');
  }

  test_function_named_record_positionalFields_integerLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = (0, 1)}) {}
''');
  }

  test_function_named_record_positionalFields_listLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = (0, [1])}) {}
//              ^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
''');
  }

  test_function_named_record_positionalFields_listLiteral_const() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({x = (0, const [1])}) {}
''');
  }

  test_function_named_undefinedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int x = X}) {}
//              ^
// [diag.undefinedIdentifier] Undefined name 'X'.
''');
  }

  test_function_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
int y = 0;
f([x = y]) {}
//     ^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
''');
  }

  test_function_positional_undefinedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([int x = X]) {}
//              ^
// [diag.undefinedIdentifier] Undefined name 'X'.
''');
  }

  test_method_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int y = 0;
  m({x = y}) {}
//       ^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.implicitThisReferenceInInitializer] The instance member 'y' can't be accessed in an initializer.
}
''');
  }

  test_method_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int y = 0;
  m([x = y]) {}
//       ^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.implicitThisReferenceInInitializer] The instance member 'y' can't be accessed in an initializer.
}
''');
  }

  test_noAppliedTypeParameters_defaultConstructorValue_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) => t;

class C<T> {
  final dynamic p;
  const C({this.p = f});
}
''');
  }

  test_noAppliedTypeParameters_defaultConstructorValue_genericFn() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) => t;

class C<T> {
  final void Function<T>(T) p;
  const C({this.p = f});
}
''');
  }

  test_noAppliedTypeParameters_defaultFunctionValue_genericFn() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) => t;

void bar<T>([void Function<T>(T) p = f]) {}
''');
  }

  test_noAppliedTypeParameters_defaultMethodValue_genericFn() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) => t;

class C<T> {
  void foo([void Function<T>(T) p = f]) {}
}
''');
  }

  test_primaryConstructor_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
int y = 0;
class A({int x = y});
//               ^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
''');
  }

  test_primaryConstructor_optionalPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
int y = 0;
class A([int x = y]);
//               ^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
''');
  }
}
