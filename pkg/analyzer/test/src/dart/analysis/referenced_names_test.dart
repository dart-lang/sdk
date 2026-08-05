// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/referenced_names.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ComputeReferencedNamesTest);
    defineReflectiveTests(ComputeSubtypedNamesTest);
  });
}

@reflectiveTest
class ComputeReferencedNamesTest extends ParserDiagnosticsTest {
  test_analyzerDiagnosticExpectation_ignoredByDefault() {
    var names = _computeReferencedNames(r'''
void f() {
  '// [diag.foo]';
}
''');
    expect(names, unorderedEquals(['void']));
  }

  test_analyzerDiagnosticExpectation_included() {
    var names = _computeReferencedNames(r'''
void f() {
  '// [diag.foo]';
}
''', includeAnalyzerDiagnosticExpectations: true);
    expect(names, unorderedEquals(['foo', 'void']));
  }

  test_class_constructor() {
    var names = _computeReferencedNames('''
class U {
  U.named(A a, B b) {
    C c = null;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_class_constructor_invocation() {
    var names = _computeReferencedNames('''
f() {
  const A.foo();
}
''');
    expect(names, unorderedEquals(['A', 'foo']));
  }

  test_class_constructor_invocation_prefixed() {
    var names = _computeReferencedNames('''
import 'a.dart' as p;

f() {
  const p.A();
}
''');
    expect(names, unorderedEquals(['A']));
  }

  test_class_constructor_parameters() {
    var names = _computeReferencedNames('''
class U {
  U(A a) {
    a;
    b;
  }
}
''');
    expect(names, unorderedEquals(['A', 'b']));
  }

  test_class_constructor_superFormalParameter() {
    var names = _computeReferencedNames('''
class A {
  A({x});
}
class B extends A {
  B({super.x});
}
''');
    expect(names, unorderedEquals(['x']));
  }

  test_class_extends_sameName_importPrefix() {
    var names = _computeReferencedNames('''
import 'a.dart' as p;
class A extends p.A {}
''');
    expect(names, unorderedEquals(['A']));
  }

  test_class_field() {
    var names = _computeReferencedNames('''
class U {
  A f = new B();
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_class_getter() {
    var names = _computeReferencedNames('''
class U {
  A get a => new B();
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_class_members() {
    var names = _computeReferencedNames('''
class U {
  int a;
  int get b;
  set c(_) {}
  m(D d) {
    a;
    b;
    c = 1;
    m();
  }
}
''');
    expect(names, unorderedEquals(['int', 'D']));
  }

  test_class_members_dontHideQualified() {
    var names = _computeReferencedNames('''
class U {
  int a;
  int get b;
  set c(_) {}
  m(D d) {
    d.a;
    d.b;
    d.c;
  }
}
''');
    expect(names, unorderedEquals(['int', 'D', 'a', 'b', 'c']));
  }

  test_class_method() {
    var names = _computeReferencedNames('''
class U {
  A m(B p) {
    C v = 0;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_class_method_localVariables() {
    var names = _computeReferencedNames('''
class U {
  A m() {
    B b = null;
    b;
    {
      C c = null;
      b;
      c;
    }
    d;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'd']));
  }

  test_class_method_parameters() {
    var names = _computeReferencedNames('''
class U {
  m(A a) {
    a;
    b;
  }
}
''');
    expect(names, unorderedEquals(['A', 'b']));
  }

  test_class_method_parameters_dontHideNamedExpressionName() {
    var names = _computeReferencedNames('''
main() {
  var p;
  new C(p: p);
}
''');
    expect(names, unorderedEquals(['C', 'p']));
  }

  test_class_method_typeParameters() {
    var names = _computeReferencedNames('''
class U {
  A m<T>(B b, T t) {
    C c = 0;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_class_setter() {
    var names = _computeReferencedNames('''
class U {
  set a(A a) {
    B b = null;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_class_typeParameters() {
    var names = _computeReferencedNames('''
class U<T> {
  T f = new A<T>();
}
''');
    expect(names, unorderedEquals(['A']));
  }

  test_extensionType_typeParameters() {
    var names = _computeReferencedNames('''
extension type Z<T>(int it) {
  A m(B b, T t, Z z) {
    C c = 0;
  }
}
''');
    expect(names, unorderedEquals(['int', 'A', 'B', 'C']));
  }

  test_instantiatedNames_importPrefix() {
    var names = _computeReferencedNames('''
import 'a.dart' as p1;
import 'b.dart' as p2;
main() {
  new p1.A();
  new p1.A.c1();
  new p1.B();
  new p2.C();
  new D();
  new D.c2();
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D', 'c1', 'c2']));
  }

  test_localFunction() {
    var names = _computeReferencedNames('''
f(A a) {
  g(B b) {}
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_superToSubs_importPrefix() {
    var names = _computeReferencedNames('''
import 'a.dart' as p1;
import 'b.dart' as p2;
class U extends p1.A with p2.B implements p2.C {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_topLevelVariable() {
    var names = _computeReferencedNames('''
A v = new B(c);
''');
    expect(names, unorderedEquals(['A', 'B', 'c']));
  }

  test_topLevelVariable_multiple() {
    var names = _computeReferencedNames('''
A v1 = new B(c), v2 = new D<E>(f);
''');
    expect(names, unorderedEquals(['A', 'B', 'c', 'D', 'E', 'f']));
  }

  test_unit_classTypeAlias() {
    var names = _computeReferencedNames('''
class U = A with B implements C;
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_classTypeAlias_typeParameters() {
    var names = _computeReferencedNames('''
class U<T1, T2 extends D> = A<T1> with B<T2> implements C<T1, T2>;
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D']));
  }

  test_unit_extension() {
    var names = _computeReferencedNames('''
extension E on int {}
f() {
  E;
}
''');
    expect(names, unorderedEquals(['int']));
  }

  test_unit_function() {
    var names = _computeReferencedNames('''
A f(B b) {
  C c = 0;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_function_doc() {
    var names = _computeReferencedNames('''
/**
 * Documentation [C.d] reference.
 */
A f(B b) {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'd']));
  }

  test_unit_function_dontHideQualified() {
    var names = _computeReferencedNames('''
class U {
  int a;
  int get b;
  set c(_) {}
  m(D d) {
    d.a;
    d.b;
    d.c;
  }
}
''');
    expect(names, unorderedEquals(['int', 'D', 'a', 'b', 'c']));
  }

  test_unit_function_localFunction_parameter() {
    var names = _computeReferencedNames('''
A f() {
  B g(x) {
    x;
    return null;
  }
  return null;
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_unit_function_localFunctions() {
    var names = _computeReferencedNames('''
A f() {
  B b = null;
  C g() {}
  g();
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_function_localsDontHideQualified() {
    var names = _computeReferencedNames('''
f(A a, B b) {
  var v = 0;
  a.v;
  a.b;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'v', 'b']));
  }

  test_unit_function_localVariables() {
    var names = _computeReferencedNames('''
A f() {
  B b = null;
  b;
  {
    C c = null;
    b;
    c;
  }
  d;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'd']));
  }

  test_unit_function_parameters() {
    var names = _computeReferencedNames('''
A f(B b) {
  C c = 0;
  b;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_function_parameters_dontHideQualified() {
    var names = _computeReferencedNames('''
f(x, C g()) {
  g().x;
}
''');
    expect(names, unorderedEquals(['C', 'x']));
  }

  test_unit_function_typeParameters() {
    var names = _computeReferencedNames('''
A f<T>(B b, T t) {
  C c = 0;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_functionTypeAlias() {
    var names = _computeReferencedNames('''
typedef A F(B B, C c(D d));
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D']));
  }

  test_unit_functionTypeAlias_typeParameters() {
    var names = _computeReferencedNames('''
typedef A F<T>(B b, T t);
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_unit_getter() {
    var names = _computeReferencedNames('''
A get aaa {
  return new B();
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_unit_setter() {
    var names = _computeReferencedNames('''
set aaa(A a) {
  B b = null;
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_unit_topLevelDeclarations() {
    var names = _computeReferencedNames('''
class L1 {}
class L2 = A with B implements C;
A L3() => null;
typedef A L4(B b);
A get L5 => null;
set L6(_) {}
A L7, L8;
main() {
  L1;
  L2;
  L3;
  L4;
  L5;
  L6;
  L7;
  L8;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  Set<String> _computeReferencedNames(
    String code, {
    bool includeAnalyzerDiagnosticExpectations = false,
  }) {
    var parseResult = parseTestCodeWithDiagnostics(code);
    var unit = parseResult.unit;
    return computeReferencedNames(
      unit,
      includeAnalyzerDiagnosticExpectations:
          includeAnalyzerDiagnosticExpectations,
    );
  }
}

@reflectiveTest
class ComputeSubtypedNamesTest extends ParserDiagnosticsTest {
  void test_classDeclaration() {
    var names = _computeSubtypedNames('''
import 'lib.dart';
class X extends A {}
class Y extends A with B {}
class Z implements A, B, C {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  void test_classTypeAlias() {
    var names = _computeSubtypedNames('''
import 'lib.dart';
class X = A with B implements C, D, E;
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D', 'E']));
  }

  void test_extensionTypeDeclaration() {
    var names = _computeSubtypedNames('''
extension type E1(X it) implements A {}
extension type E2(X it) implements B {}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  void test_mixinDeclaration() {
    var names = _computeSubtypedNames('''
import 'lib.dart';
mixin M on A, B implements C, D {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D']));
  }

  void test_prefixed() {
    var names = _computeSubtypedNames('''
import 'lib.dart' as p;
class X extends p.A with p.B implements p.C {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  void test_typeArguments() {
    var names = _computeSubtypedNames('''
import 'lib.dart';
class X extends A<B> {}
''');
    expect(names, unorderedEquals(['A']));
  }

  Set<String> _computeSubtypedNames(String code) {
    var parseResult = parseTestCodeWithDiagnostics(code);
    var unit = parseResult.unit;
    return computeSubtypedNames(unit);
  }
}
