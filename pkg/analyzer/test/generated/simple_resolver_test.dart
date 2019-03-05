// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleResolverTest);
  });
}

@reflectiveTest
class SimpleResolverTest extends DriverResolutionTest {
  test_argumentResolution_required_matching() async {
    addTestFile(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, c) {}
}''');
    await _validateArgumentResolution([0, 1, 2]);
  }

  test_argumentResolution_required_tooFew() async {
    addTestFile(r'''
class A {
  void f() {
    g(1, 2);
  }
  void g(a, b, c) {}
}''');
    await _validateArgumentResolution([0, 1]);
  }

  test_argumentResolution_required_tooMany() async {
    addTestFile(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b) {}
}''');
    await _validateArgumentResolution([0, 1, -1]);
  }

  test_argumentResolution_requiredAndNamed_extra() async {
    addTestFile('''
class A {
  void f() {
    g(1, 2, c: 3, d: 4);
  }
  void g(a, b, {c}) {}
}''');
    await _validateArgumentResolution([0, 1, 2, -1]);
  }

  test_argumentResolution_requiredAndNamed_matching() async {
    addTestFile(r'''
class A {
  void f() {
    g(1, 2, c: 3);
  }
  void g(a, b, {c}) {}
}''');
    await _validateArgumentResolution([0, 1, 2]);
  }

  test_argumentResolution_requiredAndNamed_missing() async {
    addTestFile('''
class A {
  void f() {
    g(1, 2, d: 3);
  }
  void g(a, b, {c, d}) {}
}''');
    await _validateArgumentResolution([0, 1, 3]);
  }

  test_argumentResolution_requiredAndPositional_fewer() async {
    addTestFile('''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, [c, d]) {}
}''');
    await _validateArgumentResolution([0, 1, 2]);
  }

  test_argumentResolution_requiredAndPositional_matching() async {
    addTestFile(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c, d]) {}
}''');
    await _validateArgumentResolution([0, 1, 2, 3]);
  }

  test_argumentResolution_requiredAndPositional_more() async {
    addTestFile(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c]) {}
}''');
    await _validateArgumentResolution([0, 1, 2, -1]);
  }

  test_argumentResolution_setter_propagated() async {
    addTestFile(r'''
main() {
  var a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    await resolveTestFile();

    var rhs = findNode.assignment(' = 0;').rightHandSide;
    expect(
      rhs.staticParameterElement,
      findElement.parameter('x'),
    );
  }

  test_argumentResolution_setter_propagated_propertyAccess() async {
    addTestFile(r'''
main() {
  var a = new A();
  a.b.sss = 0;
}
class A {
  B b = new B();
}
class B {
  set sss(x) {}
}''');
    await resolveTestFile();

    var rhs = findNode.assignment(' = 0;').rightHandSide;
    expect(
      rhs.staticParameterElement,
      findElement.parameter('x'),
    );
  }

  test_argumentResolution_setter_static() async {
    addTestFile(r'''
main() {
  A a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    await resolveTestFile();

    var rhs = findNode.assignment(' = 0;').rightHandSide;
    expect(
      rhs.staticParameterElement,
      findElement.parameter('x'),
    );
  }

  test_argumentResolution_setter_static_propertyAccess() async {
    addTestFile(r'''
main() {
  A a = new A();
  a.b.sss = 0;
}
class A {
  B b = new B();
}
class B {
  set sss(x) {}
}''');
    await resolveTestFile();

    var rhs = findNode.assignment(' = 0;').rightHandSide;
    expect(
      rhs.staticParameterElement,
      findElement.parameter('x'),
    );
  }

  test_breakTarget_labeled() async {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    addTestFile(r'''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      break loop1;
      break loop2;
    }
  }
}
''');
    await resolveTestFile();

    var break1 = findNode.breakStatement('break loop1;');
    var whileStatement = findNode.whileStatement('while (');
    expect(break1.target, same(whileStatement));

    var break2 = findNode.breakStatement('break loop2;');
    var forStatement = findNode.forStatement2('for (');
    expect(break2.target, same(forStatement));
  }

  test_breakTarget_unlabeledBreakFromDo() async {
    addTestFile('''
void f() {
  do {
    break;
  } while (true);
}
''');
    await resolveTestFile();

    var doStatement = findNode.doStatement('do {');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(doStatement));
  }

  test_breakTarget_unlabeledBreakFromFor() async {
    addTestFile(r'''
void f() {
  for (int i = 0; i < 10; i++) {
    break;
  }
}
''');
    await resolveTestFile();

    var forStatement = findNode.forStatement2('for (');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(forStatement));
  }

  test_breakTarget_unlabeledBreakFromForEach() async {
    addTestFile('''
void f() {
  for (x in []) {
    break;
  }
}
''');
    await resolveTestFile();

    var forStatement = findNode.forStatement2('for (');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(forStatement));
  }

  test_breakTarget_unlabeledBreakFromSwitch() async {
    addTestFile(r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        break;
    }
  }
}
''');
    await resolveTestFile();

    var switchStatement = findNode.switchStatement('switch (');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(switchStatement));
  }

  test_breakTarget_unlabeledBreakFromWhile() async {
    addTestFile(r'''
