// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentDriverResolutionTest);
  });
}

@reflectiveTest
class AssignmentDriverResolutionTest extends DriverResolutionTest
    with AssignmentResolutionMixin {}

mixin AssignmentResolutionMixin implements ResolutionTest {
  test_compound_indexExpression() async {
    addTestFile(r'''
main() {
  var x = <num>[1, 2, 3];
  x[0] += 4;
}
''');
    await resolveTestFile();

    AssignmentExpression assignment = findNode.assignment('+= 4');
    assertElement(assignment, numElement.getMethod('+'));
    assertType(assignment, 'num'); // num + int = num

    IndexExpression indexed = assignment.leftHandSide;
    assertMember(indexed, 'List<num>', listElement.getMethod('[]='));
    assertType(indexed, 'num');

    SimpleIdentifier xRef = indexed.target;
    assertElement(xRef, findElement.localVar('x'));
    assertType(xRef, 'List<num>');

    IntegerLiteral index = indexed.index;
    assertType(index, 'int');

    Expression right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_compound_local() async {
    addTestFile(r'''
main() {
  num v = 0;
  v += 3;
}
''');
    await resolveTestFile();

    var assignment = findNode.assignment('v += 3');
    assertElement(assignment, numElement.getMethod('+'));
    assertType(assignment, 'num'); // num + int = num

    SimpleIdentifier left = assignment.leftHandSide;
    assertElement(left, findElement.localVar('v'));
    assertType(left, 'num');

    Expression right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_compound_prefixedIdentifier() async {
    addTestFile(r'''
main() {
  var c = new C();
  c.f += 2;
}
class C {
  num f;
}
''');
    await resolveTestFile();

    var assignment = findNode.assignment('c.f += 2');
    assertElement(assignment, numElement.getMethod('+'));
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
    addTestFile(r'''
main() {
  new C().f += 2;
}
class C {
  num f;
}
''');
    await resolveTestFile();

    var assignment = findNode.assignment('f += 2');
    assertElement(assignment, numElement.getMethod('+'));
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

  test_in_const_context() async {
    addTestFile('''
void f(num x, int y) {
  const [x = y];
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x =');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y]');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_indexExpression_cascade() async {
    addTestFile(r'''
main() {
  <int, double>{}..[1] = 2.0;
}
''');
    await resolveTestFile();

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
    assertMember(indexed, 'Map<int, double>', mapElement.getMethod('[]='));
    assertType(indexed, 'double');
  }

  test_notLValue_parenthesized() async {
    addTestFile(r'''
int a, b;
double c = 0.0;
main() {
  (a + b) = c;
}
''');
    await resolveTestFile();
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

  test_nullAware_local() async {
    addTestFile(r'''
main() {
  String v;
  v ??= 'test';
}
''');
    await resolveTestFile();

    var assignment = findNode.assignment('v ??=');
    assertElementNull(assignment);
    assertType(assignment, 'String');

    SimpleIdentifier left = assignment.leftHandSide;
    assertElement(left, findElement.localVar('v'));
    assertType(left, 'String');

    Expression right = assignment.rightHandSide;
    assertType(right, 'String');
  }

  test_propertyAccess_forwardingStub() async {
    addTestFile(r'''
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
    await resolveTestFile();

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
    addTestFile(r'''
main() {
  var x = <int>[1, 2, 3];
  x[0] = 4;
}
''');
    await resolveTestFile();

    AssignmentExpression assignment = findNode.assignment('= 4');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    IndexExpression indexed = assignment.leftHandSide;
    assertMember(indexed, 'List<int>', listElement.getMethod('[]='));
    assertType(indexed, 'int');

    var xRef = indexed.target;
    assertElement(xRef, findElement.localVar('x'));
    assertType(xRef, 'List<int>');

    IntegerLiteral index = indexed.index;
    assertType(index, 'int');

    Expression right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_instanceField_unqualified() async {
    addTestFile(r'''
class C {
  num f = 0;
  foo() {
    f = 2;
  }
}
''');
    await resolveTestFile();

    var assignment = findNode.assignment('f = 2;');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    SimpleIdentifier left = assignment.leftHandSide;
    assertElement(left, findElement.setter('f'));
    assertType(left, 'num');

    Expression right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_local() async {
    addTestFile(r'''
main() {
  num v = 0;
  v = 2;
}
''');
    await resolveTestFile();

    var assignment = findNode.assignment('v = 2;');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    SimpleIdentifier left = assignment.leftHandSide;
    assertElement(left, findElement.localVar('v'));
    assertType(left, 'num');

    Expression right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_prefixedIdentifier() async {
    addTestFile(r'''
main() {
  var c = new C();
  c.f = 2;
}
class C {
  num f;
}
''');
    await resolveTestFile();

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
    addTestFile(r'''
main() {
  C.f = 2;
}
class C {
  static num f;
}
''');

    await resolveTestFile();

    var assignment = findNode.assignment('C.f = 2');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    PrefixedIdentifier left = assignment.leftHandSide;
    assertType(left, 'num');

    var cRef = left.prefix;
    assertElement(cRef, findElement.class_('C'));
    // TODO(scheglov) Why not `Type`? Should it even have a type?
    assertType(cRef, 'C');

    var fRef = left.identifier;
    assertElement(fRef, findElement.setter('f'));
    assertType(fRef, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_propertyAccess() async {
    addTestFile(r'''
main() {
  new C().f = 2;
}
class C {
  num f;
}
''');
    await resolveTestFile();

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
    addTestFile(r'''
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
    await resolveTestFile();

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
    addTestFile(r'''
main() {
  new C().f = 2;
}
class C {
  void set f(num _) {}
}
''');
    await resolveTestFile();

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

  test_simple_staticField_unqualified() async {
    addTestFile(r'''
class C {
  static num f = 0;
  foo() {
    f = 2;
  }
}
''');
    await resolveTestFile();

    var assignment = findNode.assignment('f = 2');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    SimpleIdentifier left = assignment.leftHandSide;
    assertElement(left, findElement.setter('f'));
    assertType(left, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_simple_topLevelVariable() async {
    addTestFile(r'''
main() {
  v = 2;
}
num v = 0;
''');
    await resolveTestFile();

    var assignment = findNode.assignment('v = 2');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    SimpleIdentifier left = assignment.leftHandSide;
    assertElement(left, findElement.topSet('v'));
    assertType(left, 'num');

    var right = assignment.rightHandSide;
    assertType(right, 'int');
  }

  test_to_class() async {
    addTestFile('''
class C {}
void f(int x) {
  C = x;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var cRef = findNode.simple('C =');
    assertElement(cRef, findElement.class_('C'));
    assertType(cRef, 'Type');

    var xRef = findNode.simple('x;');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'int');
  }

  test_to_class_ambiguous() async {
    newFile('/test/lib/a.dart', content: 'class C {}');
    newFile('/test/lib/b.dart', content: 'class C {}');
    addTestFile('''
import 'a.dart';
import 'b.dart';
void f(int x) {
  C = x;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x;');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'int');
  }

  test_to_final_parameter() async {
    addTestFile('''
f(final int x) {
  x += 2;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'int');
  }

  test_to_final_variable_local() async {
    addTestFile('''
main() {
  final x = 1;
  x += 2;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.localVar('x'));
    assertType(xRef, 'int');
  }

  test_to_getter_instance_direct() async {
    addTestFile('''
class C {
  int get x => 0;
}
f(C c) {
  c.x += 2;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.getter('x'));
    assertType(xRef, 'int');
  }

  test_to_getter_instance_via_implicit_this() async {
    addTestFile('''
class C {
  int get x => 0;
  f() {
    x += 2;
  }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.getter('x'));
    assertType(xRef, 'int');
  }

  test_to_getter_static_direct() async {
    addTestFile('''
class C {
  static int get x => 0;
}
main() {
  C.x += 2;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.getter('x'));
    assertType(xRef, 'int');
  }

  test_to_getter_static_via_scope() async {
    addTestFile('''
class C {
  static int get x => 0;
  f() {
    x += 2;
  }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.getter('x'));
    assertType(xRef, 'int');
  }

  test_to_getter_top_level() async {
    addTestFile('''
int get x => 0;
main() {
  x += 2;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.topGet('x'));
    assertType(xRef, 'int');
  }

  test_to_non_lvalue() async {
    addTestFile('''
void f(int x, double y, String z) {
  x + y = z;
}
''');
    await resolveTestFile();
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
    addTestFile('''
void f(num x, int y) {
  x++ = y;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x++');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_postfix_increment_compound() async {
    addTestFile('''
void f(num x, int y) {
  x++ += y;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x++');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_postfix_increment_null_aware() async {
    addTestFile('''
void f(num x, int y) {
  x++ ??= y;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x++');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_prefix() async {
    newFile('/test/lib/a.dart', content: '''
var x = 0;
''');
    addTestFile('''
import 'a.dart' as p;
main() {
  p += 2;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var pRef = findNode.simple('p +=');
    assertElement(pRef, findElement.prefix('p'));
    assertTypeDynamic(pRef);
  }

  test_to_prefix_increment() async {
    addTestFile('''
void f(num x, int y) {
  ++x = y;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x =');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_prefix_increment_compound() async {
    addTestFile('''
void f(num x, int y) {
  ++x += y;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x +=');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_to_prefix_increment_null_aware() async {
    addTestFile('''
void f(num x, int y) {
  ++x ??= y;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x ??=');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'num');

    var yRef = findNode.simple('y;');
    assertElement(yRef, findElement.parameter('y'));
    assertType(yRef, 'int');
  }

  test_types_local() async {
    addTestFile(r'''
int a;
bool b;
main() {
  a = b;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a = b');
    assertElementNull(assignment);
    assertType(assignment, 'bool');

    assertIdentifierTopSetRef(assignment.leftHandSide, 'a');
    assertIdentifierTopGetRef(assignment.rightHandSide, 'b');
  }

  test_types_top() async {
    addTestFile(r'''
int a = 0;
bool b = a;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var bDeclaration = findNode.variableDeclaration('b =');
    TopLevelVariableElement bElement = bDeclaration.declaredElement;
    assertElement(bDeclaration.name, findElement.topVar('b'));
    assertType(bDeclaration.name, 'bool');
    expect(bElement.type.toString(), 'bool');

    SimpleIdentifier aRef = bDeclaration.initializer;
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_types_top_const() async {
    addTestFile(r'''
const int a = 0;
const bool b = a;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var bDeclaration = findNode.variableDeclaration('b =');
    TopLevelVariableElement bElement = bDeclaration.declaredElement;
    assertElement(bDeclaration.name, bElement);
    assertType(bDeclaration.name, 'bool');
    expect(bElement.type.toString(), 'bool');

    SimpleIdentifier aRef = bDeclaration.initializer;
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_unresolved_left_identifier_compound() async {
    addTestFile(r'''
int b;
main() {
  a += b;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a += b');
    assertElementNull(assignment);
    assertTypeDynamic(assignment);

    assertElementNull(assignment.leftHandSide);
    assertTypeDynamic(assignment.leftHandSide);

    assertElement(assignment.rightHandSide, findElement.topGet('b'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_identifier_simple() async {
    addTestFile(r'''
int b;
main() {
  a = b;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var assignment = findNode.assignment('a = b');
    assertElementNull(assignment);
    assertType(assignment, 'int');

    assertElementNull(assignment.leftHandSide);
    assertTypeDynamic(assignment.leftHandSide);

    assertElement(assignment.rightHandSide, findElement.topGet('b'));
    assertType(assignment.rightHandSide, 'int');
  }

  test_unresolved_left_indexed1_simple() async {
    addTestFile(r'''
int c;
main() {
  a[b] = c;
}
''');
    await resolveTestFile();
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
    addTestFile(r'''
A a;
int c;
main() {
  a[b] = c;
}
class A {}
''');
    await resolveTestFile();
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
    addTestFile(r'''
A a;
int c;
main() {
  a[b] = c;
}
class A {
  operator[]=(double b) {}
}
''');
    await resolveTestFile();
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
    addTestFile(r'''
double b;
int c;
main() {
  a[b] = c;
}
''');
    await resolveTestFile();
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
    addTestFile(r'''
int c;
main() {
  a.b = c;
}
''');
    await resolveTestFile();
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
    addTestFile(r'''
class A {}
A a;
int c;
main() {
  a.b = c;
}
''');
    await resolveTestFile();
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
    addTestFile(r'''
int d;
main() {
  a.b.c = d;
}
''');
    await resolveTestFile();
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
    addTestFile(r'''
A a;
int d;
main() {
  a.b.c = d;
}
class A {}
''');
    await resolveTestFile();
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
    addTestFile(r'''
A a;
int d;
main() {
  a.b.c = d;
}
class A { B b; }
class B {}
''');
    await resolveTestFile();
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

  test_with_synthetic_lhs() async {
    addTestFile('''
void f(int x) {
  = x;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x;');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'int');
  }

  test_with_synthetic_lhs_in_method() async {
    addTestFile('''
class C {
  void f(int x) {
    = x;
  }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x;');
    assertElement(xRef, findElement.parameter('x'));
    assertType(xRef, 'int');
  }
}
