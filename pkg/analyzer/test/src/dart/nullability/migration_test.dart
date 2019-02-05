// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/nullability/conditional_discard.dart';
import 'package:analyzer/src/dart/nullability/constraint_gatherer.dart';
import 'package:analyzer/src/dart/nullability/constraint_variable_gatherer.dart';
import 'package:analyzer/src/dart/nullability/decorated_type.dart';
import 'package:analyzer/src/dart/nullability/expression_checks.dart';
import 'package:analyzer/src/dart/nullability/transitional_api.dart';
import 'package:analyzer/src/dart/nullability/unit_propagation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstraintGathererTest);
    defineReflectiveTests(ConstraintVariableGathererTest);
    defineReflectiveTests(MigrationIntegrationTest);
  });
}

@reflectiveTest
class ConstraintGathererTest extends ConstraintsTestBase {
  @override
  final _Constraints constraints = _Constraints();

  /// Checks that a constraint was recorded with a left hand side of
  /// [conditions] and a right hand side of [consequence].
  void assertConstraint(
      Iterable<ConstraintVariable> conditions, ConstraintVariable consequence) {
    expect(constraints._clauses,
        contains(_Clause(conditions.toSet(), consequence)));
  }

  /// Checks that no constraint was recorded with a right hand side of
  /// [consequence].
  void assertNoConstraints(ConstraintVariable consequence) {
    expect(
        constraints._clauses,
        isNot(contains(
            predicate((_Clause clause) => clause.consequence == consequence))));
  }

  /// Gets the [ExpressionChecks] associated with the expression whose text
  /// representation is [text], or `null` if the expression has no
  /// [ExpressionChecks] associated with it.
  ExpressionChecks checkExpression(String text) {
    return _variables.checkExpression(findNode.expression(text));
  }

  /// Gets the [DecoratedType] associated with the expression whose text
  /// representation is [text], or `null` if the expression has no
  /// [DecoratedType] associated with it.
  DecoratedType decoratedExpressionType(String text) {
    return _variables.decoratedExpressionType(findNode.expression(text));
  }

  test_always() async {
    await analyze('');

    // No clause is needed for `always`; it is assigned the value `true` before
    // solving begins.
    assertNoConstraints(ConstraintVariable.always);
    assert(ConstraintVariable.always.value, isTrue);
  }

  test_binaryExpression_add_left_check() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertConstraint([decoratedTypeAnnotation('int i').nullable],
        checkExpression('i +').notNull);
  }

  test_binaryExpression_add_left_check_custom() async {
    await analyze('''
class Int {
  Int operator+(Int other) => this;
}
Int f(Int i, Int j) => i + j;
''');

    assertConstraint([decoratedTypeAnnotation('Int i').nullable],
        checkExpression('i +').notNull);
  }

  test_binaryExpression_add_result_custom() async {
    await analyze('''
class Int {
  Int operator+(Int other) => this;
}
Int f(Int i, Int j) => i + j;
''');

    assertConstraint([decoratedTypeAnnotation('Int operator+').nullable],
        decoratedTypeAnnotation('Int f').nullable);
  }

  test_binaryExpression_add_result_not_null() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNoConstraints(decoratedTypeAnnotation('int f').nullable);
  }

  test_binaryExpression_add_right_check() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertConstraint([decoratedTypeAnnotation('int j').nullable],
        checkExpression('j;').notNull);
  }

  test_binaryExpression_add_right_check_custom() async {
    await analyze('''
class Int {
  Int operator+(Int other) => this;
}
Int f(Int i, Int j) => i + j;
''');

    assertConstraint([decoratedTypeAnnotation('Int j').nullable],
        decoratedTypeAnnotation('Int other').nullable);
  }

  test_binaryExpression_equal() async {
    await analyze('''
bool f(int i, int j) => i == j;
''');

    assertNoConstraints(decoratedTypeAnnotation('bool f').nullable);
  }

  test_conditionalExpression_condition_check() async {
    await analyze('''
int f(bool b, int i, int j) {
  return (b ? i : j);
}
''');

    var nullable_b = decoratedTypeAnnotation('bool b').nullable;
    var check_b = checkExpression('b ?').notNull;
    assertConstraint([nullable_b], check_b);
  }

  test_conditionalExpression_general() async {
    await analyze('''
int f(bool b, int i, int j) {
  return (b ? i : j);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').nullable;
    var nullable_j = decoratedTypeAnnotation('int j').nullable;
    var nullable_i_or_nullable_j = _mockOr(nullable_i, nullable_j);
    var nullable_conditional = decoratedExpressionType('(b ?').nullable;
    var nullable_return = decoratedTypeAnnotation('int f').nullable;
    assertConstraint([nullable_i], nullable_conditional);
    assertConstraint([nullable_j], nullable_conditional);
    assertConstraint([nullable_conditional], nullable_i_or_nullable_j);
    assertConstraint([nullable_conditional], nullable_return);
  }

  test_conditionalExpression_left_non_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? (throw i) : i);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').nullable;
    var nullable_conditional = decoratedExpressionType('(b ?').nullable;
    expect(nullable_conditional, same(nullable_i));
  }

  test_conditionalExpression_left_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? null : i);
}
''');

    var nullable_conditional = decoratedExpressionType('(b ?').nullable;
    expect(nullable_conditional, same(ConstraintVariable.always));
  }

  test_conditionalExpression_right_non_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? i : (throw i));
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').nullable;
    var nullable_conditional = decoratedExpressionType('(b ?').nullable;
    expect(nullable_conditional, same(nullable_i));
  }

  test_conditionalExpression_right_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? i : null);
}
''');

    var nullable_conditional = decoratedExpressionType('(b ?').nullable;
    expect(nullable_conditional, same(ConstraintVariable.always));
  }

  test_functionDeclaration_expression_body() async {
    await analyze('''
