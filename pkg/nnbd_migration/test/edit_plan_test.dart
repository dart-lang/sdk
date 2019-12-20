// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditPlanTest);
    defineReflectiveTests(EndsInCascadeTest);
    defineReflectiveTests(PrecedenceTest);
  });
}

@reflectiveTest
class EditPlanTest extends AbstractSingleUnitTest {
  String code;

  Future<void> analyze(String code) async {
    this.code = code;
    await resolveTestUnit(code);
  }

  void checkPlan(EditPlan plan, String expected) {
    expect(plan.finalize().applyTo(code), expected);
  }

  EditPlan extract(AstNode inner, AstNode outer) =>
      EditPlan.extract(outer, EditPlan.passThrough(inner));

  test_cascadeSearchLimit() async {
    // Ok, we have to ask each parent if it represents a cascade section.
    // If we create a passThrough at node N, then when we create an enclosing
    // passThrough, the first thing we'll check is N's parent.
    await analyze('f(a, c) => a..b = c = 1;');
    var cascade = findNode.cascade('..');
    var outerAssignment = findNode.assignment('= c');
    assert(identical(cascade, outerAssignment.parent));
    var innerAssignment = findNode.assignment('= 1');
    assert(identical(outerAssignment, innerAssignment.parent));
    var one = findNode.integerLiteral('1');
    assert(identical(innerAssignment, one.parent));
    // The tests below will be based on an inner plan that adds `..isEven` after
    // the `1`.
    EditPlan makeInnerPlan() => EditPlan.surround(EditPlan.passThrough(one),
        suffix: [InsertText('..isEven')], endsInCascade: true);
    {
      // If we make a plan that passes through `c = 1`, containing a plan that
      // adds `..isEven` to `1`, then we don't necessarily want to add parens yet,
      // because we might not keep the cascade section above it.
      var plan =
          EditPlan.passThrough(innerAssignment, innerPlans: [makeInnerPlan()]);
      // `endsInCascade` returns true because we haven't committed to adding
      // parens, so we need to remember that the presence of `..isEven` may
      // require parens later.
      expect(plan.endsInCascade, true);
      checkPlan(EditPlan.extract(cascade, plan), 'f(a, c) => c = 1..isEven;');
    }
    {
      // If we make a plan that passes through `..b = c = 1`, containing a plan
      // that adds `..isEven` to `1`, then we do necessarily want to add parens,
      // because we're committed to keeping the cascade section.
      var plan =
          EditPlan.passThrough(outerAssignment, innerPlans: [makeInnerPlan()]);
      // We can tell that the parens have been finalized because `endsInCascade`
      // returns false now.
      expect(plan.endsInCascade, false);
      checkPlan(plan, 'f(a, c) => a..b = c = (1..isEven);');
    }
  }

  test_extract_add_parens() async {
    await analyze('f(g) => 1 * g(2, 3 + 4, 5);');
    checkPlan(
        extract(
            findNode.binary('+'), findNode.functionExpressionInvocation('+')),
        'f(g) => 1 * (3 + 4);');
  }

  test_extract_inner_endsInCascade() async {
    await analyze('f(a, g) => a..b = g(0, 1..isEven, 2);');
    expect(
        extract(findNode.cascade('1..isEven'),
                findNode.functionExpressionInvocation('g('))
            .endsInCascade,
        true);
    expect(
        extract(findNode.integerLiteral('1'),
                findNode.functionExpressionInvocation('g('))
            .endsInCascade,
        false);
  }

  test_extract_left() async {
    await analyze('var x = 1 + 2;');
    checkPlan(extract(findNode.integerLiteral('1'), findNode.binary('+')),
        'var x = 1;');
  }

  test_extract_no_parens_needed() async {
    await analyze('var x = 1 + 2 * 3;');
    checkPlan(extract(findNode.integerLiteral('2'), findNode.binary('*')),
        'var x = 1 + 2;');
  }

  test_extract_preserve_parens() async {
    // Note: extra spaces to verify that we are really preserving the parens
    // rather than removing them and adding new ones.
    await analyze('var x = ( 1 << 2 ) * 3 + 4;');
    checkPlan(extract(findNode.binary('<<'), findNode.binary('*')),
        'var x = ( 1 << 2 ) + 4;');
  }

  test_extract_remove_parens() async {
    await analyze('var x = (1 + 2) * 3 << 4;');
    checkPlan(extract(findNode.binary('+'), findNode.binary('*')),
        'var x = 1 + 2 << 4;');
  }

