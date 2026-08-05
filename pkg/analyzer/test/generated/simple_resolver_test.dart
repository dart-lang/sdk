// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import '../src/dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleResolverTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SimpleResolverTest extends PubPackageResolutionTest {
  test_argumentResolution_required_matching() async {
    var result = await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, c) {}
}''');
    await _validateArgumentResolution(result, [0, 1, 2]);
  }

  test_argumentResolution_required_tooFew() async {
    var result = await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2);
  }
  void g(a, b, c) {}
}''');
    await _validateArgumentResolution(result, [0, 1]);
  }

  test_argumentResolution_required_tooMany() async {
    var result = await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b) {}
}''');
    await _validateArgumentResolution(result, [0, 1, -1]);
  }

  test_argumentResolution_requiredAndNamed_extra() async {
    var result = await resolveTestCode('''
class A {
  void f() {
    g(1, 2, c: 3, d: 4);
  }
  void g(a, b, {c}) {}
}''');
    await _validateArgumentResolution(result, [0, 1, 2, -1]);
  }

  test_argumentResolution_requiredAndNamed_matching() async {
    var result = await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, c: 3);
  }
  void g(a, b, {c}) {}
}''');
    await _validateArgumentResolution(result, [0, 1, 2]);
  }

  test_argumentResolution_requiredAndNamed_missing() async {
    var result = await resolveTestCode('''
class A {
  void f() {
    g(1, 2, d: 3);
  }
  void g(a, b, {c, d}) {}
}''');
    await _validateArgumentResolution(result, [0, 1, 3]);
  }

  test_argumentResolution_requiredAndPositional_fewer() async {
    var result = await resolveTestCode('''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, [c, d]) {}
}''');
    await _validateArgumentResolution(result, [0, 1, 2]);
  }

  test_argumentResolution_requiredAndPositional_matching() async {
    var result = await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c, d]) {}
}''');
    await _validateArgumentResolution(result, [0, 1, 2, 3]);
  }

  test_argumentResolution_requiredAndPositional_more() async {
    var result = await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c]) {}
}''');
    await _validateArgumentResolution(result, [0, 1, 2, -1]);
  }

  test_argumentResolution_setter_propagated() async {
    var result = await resolveTestCode(r'''
main() {
  var a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    var rhs = result.findNode.assignment(' = 0;').rightHandSide;
    expect(rhs.correspondingParameter, result.findElement.parameter('x'));
  }

  test_argumentResolution_setter_propagated_propertyAccess() async {
    var result = await resolveTestCode(r'''
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
    var rhs = result.findNode.assignment(' = 0;').rightHandSide;
    expect(rhs.correspondingParameter, result.findElement.parameter('x'));
  }

  test_argumentResolution_setter_static() async {
    var result = await resolveTestCode(r'''
main() {
  A a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    var rhs = result.findNode.assignment(' = 0;').rightHandSide;
    expect(rhs.correspondingParameter, result.findElement.parameter('x'));
  }

  test_argumentResolution_setter_static_propertyAccess() async {
    var result = await resolveTestCode(r'''
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
    var rhs = result.findNode.assignment(' = 0;').rightHandSide;
    expect(rhs.correspondingParameter, result.findElement.parameter('x'));
  }

  test_breakTarget_labeled() async {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    var result = await resolveTestCode(r'''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      break loop1;
      break loop2;
    }
  }
}
''');
    var break1 = result.findNode.breakStatement('break loop1;');
    var whileStatement = result.findNode.whileStatement('while (');
    expect(break1.target, same(whileStatement));

    var break2 = result.findNode.breakStatement('break loop2;');
    var forStatement = result.findNode.forStatement('for (');
    expect(break2.target, same(forStatement));
  }

  test_breakTarget_unlabeledBreakFromDo() async {
    var result = await resolveTestCode('''
void f() {
  do {
    break;
  } while (true);
}
''');
    var doStatement = result.findNode.doStatement('do {');
    var breakStatement = result.findNode.breakStatement('break;');
    expect(breakStatement.target, same(doStatement));
  }

  test_breakTarget_unlabeledBreakFromFor() async {
    var result = await resolveTestCode(r'''
void f() {
  for (int i = 0; i < 10; i++) {
    break;
  }
}
''');
    var forStatement = result.findNode.forStatement('for (');
    var breakStatement = result.findNode.breakStatement('break;');
    expect(breakStatement.target, same(forStatement));
  }

  test_breakTarget_unlabeledBreakFromForEach() async {
    var result = await resolveTestCode('''
void f() {
  for (x in []) {
    break;
  }
}
''');
    var forStatement = result.findNode.forStatement('for (');
    var breakStatement = result.findNode.breakStatement('break;');
    expect(breakStatement.target, same(forStatement));
  }

  test_breakTarget_unlabeledBreakFromSwitch() async {
    var result = await resolveTestCode(r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        break;
    }
  }
}
''');
    var switchStatement = result.findNode.switchStatement('switch (');
    var breakStatement = result.findNode.breakStatement('break;');
    expect(breakStatement.target, same(switchStatement));
  }

  test_breakTarget_unlabeledBreakFromSwitch_language219() async {
    var result = await resolveTestCode(r'''
// @dart = 2.19
void f() {
  while (true) {
    switch (0) {
      case 0:
        break;
    }
  }
}
''');
    var switchStatement = result.findNode.switchStatement('switch (');
    var breakStatement = result.findNode.breakStatement('break;');
    expect(breakStatement.target, same(switchStatement));
  }

  test_breakTarget_unlabeledBreakFromWhile() async {
    var result = await resolveTestCode(r'''
void f() {
  while (true) {
    break;
  }
}
''');
    var whileStatement = result.findNode.whileStatement('while (');
    var breakStatement = result.findNode.breakStatement('break;');
    expect(breakStatement.target, same(whileStatement));
  }

  test_breakTarget_unlabeledBreakToOuterFunction() async {
    // Verify that unlabeled break statements can't resolve to loops in an
    // outer function.
    var result = await resolveTestCode(r'''
void f() {
  while (true) {
    void g() {
      break;
    }
  }
}
''');
    var breakStatement = result.findNode.breakStatement('break;');
    expect(breakStatement.target, isNull);
  }

  test_class_definesCall() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int call(int x) { return x; }
}
int f(A a) {
  return a(0);
}''');
  }

  test_class_extends_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends B implements C {}
