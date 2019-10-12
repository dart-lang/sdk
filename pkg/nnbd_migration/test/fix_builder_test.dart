// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/fix_builder.dart';
import 'package:nnbd_migration/src/variables.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixBuilderTest);
  });
}

@reflectiveTest
class FixBuilderTest extends EdgeBuilderTestBase {
  DartType get dynamicType => postMigrationTypeProvider.dynamicType;

  DartType get objectType => postMigrationTypeProvider.objectType;

  TypeProvider get postMigrationTypeProvider =>
      (typeProvider as TypeProviderImpl)
          .withNullability(NullabilitySuffix.none);

  @override
  Future<CompilationUnit> analyze(String code) async {
    var unit = await super.analyze(code);
    graph.propagate();
    return unit;
  }

  test_assignmentExpression_compound_combined_nullable_noProblem() async {
    await analyze('''
abstract class _C {
  _D/*?*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*!*/ get x;
  void set x(_C/*?*/ value);
  f(int/*!*/ y) => x += y;
}
''');
    visitSubexpression(findNode.assignment('+='), '_D?');
  }

  test_assignmentExpression_compound_combined_nullable_noProblem_dynamic() async {
    await analyze('''
abstract class _E {
  dynamic get x;
  void set x(Object/*!*/ value);
  f(int/*!*/ y) => x += y;
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, 'dynamic');
  }

  test_assignmentExpression_compound_combined_nullable_problem() async {
    await analyze('''
abstract class _C {
  _D/*?*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*!*/ get x;
  void set x(_C/*!*/ value);
  f(int/*!*/ y) => x += y;
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, '_D', problems: {
      assignment: {const CompoundAssignmentCombinedNullable()}
    });
  }

  test_assignmentExpression_compound_dynamic() async {
    // To confirm that the RHS is visited, we check that a null check was
    // properly inserted into a subexpression of the RHS.
    await analyze('''
_f(dynamic x, int/*?*/ y) => x += y + 1;
''');
    visitSubexpression(findNode.assignment('+='), 'dynamic',
        nullChecked: {findNode.simple('y +')});
  }

  test_assignmentExpression_compound_intRules() async {
    await analyze('''
_f(int x, int y) => x += y;
''');
    visitSubexpression(findNode.assignment('+='), 'int');
  }

  test_assignmentExpression_compound_lhs_nullable_problem() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*?*/ get x;
  void set x(_C/*?*/ value);
  f(int/*!*/ y) => x += y;
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, '_D', problems: {
      assignment: {const CompoundAssignmentReadNullable()}
    });
  }

  test_assignmentExpression_compound_promoted() async {
    await analyze('''
f(bool/*?*/ x, bool/*?*/ y) => x != null && (x = y);
''');
    // It is ok to assign a nullable value to `x` even though it is promoted to
    // non-nullable, so `y` should not be null-checked.  However, the whole
    // assignment `x = y` should be null checked because the RHS of `&&` cannot
    // be nullable.
    visitSubexpression(findNode.binary('&&'), 'bool',
        nullChecked: {findNode.parenthesized('x = y')});
  }

  test_assignmentExpression_compound_rhs_nonNullable() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
_f(_C/*!*/ x, int/*!*/ y) => x += y;
''');
    visitSubexpression(findNode.assignment('+='), '_D');
  }

  test_assignmentExpression_compound_rhs_nullable_check() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
_f(_C/*!*/ x, int/*?*/ y) => x += y;
''');
    visitSubexpression(findNode.assignment('+='), '_D',
        nullChecked: {findNode.simple('y;')});
  }

  test_assignmentExpression_compound_rhs_nullable_noCheck() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*?*/ value);
}
abstract class _D extends _C {}
_f(_C/*!*/ x, int/*?*/ y) => x += y;
''');
    visitSubexpression(findNode.assignment('+='), '_D');
  }

  test_assignmentExpression_null_aware_rhs_nonNullable() async {
    await analyze('''
