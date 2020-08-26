// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentDriverResolutionTest);
    defineReflectiveTests(AssignmentDriverResolutionWithNullSafetyTest);
  });
}

@reflectiveTest
class AssignmentDriverResolutionTest extends PubPackageResolutionTest
    with AssignmentDriverResolutionTestCases {}

mixin AssignmentDriverResolutionTestCases on PubPackageResolutionTest {
  test_compound_indexExpression() async {
    await resolveTestCode(r'''
main() {
  var x = <num>[1, 2, 3];
  x[0] += 4;
}
''');
    AssignmentExpression assignment = findNode.assignment('+= 4');
    assertElement(
      assignment,
      elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
    );
    assertType(assignment, 'num'); // num + int = num

    IndexExpression indexed = assignment.leftHandSide;
    assertMember(indexed, listElement.getMethod('[]='), {'E': 'num'});
    assertType(indexed, 'num');

    SimpleIdentifier xRef = indexed.target;
    assertElement(xRef, findElement.localVar('x'));
    assertType(xRef, 'List<num>');

    IntegerLiteral index = indexed.index;
    assertType(index, 'int');

    Expression right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_compound_plus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a += f();
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeToStringWithNullability ? 'int' : 'num']);
  }

  test_compound_plus_int_context_int_complex() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(List<int> a) {
  a[0] += f();
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeToStringWithNullability ? 'int' : 'num']);
  }

  test_compound_plus_int_context_int_promoted() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(num a) {
  if (a is int) {
    a += f();
  }
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeToStringWithNullability ? 'int' : 'num']);
  }

  test_compound_plus_int_context_int_promoted_with_subsequent_demotion() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(num a, bool b) {
  if (a is int) {
    a += b ? f() : 1.0;
    print(a);
  }
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeToStringWithNullability ? 'int' : 'num']);
    assertType(findNode.simple('a);').staticType, 'num');
  }

  test_compound_prefixedIdentifier() async {
    await resolveTestCode(r'''
main() {
  var c = new C();
  c.f += 2;
}
class C {
  num f;
}
''');
    var assignment = findNode.assignment('c.f += 2');
    assertElement(
      assignment,
      elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
    );
    assertType(assignment, 'num'); // num + int = num

    PrefixedIdentifier left = assignment.leftHandSide;
    assertType(left, 'num');

    var cRef = left.prefix;
    assertElement(cRef, findElement.localVar('c'));
    assertType(cRef, 'C');

    var fRef = left.identifier;
    assertElement(fRef, findElement.setter('f'));
    assertType(fRef, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_compound_propertyAccess() async {
    await resolveTestCode(r'''
main() {
  new C().f += 2;
}
class C {
  num f;
}
''');
    var assignment = findNode.assignment('f += 2');
    assertElement(
      assignment,
      elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
    );
    assertType(assignment, 'num'); // num + int = num

    PropertyAccess left = assignment.leftHandSide;
    assertType(left, 'num');

    InstanceCreationExpression creation = left.target;
    assertElement(creation, findElement.unnamedConstructor('C'));
    assertType(creation, 'C');

    var fRef = left.propertyName;
    assertElement(fRef, findElement.setter('f'));
    assertType(fRef, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_indexExpression_cascade() async {
    await resolveTestCode(r'''
main() {
  <int, double>{}..[1] = 2.0;
}
''');
    var cascade = findNode.cascade('<int, double>');
    assertType(cascade, 'Map<int, double>');

    SetOrMapLiteral map = cascade.target;
    assertType(map, 'Map<int, double>');
    assertTypeName(map.typeArguments.arguments[0], intElement, 'int');
    assertTypeName(map.typeArguments.arguments[1], doubleElement, 'double');

    AssignmentExpression assignment = cascade.cascadeSections[0];
    assertElementNull(assignment);
    assertType(assignment, 'double');

    IndexExpression indexed = assignment.leftHandSide;
    assertMember(
      indexed,
      mapElement.getMethod('[]='),
      {'K': 'int', 'V': 'double'},
    );
    assertType(indexed, 'double');
  }

  test_notLValue_parenthesized() async {
    await resolveTestCode(r'''
int a, b;
double c = 0.0;
main() {
  (a + b) = c;
}
''');
    expect(result.errors, isNotEmpty);

    var parenthesized = findNode.parenthesized('(a + b)');
    assertType(parenthesized, 'int');

    assertTopGetRef('a + b', 'a');
    assertTopGetRef('b)', 'b');
    assertTopGetRef('c;', 'c');

    var assignment = findNode.assignment('= c');
    assertElementNull(assignment);
    assertType(assignment, 'double');
  }

  test_nullAware_context() async {
    var question = typeToStringWithNullability ? '?' : '';
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int$question a) {
  a ??= f();
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['int$question']);
  }

  test_propertyAccess_forwardingStub() async {
    await resolveTestCode(r'''
class A {
  int f;
}
abstract class I<T> {
  T f;
}
class B extends A implements I<int> {}
main() {
  new B().f = 1;
}
''');
    var assignment = findNode.assignment('f = 1');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PropertyAccess left = assignment.leftHandSide;
    assertType(left, 'int');

    InstanceCreationExpression creation = left.target;
    assertElement(creation, findElement.unnamedConstructor('B'));
    assertType(creation, 'B');

    var fRef = left.propertyName;
    assertElement(fRef, findElement.setter('f', of: 'A'));
    assertType(fRef, 'int');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_indexExpression() async {
    await resolveTestCode(r'''
main() {
  var x = <int>[1, 2, 3];
  x[0] = 4;
}
''');
    AssignmentExpression assignment = findNode.assignment('= 4');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    IndexExpression indexed = assignment.leftHandSide;
    assertMember(indexed, listElement.getMethod('[]='), {'E': 'int'});
    assertType(indexed, 'int');

    var xRef = indexed.target;
    assertElement(xRef, findElement.localVar('x'));
    assertType(xRef, 'List<int>');

    IntegerLiteral index = indexed.index;
    assertType(index, 'int');

    Expression right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_prefixedIdentifier() async {
    await resolveTestCode(r'''
main() {
  var c = new C();
  c.f = 2;
}
class C {
  num f;
}
''');
    var assignment = findNode.assignment('c.f = 2');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PrefixedIdentifier left = assignment.leftHandSide;
    assertType(left, 'num');

    var cRef = left.prefix;
    assertElement(cRef, findElement.localVar('c'));
    assertType(cRef, 'C');

    var fRef = left.identifier;
    assertElement(fRef, findElement.setter('f'));
    assertType(fRef, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_prefixedIdentifier_staticField() async {
    await resolveTestCode(r'''
main() {
  C.f = 2;
}
class C {
  static num f;
}
''');

    var assignment = findNode.assignment('C.f = 2');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PrefixedIdentifier left = assignment.leftHandSide;
    assertType(left, 'num');

    var cRef = left.prefix;
    assertElement(cRef, findElement.class_('C'));
    assertTypeNull(cRef);

    var fRef = left.identifier;
    assertElement(fRef, findElement.setter('f'));
    assertType(fRef, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_propertyAccess() async {
    await resolveTestCode(r'''
main() {
  new C().f = 2;
}
class C {
  num f;
}
''');
    var assignment = findNode.assignment('f = 2');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PropertyAccess left = assignment.leftHandSide;
    assertType(left, 'num');

    InstanceCreationExpression creation = left.target;
    assertElement(creation, findElement.unnamedConstructor('C'));
    assertType(creation, 'C');

    var fRef = left.propertyName;
    assertElement(fRef, findElement.setter('f'));
    assertType(fRef, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_propertyAccess_chained() async {
    await resolveTestCode(r'''
main() {
  var a = new A();
  a.b.f = 2;
}
class A {
  B b;
}
class B {
  num f;
}
''');
    var assignment = findNode.assignment('a.b.f = 2');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PropertyAccess left = assignment.leftHandSide;
    assertType(left, 'num');

    PrefixedIdentifier ab = left.target;
    assertType(ab, 'B');

    var aRef = ab.prefix;
    assertElement(aRef, findElement.localVar('a'));
    assertType(aRef, 'A');

    var bRef = ab.identifier;
    assertElement(bRef, findElement.getter('b'));
    assertType(bRef, 'B');

    var fRef = left.propertyName;
    assertElement(fRef, findElement.setter('f'));
    assertType(fRef, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_propertyAccess_setter() async {
    await resolveTestCode(r'''
main() {
  new C().f = 2;
}
class C {
  void set f(num _) {}
}
''');
    var assignment = findNode.assignment('f = 2');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PropertyAccess left = assignment.leftHandSide;
    assertType(left, 'num');

    InstanceCreationExpression creation = left.target;
    assertElement(creation, findElement.unnamedConstructor('C'));
    assertType(creation, 'C');

    var fRef = left.propertyName;
    assertElement(fRef, findElement.setter('f'));
    assertType(fRef, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simpleIdentifier_class_simple() async {
    await assertErrorsInCode('''
class C {}

void f() {
  C = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 25, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 29, 1),
    ]);

    var assignment = findNode.assignment('C = 0');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.class_('C'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_fieldInstance_simple() async {
    await assertNoErrorsInCode(r'''
class C {
  num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.setter('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_fieldStatic_simple() async {
    await assertNoErrorsInCode(r'''
class C {
  static num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.setter('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_getterInstance_simple() async {
    await assertErrorsInCode('''
class C {
  num get x => 0;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 46, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.getter('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_getterStatic_simple() async {
    await assertErrorsInCode('''
class C {
  static num get x => 0;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 53, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.getter('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_getterTopLevel_simple() async {
    await assertErrorsInCode('''
int get x => 0;

void f() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 30, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.topGet('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_importPrefix_simple() async {
    await assertErrorsInCode('''
import 'dart:math' as x;

main() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 37, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.prefix('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_localVariable_compound() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x += 3;
}
''');

    var assignment = findNode.assignment('x += 3');
    assertAssignment(
      assignment,
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'num', // num + int = num
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: findElement.localVar('x'),
      writeElement: findElement.localVar('x'),
      type: 'num',
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_localVariable_simple() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.localVar('x'),
      type: 'num',
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_localVariableConst_simple() async {
    await assertErrorsInCode('''
void f() {
  // ignore:unused_local_variable
  const num x = 1;
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_CONST, 66, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.localVar('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_localVariableFinal_simple() async {
    await assertErrorsInCode('''
void f() {
  // ignore:unused_local_variable
  final num x = 1;
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 66, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.localVar('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_parameter_compound_ifNull() async {
    var question = typeToStringWithNullability ? '?' : '';
    await assertNoErrorsInCode('''
void f(num$question x) {
  x ??= 0;
}
''');

    var assignment = findNode.assignment('x ??=');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'num',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: findElement.parameter('x'),
      writeElement: findElement.parameter('x'),
      type: 'num$question',
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_parameter_compound_ifNull_notAssignableType() async {
    var question = typeToStringWithNullability ? '?' : '';
    var code = '''
void f(double$question a, int b) {
  a ??= b;
}
''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, code.indexOf('b;'), 1),
    ]);

    var assignment = findNode.assignment('a ??=');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'num',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: findElement.parameter('a'),
      writeElement: findElement.parameter('a'),
      type: 'double$question',
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      readElement: findElement.parameter('b'),
      writeElement: null,
      type: 'int',
    );
  }

  test_simpleIdentifier_parameter_compound_refineType_int_double() async {
    await assertErrorsInCode(r'''
void f(int x) {
  x += 1.2;
  x -= 1.2;
  x *= 1.2;
  x %= 1.2;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 23, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 35, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 47, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 59, 3),
    ]);
    assertType(findNode.assignment('+='), 'double');
    assertType(findNode.assignment('-='), 'double');
    assertType(findNode.assignment('*='), 'double');
    assertType(findNode.assignment('%='), 'double');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_int() async {
    await assertNoErrorsInCode(r'''
main(int x) {
  x += 1;
  x -= 1;
  x *= 1;
  x ~/= 1;
  x %= 1;
}
''');
    assertType(findNode.assignment('+='), 'int');
    assertType(findNode.assignment('-='), 'int');
    assertType(findNode.assignment('*='), 'int');
    assertType(findNode.assignment('~/='), 'int');
    assertType(findNode.assignment('%='), 'int');
  }

  test_simpleIdentifier_parameter_simple() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.parameter('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_parameter_simple_notAssignableType() async {
    await assertErrorsInCode(r'''
void f(int x) {
  x = true;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 22, 4),
    ]);

    var assignment = findNode.assignment('x = true');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'bool',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.parameter('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'bool');
  }

  test_simpleIdentifier_parameterFinal_simple() async {
    await assertErrorsInCode('''
void f(final int x) {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 24, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.parameter('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_synthetic_simple() async {
    await assertErrorsInCode('''
void f(int y) {
  = y;
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('= y');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      readElement: findElement.parameter('y'),
      writeElement: null,
      type: 'int',
    );
  }

  test_simpleIdentifier_topLevelVariable_simple() async {
    await assertNoErrorsInCode(r'''
num x = 0;

void f() {
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.topSet('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_topLevelVariable_simple_notAssignableType() async {
    await assertErrorsInCode(r'''
int x = 0;

void f() {
  x = true;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 29, 4),
    ]);

    var assignment = findNode.assignment('x = true');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'bool',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.topSet('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'bool');
  }

  test_simpleIdentifier_topLevelVariableFinal_simple() async {
    await assertErrorsInCode(r'''
final num x = 0;

void f() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 31, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: findElement.topGet('x'),
      type: null,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_unresolved_simple() async {
    await assertErrorsInCode(r'''
void f(int a) {
  x = a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('x = a');
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      assignment.leftHandSide,
      readElement: null,
      writeElement: null,
      type: null,
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      readElement: findElement.parameter('a'),
      writeElement: null,
      type: 'int',
    );
  }

  test_to_class_ambiguous() async {
    newFile('/test/lib/a.dart', content: 'class C {}');
    newFile('/test/lib/b.dart', content: 'class C {}');
    await resolveTestCode('''
import 'a.dart';
import 'b.dart';
void f(int x) {
  C = x;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x;');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'int');
  }

  test_to_getter_instance_direct() async {
    await resolveTestCode('''
class C {
  int get x => 0;
}
f(C c) {
  c.x += 2;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.getter('x'));
    assertType(xRef, 'int');
  }

  test_to_getter_static_direct() async {
    await resolveTestCode('''
class C {
  static int get x => 0;
}
main() {
  C.x += 2;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.getter('x'));
    assertType(xRef, 'int');
  }

  test_to_non_lvalue() async {
    await resolveTestCode('''
void f(int x, double y, String z) {
  x + y = z;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'int');

    var yRef = findNode.simple('y =');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'double');

    var zRef = findNode.simple('z;');
    assertElement(zRef, findElement.parameter('z'));
    assertType(zRef, 'String');
  }

  test_to_postfix_increment() async {
    await resolveTestCode('''
void f(num x, int y) {
  x++ = y;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x++');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_postfix_increment_compound() async {
    await resolveTestCode('''
void f(num x, int y) {
  x++ += y;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x++');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_postfix_increment_null_aware() async {
    await resolveTestCode('''
void f(num x, int y) {
  x++ ??= y;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x++');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_prefix_increment() async {
    await resolveTestCode('''
void f(num x, int y) {
  ++x = y;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x =');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_prefix_increment_compound() async {
    await resolveTestCode('''
void f(num x, int y) {
  ++x += y;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_prefix_increment_null_aware() async {
    await resolveTestCode('''
void f(num x, int y) {
  ++x ??= y;
}
''');
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x ??=');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_unresolved_left_identifier_compound() async {
    await resolveTestCode(r'''
int b;
main() {
  a += b;
}
''');
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a += b');
    assertElementNull(assignment);
    assertTypeDynamic(assignment);

    assertElementNull(assignment.leftHandSide);
    assertTypeDynamic(assignment.leftHandSide);

    assertElement(assignment.rightHandSide, findElement.topGet('b'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_indexed1_simple() async {
    await resolveTestCode(r'''
int c;
main() {
  a[b] = c;
}
''');
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a[b] = c');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    IndexExpression indexed = assignment.leftHandSide;
    assertElementNull(indexed);
    assertTypeDynamic(indexed);

    assertElementNull(indexed.target);
    assertTypeDynamic(indexed.target);

    assertElementNull(indexed.index);
    assertTypeDynamic(indexed.index);

    assertElement(assignment.rightHandSide, findElement.topGet('c'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_indexed2_simple() async {
    await resolveTestCode(r'''
A a;
int c;
main() {
  a[b] = c;
}
class A {}
''');
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a[b] = c');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    IndexExpression indexed = assignment.leftHandSide;
    assertElementNull(indexed);
    assertTypeDynamic(indexed);

    assertElement(indexed.target, findElement.topGet('a'));
    assertType(indexed.target, 'A');

    assertElementNull(indexed.index);
    assertTypeDynamic(indexed.index);

    assertElement(assignment.rightHandSide, findElement.topGet('c'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_indexed3_simple() async {
    await resolveTestCode(r'''
A a;
int c;
main() {
  a[b] = c;
}
class A {
  operator[]=(double b) {}
}
''');
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a[b] = c');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    IndexExpression indexed = assignment.leftHandSide;
    assertElement(indexed, findElement.method('[]='));
    assertTypeDynamic(indexed);

    assertElement(indexed.target, findElement.topGet('a'));
    assertType(indexed.target, 'A');

    assertElementNull(indexed.index);
    assertTypeDynamic(indexed.index);

    assertElement(assignment.rightHandSide, findElement.topGet('c'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_indexed4_simple() async {
    await resolveTestCode(r'''
double b;
int c;
main() {
  a[b] = c;
}
''');
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a[b] = c');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    IndexExpression indexed = assignment.leftHandSide;
    assertElementNull(indexed);
    assertTypeDynamic(indexed);

    assertElementNull(indexed.target);
    assertTypeDynamic(indexed.target);

    assertElement(indexed.index, findElement.topGet('b'));
    assertType(indexed.index, 'double');

    assertElement(assignment.rightHandSide, findElement.topGet('c'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_prefixed1_simple() async {
    await resolveTestCode(r'''
int c;
main() {
  a.b = c;
}
''');
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a.b = c');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PrefixedIdentifier prefixed = assignment.leftHandSide;
    assertElementNull(prefixed);
    assertTypeDynamic(prefixed);

    assertElementNull(prefixed.prefix);
    assertTypeDynamic(prefixed.prefix);

    assertElementNull(prefixed.identifier);
    assertTypeDynamic(prefixed.identifier);

    assertElement(assignment.rightHandSide, findElement.topGet('c'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_prefixed2_simple() async {
    await resolveTestCode(r'''
class A {}
A a;
int c;
main() {
  a.b = c;
}
''');
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a.b = c');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PrefixedIdentifier prefixed = assignment.leftHandSide;
    assertElementNull(prefixed);
    assertTypeDynamic(prefixed);

    assertElement(prefixed.prefix, findElement.topGet('a'));
    assertType(prefixed.prefix, 'A');

    assertElementNull(prefixed.identifier);
    assertTypeDynamic(prefixed.identifier);

    assertElement(assignment.rightHandSide, findElement.topGet('c'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_property1_simple() async {
    await resolveTestCode(r'''
int d;
main() {
  a.b.c = d;
}
''');
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a.b.c = d');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PropertyAccess access = assignment.leftHandSide;
    assertTypeDynamic(access);

    PrefixedIdentifier prefixed = access.target;
    assertElementNull(prefixed);
    assertTypeDynamic(prefixed);

    assertElementNull(prefixed.prefix);
    assertTypeDynamic(prefixed.prefix);

    assertElementNull(prefixed.identifier);
    assertTypeDynamic(prefixed.identifier);

    assertElementNull(access.propertyName);
    assertTypeDynamic(access.propertyName);

    assertElement(assignment.rightHandSide, findElement.topGet('d'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_property2_simple() async {
    await resolveTestCode(r'''
A a;
int d;
main() {
  a.b.c = d;
}
class A {}
''');
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a.b.c = d');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PropertyAccess access = assignment.leftHandSide;
    assertTypeDynamic(access);

    PrefixedIdentifier prefixed = access.target;
    assertElementNull(prefixed);
    assertTypeDynamic(prefixed);

    assertElement(prefixed.prefix, findElement.topGet('a'));
    assertType(prefixed.prefix, 'A');

    assertElementNull(prefixed.identifier);
    assertTypeDynamic(prefixed.identifier);

    assertElementNull(access.propertyName);
    assertTypeDynamic(access.propertyName);

    assertElement(assignment.rightHandSide, findElement.topGet('d'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_property3_simple() async {
    await resolveTestCode(r'''
A a;
int d;
main() {
  a.b.c = d;
}
class A { B b; }
class B {}
''');
    expect(result.errors, isNotEmpty);
    var bElement = findElement.field('b');

    var assignment = findNode.assignment('a.b.c = d');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PropertyAccess access = assignment.leftHandSide;
    assertTypeDynamic(access);

    PrefixedIdentifier prefixed = access.target;
    assertElement(prefixed, bElement.getter);
    assertType(prefixed, 'B');

    assertElement(prefixed.prefix, findElement.topGet('a'));
    assertType(prefixed.prefix, 'A');

    assertElement(prefixed.identifier, bElement.getter);
    assertType(prefixed.identifier, 'B');

    assertElementNull(access.propertyName);
    assertTypeDynamic(access.propertyName);

    assertElement(assignment.rightHandSide, findElement.topGet('d'));
    assertType(assignment.rightHandSide, 'int');
  }
}

@reflectiveTest
class AssignmentDriverResolutionWithNullSafetyTest
    extends PubPackageResolutionTest
    with WithNullSafetyMixin, AssignmentDriverResolutionTestCases {}
