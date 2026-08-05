// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingRequiredParamTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MissingRequiredParamTest extends PubPackageResolutionTest {
  test_annotation_noImportPrefix_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.named({required int a});
}

@A.named()
// ^^^^^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
void f() {}
''');
  }

  test_annotation_noImportPrefix_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A({required int a});
}

@A()
// [diag.missingRequiredArgument][column 2][length 1] The named parameter 'a' is required, but there's no corresponding argument.
void f() {}
''');
  }

  test_annotation_withImportPrefix_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named({required int a});
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as a;

@a.A.named()
//   ^^^^^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
void f() {}
''');
  }

  test_annotation_withImportPrefix_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A({required int a});
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as a;

@a.A()
// ^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
void f() {}
''');
  }

  test_constructor_argumentGiven() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C({required int a}) {}
}

main() {
  new C(a: 2);
}
''');
  }

  test_constructor_fieldFormal_missingName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required this.})
//   ^^^^^^^^^^^^^^
// [diag.initializingFormalForNonExistentField] '' isn't a field in the enclosing class.
//                 ^
// [diag.missingIdentifier] Expected an identifier.
}
// [diag.missingFunctionBody][column 1][length 1] A function body must be provided.

void f() {
  A();
}
''');
  }

  test_constructor_missingArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C({required int a}) {}
}
main() {
  new C();
//    ^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
}
''');
  }

  test_constructor_redirectingConstructorCall() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C({required int x});
  C.named() : this();
//            ^^^^^^
// [diag.missingRequiredArgument] The named parameter 'x' is required, but there's no corresponding argument.
}
''');
  }

  test_constructor_superCall() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C({required int a}) {}
}

class D extends C {
  D() : super();
//      ^^^^^^^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
}
''');
  }

  test_constructor_superFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a}) : super();
}
''');
  }

  test_enumConstant_withArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v();
//^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
  const E({required int a});
}
''');
  }

  test_enumConstant_withoutArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
//^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
  const E({required int a});
}
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({required int a}) {}

main() {
  f();
//^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
}
''');
  }

  test_function_call() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({required int a}) {}

main() {
  f.call();
//      ^^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
}
''');
  }

  test_functionInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
void Function({required int a}) f() => throw '';
g() {
  f()();
//^^^^^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void m({required int a}) {}
}
f() {
  new A().m();
//        ^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
}
''');
  }

  test_method_inOtherLib() async {
    newFile('$testPackageLibPath/a_lib.dart', r'''
class A {
  void m({required int a}) {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import "a_lib.dart";
f() {
  new A().m();
//        ^
// [diag.missingRequiredArgument] The named parameter 'a' is required, but there's no corresponding argument.
}
''');
  }

  test_typedef_function() async {
    await resolveTestCodeWithDiagnostics(r'''
String test(C c) => c.m()();
//                  ^^^^^^^
// [diag.missingRequiredArgument] The named parameter 'x' is required, but there's no corresponding argument.

typedef String F({required String x});

class C {
  F m() => ({required String x}) => throw '';
}
''');
  }
}
