// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedOptionalTest);
  });
}

@reflectiveTest
class DeprecatedOptionalTest extends PubPackageResolutionTest {
  test_argumentGiven() async {
    await assertNoErrorsInCode(r'''
void f([@Deprecated.optional() int? p]) {}

void g() {
  f(1);
}
''');
  }

  test_argumentGiven_implicitSuperInvocation_namedParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  C({@Deprecated.optional() int? p});
}

class D extends C {
  D({super.p});
}
''');
  }

  test_argumentGiven_implicitSuperInvocation_withSuperParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  C([@Deprecated.optional() int? p]);
}

class D extends C {
  D(super.p);
}
''');
  }

  test_argumentGiven_named() async {
    await assertNoErrorsInCode(r'''
void f({@Deprecated.optional() int? p}) {}

void g() {
  f(p: 1);
}
''');
  }

  test_argumentGiven_redirectedFromFactory_parameter_named() async {
    await assertNoErrorsInCode(r'''
class C {
  C();
  factory C.two({int? p}) = D;
}

class D extends C {
  D({@Deprecated.optional() int? p});
}
''');
  }

  test_argumentGiven_redirectedFromFactory_parameter_positional() async {
    await assertNoErrorsInCode(r'''
class C {
  C();
  factory C.two([int? p]) = D;
}

class D extends C {
  D([@Deprecated.optional() int? p]);
}
''');
  }

  test_argumentGiven_superInvocation() async {
    await assertNoErrorsInCode(r'''
class C {
  C([@Deprecated.optional() int? p]);
}

class D extends C {
  D() : super(7);
}
''');
  }

  test_argumentGiven_superInvocation_namedParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  C({@Deprecated.optional() int? p});
}

class D extends C {
  D() : super(p: 7);
}
''');
  }

  test_argumentGiven_superInvocation_namedParameter_withSuperParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  C({@Deprecated.optional() int? p});
}

class D extends C {
  D({super.p}) : super();
}
''');
  }

  test_argumentGiven_superInvocation_namedSuperConstructor() async {
    await assertNoErrorsInCode(r'''
class C {
  C.named([@Deprecated.optional() int? p]);
}

class D extends C {
  D() : super.named(7);
}
''');
  }

  test_argumentGiven_superInvocation_withSuperParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  C([@Deprecated.optional() int? p]);
}

class D extends C {
  D(super.p) : super();
}
''');
  }

  test_argumentOmitted() async {
    await assertErrorsInCode(
      r'''
void f([@Deprecated.optional() int? p]) {}

void g() {
  f();
}
''',
      [error(diag.deprecatedOptional, 57, 1)],
    );
  }

  test_argumentOmitted_dotShorthand() async {
    await assertErrorsInCode(
      r'''
class C {
  static C m({@Deprecated.optional() int? p}) => C();
}

C f() {
  return .m();
}
''',
      [error(diag.deprecatedOptional, 85, 1)],
    );
  }

  test_argumentOmitted_dotShorthandConstructor() async {
    await assertErrorsInCode(
      r'''
class C {
  C({@Deprecated.optional() int? p});
}

C f() {
  return .new();
}
''',
      [error(diag.deprecatedOptional, 69, 3)],
    );
  }

  test_argumentOmitted_implicitSuperInvocation() async {
    await assertErrorsInCode(
      r'''
class C {
  C([@Deprecated.optional() int? p]);
}

class D extends C {
  D();
}
''',
      [error(diag.deprecatedOptional, 73, 1)],
    );
  }

  test_argumentOmitted_implicitSuperInvocation_namedParameter() async {
    await assertErrorsInCode(
      r'''
class C {
  C({@Deprecated.optional() int? p});
}

class D extends C {
  D();
}
''',
      [error(diag.deprecatedOptional, 73, 1)],
    );
  }

  test_argumentOmitted_instanceCreation() async {
    await assertErrorsInCode(
      r'''
class C {
  C([@Deprecated.optional() int? p]);
}

void f() {
  C();
}
''',
      [error(diag.deprecatedOptional, 64, 1)],
    );
  }

  test_argumentOmitted_methodInvocation() async {
    await assertErrorsInCode(
      r'''
class C {
  void m({@Deprecated.optional() int? p}) {}
}

void f(C c) {
  c.m();
}
''',
      [error(diag.deprecatedOptional, 76, 1)],
    );
  }

  test_argumentOmitted_named() async {
    await assertErrorsInCode(
      r'''
void f({@Deprecated.optional() int? p}) {}

void g() {
  f();
}
''',
      [error(diag.deprecatedOptional, 57, 1)],
    );
  }

  test_argumentOmitted_override() async {
    await assertNoErrorsInCode(r'''
class C {
  void m({@Deprecated.optional() int? p}) {}
}

class D extends C {
  @override
  void m({int? p}) {}
}

