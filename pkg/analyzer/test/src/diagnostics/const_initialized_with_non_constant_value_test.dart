// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstInitializedWithNonConstantValueTest);
  });
}

@reflectiveTest
class ConstInitializedWithNonConstantValueTest
    extends PubPackageResolutionTest {
  test_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(p) {
  const c = p;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
//          ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
}
''');
  }

  test_finalField() async {
    // Regression test for bug #25526; previously, two errors were reported.
    await resolveTestCodeWithDiagnostics(r'''
class Foo {
  final field = 0;
  foo([int x = field]) {}
//             ^^^^^
// [diag.nonConstantDefaultValue] The default value of an optional parameter must be constant.
// [diag.implicitThisReferenceInInitializer] The instance member 'field' can't be accessed in an initializer.
}
''');
  }

  test_functionExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = () {};
//        ^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_invalidNamedRead_instance() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = 'abc'.lenght;
//              ^^^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'lenght' isn't defined for the type 'String'.
''');
  }

  test_invalidNamedRead_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
const x = p.foo;
//          ^^^
// [diag.undefinedPrefixedNameReadNotFoundConstant] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
''');
  }

  test_invalidNamedRead_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
const x = C.foo;
//          ^^^
// [diag.undefinedStaticMemberReadNotFoundConstant] The class 'C' doesn't have a static member or constructor named 'foo'.
''');
  }

  test_invalidNamedRead_unqualified() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = foo;
//        ^^^
// [diag.undefinedUnqualifiedNameReadNotFoundConstant] Undefined name 'foo'.
''');
  }

  test_invalidNamedRead_unqualified_binaryOperand() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = foo + 1;
//        ^^^
// [diag.undefinedUnqualifiedNameReadNotFoundConstant] Undefined name 'foo'.
''');
  }

  test_invalidType_functionInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
Undefined f() => throw 0;
// [diag.undefinedClass][column 1][length 9] Undefined class 'Undefined'.
const x = f();
//        ^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_invalidType_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
Undefined v = throw 0;
// [diag.undefinedClass][column 1][length 9] Undefined class 'Undefined'.
const x = v;
//        ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_missingConstInListLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
const List L = [0];
''');
  }

  test_missingConstInMapLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
const Map M = {'a' : 0};
''');
  }

  test_newInstance_constConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}
const a = new A();
//        ^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_newInstance_externalFactoryConstConstructor() async {
    // We can't evaluate "const A()" because its constructor is external.  But
    // the code is correct--we shouldn't report an error.
    await resolveTestCodeWithDiagnostics(r'''
class A {
  external const factory A();
}
const x = const A();
''');
  }

  test_propertyExtraction_targetNotConst() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
  int m() => 0;
}
final a = const A();
const c = a.m;
//        ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_typeLiteral_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = int;
''');
  }

  test_typeLiteral_typeAlias_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A = int;
const a = A;
''');
  }
}
