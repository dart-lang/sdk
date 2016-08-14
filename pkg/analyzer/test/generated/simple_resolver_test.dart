// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.simple_resolver_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(SimpleResolverTest);
}

@reflectiveTest
class SimpleResolverTest extends ResolverTestCase {
  void test_argumentResolution_required_matching() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, c) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2]);
  }

  void test_argumentResolution_required_tooFew() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2);
  }
  void g(a, b, c) {}
}''');
    _validateArgumentResolution(source, [0, 1]);
  }

  void test_argumentResolution_required_tooMany() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b) {}
}''');
    _validateArgumentResolution(source, [0, 1, -1]);
  }

  void test_argumentResolution_requiredAndNamed_extra() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, c: 3, d: 4);
  }
  void g(a, b, {c}) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2, -1]);
  }

  void test_argumentResolution_requiredAndNamed_matching() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, c: 3);
  }
  void g(a, b, {c}) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2]);
  }

  void test_argumentResolution_requiredAndNamed_missing() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, d: 3);
  }
  void g(a, b, {c, d}) {}
}''');
    _validateArgumentResolution(source, [0, 1, 3]);
  }

  void test_argumentResolution_requiredAndPositional_fewer() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, [c, d]) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2]);
  }

  void test_argumentResolution_requiredAndPositional_matching() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c, d]) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2, 3]);
  }

  void test_argumentResolution_requiredAndPositional_more() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c]) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2, -1]);
  }

  void test_argumentResolution_setter_propagated() {
    Source source = addSource(r'''