  test_finalize_compilationUnit() async {
    // Verify that an edit plan referring to the entire compilation unit can be
    // finalized.  (This is an important corner case because the entire
    // compilation unit is an AstNode with no parent).
    await analyze('var x = 0;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(testUnit),
            suffix: [InsertText(' var y = 0;')]),
        'var x = 0; var y = 0;');
  }

  test_surround_allowCascade() async {
    await analyze('f(x) => 1..isEven;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.cascade('..')),
            prefix: [InsertText('x..y = ')]),
        'f(x) => x..y = (1..isEven);');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.cascade('..')),
            prefix: [InsertText('x = ')], allowCascade: true),
        'f(x) => x = 1..isEven;');
  }

  test_surround_associative() async {
    await analyze('var x = 1 - 2;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.binary('-')),
            suffix: [InsertText(' - 3')],
            innerPrecedence: Precedence.additive,
            associative: true),
        'var x = 1 - 2 - 3;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.binary('-')),
            prefix: [InsertText('0 - ')], innerPrecedence: Precedence.additive),
        'var x = 0 - (1 - 2);');
  }

  test_surround_endsInCascade() async {
    await analyze('f(x) => x..y = 1;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.integerLiteral('1')),
            suffix: [InsertText(' + 2')]),
        'f(x) => x..y = 1 + 2;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.integerLiteral('1')),
            suffix: [InsertText('..isEven')], endsInCascade: true),
        'f(x) => x..y = (1..isEven);');
  }

  test_surround_endsInCascade_does_not_propagate_through_added_parens() async {
    await analyze('f(a) => a..b = 0;');
    checkPlan(
        EditPlan.surround(
            EditPlan.surround(EditPlan.passThrough(findNode.cascade('..')),
                prefix: [InsertText('1 + ')],
                innerPrecedence: Precedence.additive),
            prefix: [InsertText('true ? ')],
            suffix: [InsertText(' : 2')]),
        'f(a) => true ? 1 + (a..b = 0) : 2;');
    checkPlan(
        EditPlan.surround(
            EditPlan.surround(EditPlan.passThrough(findNode.cascade('..')),
                prefix: [InsertText('throw ')], allowCascade: true),
            prefix: [InsertText('true ? ')],
            suffix: [InsertText(' : 2')]),
        'f(a) => true ? (throw a..b = 0) : 2;');
  }

  test_surround_endsInCascade_internal_throw() async {
    await analyze('f(x, g) => g(0, throw x, 1);');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.simple('x, 1')),
            suffix: [InsertText('..y')], endsInCascade: true),
        'f(x, g) => g(0, throw x..y, 1);');
  }

  test_surround_endsInCascade_propagates() async {
    await analyze('f(a) => a..b = 0;');
    checkPlan(
        EditPlan.surround(
            EditPlan.surround(EditPlan.passThrough(findNode.cascade('..')),
                prefix: [InsertText('throw ')], allowCascade: true),
            prefix: [InsertText('true ? ')],
            suffix: [InsertText(' : 2')]),
        'f(a) => true ? (throw a..b = 0) : 2;');
    checkPlan(
        EditPlan.surround(
            EditPlan.surround(
                EditPlan.passThrough(findNode.integerLiteral('0')),
                prefix: [InsertText('throw ')],
                allowCascade: true),
            prefix: [InsertText('true ? ')],
            suffix: [InsertText(' : 2')]),
        'f(a) => a..b = true ? throw 0 : 2;');
  }

  test_surround_precedence() async {
    await analyze('var x = 1 == true;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.integerLiteral('1')),
            suffix: [InsertText(' < 2')],
            outerPrecedence: Precedence.relational),
        'var x = 1 < 2 == true;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.integerLiteral('1')),
            suffix: [InsertText(' == 2')],
            outerPrecedence: Precedence.equality),
        'var x = (1 == 2) == true;');
  }

  test_surround_prefix() async {
    await analyze('var x = 1;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.integerLiteral('1')),
            prefix: [InsertText('throw ')]),
        'var x = throw 1;');
  }

  test_surround_suffix() async {
    await analyze('var x = 1;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.integerLiteral('1')),
            suffix: [InsertText('..isEven')]),
        'var x = 1..isEven;');
  }

  test_surround_threshold() async {
    await analyze('var x = 1 < 2;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.binary('<')),
            suffix: [InsertText(' == true')],
            innerPrecedence: Precedence.equality),
        'var x = 1 < 2 == true;');
    checkPlan(
        EditPlan.surround(EditPlan.passThrough(findNode.binary('<')),
            suffix: [InsertText(' as bool')],
            innerPrecedence: Precedence.relational),
        'var x = (1 < 2) as bool;');
  }
}

@reflectiveTest
class EndsInCascadeTest extends AbstractSingleUnitTest {
  test_ignore_subexpression_not_at_end() async {
    await resolveTestUnit('f(g) => g(0..isEven, 1);');
    expect(findNode.functionExpressionInvocation('g(').endsInCascade, false);
    expect(findNode.cascade('..').endsInCascade, true);
  }