class B {}
class C {}''');
  }

  test_continueTarget_labeled() async {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    var result = await resolveTestCode('''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      continue loop1;
      continue loop2;
    }
  }
}
''');
    var continue1 = result.findNode.continueStatement('continue loop1');
    var whileStatement = result.findNode.whileStatement('while (');
    expect(continue1.target, same(whileStatement));

    var continue2 = result.findNode.continueStatement('continue loop2');
    var forStatement = result.findNode.forStatement('for (');
    expect(continue2.target, same(forStatement));
  }

  test_continueTarget_unlabeledContinueFromDo() async {
    var result = await resolveTestCode('''
void f() {
  do {
    continue;
  } while (true);
}
''');
    var doStatement = result.findNode.doStatement('do {');
    var continueStatement = result.findNode.continueStatement('continue;');
    expect(continueStatement.target, same(doStatement));
  }

  test_continueTarget_unlabeledContinueFromFor() async {
    var result = await resolveTestCode('''
void f() {
  for (int i = 0; i < 10; i++) {
    continue;
  }
}
''');
    var forStatement = result.findNode.forStatement('for (');
    var continueStatement = result.findNode.continueStatement('continue;');
    expect(continueStatement.target, same(forStatement));
  }

  test_continueTarget_unlabeledContinueFromForEach() async {
    var result = await resolveTestCode(r'''
void f() {
  for (x in []) {
    continue;
  }
}
''');
    var forStatement = result.findNode.forStatement('for (');
    var continueStatement = result.findNode.continueStatement('continue;');
    expect(continueStatement.target, same(forStatement));
  }

  test_continueTarget_unlabeledContinueFromWhile() async {
    var result = await resolveTestCode(r'''