int/*1*/ f(int/*2*/ i) => i;
''');

    assertConstraint([decoratedTypeAnnotation('int/*2*/').nullable],
        decoratedTypeAnnotation('int/*1*/').nullable);
  }

  test_functionDeclaration_parameter_positionalOptional_no_default() async {
    await analyze('''
void f([int i]) {}
''');

    assertConstraint([], decoratedTypeAnnotation('int').nullable);
  }

  test_functionInvocation_parameter_fromLocalParameter() async {
    await analyze('''
void f(int/*1*/ i) {}
void test(int/*2*/ i) {
  f(i);
}
''');

    assertConstraint([decoratedTypeAnnotation('int/*2*/').nullable],
        decoratedTypeAnnotation('int/*1*/').nullable);
  }

  test_functionInvocation_parameter_null() async {
    await analyze('''
void f(int i) {}
void test() {
  f(null);
}
''');

    assertConstraint(
        [ConstraintVariable.always], decoratedTypeAnnotation('int').nullable);
  }

  test_functionInvocation_return() async {
    await analyze('''
int/*1*/ f() => 0;
int/*2*/ g() {
  return f();
}
''');

    assertConstraint([decoratedTypeAnnotation('int/*1*/').nullable],
        decoratedTypeAnnotation('int/*2*/').nullable);
  }

  test_if_condition() async {
    await analyze('''
void f(bool b) {
  if (b) {}
}
''');

    assertConstraint([(decoratedTypeAnnotation('bool b').nullable)],
        checkExpression('b) {}').notNull);
  }

  test_if_guard_equals_null() async {
    await analyze('''