void g(D d) {
  d.m();
}
''');
  }

  test_argumentOmitted_redirectedConstructor() async {
    await assertErrorsInCode(
      r'''
class C {
  C([@Deprecated.optional() int? p]);
  C.two() : this();
}
''',
      [error(diag.deprecatedOptional, 60, 4)],
    );
  }

  test_argumentOmitted_redirectedConstructor_indirectlyDeprecated() async {
    // This test asserts that we do _not_ report the `C.three` constructor.
    // While the `C.two` constructor must deal with the deprecation of the
    // optionality of `C.new`'s `p` parameter, there is nothing to do for
    // `C.three`. (For example, we can't pass a positional argument to
    // `this.two()`, because `C.two` does not accept a positional parameter.)
    // Whether and how `C.three` must change depends on how `C.two` is changed
    // to handle the deprecation.
    await assertErrorsInCode(
      r'''
class C {
  C([@Deprecated.optional() int? p]);
  C.two() : this();
  C.three() : this.two();
}
''',
      [error(diag.deprecatedOptional, 60, 4)],
    );
  }

  test_argumentOmitted_redirectedConstructor_named() async {
    await assertErrorsInCode(
      r'''
class C {
  C.one([@Deprecated.optional() int? p]);
  C.two() : this.one();
}
''',
      [error(diag.deprecatedOptional, 69, 3)],
    );
  }

  test_argumentOmitted_redirectedFromFactory_parameter_named() async {
    await assertErrorsInCode(
      r'''
class C {
  C();
  factory C.two() = D;
}

class D extends C {
  D({@Deprecated.optional() int? p});
}
''',
      [error(diag.deprecatedOptional, 27, 5)],
    );
  }

  test_argumentOmitted_redirectedFromFactory_parameter_positional() async {
    await assertErrorsInCode(
      r'''
class C {
  C();
  factory C.two() = D;
}

class D extends C {
  D([@Deprecated.optional() int? p]);
}
''',
      [error(diag.deprecatedOptional, 27, 5)],
    );
  }

  test_argumentOmitted_redirectedIndirectlyFromFactory_parameter_named() async {
    // In this test, we ensure that no warning is reported for `C.two`. That is,
    // we do not report indirect deprecation issues with redirecting factory
    // constructors. The signature of `C.two` cannot be atomically adjusted to
    // prepare for the new signature in `E.new`. The only way to prepare `C.two`
    // is to simultaneously prepare `D.two`, and preparing `C.two` will either
    // produce a new error or warning at `C.two` (if the signature is adjusted),
    // or will make `C.two` indirectly compliant (like if `D.two` is changed to
    // redirect differently, or not redirect, etc.).
    await assertErrorsInCode(
      r'''
class C {
  C();
  factory C.two() = D.two;
}

class D extends C {
  D();
  factory D.two() = E;
}

class E extends D {
  E({@Deprecated.optional() int? p});
}
''',
      [error(diag.deprecatedOptional, 84, 5)],
    );
  }

  test_argumentOmitted_superInvocation() async {
    await assertErrorsInCode(
      r'''
class C {
  C([@Deprecated.optional() int? p]);
}

class D extends C {
  D() : super();
}
''',
      [error(diag.deprecatedOptional, 79, 5)],
    );
  }

  test_argumentOmitted_superInvocation_indirectlyDeprecated() async {
    // This test asserts that we do _not_ report the `E.new` constructor. While
    // the `D.new` constructor must deal with the deprecation of the optionality
    // of `C.new`'s `p` parameter, there is nothing to do for `E.new`. (For
    // example, we can't pass a positional argument to `super()`, because
    // `D.new` does not accept a positional parameter.) Whether and how `E.new`
    // must change depends on how `D.new` is changed to handle the deprecation.
    await assertErrorsInCode(
      r'''
class C {
  C([@Deprecated.optional() int? p]);
}

class D extends C {
  D() : super();
}

class E extends D {
  E() : super();
}
''',
      [error(diag.deprecatedOptional, 79, 5)],
    );
  }

  test_argumentOmitted_superInvocation_namedParameter() async {
    await assertErrorsInCode(
      r'''
class C {
  C({@Deprecated.optional() int? p});
}

class D extends C {
  D() : super();
}
''',
      [error(diag.deprecatedOptional, 79, 5)],
    );
  }

  test_argumentOmitted_superInvocation_namedSuperConstructor() async {
    await assertErrorsInCode(
      r'''
class C {
  C.named([@Deprecated.optional() int? p]);
}

class D extends C {
  D() : super.named();
}
''',
      [error(diag.deprecatedOptional, 91, 5)],
    );
  }

  test_noAnnotation() async {
    await assertNoErrorsInCode(r'''
void f([int? p]) {}

void g() {
  f();
}
''');
  }
}