void f() {
  while (true) {
    continue;
  }
}
''');
    var whileStatement = result.findNode.whileStatement('while (');
    var continueStatement = result.findNode.continueStatement('continue;');
    expect(continueStatement.target, same(whileStatement));
  }

  test_continueTarget_unlabeledContinueSkipsSwitch() async {
    var result = await resolveTestCode(r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        continue;
    }
  }
}
''');
    var whileStatement = result.findNode.whileStatement('while (');
    var continueStatement = result.findNode.continueStatement('continue;');
    expect(continueStatement.target, same(whileStatement));
  }

  test_continueTarget_unlabeledContinueSkipsSwitch_language219() async {
    var result = await resolveTestCode(r'''
// @dart = 2.19
void f() {
  while (true) {
    switch (0) {
      case 0:
        continue;
    }
  }
}
''');
    var whileStatement = result.findNode.whileStatement('while (');
    var continueStatement = result.findNode.continueStatement('continue;');
    expect(continueStatement.target, same(whileStatement));
  }

  test_continueTarget_unlabeledContinueToOuterFunction() async {
    // Verify that unlabeled continue statements can't resolve to loops in an
    // outer function.
    var result = await resolveTestCode(r'''
void f() {
  while (true) {
    void g() {
      continue;
    }
  }
}
''');
    var continueStatement = result.findNode.continueStatement('continue;');
    expect(continueStatement.target, isNull);
  }

  test_empty() async {
    await resolveTestCodeWithDiagnostics('');
  }

  test_entryPoint_exported() async {
    newFile('$testPackageLibPath/a.dart', r'''
main() {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
export 'a.dart';
''');

    var library = result.libraryElement;
    var main = library.entryPoint!;

    expect(main, isNotNull);
    expect(main.library, isNot(same(library)));
  }

  test_entryPoint_local() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {}
''');

    var library = result.libraryElement;
    var main = library.entryPoint!;

    expect(main, isNotNull);
    expect(main.library, same(library));
  }

  test_entryPoint_none() async {
    var result = await resolveTestCodeWithDiagnostics('');

    var library = result.libraryElement;
    expect(library.entryPoint, isNull);
  }

  test_enum_externalLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum EEE {A, B, C}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f(EEE e) {}
''');
  }

  test_extractedMethodAsConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class Comparable<T> {
  int compareTo(T other);
  static int compare(Comparable a, Comparable b) => a.compareTo(b);
}
class A {
  void sort([compare = Comparable.compare]) {}
}''');
  }

  test_fieldFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int x;
  int y;
  A(this.x) : y = x {}
}''');

    var xParameter = result.findNode.fieldFormalParameter('this.x');

    var xParameterElement =
        xParameter.declaredFragment!.element as FieldFormalParameterElement;
    expect(xParameterElement.field, result.findElement.field('x'));

    var node1 = result.findNode.simple('x {}');
    assertResolvedNodeText(node1, r'''
SimpleIdentifier
  token: x
  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
  staticType: int
''');
  }

  test_forEachLoops_nonConflicting() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  List list = [1,2,3];
  for (int x in list) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  for (int x in list) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');
  }

  test_forLoops_nonConflicting() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (int i = 0; i < 3; i++) {
  }
  for (int i = 0; i < 3; i++) {
  }
}''');
  }

  test_functionTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef bool P(e);
class A {
  late P p;
  m(e) {
    if (p(e)) {}
  }
}''');
  }

  test_getter_fromMixins_bare_identifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
class B {}
mixin M1 {
  get x => null;
}
mixin M2 {
  get x => null;
}
class C extends B with M1, M2 {
  f() {
    return x;
  }
}
''');

    // Verify that the getter for "x" in C.f() refers to the getter defined in
    // M2.
    var node2 = result.findNode.simple('x;');
    assertResolvedNodeText(node2, r'''
SimpleIdentifier
  token: x
  element: <testLibrary>::@mixin::M2::@getter::x
  staticType: dynamic
''');
  }

  test_getter_fromMixins_property_access() async {
    var result = await resolveTestCodeWithDiagnostics('''
class B {}
mixin M1 {
  get x => null;
}
mixin M2 {
  get x => null;
}
class C extends B with M1, M2 {}
void main() {
  var y = new C().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');

    // Verify that the getter for "x" in "new C().x" refers to the getter
    // defined in M2.
    var node3 = result.findNode.simple('x;');
    assertResolvedNodeText(node3, r'''
SimpleIdentifier
  token: x
  element: <testLibrary>::@mixin::M2::@getter::x
  staticType: dynamic
''');
  }

  test_import_hide() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