  test_no_cascade() async {
    await resolveTestUnit('var x = 0;');
    expect(findNode.integerLiteral('0').endsInCascade, false);
  }

  test_stop_searching_when_parens_encountered() async {
    await resolveTestUnit('f(x) => x = (x = 0..isEven);');
    expect(findNode.assignment('= (x').endsInCascade, false);
    expect(findNode.parenthesized('(x =').endsInCascade, false);
    expect(findNode.assignment('= 0').endsInCascade, true);
    expect(findNode.cascade('..').endsInCascade, true);
  }
}

/// Tests of the precedence logic underlying [EditPlan].
///
/// The way these tests operate is as follows: we have several short snippets of
/// Dart code exercising Dart syntax with no unnecessary parentheses.  We
/// recursively visit the AST of each snippet and use [EditPlan.passThrough] to
/// create an edit plan based on each AST node.  Then we use
/// [EditPlan.parensNeededFromContext] to check whether parentheses are needed
/// around each node, and assert that the result agrees with the set of
/// parentheses that are actually present.
@reflectiveTest
class PrecedenceTest extends AbstractSingleUnitTest {
  void checkPrecedence(String content) async {
    await resolveTestUnit(content);
    testUnit.accept(_PrecedenceChecker());
  }

  void test_precedence_as() async {
    await checkPrecedence('''
f(a) => (a as num) as int;
g(a, b) => a | b as int;
''');
  }

  void test_precedence_assignment() async {
    await checkPrecedence('f(a, b, c) => a = b = c;');
  }

  void test_precedence_assignment_in_cascade_with_parens() async {
    await checkPrecedence('f(a, c, e) => a..b = (c..d = e);');
  }

  void test_precedence_await() async {
    await checkPrecedence('''
f(a) async => await -a;
g(a, b) async => await (a*b);
    ''');
  }

  void test_precedence_binary_equality() async {
    await checkPrecedence('''
f(a, b, c) => (a == b) == c;
g(a, b, c) => a == (b == c);
''');
  }

  void test_precedence_binary_left_associative() async {
    // Associativity logic is the same for all operators except relational and
    // equality, so we just test `+` as a stand-in for all the others.
    await checkPrecedence('''
f(a, b, c) => a + b + c;
g(a, b, c) => a + (b + c);
''');
  }

  void test_precedence_binary_relational() async {
    await checkPrecedence('''
f(a, b, c) => (a < b) < c;
g(a, b, c) => a < (b < c);
''');
  }

  void test_precedence_conditional() async {
    await checkPrecedence('''
g(a, b, c, d, e, f) => a ?? b ? c = d : e = f;
h(a, b, c, d, e) => (a ? b : c) ? d : e;
''');
  }

  void test_precedence_extension_override() async {
    await checkPrecedence('''
extension E on Object {
  void f() {}
}
void g(x) => E(x).f();
''');
  }

  void test_precedence_functionExpressionInvocation() async {
    await checkPrecedence('''
f(g) => g[0](1);
h(x) => (x + 2)(3);
''');
  }

  void test_precedence_is() async {
    await checkPrecedence('''
f(a) => (a as num) is int;
g(a, b) => a | b is int;
''');
  }

  void test_precedence_postfix_and_index() async {
    await checkPrecedence('''
f(a, b, c) => a[b][c];
g(a, b) => a[b]++;
h(a, b) => (-a)[b];
''');
  }

  void test_precedence_prefix() async {
    await checkPrecedence('''
f(a) => ~-a;
g(a, b) => -(a*b);
''');
  }

  void test_precedence_prefixedIdentifier() async {
    await checkPrecedence('f(a) => a.b;');
  }

  void test_precedence_propertyAccess() async {
    await checkPrecedence('''
f(a) => a?.b?.c;
g(a) => (-a)?.b;
''');
  }

  void test_precedence_throw() async {
    await checkPrecedence('''
f(a, b) => throw a = b;
g(a, c) => a..b = throw (c..d);
''');
  }

  void test_precedenceChecker_detects_unnecessary_paren() async {
    await resolveTestUnit('var x = (1);');
    expect(() => testUnit.accept(_PrecedenceChecker()),
        throwsA(TypeMatcher<TestFailure>()));
  }
}

class _PrecedenceChecker extends UnifyingAstVisitor<void> {
  @override
  void visitNode(AstNode node) {
    expect(EditPlan.passThrough(node).parensNeededFromContext(null), false);
    node.visitChildren(this);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    expect(EditPlan.passThrough(node).parensNeededFromContext(null), true);
    node.expression.visitChildren(this);
  }
}