int f(int i, int j, int k) {
  if (i == null) {
    return j;
  } else {
    return k;
  }
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').nullable;
    var nullable_j = decoratedTypeAnnotation('int j').nullable;
    var nullable_k = decoratedTypeAnnotation('int k').nullable;
    var nullable_return = decoratedTypeAnnotation('int f').nullable;
    assertConstraint([nullable_i, nullable_j], nullable_return);
    assertConstraint([nullable_k], nullable_return);
    var discard = statementDiscard('if (i == null)');
    expect(discard.keepTrue, same(nullable_i));
    expect(discard.keepFalse, same(ConstraintVariable.always));
    expect(discard.pureCondition, true);
  }

  test_if_simple() async {
    await analyze('''
int f(bool b, int i, int j) {
  if (b) {
    return i;
  } else {
    return j;
  }
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').nullable;
    var nullable_j = decoratedTypeAnnotation('int j').nullable;
    var nullable_return = decoratedTypeAnnotation('int f').nullable;
    assertConstraint([nullable_i], nullable_return);
    assertConstraint([nullable_j], nullable_return);
  }

  test_if_without_else() async {
    await analyze('''
int f(bool b, int i) {
  if (b) {
    return i;
  }
  return 0;
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').nullable;
    var nullable_return = decoratedTypeAnnotation('int f').nullable;
    assertConstraint([nullable_i], nullable_return);
  }

  test_intLiteral() async {
    await analyze('''
int f() {
  return 0;
}
''');
    assertNoConstraints(decoratedTypeAnnotation('int').nullable);
  }

  test_methodInvocation_parameter_contravariant() async {
    await analyze('''
class C<T> {
  void f(T t) {}
}
void g(C<int> c, int i) {
  c.f(i);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').nullable;
    var nullable_c_t =
        decoratedTypeAnnotation('C<int>').typeArguments[0].nullable;
    var nullable_t = decoratedTypeAnnotation('T t').nullable;
    var nullable_c_t_or_nullable_t = _mockOr(nullable_c_t, nullable_t);
    assertConstraint([nullable_i], nullable_c_t_or_nullable_t);
  }

  test_methodInvocation_parameter_generic() async {
    await analyze('''
class C<T> {}
void f(C<int/*1*/>/*2*/ c) {}
void g(C<int/*3*/>/*4*/ c) {
  f(c);
}
''');

    assertConstraint([decoratedTypeAnnotation('int/*3*/').nullable],
        decoratedTypeAnnotation('int/*1*/').nullable);
    assertConstraint([decoratedTypeAnnotation('C<int/*3*/>/*4*/').nullable],
        decoratedTypeAnnotation('C<int/*1*/>/*2*/').nullable);
  }

  test_methodInvocation_target_check() async {
    await analyze('''
class C {
  void m() {}
}
void test(C c) {
  c.m();
}
''');

    assertConstraint([decoratedTypeAnnotation('C c').nullable],
        checkExpression('c.m').notNull);
  }

  test_parenthesizedExpression() async {
    await analyze('''
int f() {
  return (null);
}
''');

    assertConstraint(
        [ConstraintVariable.always], decoratedTypeAnnotation('int').nullable);
  }

  test_return_null() async {
    await analyze('''
int f() {
  return null;
}
''');

    assertConstraint(
        [ConstraintVariable.always], decoratedTypeAnnotation('int').nullable);
  }

  test_thisExpression() async {
    await analyze('''
class C {
  C f() => this;
}
''');

    assertNoConstraints(decoratedTypeAnnotation('C f').nullable);
  }

  test_throwExpression() async {
    await analyze('''
int f() {
  return throw null;
}
''');
    assertNoConstraints(decoratedTypeAnnotation('int').nullable);
  }

  test_typeName() async {
    await analyze('''
Type f() {
  return int;
}
''');
    assertNoConstraints(decoratedTypeAnnotation('Type').nullable);
  }

  /// Creates a variable representing the disjunction of [a] and [b] solely for
  /// the purpose of inspecting constraint equations in unit tests.  No
  /// additional constraints will be recorded in [_constraints] as a consequence
  /// of creating this variable.
  ConstraintVariable _mockOr(ConstraintVariable a, ConstraintVariable b) =>
      ConstraintVariable.or(_MockConstraints(), a, b);
}

abstract class ConstraintsTestBase extends MigrationVisitorTestBase {
  Constraints get constraints;

  /// Analyzes the given source code, producing constraint variables and
  /// constraints for it.
  @override
  Future<CompilationUnit> analyze(String code) async {
    var unit = await super.analyze(code);
    unit.accept(ConstraintGatherer(typeProvider, _variables, constraints));
    return unit;
  }
}

@reflectiveTest
class ConstraintVariableGathererTest extends MigrationVisitorTestBase {
  /// Gets the [DecoratedType] associated with the function declaration whose
  /// name matches [search].
  DecoratedType decoratedFunctionType(String search) =>
      _variables.decoratedElementType(
          findNode.functionDeclaration(search).declaredElement);

  test_interfaceType_nullable() async {
    await analyze('''
void f(int? x) {}
''');
    var decoratedType = decoratedTypeAnnotation('int?');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.nullable, same(ConstraintVariable.always));
  }

  test_interfaceType_typeParameter() async {
    await analyze('''
void f(List<int> x) {}
''');
    var decoratedListType = decoratedTypeAnnotation('List<int>');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedListType));
    expect(decoratedListType.nullable, isNotNull);
    var decoratedIntType = decoratedTypeAnnotation('int');
    expect(decoratedListType.typeArguments[0], same(decoratedIntType));
    expect(decoratedIntType.nullable, isNotNull);
  }

  test_topLevelFunction_parameterType_implicit_dynamic() async {
    await analyze('''
void f(x) {}
''');
    var decoratedType =
        _variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.type.isDynamic, isTrue);
    expect(decoratedType.nullable, same(ConstraintVariable.always));
  }

  test_topLevelFunction_parameterType_positionalOptional() async {
    await analyze('''
void f([int i]) {}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.nullable, isNotNull);
  }

  test_topLevelFunction_parameterType_simple() async {
    await analyze('''
void f(int i) {}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.nullable, isNotNull);
  }

  test_topLevelFunction_returnType_implicit_dynamic() async {
    await analyze('''
f() {}
''');
    var decoratedType = decoratedFunctionType('f').returnType;
    expect(decoratedType.type.isDynamic, isTrue);
    expect(decoratedType.nullable, same(ConstraintVariable.always));
  }

  test_topLevelFunction_returnType_simple() async {
    await analyze('''
int f() => 0;
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    expect(decoratedType.nullable, isNotNull);
  }
}

@reflectiveTest
class MigrationIntegrationTest extends DriverResolutionTest {
  Map<String, List<Modification>> _modifications;

  Future<CompilationUnit> analyze(String code) async {
    addTestFile(code);
    await resolveTestFile();
    var migration = NullabilityMigration();
    migration.prepareInput(result.path, result.unit);
    migration.processInput(result.unit, typeProvider);
    _modifications = migration.finish();
  }

  /// Checks that the result of the migration matches the given string.
  void checkMigration(String expected) {
    var migrated = NullabilityMigration.applyModifications(
        result.content, _modifications[result.path]);
    expect(migrated, expected);
  }

  test_data_flow_generic_inward() async {
    await analyze('''
class C<T> {
  void f(T t) {}
}
void g(C<int> c, int i) {
  c.f(i);
}
void test(C<int> c) {
  g(c, null);
}
''');

    // Default behavior is to add nullability at the call site.  Rationale: this
    // is correct in the common case where the generic parameter represents the
    // type of an item in a container.  Also, if there are many callers that are
    // largely independent, adding nullability to the callee would likely
    // propagate to a field in the class, and thence (via return values of other
    // methods) to most users of the class.  Whereas if we add nullability at
    // the call site it's possible that other call sites won't need it.
    //
    // TODO(paulberry): possible improvement: detect that since C uses T in a
    // contravariant way, and deduce that test should change to
    // `void test(C<int?> c)`
    checkMigration('''
class C<T> {
  void f(T t) {}
}
void g(C<int?> c, int? i) {
  c.f(i);
}
void test(C<int> c) {
  g(c, null);
}
''');
  }

  test_data_flow_generic_inward_hint() async {
    await analyze('''
class C<T> {
  void f(T? t) {}
}
void g(C<int> c, int i) {
  c.f(i);
}
void test(C<int> c) {
  g(c, null);
}
''');

    // The user may override the behavior shown in test_data_flow_generic_inward
    // by explicitly marking f's use of T as nullable.  Since this makes g's
    // call to f valid regardless of the type of c, c's type will remain
    // C<int>.
    checkMigration('''
class C<T> {
  void f(T? t) {}
}
void g(C<int> c, int? i) {
  c.f(i);
}
void test(C<int> c) {
  g(c, null);
}
''');
  }

  test_data_flow_inward() async {
    await analyze('''
int f(int i) => 0;
int g(int i) => f(i);
void test() {
  g(null);
}
''');

    checkMigration('''
int f(int? i) => 0;
int g(int? i) => f(i);
void test() {
  g(null);
}
''');
  }

  test_data_flow_inward_missing_type() async {
    await analyze('''
int f(int i) => 0;
int g(i) => f(i); // TODO(danrubel): suggest type
void test() {
  g(null);
}
''');

    checkMigration('''
int f(int? i) => 0;
int g(i) => f(i); // TODO(danrubel): suggest type
void test() {
  g(null);
}
''');
  }

  test_data_flow_outward() async {
    await analyze('''
int f(int i) => null;
int g(int i) => f(i);
''');

    checkMigration('''
int? f(int i) => null;
int? g(int i) => f(i);
''');
  }

  test_data_flow_outward_missing_type() async {
    await analyze('''
f(int i) => null; // TODO(danrubel): suggest type
int g(int i) => f(i);
''');

    checkMigration('''
f(int i) => null; // TODO(danrubel): suggest type
int? g(int i) => f(i);
''');
  }

  test_discard_simple_condition() async {
    await analyze('''
int f(int i) {
  if (i == null) {
    return null;
  } else {
    return i + 1;
  }
}
''');

    checkMigration('''
int f(int i) {
  /* if (i == null) {
    return null;
  } else {
    */ return i + 1; /*
  } */
}
''');
  }

  test_non_null_assertion() async {
    await analyze('''
int f(int i, [int j]) {
  if (i == 0) return i;
  return i + j;
}
''');

    checkMigration('''
int f(int i, [int? j]) {
  if (i == 0) return i;
  return i + j!;
}
''');
  }
}

class MigrationVisitorTestBase extends DriverResolutionTest {
  final _variables = Variables();

  Future<CompilationUnit> analyze(String code) async {
    addTestFile(code);
    await resolveTestFile();
    var unit = result.unit;
    unit.accept(ConstraintVariableGatherer(_variables));
    return unit;
  }

  /// Gets the [DecoratedType] associated with the type annotation whose text
  /// is [text].
  DecoratedType decoratedTypeAnnotation(String text) {
    return _variables.decoratedTypeAnnotation(findNode.typeAnnotation(text));
  }

  /// Gets the [ConditionalDiscard] information associated with the statement
  /// whose text is [text].
  ConditionalDiscard statementDiscard(String text) {
    return _variables.conditionalDiscard(findNode.statement(text));
  }
}

/// Mock representation of a constraint equation that is not connected to a
/// constraint solver.  We use this to confirm that analysis produces the
/// correct constraint equations.
///
/// [hashCode] and equality are implemented using [toString] for simplicity.
class _Clause {
  final Set<ConstraintVariable> conditions;
  final ConstraintVariable consequence;

  _Clause(this.conditions, this.consequence);

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) =>
      other is _Clause && toString() == other.toString();

  @override
  String toString() {
    String lhs;
    if (conditions.isNotEmpty) {
      var sortedConditionStrings = conditions.map((v) => v.toString()).toList()
        ..sort();
      lhs = sortedConditionStrings.join(' & ') + ' => ';
    } else {
      lhs = '';
    }
    String rhs = consequence.toString();
    return lhs + rhs;
  }
}

/// Mock representation of a constraint solver that does not actually do any
/// solving.  We use this to confirm that analysis produced the correct
/// constraint equations.
class _Constraints extends Constraints {
  final _clauses = <_Clause>[];

  @override
  void record(
      Iterable<ConstraintVariable> conditions, ConstraintVariable consequence) {
    _clauses.add(_Clause(conditions.toSet(), consequence));
  }
}

/// Mock implementation of [Constraints] that doesn't record any constraints.
class _MockConstraints implements Constraints {
  @override
  void record(Iterable<ConstraintVariable> conditions,
      ConstraintVariable consequence) {}
}