void f() {
  while (true) {
    break;
  }
}
''');
    await resolveTestFile();

    var whileStatement = findNode.whileStatement('while (');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(whileStatement));
  }

  test_breakTarget_unlabeledBreakToOuterFunction() async {
    // Verify that unlabeled break statements can't resolve to loops in an
    // outer function.
    addTestFile(r'''
void f() {
  while (true) {
    void g() {
      break;
    }
  }
}
''');
    await resolveTestFile();

    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, isNull);
  }

  test_class_definesCall() async {
    await assertNoErrorsInCode(r'''
class A {
  int call(int x) { return x; }
}
int f(A a) {
  return a(0);
}''');
  }

  test_class_extends_implements() async {
    await assertNoErrorsInCode(r'''
class A extends B implements C {}
class B {}
class C {}''');
  }

  test_continueTarget_labeled() async {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    addTestFile('''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      continue loop1;
      continue loop2;
    }
  }
}
''');
    await resolveTestFile();

    var continue1 = findNode.continueStatement('continue loop1');
    var whileStatement = findNode.whileStatement('while (');
    expect(continue1.target, same(whileStatement));

    var continue2 = findNode.continueStatement('continue loop2');
    var forStatement = findNode.forStatement2('for (');
    expect(continue2.target, same(forStatement));
  }

  test_continueTarget_unlabeledContinueFromDo() async {
    addTestFile('''
void f() {
  do {
    continue;
  } while (true);
}
''');
    await resolveTestFile();

    var doStatement = findNode.doStatement('do {');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(doStatement));
  }

  test_continueTarget_unlabeledContinueFromFor() async {
    addTestFile('''
void f() {
  for (int i = 0; i < 10; i++) {
    continue;
  }
}
''');
    await resolveTestFile();

    var forStatement = findNode.forStatement2('for (');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(forStatement));
  }

  test_continueTarget_unlabeledContinueFromForEach() async {
    addTestFile(r'''
void f() {
  for (x in []) {
    continue;
  }
}
''');
    await resolveTestFile();

    var forStatement = findNode.forStatement2('for (');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(forStatement));
  }

  test_continueTarget_unlabeledContinueFromWhile() async {
    addTestFile(r'''