set foo(value) {}
class A {}''');

    newFile('$testPackageLibPath/lib2.dart', r'''
set foo(value) {}''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' hide foo;
import 'lib2.dart';

main() {
  foo = 0;
}
A a = A();''');
  }

  test_import_prefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
f(int x) {
  return x * x;
}''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as _a;
main() {
  _a.f(0);
}''');
  }

  test_import_prefix_doesNotExist() async {
    //
    // The primary purpose of this test is to ensure that we are only getting a
    // single error generated when the only problem is that an imported file
    // does not exist.
    //
    await resolveTestCodeWithDiagnostics('''
import 'missing.dart' as p;
//     ^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'missing.dart'.
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
  }

  test_import_show_doesNotExist() async {
    //
    // The primary purpose of this test is to ensure that we are only getting a
    // single error generated when the only problem is that an imported file
    // does not exist.
    //
    await resolveTestCodeWithDiagnostics('''
import 'missing.dart' show q, r, t, u, T, U, V, W;
//     ^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'missing.dart'.
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
  }

  test_import_spaceInUri() async {
    newFile('$testPackageLibPath/sub folder/a.dart', r'''
foo() {}''');

    await resolveTestCodeWithDiagnostics(r'''
import 'sub folder/a.dart';

main() {
  foo();
}''');
  }

  test_indexExpression_typeParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  List<int> a = [];
  a[0];
  List<List<int>> b = [];
  b[0][0];
  List<List<List<int>>> c = [];
  c[0][0][0];
}''');
  }

  test_indexExpression_typeParameters_invalidAssignmentWarning() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  List<List<int>> b = [];
  b[0][0] = 'hi';
//          ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}''');
  }

  test_indirectOperatorThroughCall() async {
    await resolveTestCodeWithDiagnostics(r'''
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
  }

  test_invoke_dynamicThroughGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  List get X => [() => 0];
  m(A a) {
    X.last;
  }
}''');
  }

  test_isValidMixin_badSuperclass() async {
    var result = await resolveTestCodeWithDiagnostics(
      r'''
class A extends B {}
class B {}
class C = Object with A;
//                    ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.''',
    );

    var a = result.findElement.class_('A');
    expect(a.isValidMixin, isFalse);
  }

  test_isValidMixin_constructor() async {
    var result = await resolveTestCodeWithDiagnostics(
      r'''
class A {
  A() {}
}
class C = Object with A;
//                    ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.''',
    );

    var a = result.findElement.class_('A');
    expect(a.isValidMixin, isFalse);
  }

  test_isValidMixin_factoryConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  factory A() => throw 0;
}
class C = Object with A;''');

    var a = result.findElement.class_('A');
    expect(a.isValidMixin, isTrue);
  }

  test_isValidMixin_super_toString() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  toString() {
    return super.toString();
  }
}
class C = Object with A;''');

    var a = result.findElement.class_('A');
    expect(a.isValidMixin, isTrue);
  }

  test_isValidMixin_valid() async {
    var result = await resolveTestCodeWithDiagnostics('''
mixin class A {}
class C = Object with A;''');

    var a = result.findElement.class_('A');
    expect(a.isValidMixin, isTrue);
  }

  test_labels_switch() async {
    await resolveTestCodeWithDiagnostics(r'''
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
  }

  test_labels_switch_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
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
  }

  test_localVariable_types_invoked() async {
    var result = await resolveTestCode(r'''
const A = null;
main() {
  var myVar = (int p) => 'foo';
  myVar(42);
}''');
    var node = result.findNode.simple('myVar(42)');
    assertType(node, 'String Function(int)');
  }

  test_metadata_class() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
@A class C<A> {}''');

    var annotations = result.findElement.class_('C').metadata.annotations;
    expect(annotations, hasLength(1));

    var cDeclaration = result.findNode.classDeclaration('C<A>');
    var node = cDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_classTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
@A class C<A> = D with E;
class D {}
mixin E {}
''');

    var annotations = result.findElement.class_('C').metadata.annotations;
    expect(annotations, hasLength(1));

    var cDeclaration = result.findNode.classTypeAlias('C<A>');
    var node = cDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_enum() async {
    var result = await resolveTestCodeWithDiagnostics('''
const A = null;
@A enum E { A, B }
''');

    var annotations = result.findElement.enum_('E').metadata.annotations;
    expect(annotations, hasLength(1));

    var eDeclaration = result.findNode.enumDeclaration('E');
    var node = eDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
@A extension E<A> on List<A> {}''');

    var annotations = result.findElement.extension_('E').metadata.annotations;
    expect(annotations, hasLength(1));

    var cDeclaration = result.findNode.extensionDeclaration('E<A>');
    var node = cDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