abstract class _B {}
abstract class _C extends _B {}
abstract class _D extends _C {}
abstract class _E extends _C {}
abstract class _F {
  _D/*?*/ get x;
  void set x(_B/*?*/ value);
  f(_E/*!*/ y) => x ??= y;
}
''');
    visitSubexpression(findNode.assignment('??='), '_C');
  }

  test_assignmentExpression_null_aware_rhs_nullable() async {
    await analyze('''
abstract class _B {}
abstract class _C extends _B {}
abstract class _D extends _C {}
abstract class _E extends _C {}
abstract class _F {
  _D/*?*/ get x;
  void set x(_B/*?*/ value);
  f(_E/*?*/ y) => x ??= y;
}
''');
    visitSubexpression(findNode.assignment('??='), '_C?');
  }

  test_assignmentExpression_simple_nonNullable_to_nonNullable() async {
    await analyze('''
_f(int/*!*/ x, int/*!*/ y) => x = y;
''');
    visitSubexpression(findNode.assignment('= '), 'int');
  }

  test_assignmentExpression_simple_nonNullable_to_nullable() async {
    await analyze('''
_f(int/*?*/ x, int/*!*/ y) => x = y;
''');
    visitSubexpression(findNode.assignment('= '), 'int');
  }

  test_assignmentExpression_simple_nullable_to_nonNullable() async {
    await analyze('''
_f(int/*!*/ x, int/*?*/ y) => x = y;
''');
    visitSubexpression(findNode.assignment('= '), 'int',
        contextType: objectType, nullChecked: {findNode.simple('y;')});
  }

  test_assignmentExpression_simple_nullable_to_nullable() async {
    await analyze('''
_f(int/*?*/ x, int/*?*/ y) => x = y;
''');
    visitSubexpression(findNode.assignment('= '), 'int?');
  }

  test_assignmentExpression_simple_promoted() async {
    await analyze('''
_f(bool/*?*/ x, bool/*?*/ y) => x != null && (x = y) != null;
''');
    // On the RHS of the `&&`, `x` is promoted to non-nullable, but it is still
    // considered to be a nullable assignment target, so no null check is
    // generated for `y`.
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  test_assignmentTarget_simpleIdentifier_field_generic() async {
    await analyze('''
