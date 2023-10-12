// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstConstructorsInImmutablesTest);
  });
}

@reflectiveTest
class PreferConstConstructorsInImmutablesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'prefer_const_constructors_in_immutables';

  test_assertInitializer_canBeConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class C {
  C.named(a) : assert(a != null);
}
''', [
      lint(57, 1),
    ]);
  }

  test_assertInitializer_cannotBeConst() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class C {
  C.named(a) : assert(a.toString() == 'string');
}
''');
  }

  test_extendsImmutable_constConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  const A();
}
class B extends A {
  const B();
}
''');
  }

  test_extendsImmutable_nonConstConstructor() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  const A();
}
class B extends A {
  B();
}
''', [
      lint(91, 1),
    ]);
  }

  test_extendsImmutable_nonConstSuperCall() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
class B extends A {
  B() : super();
}
''');
  }

  test_extensionType_constConstructor_named() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
extension type const E(int i) {
  const E.e(this.i);
}
''');
  }

  test_extensionType_constConstructor_primary() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
extension type const E(int i) { }
''');
  }

  test_extensionType_nonConstConstructor_named() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
extension type const E(int i) {
  E.e(this.i);
}
''', [
      lint(78, 1),
    ]);
  }

  test_extensionType_nonConstConstructor_primary() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
extension type E(int i) { }
''', [
      lint(59, 1),
    ]);
  }

  test_immutable_constConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  const A();
}
''');
  }

  test_immutable_constConstructor_named() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  const A.named();
}
''');
  }

  test_immutable_constFactory() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const factory C() = C.named;
  const C.named();
}
''');
  }

  test_immutable_constRedirectingConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C();
  const C.named() : this();
}
''');
  }

  test_immutable_constructorHasBody() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  A.named() {}
}
''');
  }

  test_immutable_factoryConsrtuctor_toConstConstructor() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C();
  factory C.named() = C;
}
''', [
      lint(69, 7),
    ]);
  }

  test_immutable_factoryConstructor_toNonConst() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  C() {}
  factory C.named() = C;
}
''');
  }

  test_immutable_fieldWithInitializer() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  final f = Object();
  C();
}
''');
  }

  test_immutable_hasMixin() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
mixin M {}

@immutable
class C with M {
  C();
}
''');
  }

  test_immutable_nonConstConstructor() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  A();
}
''', [
      lint(56, 1),
    ]);
  }

  test_immutable_nonConstFactory() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  factory C() = C.named;
  const C.named();
}
''', [
      lint(56, 7),
    ]);
  }

  test_immutable_nonConstInInitializerList() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  final String _a; // ignore: unused_field
  C(int a) : _a = a.toString();
}
''');
  }

  test_immutable_nonConstInInitializerList2() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  final int _a; // ignore: unused_field
  C(int a) : _a = a;
}
''', [
      lint(96, 1),
    ]);
  }

  test_immutable_nonConstInInitializerList3() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  final bool _a; // ignore: unused_field
  C(bool a) : _a = a && a;
}
''', [
      lint(97, 1),
    ]);
  }

  test_immutable_nonConstInInitializerList4() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  final String _a; // ignore: unused_field
  C(bool a) : _a = '${a ? a : ''}';
}
''', [
      lint(99, 1),
    ]);
  }

  test_immutable_nonConstInInitializerList5() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  final bool f;
  C(bool? f) : f = f ?? f == null;
}
''', [
      lint(72, 1),
    ]);
  }

  test_immutable_nonConstInInitializerList6() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
int notConst = 0;
@immutable
class C {
  final int f;
  C(Object f) : f = notConst;
}
''');
  }

  test_immutable_redirectingConstructor() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  C.a();
  C.b() : this.a();
}
''', [
      lint(56, 1),
    ]);
  }

  test_immutable_redirectingConstructor_toConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C();
  C.named(): this();
}
''', [
      lint(69, 1),
    ]);
  }

  test_implementsImmutable() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  const A();
}
class B implements A {
  B();
}
''');
  }

  test_implementsImmutable_named() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  const A();
}
class B implements A {
  const B.named();
}
''');
  }

  test_implicitSuperConstructorInvocation_undefined() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class A {
  const A.named();
}

class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          99, 1),
    ]);
  }

  test_returnOfInvalidType() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class F {
  factory F.fc() => null;
}
''', [
      // No lint
      error(
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR, 75, 4),
    ]);
  }
}