class C {
  @A int f = 1;
}''');

    var metadata = result.findElement.field('f').metadata.annotations;
    expect(metadata, hasLength(1));
  }

  test_metadata_fieldFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
class C {
  int f;
  C(@A this.f);
}''');

    var metadata = result.findElement
        .fieldFormalParameter('f')
        .metadata
        .annotations;
    expect(metadata, hasLength(1));
  }

  test_metadata_function() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
@A f() {}''');

    var annotations = result.findElement.topFunction('f').metadata.annotations;
    expect(annotations, hasLength(1));
  }

  test_metadata_function_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
@A f<A>() {}''');

    var annotations = result.findElement.topFunction('f').metadata.annotations;
    expect(annotations, hasLength(1));

    var fDeclaration = result.findNode.functionDeclaration('f<A>');
    var node = fDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_functionTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics('''
const A = null;
@A typedef F<A>(int A);
''');

    var annotations = result.findElement.typeAlias('F').metadata.annotations;
    expect(annotations, hasLength(1));

    var fDeclaration = result.findNode.functionTypeAlias('F');
    var node = fDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_functionTypedParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
f(@A int p(int x)) {}''');

    var metadata = result.findElement.parameter('p').metadata.annotations;
    expect(metadata, hasLength(1));
  }

  test_metadata_functionTypedParameter_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
f(@A int p<A>(int x)) {}''');

    var annotations = result.findElement.parameter('p').metadata.annotations;
    expect(annotations, hasLength(1));

    var pDeclaration = result.findNode.formalParameter('p<A>');
    var node = pDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_genericTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
@A typedef F<A> = A Function();
''');

    var annotations = result.findElement.typeAlias('F').metadata.annotations;
    expect(annotations, hasLength(1));

    var fDeclaration = result.findNode.genericTypeAlias('F<A>');
    var node = fDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_libraryDirective() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
@A library lib;
const A = null;''');

    var metadata = result.libraryElement.metadata.annotations;
    expect(metadata, hasLength(1));
  }

  test_metadata_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
class C {
  @A void m() {}
}''');

    var metadata = result.findElement.method('m').metadata.annotations;
    expect(metadata, hasLength(1));
  }

  test_metadata_method_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
class C {
  @A void m<A>() {}
}''');

    var annotations = result.findElement.method('m').metadata.annotations;
    expect(annotations, hasLength(1));

    var mDeclaration = result.findNode.methodDeclaration('m<A>');
    var node = mDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_mixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
@A mixin M<A> on Object {}''');

    var annotations = result.findElement.mixin('M').metadata.annotations;
    expect(annotations, hasLength(1));

    var mDeclaration = result.findNode.mixinDeclaration('M<A>');
    var node = mDeclaration.metadata[0];
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_metadata_namedParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
f({@A int p = 0}) {}''');

    var metadata = result.findElement.parameter('p').metadata.annotations;
    expect(metadata, hasLength(1));
  }

  test_metadata_positionalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
f([@A int p = 0]) {}''');

    var metadata = result.findElement.parameter('p').metadata.annotations;
    expect(metadata, hasLength(1));
  }

  test_metadata_simpleParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
f(@A p1, @A int p2) {}''');

    expect(
      result.findElement.parameter('p1').metadata.annotations,
      hasLength(1),
    );
    expect(
      result.findElement.parameter('p2').metadata.annotations,
      hasLength(1),
    );
  }

  test_metadata_typedef() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const A = null;