abstract class _C<T> {
  _C<T> operator+(int i);
}
class _D<T> {
  _D(this.x);
  _C<T/*!*/>/*!*/ x;
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x +='), '_C<T>', '_C<T>');
  }

  test_assignmentTarget_simpleIdentifier_field_nonNullable() async {
    await analyze('''
class _C {
  int/*!*/ x;
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x '), 'int', 'int');
  }

  test_assignmentTarget_simpleIdentifier_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ x;
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x '), 'int?', 'int?');
  }

  test_assignmentTarget_simpleIdentifier_getset_generic() async {
    await analyze('''
abstract class _C<T> {
  _C<T> operator+(int i);
}
abstract class _D<T> extends _C<T> {}
abstract class _E<T> {
  _D<T/*!*/>/*!*/ get x;
  void set x(_C<T/*!*/>/*!*/ value);
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x +='), '_D<T>', '_C<T>');
  }

  test_assignmentTarget_simpleIdentifier_getset_getterNullable() async {
    await analyze('''
class _C {
  int/*?*/ get x => 1;
  void set x(int/*!*/ value) {}
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x +='), 'int?', 'int');
  }

  test_assignmentTarget_simpleIdentifier_getset_setterNullable() async {
    await analyze('''
class _C {
  int/*!*/ get x => 1;
  void set x(int/*?*/ value) {}
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x +='), 'int', 'int?');
  }

  test_assignmentTarget_simpleIdentifier_localVariable_nonNullable() async {
    await analyze('''
_f(int/*!*/ x) => x += 0;
''');
    visitAssignmentTarget(findNode.simple('x '), 'int', 'int');
  }

  test_assignmentTarget_simpleIdentifier_localVariable_nullable() async {
    await analyze('''
_f(int/*?*/ x) => x += 0;
''');
    visitAssignmentTarget(findNode.simple('x '), 'int?', 'int?');
  }

  test_assignmentTarget_simpleIdentifier_setter_nonNullable() async {
    await analyze('''
class _C {
  void set x(int/*!*/ value) {}
  _f() => x = 0;
}
''');
    visitAssignmentTarget(findNode.simple('x '), 'int', 'int');
  }

  test_assignmentTarget_simpleIdentifier_setter_nullable() async {
    await analyze('''
class _C {
  void set x(int/*?*/ value) {}
  _f() => x = 0;
}
''');
    visitAssignmentTarget(findNode.simple('x '), 'int?', 'int?');
  }

  test_binaryExpression_ampersand_ampersand() async {
    await analyze('''
_f(bool x, bool y) => x && y;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  test_binaryExpression_ampersand_ampersand_flow() async {
    await analyze('''
_f(bool/*?*/ x) => x != null && x;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  test_binaryExpression_ampersand_ampersand_nullChecked() async {
    await analyze('''
_f(bool/*?*/ x, bool/*?*/ y) => x && y;
''');
    var xRef = findNode.simple('x &&');
    var yRef = findNode.simple('y;');
    visitSubexpression(findNode.binary('&&'), 'bool',
        nullChecked: {xRef, yRef});
  }

  test_binaryExpression_bang_eq() async {
    await analyze('''
_f(Object/*?*/ x, Object/*?*/ y) => x != y;
''');
    visitSubexpression(findNode.binary('!='), 'bool');
  }

  test_binaryExpression_bar_bar() async {
    await analyze('''
_f(bool x, bool y) {
  return x || y;
}
''');
    visitSubexpression(findNode.binary('||'), 'bool');
  }

  test_binaryExpression_bar_bar_flow() async {
    await analyze('''
_f(bool/*?*/ x) {
  return x == null || x;
}
''');
    visitSubexpression(findNode.binary('||'), 'bool');
  }

  test_binaryExpression_bar_bar_nullChecked() async {
    await analyze('''
_f(Object/*?*/ x, Object/*?*/ y) {
  return x || y;
}
''');
    var xRef = findNode.simple('x ||');
    var yRef = findNode.simple('y;');
    visitSubexpression(findNode.binary('||'), 'bool',
        nullChecked: {xRef, yRef});
  }

  test_binaryExpression_eq_eq() async {
    await analyze('''
_f(Object/*?*/ x, Object/*?*/ y) {
  return x == y;
}
''');
    visitSubexpression(findNode.binary('=='), 'bool');
  }

  test_binaryExpression_question_question() async {
    await analyze('''
_f(int/*?*/ x, double/*?*/ y) {
  return x ?? y;
}
''');
    visitSubexpression(findNode.binary('??'), 'num?');
  }

  test_binaryExpression_question_question_nullChecked() async {
    await analyze('''
Object/*!*/ _f(int/*?*/ x, double/*?*/ y) {
  return x ?? y;
}
''');
    var yRef = findNode.simple('y;');
    visitSubexpression(findNode.binary('??'), 'num',
        contextType: objectType, nullChecked: {yRef});
  }

  test_binaryExpression_userDefinable_dynamic() async {
    await analyze('''
Object/*!*/ _f(dynamic d, int/*?*/ i) => d + i;
''');
    visitSubexpression(findNode.binary('+'), 'dynamic',
        contextType: objectType);
  }

  test_binaryExpression_userDefinable_intRules() async {
    await analyze('''
_f(int i, int j) => i + j;
''');
    visitSubexpression(findNode.binary('+'), 'int');
  }

  test_binaryExpression_userDefinable_simple() async {
    await analyze('''
class _C {
  int operator+(String s) => 1;
}
_f(_C c) => c + 'foo';
''');
    visitSubexpression(findNode.binary('c +'), 'int');
  }

  test_binaryExpression_userDefinable_simple_check_lhs() async {
    await analyze('''
class _C {
  int operator+(String s) => 1;
}
_f(_C/*?*/ c) => c + 'foo';
''');
    visitSubexpression(findNode.binary('c +'), 'int',
        nullChecked: {findNode.simple('c +')});
  }

  test_binaryExpression_userDefinable_simple_check_rhs() async {
    await analyze('''
class _C {
  int operator+(String/*!*/ s) => 1;
}
_f(_C c, String/*?*/ s) => c + s;
''');
    visitSubexpression(findNode.binary('c +'), 'int',
        nullChecked: {findNode.simple('s;')});
  }

  test_binaryExpression_userDefinable_substituted() async {
    await analyze('''
class _C<T, U> {
  T operator+(U u) => throw 'foo';
}
_f(_C<int, String> c) => c + 'foo';
''');
    visitSubexpression(findNode.binary('c +'), 'int');
  }

  test_binaryExpression_userDefinable_substituted_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator+(U u) => throw 'foo';
}
_f(_C<int, String/*!*/> c, String/*?*/ s) => c + s;
''');
    visitSubexpression(findNode.binary('c +'), 'int',
        nullChecked: {findNode.simple('s;')});
  }

  test_binaryExpression_userDefinable_substituted_no_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator+(U u) => throw 'foo';
}
_f(_C<int, String/*?*/> c, String/*?*/ s) => c + s;
''');
    visitSubexpression(findNode.binary('c +'), 'int');
  }

  test_block() async {
    await analyze('''
_f(int/*?*/ x, int/*?*/ y) {
  { // block
    x + 1;
    y + 1;
  }
}
''');
    visitStatement(findNode.statement('{ // block'),
        nullChecked: {findNode.simple('x + 1'), findNode.simple('y + 1')});
  }

  test_booleanLiteral() async {
    await analyze('''
f() => true;
''');
    visitSubexpression(findNode.booleanLiteral('true'), 'bool');
  }

  test_conditionalExpression_flow_as_condition() async {
    await analyze('''
_f(bool x, int/*?*/ y) => (x ? y != null : y != null) ? y + 1 : 0;
''');
    // No explicit check needs to be added to `y + 1`, because both arms of the
    // conditional can only be true if `y != null`.
    visitSubexpression(findNode.conditionalExpression('y + 1'), 'int');
  }

  test_conditionalExpression_flow_condition() async {
    await analyze('''
_f(bool/*?*/ x) => x ? (x && true) : (x && true);
''');
    // No explicit check needs to be added to either `x && true`, because there
    // is already an explicit null check inserted for the condition.
    visitSubexpression(findNode.conditionalExpression('x ?'), 'bool',
        nullChecked: {findNode.simple('x ?')});
  }

  test_conditionalExpression_flow_then_else() async {
    await analyze('''
_f(bool x, bool/*?*/ y) => (x ? (y && true) : (y && true)) && y;
''');
    // No explicit check needs to be added to the final reference to `y`,
    // because null checks are added to the "then" and "else" branches promoting
    // y.
    visitSubexpression(findNode.binary('&& y'), 'bool', nullChecked: {
      findNode.simple('y && true) '),
      findNode.simple('y && true))')
    });
  }

  test_conditionalExpression_lub() async {
    await analyze('''
_f(bool b) => b ? 1 : 1.0;
''');
    visitSubexpression(findNode.conditionalExpression('1.0'), 'num');
  }

  test_conditionalExpression_throw_promotes() async {
    await analyze('''
_f(int/*?*/ x) =>
    <dynamic>[(x != null ? 1 : throw 'foo'), x + 1];
''');
    // No null check needs to be added to `x + 1`, because there is already an
    // explicit null check.
    visitSubexpression(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_doubleLiteral() async {
    await analyze('''
f() => 1.0;
''');
    visitSubexpression(findNode.doubleLiteral('1.0'), 'double');
  }

  test_expressionStatement() async {
    await analyze('''
_f(int/*!*/ x, int/*?*/ y) {
  x = y;
}
''');
    visitStatement(findNode.statement('x = y'),
        nullChecked: {findNode.simple('y;')});
  }

  test_ifStatement_flow_promote_in_else() async {
    await analyze('''
_f(int/*?*/ x) {
  if (x == null) {
    x + 1;
  } else {
    x + 2;
  }
}
''');
    visitStatement(findNode.statement('if'),
        nullChecked: {findNode.simple('x + 1')});
  }

  test_ifStatement_flow_promote_in_then() async {
    await analyze('''
_f(int/*?*/ x) {
  if (x != null) {
    x + 1;
  } else {
    x + 2;
  }
}
''');
    visitStatement(findNode.statement('if'),
        nullChecked: {findNode.simple('x + 2')});
  }

  test_ifStatement_flow_promote_in_then_no_else() async {
    await analyze('''
_f(int/*?*/ x) {
  if (x != null) {
    x + 1;
  }
}
''');
    visitStatement(findNode.statement('if'));
  }

  test_integerLiteral() async {
    await analyze('''
f() => 1;
''');
    visitSubexpression(findNode.integerLiteral('1'), 'int');
  }

  test_listLiteral_typed() async {
    await analyze('''
_f() => <int>[];
''');
    visitSubexpression(findNode.listLiteral('['), 'List<int>');
  }

  test_listLiteral_typed_visit_contents() async {
    await analyze('''
_f(int/*?*/ x) => <int/*!*/>[x];
''');
    visitSubexpression(findNode.listLiteral('['), 'List<int>',
        nullChecked: {findNode.simple('x]')});
  }

  test_nullAssertion_promotes() async {
    await analyze('''
_f(bool/*?*/ x) => x && x;
''');
    // Only the first `x` is null-checked because thereafter, the type of `x` is
    // promoted to `bool`.
    visitSubexpression(findNode.binary('&&'), 'bool',
        nullChecked: {findNode.simple('x &&')});
  }

  test_nullLiteral() async {
    await analyze('''
f() => null;
''');
    visitSubexpression(findNode.nullLiteral('null'), 'Null');
  }

  test_parenthesizedExpression() async {
    await analyze('''
f() => (1);
''');
    visitSubexpression(findNode.integerLiteral('1'), 'int');
  }

  test_parenthesizedExpression_flow() async {
    await analyze('''
_f(bool/*?*/ x) => ((x) != (null)) && x;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  test_simpleIdentifier_className() async {
    await analyze('''
_f() => int;
''');
    visitSubexpression(findNode.simple('int'), 'Type');
  }

  test_simpleIdentifier_field() async {
    await analyze('''
class _C {
  int i = 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int');
  }

  test_simpleIdentifier_field_generic() async {
    await analyze('''
class _C<T> {
  List<T> x = null;
  f() => x;
}
''');
    visitSubexpression(findNode.simple('x;'), 'List<T>?');
  }

  test_simpleIdentifier_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ i = 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int?');
  }

  test_simpleIdentifier_getter() async {
    await analyze('''
class _C {
  int get i => 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int');
  }

  test_simpleIdentifier_getter_nullable() async {
    await analyze('''
class _C {
  int/*?*/ get i => 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int?');
  }

  test_simpleIdentifier_localVariable_nonNullable() async {
    await analyze('''
_f(int x) {
  return x;
}
''');
    visitSubexpression(findNode.simple('x;'), 'int');
  }

  test_simpleIdentifier_localVariable_nullable() async {
    await analyze('''
_f(int/*?*/ x) {
  return x;
}
''');
    visitSubexpression(findNode.simple('x;'), 'int?');
  }

  test_stringLiteral() async {
    await analyze('''
f() => 'foo';
''');
    visitSubexpression(findNode.stringLiteral("'foo'"), 'String');
  }

  test_symbolLiteral() async {
    await analyze('''
f() => #foo;
''');
    visitSubexpression(findNode.symbolLiteral('#foo'), 'Symbol');
  }

  test_throw_flow() async {
    await analyze('''
_f(int/*?*/ i) {
  if (i == null) throw 'foo';
  i + 1;
}
''');
    visitStatement(findNode.block('{'));
  }

  test_throw_nullable() async {
    await analyze('''
_f(int/*?*/ i) => throw i;
''');
    visitSubexpression(findNode.throw_('throw'), 'Never',
        nullChecked: {findNode.simple('i;')});
  }

  test_throw_simple() async {
    await analyze('''
_f() => throw 'foo';
''');
    visitSubexpression(findNode.throw_('throw'), 'Never');
  }

  test_typeName_dynamic() async {
    await analyze('''
void _f() {
  dynamic d = null;
}
''');
    visitTypeAnnotation(findNode.typeAnnotation('dynamic'), 'dynamic');
  }

  test_typeName_generic_nonNullable() async {
    await analyze('''
void _f() {
  List<int> i = [0];
}
''');
    visitTypeAnnotation(findNode.typeAnnotation('List<int>'), 'List<int>');
  }

  test_typeName_generic_nullable() async {
    await analyze('''
void _f() {
  List<int> i = null;
}
''');
    var listIntAnnotation = findNode.typeAnnotation('List<int>');
    visitTypeAnnotation(listIntAnnotation, 'List<int>?',
        nullable: {listIntAnnotation});
  }

  test_typeName_generic_nullable_arg() async {
    await analyze('''
void _f() {
  List<int> i = [null];
}
''');
    visitTypeAnnotation(findNode.typeAnnotation('List<int>'), 'List<int?>',
        nullable: {findNode.typeAnnotation('int')});
  }

  test_typeName_simple_nonNullable() async {
    await analyze('''
void _f() {
  int i = 0;
}
''');
    visitTypeAnnotation(findNode.typeAnnotation('int'), 'int');
  }

  test_typeName_simple_nullable() async {
    await analyze('''
void _f() {
  int i = null;
}
''');
    var intAnnotation = findNode.typeAnnotation('int');
    visitTypeAnnotation((intAnnotation), 'int?', nullable: {intAnnotation});
  }

  test_typeName_void() async {
    await analyze('''
void _f() {
  void v;
}
''');
    visitTypeAnnotation(findNode.typeAnnotation('void v'), 'void');
  }

  test_use_of_dynamic() async {
    // Use of `dynamic` in a context requiring non-null is not explicitly null
    // checked.
    await analyze('''
bool _f(dynamic d, bool b) => d && b;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  test_variableDeclaration_typed_initialized_nonNullable() async {
    await analyze('''
void _f() {
  int x = 0;
}
''');
    visitStatement(findNode.statement('int x'));
  }

  test_variableDeclaration_typed_initialized_nullable() async {
    await analyze('''
void _f() {
  int x = null;
}
''');
    visitStatement(findNode.statement('int x'),
        nullable: {findNode.typeAnnotation('int')});
  }

  test_variableDeclaration_typed_uninitialized() async {
    await analyze('''
void _f() {
  int x;
}
''');
    visitStatement(findNode.statement('int x'));
  }

  test_variableDeclaration_untyped_initialized() async {
    await analyze('''
void _f() {
  var x = 0;
}
''');
    visitStatement(findNode.statement('var x'));
  }

  test_variableDeclaration_untyped_uninitialized() async {
    await analyze('''
void _f() {
  var x;
}
''');
    visitStatement(findNode.statement('var x'));
  }

  test_variableDeclaration_visit_initializer() async {
    await analyze('''
void _f(bool/*?*/ x, bool/*?*/ y) {
  bool z = x && y;
}
''');
    visitStatement(findNode.statement('bool z'),
        nullChecked: {findNode.simple('x &&'), findNode.simple('y;')});
  }

  void visitAssignmentTarget(
      Expression node, String expectedReadType, String expectedWriteType,
      {Set<Expression> nullChecked = const <Expression>{},
      Map<AstNode, Set<Problem>> problems = const <AstNode, Set<Problem>>{}}) {
    _FixBuilder fixBuilder = _createFixBuilder(node);
    var targetInfo = fixBuilder.visitAssignmentTarget(node);
    expect((targetInfo.readType as TypeImpl).toString(withNullability: true),
        expectedReadType);
    expect((targetInfo.writeType as TypeImpl).toString(withNullability: true),
        expectedWriteType);
    expect(fixBuilder.nullCheckedExpressions, nullChecked);
    expect(fixBuilder.problems, problems);
  }

  void visitStatement(Statement node,
      {Set<Expression> nullChecked = const <Expression>{},
      Map<AstNode, Set<Problem>> problems = const <AstNode, Set<Problem>>{},
      Set<TypeAnnotation> nullable = const <TypeAnnotation>{}}) {
    _FixBuilder fixBuilder = _createFixBuilder(node);
    var type = node.accept(fixBuilder);
    expect(type, null);
    expect(fixBuilder.nullCheckedExpressions, nullChecked);
    expect(fixBuilder.problems, problems);
    expect(fixBuilder.nullable, nullable);
  }

  void visitSubexpression(Expression node, String expectedType,
      {DartType contextType,
      Set<Expression> nullChecked = const <Expression>{},
      Map<AstNode, Set<Problem>> problems = const <AstNode, Set<Problem>>{},
      Set<TypeAnnotation> nullable = const <TypeAnnotation>{}}) {
    contextType ??= dynamicType;
    _FixBuilder fixBuilder = _createFixBuilder(node);
    var type = fixBuilder.visitSubexpression(node, contextType);
    expect((type as TypeImpl).toString(withNullability: true), expectedType);
    expect(fixBuilder.nullCheckedExpressions, nullChecked);
    expect(fixBuilder.problems, problems);
    expect(fixBuilder.nullable, nullable);
  }

  void visitTypeAnnotation(TypeAnnotation node, String expectedType,
      {Set<Expression> nullChecked = const <Expression>{},
      Map<AstNode, Set<Problem>> problems = const <AstNode, Set<Problem>>{},
      Set<TypeAnnotation> nullable = const <TypeAnnotation>{}}) {
    _FixBuilder fixBuilder = _createFixBuilder(node);
    var type = node.accept(fixBuilder);
    expect((type as TypeImpl).toString(withNullability: true), expectedType);
    expect(fixBuilder.nullCheckedExpressions, nullChecked);
    expect(fixBuilder.problems, problems);
    expect(fixBuilder.nullable, nullable);
  }

  _FixBuilder _createFixBuilder(AstNode node) {
    var fixBuilder = _FixBuilder(testSource, decoratedClassHierarchy,
        typeProvider, typeSystem, variables);
    var body = node.thisOrAncestorOfType<FunctionBody>();
    var declaration = body.thisOrAncestorOfType<Declaration>();
    fixBuilder.createFlowAnalysis(declaration, null);
    return fixBuilder;
  }
}

class _FixBuilder extends FixBuilder {
  final Set<Expression> nullCheckedExpressions = {};

  final Set<TypeAnnotation> nullable = {};

  final Map<AstNode, Set<Problem>> problems = {};

  _FixBuilder(Source source, DecoratedClassHierarchy decoratedClassHierarchy,
      TypeProvider typeProvider, TypeSystem typeSystem, Variables variables)
      : super(source, decoratedClassHierarchy, typeProvider, typeSystem,
            variables);

  @override
  void addNullable(TypeAnnotation node) {
    var newlyAdded = nullable.add(node);
    expect(newlyAdded, true);
  }

  @override
  void addNullCheck(Expression subexpression) {
    var newlyAdded = nullCheckedExpressions.add(subexpression);
    expect(newlyAdded, true);
  }

  @override
  void addProblem(AstNode node, Problem problem) {
    var newlyAdded = (problems[node] ??= {}).add(problem);
    expect(newlyAdded, true);
  }
}