void f() {
  while (true) {
    continue;
  }
}
''');
    await resolveTestFile();

    var whileStatement = findNode.whileStatement('while (');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(whileStatement));
  }

  test_continueTarget_unlabeledContinueSkipsSwitch() async {
    addTestFile(r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        continue;
    }
  }
}
''');
    await resolveTestFile();

    var whileStatement = findNode.whileStatement('while (');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(whileStatement));
  }

  test_continueTarget_unlabeledContinueToOuterFunction() async {
    // Verify that unlabeled continue statements can't resolve to loops in an
    // outer function.
    addTestFile(r'''
void f() {
  while (true) {
    void g() {
      continue;
    }
  }
}
''');
    await resolveTestFile();

    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, isNull);
  }

  test_empty() async {
    addTestFile('');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_entryPoint_exported() async {
    newFile('/test/lib/a.dart', content: r'''
main() {}
''');

    addTestFile(r'''
export 'a.dart';
''');
    await resolveTestFile();
    assertNoTestErrors();

    var library = result.libraryElement;
    var main = library.entryPoint;

    expect(main, isNotNull);
    expect(main.library, isNot(same(library)));
  }

  test_entryPoint_local() async {
    addTestFile(r'''
main() {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var library = result.libraryElement;
    var main = library.entryPoint;

    expect(main, isNotNull);
    expect(main.library, same(library));
  }

  test_entryPoint_none() async {
    addTestFile('');
    await resolveTestFile();
    assertNoTestErrors();

    var library = result.libraryElement;
    expect(library.entryPoint, isNull);
  }

  test_enum_externalLibrary() async {
    newFile('/test/lib/a.dart', content: r'''
enum EEE {A, B, C}
''');
    addTestFile(r'''
import 'a.dart';

void f(EEE e) {}
''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  test_extractedMethodAsConstant() async {
    await assertNoErrorsInCode(r'''
abstract class Comparable<T> {
  int compareTo(T other);
  static int compare(Comparable a, Comparable b) => a.compareTo(b);
}
class A {
  void sort([compare = Comparable.compare]) {}
}''');
    verifyTestResolved();
  }

  test_fieldFormalParameter() async {
    addTestFile(r'''
class A {
  int x;
  int y;
  A(this.x) : y = x {}
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var xParameter = findNode.fieldFormalParameter('this.x');

    var xParameterElement =
        xParameter.declaredElement as FieldFormalParameterElement;
    expect(xParameterElement.field, findElement.field('x'));

    assertElement(
      findNode.simple('x {}'),
      xParameterElement,
    );
  }

  test_forEachLoops_nonConflicting() async {
    await assertNoErrorsInCode(r'''
f() {
  List list = [1,2,3];
  for (int x in list) {}
  for (int x in list) {}
}''');
    verifyTestResolved();
  }

  test_forLoops_nonConflicting() async {
    await assertNoErrorsInCode(r'''
f() {
  for (int i = 0; i < 3; i++) {
  }
  for (int i = 0; i < 3; i++) {
  }
}''');
    verifyTestResolved();
  }

  test_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef bool P(e);
class A {
  P p;
  m(e) {
    if (p(e)) {}
  }
}''');
    verifyTestResolved();
  }

  test_getter_and_setter_fromMixins_bare_identifier() async {
    addTestFile('''
class B {}
class M1 {
  get x => null;
  set x(value) {}
}
class M2 {
  get x => null;
  set x(value) {}
}
class C extends B with M1, M2 {
  void f() {
    x += 1;
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    // Verify that both the getter and setter for "x" in C.f() refer to the
    // accessors defined in M2.
    var leftHandSide = findNode.simple('x +=');
    expect(
      leftHandSide.staticElement,
      findElement.setter('x', of: 'M2'),
    );
    expect(
      leftHandSide.auxiliaryElements.staticElement,
      findElement.getter('x', of: 'M2'),
    );
  }

  @failingTest
  test_getter_and_setter_fromMixins_property_access() async {
    // TODO(paulberry): it appears that auxiliaryElements isn't properly set on
    // a SimpleIdentifier that's inside a property access.  This bug should be
    // fixed.
    addTestFile(r'''
class B {}
class M1 {
  get x => null;
  set x(value) {}
}
class M2 {
  get x => null;
  set x(value) {}
}
class C extends B with M1, M2 {}
void main() {
  new C().x += 1;
}
''');
    assertNoTestErrors();
    verifyTestResolved();

    // Verify that both the getter and setter for "x" in "new C().x" refer to
    // the accessors defined in M2.
    var leftHandSide = findNode.simple('x +=');
    expect(
      leftHandSide.staticElement,
      findElement.setter('x', of: 'M2'),
    );
    expect(
      leftHandSide.auxiliaryElements.staticElement,
      findElement.getter('x', of: 'M2'),
    );
  }

  test_getter_fromMixins_bare_identifier() async {
    addTestFile('''
class B {}
class M1 {
  get x => null;
}
class M2 {
  get x => null;
}
class C extends B with M1, M2 {
  f() {
    return x;
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    // Verify that the getter for "x" in C.f() refers to the getter defined in
    // M2.
    expect(
      findNode.simple('x;').staticElement,
      findElement.getter('x', of: 'M2'),
    );
  }

  test_getter_fromMixins_property_access() async {
    addTestFile('''
class B {}
class M1 {
  get x => null;
}
class M2 {
  get x => null;
}
class C extends B with M1, M2 {}
void main() {
  var y = new C().x;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    // Verify that the getter for "x" in "new C().x" refers to the getter
    // defined in M2.
    expect(
      findNode.simple('x;').staticElement,
      findElement.getter('x', of: 'M2'),
    );
  }

  test_getterAndSetterWithDifferentTypes() async {
    addTestFile(r'''
class A {
  int get f => 0;
  void set f(String s) {}
}
g (A a) {
  a.f = a.f.toString();
}''');
    await resolveTestFile();
    assertTestErrors([StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verifyTestResolved();
  }

  test_hasReferenceToSuper() async {
    addTestFile(r'''
class A {}
class B {toString() => super.toString();}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.hasReferenceToSuper, isFalse);

    var b = findElement.class_('B');
    expect(b.hasReferenceToSuper, isTrue);
  }

  test_import_hide() async {
    newFile('/test/lib/lib1.dart', content: r'''
set foo(value) {}
class A {}''');

    newFile('/test/lib/lib2.dart', content: r'''
set foo(value) {}''');

    addTestFile(r'''
import 'lib1.dart' hide foo;
import 'lib2.dart';

main() {
  foo = 0;
}
A a;''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  test_import_prefix() async {
    newFile('/test/lib/a.dart', content: r'''
f(int x) {
  return x * x;
}''');

    addTestFile(r'''
import 'a.dart' as _a;
main() {
  _a.f(0);
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  test_import_prefix_doesNotExist() async {
    //
    // The primary purpose of this test is to ensure that we are only getting a
    // single error generated when the only problem is that an imported file
    // does not exist.
    //
    addTestFile('''
import 'missing.dart' as p;
int a = p.q + p.r.s;
String b = p.t(a) + p.u(v: 0);
p.T c = new p.T();
class D<E> extends p.T {
  D(int i) : super(i);
  p.U f = new p.V();
}
class F implements p.T {
  p.T m(p.U u) => null;
}
class G extends Object with p.V {}
class H extends D<p.W> {
  H(int i) : super(i);
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
    verifyTestResolved();
  }

  test_import_show_doesNotExist() async {
    //
    // The primary purpose of this test is to ensure that we are only getting a
    // single error generated when the only problem is that an imported file
    // does not exist.
    //
    addTestFile('''
import 'missing.dart' show q, r, t, u, T, U, V, W;
int a = q + r.s;
String b = t(a) + u(v: 0);
T c = new T();
class D<E> extends T {
  D(int i) : super(i);
  U f = new V();
}
class F implements T {
  T m(U u) => null;
}
class G extends Object with V {}
class H extends D<W> {
  H(int i) : super(i);
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
    verifyTestResolved();
  }

  @failingTest
  test_import_spaceInUri() async {
    // TODO(scheglov) Fix this. The problem is in `package` URI resolver.
    newFile('/test/lib/sub folder/a.dart', content: r'''
foo() {}''');

    await assertNoErrorsInCode(r'''
import 'sub folder/a.dart';

main() {
  foo();
}''');
    verifyTestResolved();
  }

  test_indexExpression_typeParameters() async {
    await assertNoErrorsInCode(r'''
f() {
  List<int> a;
  a[0];
  List<List<int>> b;
  b[0][0];
  List<List<List<int>>> c;
  c[0][0][0];
}''');
    verifyTestResolved();
  }

  test_indexExpression_typeParameters_invalidAssignmentWarning() async {
    addTestFile(r'''
f() {
  List<List<int>> b;
  b[0][0] = 'hi';
}''');
    await resolveTestFile();
    assertTestErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verifyTestResolved();
  }

  test_indirectOperatorThroughCall() async {
    await assertNoErrorsInCode(r'''
class A {
  B call() { return new B(); }
}

class B {
  int operator [](int i) { return i; }
}

A f = new A();

g(int x) {}

main() {
  g(f()[0]);
}''');
    verifyTestResolved();
  }

  test_invoke_dynamicThroughGetter() async {
    await assertNoErrorsInCode(r'''
class A {
  List get X => [() => 0];
  m(A a) {
    X.last;
  }
}''');
    verifyTestResolved();
  }

  test_isValidMixin_badSuperclass() async {
    addTestFile(r'''
class A extends B {}
class B {}
class C = Object with A;''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isFalse);
  }

  test_isValidMixin_constructor() async {
    addTestFile(r'''
class A {
  A() {}
}
class C = Object with A;''');
    await resolveTestFile();
    assertTestErrors(
      [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR],
    );
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isFalse);
  }

  test_isValidMixin_factoryConstructor() async {
    addTestFile(r'''
class A {
  factory A() => null;
}
class C = Object with A;''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isTrue);
  }

  test_isValidMixin_super() async {
    addTestFile(r'''
class A {
  toString() {
    return super.toString();
  }
}
class C = Object with A;''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MIXIN_REFERENCES_SUPER]);
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isFalse);
  }

  test_isValidMixin_valid() async {
    await assertNoErrorsInCode('''
class A {}
class C = Object with A;''');
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isTrue);
  }

  test_labels_switch() async {
    await assertNoErrorsInCode(r'''
void doSwitch(int target) {
  switch (target) {
    l0: case 0:
      continue l1;
    l1: case 1:
      continue l0;
    default:
      continue l1;
  }
}''');
    verifyTestResolved();
  }

  test_localVariable_types_invoked() async {
    addTestFile(r'''
const A = null;
main() {
  var myVar = (int p) => 'foo';
  myVar(42);
}''');
    await resolveTestFile();

    var node = findNode.simple('myVar(42)');
    assertType(node, '(int) → String');
  }

  test_metadata_class() async {
    addTestFile(r'''
const A = null;
@A class C<A> {}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var annotations = findElement.class_('C').metadata;
    expect(annotations, hasLength(1));

    var cDeclaration = findNode.classDeclaration('C<A>');
    assertElement(
      cDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_field() async {
    addTestFile(r'''
const A = null;
class C {
  @A int f;
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var metadata = findElement.field('f').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_fieldFormalParameter() async {
    addTestFile(r'''
const A = null;
class C {
  int f;
  C(@A this.f);
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var metadata = findElement.fieldFormalParameter('f').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_function() async {
    addTestFile(r'''
const A = null;
@A f() {}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var annotations = findElement.topFunction('f').metadata;
    expect(annotations, hasLength(1));
  }

  test_metadata_functionTypedParameter() async {
    addTestFile(r'''
const A = null;
f(@A int p(int x)) {}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var metadata = findElement.parameter('p').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_libraryDirective() async {
    addTestFile(r'''
@A library lib;
const A = null;''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var metadata = result.libraryElement.metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_method() async {
    addTestFile(r'''
const A = null;
class C {
  @A void m() {}
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var metadata = findElement.method('m').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_namedParameter() async {
    addTestFile(r'''
const A = null;
f({@A int p : 0}) {}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var metadata = findElement.parameter('p').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_positionalParameter() async {
    addTestFile(r'''
const A = null;
f([@A int p = 0]) {}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    var metadata = findElement.parameter('p').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_simpleParameter() async {
    addTestFile(r'''
const A = null;
f(@A p1, @A int p2) {}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    expect(findElement.parameter('p1').metadata, hasLength(1));
    expect(findElement.parameter('p2').metadata, hasLength(1));
  }

  test_metadata_typedef() async {
    addTestFile(r'''
const A = null;
@A typedef F<A>();''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    expect(
      findElement.genericTypeAlias('F').metadata,
      hasLength(1),
    );

    var actualElement = findNode.annotation('@A').name.staticElement;
    expect(actualElement, findElement.topGet('A'));
  }

  test_method_fromMixin() async {
    addTestFile(r'''
class B {
  bar() => 1;
}
class A {
  foo() => 2;
}

class C extends B with A {
  bar() => super.bar();
  foo() => super.foo();
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  test_method_fromMixins() async {
    addTestFile('''
class B {}
class M1 {
  void f() {}
}
class M2 {
  void f() {}
}
class C extends B with M1, M2 {}
void main() {
  new C().f();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    expect(
      findNode.simple('f();').staticElement,
      findElement.method('f', of: 'M2'),
    );
  }

  test_method_fromMixins_bare_identifier() async {
    addTestFile('''
class B {}
class M1 {
  void f() {}
}
class M2 {
  void f() {}
}
class C extends B with M1, M2 {
  void g() {
    f();
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    expect(
      findNode.simple('f();').staticElement,
      findElement.method('f', of: 'M2'),
    );
  }

  test_method_fromMixins_invoked_from_outside_class() async {
    addTestFile('''
class B {}
class M1 {
  void f() {}
}
class M2 {
  void f() {}
}
class C extends B with M1, M2 {}
void main() {
  new C().f();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    expect(
      findNode.simple('f();').staticElement,
      findElement.method('f', of: 'M2'),
    );
  }

  test_method_fromSuperclassMixin() async {
    addTestFile(r'''
class A {
  void m1() {}
}
class B extends Object with A {
}
class C extends B {
}
f(C c) {
  c.m1();
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  test_methodCascades() async {
    addTestFile(r'''
class A {
  void m1() {}
  void m2() {}
  void m() {
    A a = new A();
    a..m1()
     ..m2();
  }
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  test_methodCascades_withSetter() async {
    addTestFile(r'''
class A {
  String name;
  void m1() {}
  void m2() {}
  void m() {
    A a = new A();
    a..m1()
     ..name = 'name'
     ..m2();
  }
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  test_resolveAgainstNull() async {
    addTestFile(r'''
f(var p) {
  return null == p;
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  test_setter_fromMixins_bare_identifier() async {
    addTestFile('''
class B {}
class M1 {
  set x(value) {}
}
class M2 {
  set x(value) {}
}
class C extends B with M1, M2 {
  void f() {
    x = 1;
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    expect(
      findNode.simple('x = ').staticElement,
      findElement.setter('x', of: 'M2'),
    );
  }

  test_setter_fromMixins_property_access() async {
    addTestFile('''
class B {}
class M1 {
  set x(value) {}
}
class M2 {
  set x(value) {}
}
class C extends B with M1, M2 {}
void main() {
  new C().x = 1;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();

    expect(
      findNode.simple('x = ').staticElement,
      findElement.setter('x', of: 'M2'),
    );
  }

  test_setter_inherited() async {
    addTestFile(r'''
class A {
  int get x => 0;
  set x(int p) {}
}
class B extends A {
  int get x => super.x == null ? 0 : super.x;
  int f() => x = 1;
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  test_setter_static() async {
    addTestFile(r'''
set s(x) {
}

main() {
  s = 123;
}''');
    await resolveTestFile();
    assertNoTestErrors();
    verifyTestResolved();
  }

  /**
   * Verify that all of the identifiers in the [result] have been resolved.
   */
  void verifyTestResolved() {
    var verifier = new ResolutionVerifier();
    result.unit.accept(verifier);
    verifier.assertResolved();
  }

  /**
   * Resolve the test file and verify that the arguments in a specific method
   * invocation were correctly resolved.
   *
   * The file is expected to define a method named `g`, and has exactly one
   * [MethodInvocation] in a statement ending with `);`. It is the arguments to
   * that method invocation that are tested. The method invocation can contain
   * errors.
   *
   * The arguments were resolved correctly if the number of expressions in the list matches the
   * length of the array of indices and if, for each index in the array of indices, the parameter to
   * which the argument expression was resolved is the parameter in the invoked method's list of
   * parameters at that index. Arguments that should not be resolved to a parameter because of an
   * error can be denoted by including a negative index in the array of indices.
   *
   * @param indices the array of indices used to associate arguments with parameters
   * @throws Exception if the source could not be resolved or if the structure of the source is not
   *           valid
   */
  Future<void> _validateArgumentResolution(List<int> indices) async {
    await resolveTestFile();

    var g = findElement.method('g');
    var parameters = g.parameters;

    var invocation = findNode.methodInvocation(');');

    var arguments = invocation.argumentList.arguments;

    var argumentCount = arguments.length;
    expect(argumentCount, indices.length);

    for (var i = 0; i < argumentCount; i++) {
      var argument = arguments[i];
      var actualParameter = argument.staticParameterElement;

      var index = indices[i];
      if (index < 0) {
        expect(actualParameter, isNull);
      } else {
        var expectedParameter = parameters[index];
        expect(actualParameter, same(expectedParameter));
      }
    }
  }
}
