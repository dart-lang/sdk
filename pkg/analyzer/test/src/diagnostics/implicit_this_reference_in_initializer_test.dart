// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitThisReferenceInInitializerTest);
  });
}

@reflectiveTest
class ImplicitThisReferenceInInitializerTest extends PubPackageResolutionTest {
  test_class_fieldInitializer_commentReference_prefixedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int a = 0;
  /// foo [a.isEven] bar
  int x = 1;
}
''');
  }

  test_class_fieldInitializer_commentReference_simpleIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int a = 0;
  /// foo [a] bar
  int x = 1;
}
''');
  }

  test_class_fieldInitializer_late_invokeInstanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  late int x = foo();
  int foo() => 0;
}
''');
  }

  test_class_fieldInitializer_late_invokeStaticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  late int x = foo();
  static int foo() => 0;
}
''');
  }

  test_class_fieldInitializer_late_readInstanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int a = 0;
  late int x = a;
}
''');
  }

  test_class_fieldInitializer_late_readStaticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int a = 0;
  late int x = a;
}
''');
  }

  test_constructorInitializer_assert_superClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get f => 0;
}

class B extends A {
  B() : assert(f != 0);
//             ^
// [diag.implicitThisReferenceInInitializer] The instance member 'f' can't be accessed in an initializer.
}
''');
  }

  test_constructorInitializer_assert_thisClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : assert(f != 0);
//             ^
// [diag.implicitThisReferenceInInitializer] The instance member 'f' can't be accessed in an initializer.
  int get f => 0;
}
''');
  }

  test_constructorInitializer_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var v;
  A() : v = f;
//          ^
// [diag.implicitThisReferenceInInitializer] The instance member 'f' can't be accessed in an initializer.
  var f;
}
''');
  }

  test_constructorName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named() {}
}
class B {
  var v;
  B() : v = new A.named();
}
''');
  }

  test_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final x = 0;
  final y = x;
//          ^
// [diag.implicitThisReferenceInInitializer] The instance member 'x' can't be accessed in an initializer.
}
''');
  }

  test_fieldInitializer_functionReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void x<T>() {}
  final y = x<int>;
//          ^
// [diag.implicitThisReferenceInInitializer] The instance member 'x' can't be accessed in an initializer.
}
''');
  }

  test_fieldInitializer_nestedLocal() async {
    // Test that (1) does not prevent reporting an error at (2).
    await resolveTestCodeWithDiagnostics(r'''
class A {
  Map foo = {
    'a': () {
      var v = 0; // (1)
      v;
    },
    'b': _foo // (2)
//       ^^^^
// [diag.implicitThisReferenceInInitializer] The instance member '_foo' can't be accessed in an initializer.
  };

  void _foo() {}
}
''');
  }

  test_invocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var v;
  A() : v = f();
//          ^
// [diag.implicitThisReferenceInInitializer] The instance member 'f' can't be accessed in an initializer.
  f() {}
}
''');
  }

  test_invocationInStatic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static var F = m();
//               ^
// [diag.implicitThisReferenceInInitializer] The instance member 'm' can't be accessed in an initializer.
  int m() => 0;
}
''');
  }

  test_mixin_field_late_readInstanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int a = 0;
  late int x = a;
}
''');
  }

  test_prefixedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var f;
}
class B {
  var v;
  B(A a) : v = a.f;
}
''');
  }

  test_qualifiedMethodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  f() {}
}
class B {
  var v;
  B() : v = new A().f();
}
''');
  }

  test_qualifiedPropertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var f;
}
class B {
  var v;
  B() : v = new A().f;
}
''');
  }

  test_redirectingConstructorInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(p) {}
  A.named() : this(f);
//                 ^
// [diag.implicitThisReferenceInInitializer] The instance member 'f' can't be accessed in an initializer.
  var f;
}
''');
  }

  test_staticField_thisClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var v;
  A() : v = f;
  static var f;
}
''');
  }

  test_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var v;
  A() : v = f;
  static get f => 42;
}
''');
  }

  test_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var v;
  A() : v = f();
  static f() => 42;
}
''');
  }

  test_superConstructorInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(p) {}
}
class B extends A {
  B() : super(f);
//            ^
// [diag.implicitThisReferenceInInitializer] The instance member 'f' can't be accessed in an initializer.
  var f;
}
''');
  }

  test_topLevelField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var v;
  A() : v = f;
}
var f = 42;
''');
  }

  test_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var v;
  A() : v = f();
}
f() => 42;
''');
  }

  test_topLevelGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var v;
  A() : v = f;
}
get f => 42;
''');
  }

  test_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  var v;
  A(p) : v = (p is T);
}
''');
  }
}