main() {
  var a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    LibraryElement library = resolve2(source);
    CompilationUnitElement unit = library.definingCompilationUnit;
    // find "a.sss = 0"
    AssignmentExpression assignment;
    {
      FunctionElement mainElement = unit.functions[0];
      FunctionBody mainBody = mainElement.computeNode().functionExpression.body;
      Statement statement = (mainBody as BlockFunctionBody).block.statements[1];
      ExpressionStatement expressionStatement =
          statement as ExpressionStatement;
      assignment = expressionStatement.expression as AssignmentExpression;
    }
    // get parameter
    Expression rhs = assignment.rightHandSide;
    expect(rhs.staticParameterElement, isNull);
    ParameterElement parameter = rhs.propagatedParameterElement;
    expect(parameter, isNotNull);
    expect(parameter.displayName, "x");
    // validate
    ClassElement classA = unit.types[0];
    PropertyAccessorElement setter = classA.accessors[0];
    expect(setter.parameters[0], same(parameter));
  }

  void test_argumentResolution_setter_propagated_propertyAccess() {
    Source source = addSource(r'''
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
    LibraryElement library = resolve2(source);
    CompilationUnitElement unit = library.definingCompilationUnit;
    // find "a.b.sss = 0"
    AssignmentExpression assignment;
    {
      FunctionElement mainElement = unit.functions[0];
      FunctionBody mainBody = mainElement.computeNode().functionExpression.body;
      Statement statement = (mainBody as BlockFunctionBody).block.statements[1];
      ExpressionStatement expressionStatement =
          statement as ExpressionStatement;
      assignment = expressionStatement.expression as AssignmentExpression;
    }
    // get parameter
    Expression rhs = assignment.rightHandSide;
    expect(rhs.staticParameterElement, isNull);
    ParameterElement parameter = rhs.propagatedParameterElement;
    expect(parameter, isNotNull);
    expect(parameter.displayName, "x");
    // validate
    ClassElement classB = unit.types[1];
    PropertyAccessorElement setter = classB.accessors[0];
    expect(setter.parameters[0], same(parameter));
  }

  void test_argumentResolution_setter_static() {
    Source source = addSource(r'''
main() {
  A a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    LibraryElement library = resolve2(source);
    CompilationUnitElement unit = library.definingCompilationUnit;
    // find "a.sss = 0"
    AssignmentExpression assignment;
    {
      FunctionElement mainElement = unit.functions[0];
      FunctionBody mainBody = mainElement.computeNode().functionExpression.body;
      Statement statement = (mainBody as BlockFunctionBody).block.statements[1];
      ExpressionStatement expressionStatement =
          statement as ExpressionStatement;
      assignment = expressionStatement.expression as AssignmentExpression;
    }
    // get parameter
    Expression rhs = assignment.rightHandSide;
    ParameterElement parameter = rhs.staticParameterElement;
    expect(parameter, isNotNull);
    expect(parameter.displayName, "x");
    // validate
    ClassElement classA = unit.types[0];
    PropertyAccessorElement setter = classA.accessors[0];
    expect(setter.parameters[0], same(parameter));
  }

  void test_argumentResolution_setter_static_propertyAccess() {
    Source source = addSource(r'''
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
    LibraryElement library = resolve2(source);
    CompilationUnitElement unit = library.definingCompilationUnit;
    // find "a.b.sss = 0"
    AssignmentExpression assignment;
    {
      FunctionElement mainElement = unit.functions[0];
      FunctionBody mainBody = mainElement.computeNode().functionExpression.body;
      Statement statement = (mainBody as BlockFunctionBody).block.statements[1];
      ExpressionStatement expressionStatement =
          statement as ExpressionStatement;
      assignment = expressionStatement.expression as AssignmentExpression;
    }
    // get parameter
    Expression rhs = assignment.rightHandSide;
    ParameterElement parameter = rhs.staticParameterElement;
    expect(parameter, isNotNull);
    expect(parameter.displayName, "x");
    // validate
    ClassElement classB = unit.types[1];
    PropertyAccessorElement setter = classB.accessors[0];
    expect(setter.parameters[0], same(parameter));
  }

  void test_breakTarget_labeled() {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    String text = r'''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      break loop1;
      break loop2;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement = EngineTestCase.findNode(
        unit, text, 'while (true)', (n) => n is WhileStatement);
    ForStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForStatement);
    BreakStatement break1 = EngineTestCase.findNode(
        unit, text, 'break loop1', (n) => n is BreakStatement);
    BreakStatement break2 = EngineTestCase.findNode(
        unit, text, 'break loop2', (n) => n is BreakStatement);
    expect(break1.target, same(whileStatement));
    expect(break2.target, same(forStatement));
  }

  void test_breakTarget_unlabeledBreakFromDo() {
    String text = r'''
void f() {
  do {
    break;
  } while (true);
}
''';
    CompilationUnit unit = resolveSource(text);
    DoStatement doStatement =
        EngineTestCase.findNode(unit, text, 'do', (n) => n is DoStatement);
    BreakStatement breakStatement = EngineTestCase.findNode(
        unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(doStatement));
  }

  void test_breakTarget_unlabeledBreakFromFor() {
    String text = r'''
void f() {
  for (int i = 0; i < 10; i++) {
    break;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ForStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForStatement);
    BreakStatement breakStatement = EngineTestCase.findNode(
        unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(forStatement));
  }

  void test_breakTarget_unlabeledBreakFromForEach() {
    String text = r'''
void f() {
  for (x in []) {
    break;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ForEachStatement forStatement = EngineTestCase.findNode(
        unit, text, 'for', (n) => n is ForEachStatement);
    BreakStatement breakStatement = EngineTestCase.findNode(
        unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(forStatement));
  }

  void test_breakTarget_unlabeledBreakFromSwitch() {
    String text = r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        break;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    SwitchStatement switchStatement = EngineTestCase.findNode(
        unit, text, 'switch', (n) => n is SwitchStatement);
    BreakStatement breakStatement = EngineTestCase.findNode(
        unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(switchStatement));
  }

  void test_breakTarget_unlabeledBreakFromWhile() {
    String text = r'''
void f() {
  while (true) {
    break;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement = EngineTestCase.findNode(
        unit, text, 'while', (n) => n is WhileStatement);
    BreakStatement breakStatement = EngineTestCase.findNode(
        unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(whileStatement));
  }

  void test_breakTarget_unlabeledBreakToOuterFunction() {
    // Verify that unlabeled break statements can't resolve to loops in an
    // outer function.
    String text = r'''
void f() {
  while (true) {
    void g() {
      break;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    BreakStatement breakStatement = EngineTestCase.findNode(
        unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, isNull);
  }

  void test_class_definesCall() {
    Source source = addSource(r'''
class A {
  int call(int x) { return x; }
}
int f(A a) {
  return a(0);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_class_extends_implements() {
    Source source = addSource(r'''
class A extends B implements C {}
class B {}
class C {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_commentReference_class() {
    Source source = addSource(r'''
f() {}
/** [A] [new A] [A.n] [new A.n] [m] [f] */
class A {
  A() {}
  A.n() {}
  m() {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_commentReference_parameter() {
    Source source = addSource(r'''
class A {
  A() {}
  A.n() {}
  /** [e] [f] */
  m(e, f()) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_commentReference_singleLine() {
    Source source = addSource(r'''
/// [A]
class A {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_continueTarget_labeled() {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    String text = r'''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      continue loop1;
      continue loop2;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement = EngineTestCase.findNode(
        unit, text, 'while (true)', (n) => n is WhileStatement);
    ForStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForStatement);
    ContinueStatement continue1 = EngineTestCase.findNode(
        unit, text, 'continue loop1', (n) => n is ContinueStatement);
    ContinueStatement continue2 = EngineTestCase.findNode(
        unit, text, 'continue loop2', (n) => n is ContinueStatement);
    expect(continue1.target, same(whileStatement));
    expect(continue2.target, same(forStatement));
  }

  void test_continueTarget_unlabeledContinueFromDo() {
    String text = r'''
void f() {
  do {
    continue;
  } while (true);
}
''';
    CompilationUnit unit = resolveSource(text);
    DoStatement doStatement =
        EngineTestCase.findNode(unit, text, 'do', (n) => n is DoStatement);
    ContinueStatement continueStatement = EngineTestCase.findNode(
        unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(doStatement));
  }

  void test_continueTarget_unlabeledContinueFromFor() {
    String text = r'''
void f() {
  for (int i = 0; i < 10; i++) {
    continue;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ForStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForStatement);
    ContinueStatement continueStatement = EngineTestCase.findNode(
        unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(forStatement));
  }

  void test_continueTarget_unlabeledContinueFromForEach() {
    String text = r'''
void f() {
  for (x in []) {
    continue;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ForEachStatement forStatement = EngineTestCase.findNode(
        unit, text, 'for', (n) => n is ForEachStatement);
    ContinueStatement continueStatement = EngineTestCase.findNode(
        unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(forStatement));
  }

  void test_continueTarget_unlabeledContinueFromWhile() {
    String text = r'''
void f() {
  while (true) {
    continue;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement = EngineTestCase.findNode(
        unit, text, 'while', (n) => n is WhileStatement);
    ContinueStatement continueStatement = EngineTestCase.findNode(
        unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(whileStatement));
  }

  void test_continueTarget_unlabeledContinueSkipsSwitch() {
    String text = r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        continue;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement = EngineTestCase.findNode(
        unit, text, 'while', (n) => n is WhileStatement);
    ContinueStatement continueStatement = EngineTestCase.findNode(
        unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(whileStatement));
  }

  void test_continueTarget_unlabeledContinueToOuterFunction() {
    // Verify that unlabeled continue statements can't resolve to loops in an
    // outer function.
    String text = r'''
void f() {
  while (true) {
    void g() {
      continue;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ContinueStatement continueStatement = EngineTestCase.findNode(
        unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, isNull);
  }

  void test_empty() {
    Source source = addSource("");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_entryPoint_exported() {
    addNamedSource(
        "/two.dart",
        r'''
library two;
main() {}''');
    Source source = addNamedSource(
        "/one.dart",
        r'''
library one;
export 'two.dart';''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    FunctionElement main = library.entryPoint;
    expect(main, isNotNull);
    expect(main.library, isNot(same(library)));
    assertNoErrors(source);
    verify([source]);
  }

  void test_entryPoint_local() {
    Source source = addNamedSource(
        "/one.dart",
        r'''
library one;
main() {}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    FunctionElement main = library.entryPoint;
    expect(main, isNotNull);
    expect(main.library, same(library));
    assertNoErrors(source);
    verify([source]);
  }

  void test_entryPoint_none() {
    Source source = addNamedSource("/one.dart", "library one;");
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    expect(library.entryPoint, isNull);
    assertNoErrors(source);
    verify([source]);
  }

  void test_enum_externalLibrary() {
    addNamedSource(
        "/my_lib.dart",
        r'''
library my_lib;
enum EEE {A, B, C}''');
    Source source = addSource(r'''
import 'my_lib.dart';
main() {
  EEE e = null;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_extractedMethodAsConstant() {
    Source source = addSource(r'''
abstract class Comparable<T> {
  int compareTo(T other);
  static int compare(Comparable a, Comparable b) => a.compareTo(b);
}
class A {
  void sort([compare = Comparable.compare]) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameter() {
    Source source = addSource(r'''
class A {
  int x;
  A(this.x) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_forEachLoops_nonConflicting() {
    Source source = addSource(r'''
f() {
  List list = [1,2,3];
  for (int x in list) {}
  for (int x in list) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_forLoops_nonConflicting() {
    Source source = addSource(r'''
f() {
  for (int i = 0; i < 3; i++) {
  }
  for (int i = 0; i < 3; i++) {
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionTypeAlias() {
    Source source = addSource(r'''
typedef bool P(e);
class A {
  P p;
  m(e) {
    if (p(e)) {}
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_getter_and_setter_fromMixins_bare_identifier() {
    Source source = addSource('''
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
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    // Verify that both the getter and setter for "x" in C.f() refer to the
    // accessors defined in M2.
    ClassElement classC = library.definingCompilationUnit.types[3];
    MethodDeclaration f = classC.getMethod('f').computeNode();
    BlockFunctionBody body = f.body;
    ExpressionStatement stmt = body.block.statements[0];
    AssignmentExpression assignment = stmt.expression;
    SimpleIdentifier leftHandSide = assignment.leftHandSide;
    expect(leftHandSide.staticElement.enclosingElement.name, 'M2');
    expect(leftHandSide.auxiliaryElements.staticElement.enclosingElement.name,
        'M2');
  }

  @failingTest
  void test_getter_and_setter_fromMixins_property_access() {
    // TODO(paulberry): it appears that auxiliaryElements isn't properly set on
    // a SimpleIdentifier that's inside a property access.  This bug should be
    // fixed.
    Source source = addSource('''
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
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    // Verify that both the getter and setter for "x" in "new C().x" refer to
    // the accessors defined in M2.
    FunctionDeclaration main =
        library.definingCompilationUnit.functions[0].computeNode();
    BlockFunctionBody body = main.functionExpression.body;
    ExpressionStatement stmt = body.block.statements[0];
    AssignmentExpression assignment = stmt.expression;
    PropertyAccess propertyAccess = assignment.leftHandSide;
    expect(
        propertyAccess.propertyName.staticElement.enclosingElement.name, 'M2');
    expect(
        propertyAccess
            .propertyName.auxiliaryElements.staticElement.enclosingElement.name,
        'M2');
  }

  void test_getter_fromMixins_bare_identifier() {
    Source source = addSource('''
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
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    // Verify that the getter for "x" in C.f() refers to the getter defined in
    // M2.
    ClassElement classC = library.definingCompilationUnit.types[3];
    MethodDeclaration f = classC.getMethod('f').computeNode();
    BlockFunctionBody body = f.body;
    ReturnStatement stmt = body.block.statements[0];
    SimpleIdentifier x = stmt.expression;
    expect(x.staticElement.enclosingElement.name, 'M2');
  }

  void test_getter_fromMixins_property_access() {
    Source source = addSource('''
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
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    // Verify that the getter for "x" in "new C().x" refers to the getter
    // defined in M2.
    FunctionDeclaration main =
        library.definingCompilationUnit.functions[0].computeNode();
    BlockFunctionBody body = main.functionExpression.body;
    VariableDeclarationStatement stmt = body.block.statements[0];
    PropertyAccess propertyAccess = stmt.variables.variables[0].initializer;
    expect(
        propertyAccess.propertyName.staticElement.enclosingElement.name, 'M2');
  }

  void test_getterAndSetterWithDifferentTypes() {
    Source source = addSource(r'''
class A {
  int get f => 0;
  void set f(String s) {}
}
g (A a) {
  a.f = a.f.toString();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }

  void test_hasReferenceToSuper() {
    Source source = addSource(r'''
class A {}
class B {toString() => super.toString();}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(2));
    expect(classes[0].hasReferenceToSuper, isFalse);
    expect(classes[1].hasReferenceToSuper, isTrue);
    assertNoErrors(source);
    verify([source]);
  }

  void test_import_hide() {
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
set foo(value) {}
class A {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
set foo(value) {}''');
    Source source = addNamedSource(
        "/lib3.dart",
        r'''
import 'lib1.dart' hide foo;
import 'lib2.dart';

main() {
  foo = 0;
}
A a;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_import_prefix() {
    addNamedSource(
        "/two.dart",
        r'''
library two;
f(int x) {
  return x * x;
}''');
    Source source = addNamedSource(
        "/one.dart",
        r'''
library one;
import 'two.dart' as _two;
main() {
  _two.f(0);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_import_prefix_doesNotExist() {
    //
    // The primary purpose of this test is to ensure that we are only getting a
    // single error generated when the only problem is that an imported file
    // does not exist.
    //
    Source source = addNamedSource(
        "/a.dart",
        r'''
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
    computeLibrarySourceErrors(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
    verify([source]);
  }

  void test_import_show_doesNotExist() {
    //
    // The primary purpose of this test is to ensure that we are only getting a
    // single error generated when the only problem is that an imported file
    // does not exist.
    //
    Source source = addNamedSource(
        "/a.dart",
        r'''
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
    computeLibrarySourceErrors(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
    verify([source]);
  }

  void test_import_spaceInUri() {
    addNamedSource(
        "/sub folder/lib.dart",
        r'''
library lib;
foo() {}''');
    Source source = addNamedSource(
        "/app.dart",
        r'''
import 'sub folder/lib.dart';

main() {
  foo();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_indexExpression_typeParameters() {
    Source source = addSource(r'''
f() {
  List<int> a;
  a[0];
  List<List<int>> b;
  b[0][0];
  List<List<List<int>>> c;
  c[0][0][0];
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_indexExpression_typeParameters_invalidAssignmentWarning() {
    Source source = addSource(r'''
f() {
  List<List<int>> b;
  b[0][0] = 'hi';
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_indirectOperatorThroughCall() {
    Source source = addSource(r'''
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invoke_dynamicThroughGetter() {
    Source source = addSource(r'''
class A {
  List get X => [() => 0];
  m(A a) {
    X.last;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_badSuperclass() {
    Source source = addSource(r'''
class A extends B {}
class B {}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isFalse);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }

  void test_isValidMixin_badSuperclass_withSuperMixins() {
    resetWithOptions(new AnalysisOptionsImpl()..enableSuperMixins = true);
    Source source = addSource(r'''
class A extends B {}
class B {}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isTrue);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_constructor() {
    Source source = addSource(r'''
class A {
  A() {}
}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isFalse);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }

  void test_isValidMixin_constructor_withSuperMixins() {
    resetWithOptions(new AnalysisOptionsImpl()..enableSuperMixins = true);
    Source source = addSource(r'''
class A {
  A() {}
}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isFalse);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }

  void test_isValidMixin_factoryConstructor() {
    Source source = addSource(r'''
class A {
  factory A() => null;
}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isTrue);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_factoryConstructor_withSuperMixins() {
    resetWithOptions(new AnalysisOptionsImpl()..enableSuperMixins = true);
    Source source = addSource(r'''
class A {
  factory A() => null;
}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isTrue);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_super() {
    Source source = addSource(r'''
class A {
  toString() {
    return super.toString();
  }
}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isFalse);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_REFERENCES_SUPER]);
    verify([source]);
  }

  void test_isValidMixin_super_withSuperMixins() {
    resetWithOptions(new AnalysisOptionsImpl()..enableSuperMixins = true);
    Source source = addSource(r'''
class A {
  toString() {
    return super.toString();
  }
}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isTrue);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_valid() {
    Source source = addSource('''
class A {}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isTrue);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_valid_withSuperMixins() {
    resetWithOptions(new AnalysisOptionsImpl()..enableSuperMixins = true);
    Source source = addSource('''
class A {}
class C = Object with A;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    ClassElement a = unit.getType('A');
    expect(a.isValidMixin, isTrue);
    assertNoErrors(source);
    verify([source]);
  }

  void test_labels_switch() {
    Source source = addSource(r'''
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
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    assertNoErrors(source);
    verify([source]);
  }

  void test_localVariable_types_invoked() {
    Source source = addSource(r'''
const A = null;
main() {
  var myVar = (int p) => 'foo';
  myVar(42);
}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, library);
    expect(unit, isNotNull);
    List<bool> found = [false];
    List<CaughtException> thrownException = new List<CaughtException>(1);
    unit.accept(new _SimpleResolverTest_localVariable_types_invoked(
        this, found, thrownException));
    if (thrownException[0] != null) {
      throw new AnalysisException(
          "Exception", new CaughtException(thrownException[0], null));
    }
    expect(found[0], isTrue);
  }

  void test_metadata_class() {
    Source source = addSource(r'''
const A = null;
@A class C<A> {}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unitElement = library.definingCompilationUnit;
    expect(unitElement, isNotNull);
    List<ClassElement> classes = unitElement.types;
    expect(classes, hasLength(1));
    List<ElementAnnotation> annotations = classes[0].metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(2));
    Element expectedElement = (declarations[0] as TopLevelVariableDeclaration)
        .variables
        .variables[0]
        .name
        .staticElement;
    EngineTestCase.assertInstanceOf((obj) => obj is PropertyInducingElement,
        PropertyInducingElement, expectedElement);
    expectedElement = (expectedElement as PropertyInducingElement).getter;
    Element actualElement =
        (declarations[1] as ClassDeclaration).metadata[0].name.staticElement;
    expect(actualElement, same(expectedElement));
  }

  void test_metadata_field() {
    Source source = addSource(r'''
const A = null;
class C {
  @A int f;
}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(1));
    FieldElement field = classes[0].fields[0];
    List<ElementAnnotation> annotations = field.metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_fieldFormalParameter() {
    Source source = addSource(r'''
const A = null;
class C {
  int f;
  C(@A this.f);
}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(1));
    List<ConstructorElement> constructors = classes[0].constructors;
    expect(constructors, hasLength(1));
    List<ParameterElement> parameters = constructors[0].parameters;
    expect(parameters, hasLength(1));
    List<ElementAnnotation> annotations = parameters[0].metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_function() {
    Source source = addSource(r'''
const A = null;
@A f() {}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ElementAnnotation> annotations = functions[0].metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_functionTypedParameter() {
    Source source = addSource(r'''
const A = null;
f(@A int p(int x)) {}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ParameterElement> parameters = functions[0].parameters;
    expect(parameters, hasLength(1));
    List<ElementAnnotation> annotations1 = parameters[0].metadata;
    expect(annotations1, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_libraryDirective() {
    Source source = addSource(r'''
@A library lib;
const A = null;''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    List<ElementAnnotation> annotations = library.metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_method() {
    Source source = addSource(r'''
const A = null;
class C {
  @A void m() {}
}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(1));
    MethodElement method = classes[0].methods[0];
    List<ElementAnnotation> annotations = method.metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_namedParameter() {
    Source source = addSource(r'''
const A = null;
f({@A int p : 0}) {}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ParameterElement> parameters = functions[0].parameters;
    expect(parameters, hasLength(1));
    List<ElementAnnotation> annotations1 = parameters[0].metadata;
    expect(annotations1, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_positionalParameter() {
    Source source = addSource(r'''
const A = null;
f([@A int p = 0]) {}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ParameterElement> parameters = functions[0].parameters;
    expect(parameters, hasLength(1));
    List<ElementAnnotation> annotations1 = parameters[0].metadata;
    expect(annotations1, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_simpleParameter() {
    Source source = addSource(r'''
const A = null;
f(@A p1, @A int p2) {}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ParameterElement> parameters = functions[0].parameters;
    expect(parameters, hasLength(2));
    List<ElementAnnotation> annotations1 = parameters[0].metadata;
    expect(annotations1, hasLength(1));
    List<ElementAnnotation> annotations2 = parameters[1].metadata;
    expect(annotations2, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_typedef() {
    Source source = addSource(r'''
const A = null;
@A typedef F<A>();''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    CompilationUnitElement unitElement = library.definingCompilationUnit;
    expect(unitElement, isNotNull);
    List<FunctionTypeAliasElement> aliases = unitElement.functionTypeAliases;
    expect(aliases, hasLength(1));
    List<ElementAnnotation> annotations = aliases[0].metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(2));
    Element expectedElement = (declarations[0] as TopLevelVariableDeclaration)
        .variables
        .variables[0]
        .name
        .staticElement;
    EngineTestCase.assertInstanceOf((obj) => obj is PropertyInducingElement,
        PropertyInducingElement, expectedElement);
    expectedElement = (expectedElement as PropertyInducingElement).getter;
    Element actualElement =
        (declarations[1] as FunctionTypeAlias).metadata[0].name.staticElement;
    expect(actualElement, same(expectedElement));
  }

  void test_method_fromMixin() {
    Source source = addSource(r'''
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_method_fromMixins() {
    Source source = addSource('''
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
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    // Verify that the "f" in "new C().f()" refers to the "f" defined in M2.
    FunctionDeclaration main =
        library.definingCompilationUnit.functions[0].computeNode();
    BlockFunctionBody body = main.functionExpression.body;
    ExpressionStatement stmt = body.block.statements[0];
    MethodInvocation expr = stmt.expression;
    expect(expr.methodName.staticElement.enclosingElement.name, 'M2');
  }

  void test_method_fromMixins_bare_identifier() {
    Source source = addSource('''
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
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    // Verify that the call to f() in C.g() refers to the method defined in M2.
    ClassElement classC = library.definingCompilationUnit.types[3];
    MethodDeclaration g = classC.getMethod('g').computeNode();
    BlockFunctionBody body = g.body;
    ExpressionStatement stmt = body.block.statements[0];
    MethodInvocation invocation = stmt.expression;
    SimpleIdentifier methodName = invocation.methodName;
    expect(methodName.staticElement.enclosingElement.name, 'M2');
  }

  void test_method_fromMixins_invked_from_outside_class() {
    Source source = addSource('''
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
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    // Verify that the call to f() in "new C().f()" refers to the method
    // defined in M2.
    FunctionDeclaration main =
        library.definingCompilationUnit.functions[0].computeNode();
    BlockFunctionBody body = main.functionExpression.body;
    ExpressionStatement stmt = body.block.statements[0];
    MethodInvocation invocation = stmt.expression;
    expect(invocation.methodName.staticElement.enclosingElement.name, 'M2');
  }

  void test_method_fromSuperclassMixin() {
    Source source = addSource(r'''
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_methodCascades() {
    Source source = addSource(r'''
class A {
  void m1() {}
  void m2() {}
  void m() {
    A a = new A();
    a..m1()
     ..m2();
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_methodCascades_withSetter() {
    Source source = addSource(r'''
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
    computeLibrarySourceErrors(source);
    // failing with error code: INVOCATION_OF_NON_FUNCTION
    assertNoErrors(source);
    verify([source]);
  }

  void test_resolveAgainstNull() {
    Source source = addSource(r'''
f(var p) {
  return null == p;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_setter_fromMixins_bare_identifier() {
    Source source = addSource('''
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
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    // Verify that the setter for "x" in C.f() refers to the setter defined in
    // M2.
    ClassElement classC = library.definingCompilationUnit.types[3];
    MethodDeclaration f = classC.getMethod('f').computeNode();
    BlockFunctionBody body = f.body;
    ExpressionStatement stmt = body.block.statements[0];
    AssignmentExpression assignment = stmt.expression;
    SimpleIdentifier leftHandSide = assignment.leftHandSide;
    expect(leftHandSide.staticElement.enclosingElement.name, 'M2');
  }

  void test_setter_fromMixins_property_access() {
    Source source = addSource('''
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
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    // Verify that the setter for "x" in "new C().x" refers to the setter
    // defined in M2.
    FunctionDeclaration main =
        library.definingCompilationUnit.functions[0].computeNode();
    BlockFunctionBody body = main.functionExpression.body;
    ExpressionStatement stmt = body.block.statements[0];
    AssignmentExpression assignment = stmt.expression;
    PropertyAccess propertyAccess = assignment.leftHandSide;
    expect(
        propertyAccess.propertyName.staticElement.enclosingElement.name, 'M2');
  }

  void test_setter_inherited() {
    Source source = addSource(r'''
class A {
  int get x => 0;
  set x(int p) {}
}
class B extends A {
  int get x => super.x == null ? 0 : super.x;
  int f() => x = 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_setter_static() {
    Source source = addSource(r'''
set s(x) {
}

main() {
  s = 123;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  @failingTest
  void test_staticInvocation() {
    Source source = addSource(r'''
class A {
  static int get g => (a,b) => 0;
}
class B {
  f() {
    A.g(1,0);
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  /**
   * Resolve the given source and verify that the arguments in a specific method invocation were
   * correctly resolved.
   *
   * The source is expected to be source for a compilation unit, the first declaration is expected
   * to be a class, the first member of which is expected to be a method with a block body, and the
   * first statement in the body is expected to be an expression statement whose expression is a
   * method invocation. It is the arguments to that method invocation that are tested. The method
   * invocation can contain errors.
   *
   * The arguments were resolved correctly if the number of expressions in the list matches the
   * length of the array of indices and if, for each index in the array of indices, the parameter to
   * which the argument expression was resolved is the parameter in the invoked method's list of
   * parameters at that index. Arguments that should not be resolved to a parameter because of an
   * error can be denoted by including a negative index in the array of indices.
   *
   * @param source the source to be resolved
   * @param indices the array of indices used to associate arguments with parameters
   * @throws Exception if the source could not be resolved or if the structure of the source is not
   *           valid
   */
  void _validateArgumentResolution(Source source, List<int> indices) {
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    ClassElement classElement = library.definingCompilationUnit.types[0];
    List<ParameterElement> parameters = classElement.methods[1].parameters;
    CompilationUnit unit = resolveCompilationUnit(source, library);
    expect(unit, isNotNull);
    ClassDeclaration classDeclaration =
        unit.declarations[0] as ClassDeclaration;
    MethodDeclaration methodDeclaration =
        classDeclaration.members[0] as MethodDeclaration;
    Block block = (methodDeclaration.body as BlockFunctionBody).block;
    ExpressionStatement statement = block.statements[0] as ExpressionStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;
    NodeList<Expression> arguments = invocation.argumentList.arguments;
    int argumentCount = arguments.length;
    expect(argumentCount, indices.length);
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      ParameterElement element = argument.staticParameterElement;
      int index = indices[i];
      if (index < 0) {
        expect(element, isNull);
      } else {
        expect(element, same(parameters[index]));
      }
    }
  }
}

class _SimpleResolverTest_localVariable_types_invoked
    extends RecursiveAstVisitor<Object> {
  final SimpleResolverTest test;

  List<bool> found;

  List<CaughtException> thrownException;

  _SimpleResolverTest_localVariable_types_invoked(
      this.test, this.found, this.thrownException)
      : super();

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == "myVar" && node.parent is MethodInvocation) {
      try {
        found[0] = true;
        // check static type
        DartType staticType = node.staticType;
        expect(staticType, same(test.typeProvider.dynamicType));
        // check propagated type
        FunctionType propagatedType = node.propagatedType as FunctionType;
        expect(propagatedType.returnType, test.typeProvider.stringType);
      } on AnalysisException catch (e, stackTrace) {
        thrownException[0] = new CaughtException(e, stackTrace);
      }
    }
    return null;
  }
}
