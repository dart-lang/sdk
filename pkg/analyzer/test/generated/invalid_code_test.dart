// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCodeTest);
    defineReflectiveTests(InvalidCodeWithNullSafetyTest);
  });
}

/// Tests for various end-to-end cases when invalid code caused exceptions
/// in one or another Analyzer subsystem. We are not interested not in specific
/// errors generated, but we want to make sure that there is at least one,
/// and analysis finishes without exceptions.
@reflectiveTest
class InvalidCodeTest extends PubPackageResolutionTest {
  /// This code results in a method with the empty name, and the default
  /// constructor, which also has the empty name. The `Map` in `f` initializer
  /// references the empty name.
  test_constructorAndMethodNameCollision() async {
    await _assertCanBeAnalyzed('''
class C {
  var f = { : };
  @ ();
}
''');
  }

  test_constructorDeclaration_named_missingName() async {
    await _assertCanBeAnalyzed('''
class C {
  C.();
}
''');
  }

  test_constructorDeclaration_named_missingName_factory() async {
    await _assertCanBeAnalyzed('''
class C {
  factory C.();
}
''');
  }

  test_duplicateName_class_enum() async {
    await _assertCanBeAnalyzed('''
class A<T> {
  void foo(B b) {
    b.bar(this);
  }
}

class B {
  void bar(A a) {}
}

enum A {
  a, b, c
}
''');
  }

  test_extensionOverrideInAnnotationContext() async {
    await _assertCanBeAnalyzed('''
class R {
  const R(int x);
}

@R(E(null).f())
extension E on Object {
  int f() => 0;
}
''');
  }

  test_extensionOverrideInConstContext() async {
    await _assertCanBeAnalyzed('''
extension E on Object {
  int f() => 0;
}

const e = E(null).f();
''');
  }

  test_fieldFormalParameter_annotation_localFunction() async {
    await _assertCanBeAnalyzed(r'''
void main() {
  void foo(@deprecated this.bar) {}
}
''');
  }