@A typedef F<A>();''');

    expect(
      result.findElement.typeAlias('F').metadata.annotations,
      hasLength(1),
    );

    var node = result.findNode.annotation('@A');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@getter::A
    staticType: null
  element: <testLibrary>::@getter::A
''');
  }

  test_method_fromMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class B {
  bar() => 1;
}
mixin class A {
  foo() => 2;
}

class C extends B with A {
  bar() => super.bar();
  foo() => super.foo();
}''');
  }

  test_method_fromMixins() async {
    var result = await resolveTestCodeWithDiagnostics('''
class B {}
mixin M1 {
  void f() {}
}
mixin M2 {
  void f() {}
}
class C extends B with M1, M2 {}
void main() {
  new C().f();
}
''');

    var node4 = result.findNode.simple('f();');
    assertResolvedNodeText(node4, r'''
SimpleIdentifier
  token: f
  element: <testLibrary>::@mixin::M2::@method::f
  staticType: void Function()
''');
  }

  test_method_fromMixins_bare_identifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
class B {}
mixin M1 {
  void f() {}
}
mixin M2 {
  void f() {}
}
class C extends B with M1, M2 {
  void g() {
    f();
  }
}
''');

    var node5 = result.findNode.simple('f();');
    assertResolvedNodeText(node5, r'''
SimpleIdentifier
  token: f
  element: <testLibrary>::@mixin::M2::@method::f
  staticType: void Function()
''');
  }

  test_method_fromMixins_invoked_from_outside_class() async {
    var result = await resolveTestCodeWithDiagnostics('''
class B {}
mixin M1 {
  void f() {}
}
mixin M2 {
  void f() {}
}
class C extends B with M1, M2 {}
void main() {
  new C().f();
}
''');

    var node6 = result.findNode.simple('f();');
    assertResolvedNodeText(node6, r'''
SimpleIdentifier
  token: f
  element: <testLibrary>::@mixin::M2::@method::f
  staticType: void Function()
''');
  }

  test_method_fromSuperclassMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void m1() {}
}
class B extends Object with A {
}
class C extends B {
}
f(C c) {
  c.m1();
}''');
  }

  test_methodCascades() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void m1() {}
  void m2() {}
  void m() {
    A a = new A();
    a..m1()
     ..m2();
  }
}''');
  }

  test_methodCascades_withSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  String name = '';
  void m1() {}
  void m2() {}
  void m() {
    A a = new A();
    a..m1()
     ..name = 'name'
     ..m2();
  }
}''');
  }

  test_resolveAgainstNull() async {
    await resolveTestCodeWithDiagnostics(r'''
f(p) {
  return null == p;
}''');
  }

  test_setter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
set s(x) {
}

main() {
  s = 123;
}''');
  }

  /// Resolve the test file and verify that the arguments in a specific method
  /// invocation were correctly resolved.
  ///
  /// The file is expected to define a method named `g`, and has exactly one
  /// [MethodInvocation] in a statement ending with `);`. It is the arguments to
  /// that method invocation that are tested. The method invocation can contain
  /// errors.
  ///
  /// The arguments were resolved correctly if the number of expressions in the
  /// list matches the length of the array of indices and if, for each index in
  /// the array of indices, the parameter to which the argument expression was
  /// resolved is the parameter in the invoked method's list of parameters at
  /// that index. Arguments that should not be resolved to a parameter because
  /// of an error can be denoted by including a negative index in the array of
  /// indices.
  ///
  /// @param indices the array of indices used to associate arguments with
  ///          parameters
  /// @throws Exception if the source could not be resolved or if the structure
  ///           of the source is not valid
  Future<void> _validateArgumentResolution(
    TestResolvedUnitResult result,
    List<int> indices,
  ) async {
    var g = result.findElement.method('g');
    var parameters = g.formalParameters;

    var invocation = result.findNode.methodInvocation(');');

    var arguments = invocation.argumentList.arguments;

    var argumentCount = arguments.length;
    expect(argumentCount, indices.length);

    for (var i = 0; i < argumentCount; i++) {
      var argument = arguments[i];
      var actualParameter = argument.correspondingParameter;

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