  test_fuzz_01() async {
    await _assertCanBeAnalyzed(r'''
typedef F = void Function(bool, int a(double b));
''');
    var alias = findElement.functionTypeAlias('F');
    assertType(
        alias.instantiate(
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
        'void Function(bool, int Function(double))');
  }

  test_fuzz_02() async {
    await _assertCanBeAnalyzed(r'''
class G<class G{d
''');
  }

  test_fuzz_03() async {
    await _assertCanBeAnalyzed('''
class{const():super.{n
''');
  }

  test_fuzz_04() async {
    await _assertCanBeAnalyzed('''
f({a: ({b = 0}) {}}) {}
''');
  }

  test_fuzz_05() async {
    // Here 'v' is used as both the local variable name, and its type.
    // This triggers "reference before declaration" diagnostics.
    // It attempts to ask the enclosing unit element for "v".
    // Every (not library or unit) element must have the enclosing unit.
    await _assertCanBeAnalyzed('''
f({a = [for (v v in [])]}) {}
''');
  }

  test_fuzz_06() async {
    await _assertCanBeAnalyzed(r'''
class C {
  int f;
  set f() {}
}
''');
  }

  test_fuzz_07() async {
    // typedef v(<T extends T>(e
    await _assertCanBeAnalyzed(r'''
typedef F(a<TT extends TT>(e));
''');
  }

  test_fuzz_08() async {
//    class{const v
//    v=((){try catch
    // When we resolve initializers of typed constant variables,
    // we should build locale elements.
    await _assertCanBeAnalyzed(r'''
class C {
  const Object v = () { var a = 0; };
}
''');
  }

  test_fuzz_09() async {
    await _assertCanBeAnalyzed(r'''
typedef void F(int a, this.b);
''');
    var alias = findElement.functionTypeAlias('F');
    assertType(
        alias.instantiate(
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
        'void Function(int, dynamic)');
  }

  test_fuzz_10() async {
    await _assertCanBeAnalyzed(r'''
void f<@A(() { Function() v; }) T>() {}
''');
  }

  test_fuzz_11() async {
    // Here `F` is a generic function, so it cannot be used as a bound for
    // a type parameter. The reason it crashed was that we did not build
    // the bound for `Y` (not `T`), because of the order in which types
    // for `T extends F` and `typedef F` were built.
    await _assertCanBeAnalyzed(r'''
typedef F<X> = void Function<Y extends num>();
class A<T extends F> {}
''');
  }

  @failingTest
  test_fuzz_12() async {
    // This code crashed with summary2 because usually AST reader is lazy,
    // so we did not read metadata `@b` for `c`. But default values must be
    // read fully.
    await _assertCanBeAnalyzed(r'''
void f({a = [for (@b c = 0;;)]}) {}
''');
  }

  test_fuzz_13() async {
    // `x is int` promotes the type of `x` to `S extends int`, and the
    // underlying element is `TypeParameterMember`, which by itself is
    // questionable.  But this is not a valid constant anyway, so we should
    // not even try to serialize it.
    await _assertCanBeAnalyzed(r'''
const v = [<S extends num>(S x) => x is int ? x : 0];
''');
  }

  test_fuzz_14() async {
    // This crashed because parser produces `ConstructorDeclaration`.
    // So, we try to create `ConstructorElement` for it, and it wants
    // `ClassElement` as the enclosing element. But we have `ExtensionElement`.
    await _assertCanBeAnalyzed(r'''
extension E {
  factory S() {}
}
''');
  }

  test_fuzz_15() async {
    // `@A` is not a valid annotation, it is missing arguments.
    // There was a bug that we did not check for arguments being missing.
    await _assertCanBeAnalyzed(r'''
class A<T> {}

@A
class B {}
''');
  }

  test_fuzz_16() async {
    // The default constructor of `A` does not have formal parameters.
    // But we give it arguments.
    // There was a bug that we did not check for this mismatch.
    await _assertCanBeAnalyzed(r'''
class A<T> {}

@A(0)
class B {}
''');
  }

  test_fuzz_38091() async {
    // https://github.com/dart-lang/sdk/issues/38091
    // this caused an infinite loop in parser recovery
    await _assertCanBeAnalyzed(r'c(=k(<)>');
  }

  test_fuzz_38506() async {
    // https://github.com/dart-lang/sdk/issues/38506
    // We have only one LibraryElement to get resolved annotations.
    // Leave annotations node of other LibraryDirective(s) unresolved.
    await _assertCanBeAnalyzed(r'''
library c;
@foo
library c;
''');
  }

  test_fuzz_38878() async {
    // We should not attempt to resolve `super` in annotations.
    await _assertCanBeAnalyzed(r'''
class C {
  @A(super.f())
  f(int x) {}
}
''');
  }

  test_fuzz_38953() async {
    // When we enter a directive, we should stop using the element walker
    // of the unit, just like when we enter a method body. Even though using
    // interpolation is not allowed in any directives.
    await _assertCanBeAnalyzed(r'''
import '${[for(var v = 0;;) v]}';
export '${[for(var v = 0;;) v]}';
part '${[for(var v = 0;;) v]}';
''');
  }

  test_genericFunction_asTypeArgument_ofUnresolvedClass() async {
    await _assertCanBeAnalyzed(r'''
C<int Function()> c;
''');
  }

  test_keywordInConstructorInitializer_assert() async {
    await _assertCanBeAnalyzed('''
class C {
  C() : assert = 0;
}
''');
  }

  test_keywordInConstructorInitializer_null() async {
    await _assertCanBeAnalyzed('''
class C {
  C() : null = 0;
}
''');
  }

  test_keywordInConstructorInitializer_super() async {
    await _assertCanBeAnalyzed('''
class C {
  C() : super = 0;
}
''');
  }

  test_keywordInConstructorInitializer_this() async {
    await _assertCanBeAnalyzed('''
class C {
  C() : this = 0;
}
''');
  }

  test_typeBeforeAnnotation() async {
    await _assertCanBeAnalyzed('''
class A {
  const A([x]);
}
class B {
  dynamic @A(const A()) x;
}
''');
  }

  Future<void> _assertCanBeAnalyzed(String text) async {
    await resolveTestCode(text);
    assertHasTestErrors();
  }
}

@reflectiveTest
class InvalidCodeWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_issue_40837() async {
    await _assertCanBeAnalyzed('''
class A {
  const A(_);
}

@A(() => 0)
class B {}
''');
  }

  Future<void> _assertCanBeAnalyzed(String text) async {
    await resolveTestCode(text);
    assertHasTestErrors();
  }
}
