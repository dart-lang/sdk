// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/utilities/hint_utils.dart';
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

  EditPlanner _planner;

  @override
  bool get analyzeWithNnbd => true;

  EditPlanner get planner {
    if (_planner == null) createPlanner();
    return _planner;
  }

  Future<void> analyze(String code) async {
    this.code = code;
    await resolveTestUnit(code);
  }

  Map<int, List<AtomicEdit>> checkPlan(EditPlan plan, String expected,
      {String expectedIncludingInformative}) {
    expectedIncludingInformative ??= expected;
    var changes = planner.finalize(plan);
    expect(changes.applyTo(code), expected);
    expect(changes.applyTo(code, includeInformative: true),
        expectedIncludingInformative);
    return changes;
  }

  void createPlanner({bool removeViaComments = false}) {
    _planner = EditPlanner(testUnit.lineInfo, code,
        removeViaComments: removeViaComments);
  }

  NodeProducingEditPlan extract(AstNode inner, AstNode outer) =>
      planner.extract(outer, planner.passThrough(inner));

  Future<void> test_acceptLateHint() async {
    var code = '/* late */ int x = 0;';
    await analyze(code);
    var hint = getPrefixHint(findNode.simple('int').token);
    var changes = checkPlan(
        planner.acceptLateHint(
            planner.passThrough(findNode.simple('int')), hint),
        'late int x = 0;');
    expect(changes.keys, unorderedEquals([0, 7]));
    expect(changes[7], hasLength(1));
    expect(changes[7][0].length, 3);
  }

  Future<void> test_acceptLateHint_space_needed_after() async {
    var code = '/* late */int x = 0;';
    await analyze(code);
    var hint = getPrefixHint(findNode.simple('int').token);
    checkPlan(
        planner.acceptLateHint(
            planner.passThrough(findNode.simple('int')), hint),
        'late int x = 0;');
  }

  Future<void> test_acceptLateHint_space_needed_before() async {
    var code = '@deprecated/* late */ int x = 0;';
    await analyze(code);
    var hint = getPrefixHint(findNode.simple('int').token);
    checkPlan(
        planner.acceptLateHint(
            planner.passThrough(findNode.simple('int')), hint),
        '@deprecated late int x = 0;');
  }

  Future<void>
      test_acceptNullabilityHint_function_typed_field_formal_parameter() async {
    await analyze('''
class C {
  void Function(int) f;
  C(void this.f(int i) /*?*/);
}
''');
    var parameter = findNode.fieldFormalParameter('void this.f(int i)');
    var typeName = planner.passThrough(parameter);
    checkPlan(
        planner.acceptNullabilityOrNullCheckHint(
            typeName, getPostfixHint(parameter.parameters.rightParenthesis)),
        '''
class C {
  void Function(int) f;
  C(void this.f(int i)?);
}
''');
  }

  Future<void> test_acceptNullabilityHint_function_typed_parameter() async {
    await analyze('f(void g(int i) /*?*/) {}');
    var parameter = findNode.functionTypedFormalParameter('void g(int i)');
    var typeName = planner.passThrough(parameter);
    checkPlan(
        planner.acceptNullabilityOrNullCheckHint(
            typeName, getPostfixHint(parameter.parameters.rightParenthesis)),
        'f(void g(int i)?) {}');
  }

  Future<void> test_acceptNullabilityOrNullCheckHint() async {
    var code = 'int /*?*/ x = 0;';
    await analyze(code);
    var intRef = findNode.simple('int');
    var typeName = planner.passThrough(intRef);
    checkPlan(
        planner.acceptNullabilityOrNullCheckHint(
            typeName, getPostfixHint(intRef.token)),
        'int? x = 0;');
  }

  Future<void> test_acceptNullabilityOrNullCheckHint_inside_extract() async {
    var code = 'f(x) => 3 * x /*!*/ * 4;';
    await analyze(code);
    var xRef = findNode.simple('x /*');
    checkPlan(
        planner.extract(
            xRef.parent.parent,
            planner.acceptNullabilityOrNullCheckHint(
                planner.passThrough(xRef), getPostfixHint(xRef.token))),
        'f(x) => x!;');
  }

  Future<void> test_addBinaryPostfix_assignment_right_associative() async {
    await analyze('_f(a, b, c) => a = b;');
    // Admittedly this is sort of a bogus test case, since the code it produces
    // (`(a = b) = c`) is non-grammatical.  But we still want to verify that it
    // *doesn't* produce `a = b = c`, which would be grammatical but which would
    // break apart the subexpression `a = b`.
    checkPlan(
        planner.addBinaryPostfix(
            planner.passThrough(findNode.assignment('a = b')),
            TokenType.EQ,
            'c'),
        '_f(a, b, c) => (a = b) = c;');
  }

  Future<void> test_addBinaryPostfix_associative() async {
    await analyze('var x = 1 - 2;');
    checkPlan(
        planner.addBinaryPostfix(
            planner.passThrough(findNode.binary('-')), TokenType.MINUS, '3'),
        'var x = 1 - 2 - 3;');
  }

  Future<void> test_addBinaryPostfix_endsInCascade() async {
    await analyze('f(x) => x..y = 1;');
    checkPlan(
        planner.addBinaryPostfix(
            planner.passThrough(findNode.integerLiteral('1')),
            TokenType.PLUS,
            '2'),
        'f(x) => x..y = 1 + 2;');
  }

  Future<void> test_addBinaryPostfix_equality_non_associative() async {
    await analyze('var x = 1 == 2;');
    checkPlan(
        planner.addBinaryPostfix(
            planner.passThrough(findNode.binary('==')), TokenType.EQ_EQ, '3'),
        'var x = (1 == 2) == 3;');
  }

  Future<void> test_addBinaryPostfix_inner_precedence() async {
    await analyze('var x = 1 < 2;');
    checkPlan(
        planner.addBinaryPostfix(
            planner.passThrough(findNode.binary('<')), TokenType.EQ_EQ, 'true'),
        'var x = 1 < 2 == true;');
    checkPlan(
        planner.addBinaryPostfix(
            planner.passThrough(findNode.binary('<')), TokenType.AS, 'bool'),
        'var x = (1 < 2) as bool;');
  }

  Future<void> test_addBinaryPostfix_outer_precedence() async {
    await analyze('var x = 1 == true;');
    checkPlan(
        planner.addBinaryPostfix(
            planner.passThrough(findNode.integerLiteral('1')),
            TokenType.LT,
            '2'),
        'var x = 1 < 2 == true;');
    checkPlan(
        planner.addBinaryPostfix(
            planner.passThrough(findNode.integerLiteral('1')),
            TokenType.EQ_EQ,
            '2'),
        'var x = (1 == 2) == true;');
  }

  Future<void> test_addBinaryPostfix_to_expression_function() async {
    await analyze('var x = () => null;');
    checkPlan(
        planner.addBinaryPostfix(
            planner.passThrough(findNode.functionExpression('()')),
            TokenType.AS,
            'Object'),
        'var x = (() => null) as Object;');
  }

  Future<void> test_addBinaryPrefix_allowCascade() async {
    await analyze('f(x) => 1..isEven;');
    checkPlan(
        planner.addBinaryPrefix(
            'x..y', TokenType.EQ, planner.passThrough(findNode.cascade('..'))),
        'f(x) => x..y = (1..isEven);');
    checkPlan(
        planner.addBinaryPrefix(
            'x', TokenType.EQ, planner.passThrough(findNode.cascade('..')),
            allowCascade: true),
        'f(x) => x = 1..isEven;');
  }

  Future<void> test_addBinaryPrefix_assignment_right_associative() async {
    await analyze('_f(a, b, c) => b = c;');
    checkPlan(
        planner.addBinaryPrefix('a', TokenType.EQ,
            planner.passThrough(findNode.assignment('b = c'))),
        '_f(a, b, c) => a = b = c;');
  }

  Future<void> test_addBinaryPrefix_associative() async {
    await analyze('var x = 1 - 2;');
    checkPlan(
        planner.addBinaryPrefix(
            '0', TokenType.MINUS, planner.passThrough(findNode.binary('-'))),
        'var x = 0 - (1 - 2);');
  }

  Future<void> test_addBinaryPrefix_outer_precedence() async {
    await analyze('var x = 2 == true;');
    checkPlan(
        planner.addBinaryPrefix('1', TokenType.LT,
            planner.passThrough(findNode.integerLiteral('2'))),
        'var x = 1 < 2 == true;');
    checkPlan(
        planner.addBinaryPrefix('1', TokenType.EQ_EQ,
            planner.passThrough(findNode.integerLiteral('2'))),
        'var x = (1 == 2) == true;');
  }

  Future<void> test_addBinaryPrefix_to_expression_function() async {
    await analyze('f(x) => () => null;');
    checkPlan(
        planner.addBinaryPrefix('x', TokenType.EQ,
            planner.passThrough(findNode.functionExpression('()'))),
        'f(x) => x = () => null;');
  }

  Future<void> test_addCommentPostfix_before_closer() async {
    await analyze('f(g) => g(0);');
    checkPlan(
        planner.addCommentPostfix(
            planner.passThrough(findNode.integerLiteral('0')), '/* zero */'),
        'f(g) => g(0 /* zero */);');
  }

  Future<void> test_addCommentPostfix_before_other() async {
    await analyze('f() => 0.isEven;');
    checkPlan(
        planner.addCommentPostfix(
            planner.passThrough(findNode.integerLiteral('0')), '/* zero */'),
        'f() => 0 /* zero */ .isEven;');
  }

  Future<void> test_addCommentPostfix_before_semicolon() async {
    await analyze('f() => 0;');
    checkPlan(
        planner.addCommentPostfix(
            planner.passThrough(findNode.integerLiteral('0')), '/* zero */'),
        'f() => 0 /* zero */;');
  }

  Future<void> test_addCommentPostfix_before_space() async {
    await analyze('f() => 0 + 1;');
    checkPlan(
        planner.addCommentPostfix(
            planner.passThrough(findNode.integerLiteral('0')), '/* zero */'),
        'f() => 0 /* zero */ + 1;');
  }

  Future<void> test_addCommentPostfix_informative() async {
    await analyze('f() => 0.isEven;');
    checkPlan(
        planner.addCommentPostfix(
            planner.passThrough(findNode.integerLiteral('0')), '/* zero */',
            isInformative: true),
        'f() => 0.isEven;',
        expectedIncludingInformative: 'f() => 0 /* zero */ .isEven;');
  }

  Future<void> test_addUnaryPostfix_inner_precedence_add_parens() async {
    await analyze('f(x) => -x;');
    checkPlan(
        planner.addUnaryPostfix(
            planner.passThrough(findNode.prefix('-x')), TokenType.BANG),
        'f(x) => (-x)!;');
  }

  Future<void> test_addUnaryPostfix_inner_precedence_no_parens() async {
    await analyze('f(x) => x++;');
    checkPlan(
        planner.addUnaryPostfix(
            planner.passThrough(findNode.postfix('x++')), TokenType.BANG),
        'f(x) => x++!;');
  }

  Future<void> test_addUnaryPostfix_outer_precedence() async {
    await analyze('f(x) => x/*!*/;');
    checkPlan(
        planner.addUnaryPostfix(planner.passThrough(findNode.simple('x/*!*/')),
            TokenType.PLUS_PLUS),
        'f(x) => x++/*!*/;');
  }

  Future<void> test_addUnaryPrefix_inner_precedence_add_parens() async {
    await analyze('f(x, y) => x * y;');
    checkPlan(
        planner.addUnaryPrefix(
            TokenType.MINUS, planner.passThrough(findNode.binary('*'))),
        'f(x, y) => -(x * y);');
  }

  Future<void> test_addUnaryPrefix_inner_precedence_no_parens() async {
    await analyze('f(x) => -x;');
    // TODO(paulberry): if we added a `-` instead of a `~`, the result would
    // scan as a single `--` token, so we would need parens.  Add support for
    // this corner case.
    checkPlan(
        planner.addUnaryPrefix(
            TokenType.TILDE, planner.passThrough(findNode.prefix('-x'))),
        'f(x) => ~-x;');
  }

  Future<void> test_addUnaryPrefix_outer_precedence_add_parens() async {
    await analyze('f(x) => x!;');
    checkPlan(
        planner.addUnaryPrefix(
            TokenType.MINUS, planner.passThrough(findNode.simple('x!'))),
        'f(x) => (-x)!;');
  }

  Future<void> test_addUnaryPrefix_outer_precedence_no_parens() async {
    await analyze('f(x) => -x;');
    // TODO(paulberry): if we added a `-` instead of a `~`, the result would
    // scan as a single `--` token, so we would need parens.  Add support for
    // this corner case.
    checkPlan(
        planner.addUnaryPrefix(
            TokenType.TILDE, planner.passThrough(findNode.simple('x;'))),
        'f(x) => -~x;');
  }

  Future<void> test_cascadeSearchLimit() async {
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
    EditPlan makeInnerPlan() => planner.surround(planner.passThrough(one),
        suffix: [AtomicEdit.insert('..isEven')], endsInCascade: true);
    {
      // If we make a plan that passes through `c = 1`, containing a plan that
      // adds `..isEven` to `1`, then we don't necessarily want to add parens yet,
      // because we might not keep the cascade section above it.
      var plan =
          planner.passThrough(innerAssignment, innerPlans: [makeInnerPlan()]);
      // `endsInCascade` returns true because we haven't committed to adding
      // parens, so we need to remember that the presence of `..isEven` may
      // require parens later.
      expect(plan.endsInCascade, true);
      checkPlan(planner.extract(cascade, plan), 'f(a, c) => c = 1..isEven;');
    }
    {
      // If we make a plan that passes through `..b = c = 1`, containing a plan
      // that adds `..isEven` to `1`, then we do necessarily want to add parens,
      // because we're committed to keeping the cascade section.
      var plan =
          planner.passThrough(outerAssignment, innerPlans: [makeInnerPlan()]);
      // We can tell that the parens have been finalized because `endsInCascade`
      // returns false now.
      expect(plan.endsInCascade, false);
      checkPlan(plan, 'f(a, c) => a..b = (c = 1..isEven);');
    }
  }

  Future<void> test_dropNullabilityHint() async {
    var code = 'int /*!*/ x = 0;';
    await analyze(code);
    var intRef = findNode.simple('int');
    var typeName = planner.passThrough(intRef);
    checkPlan(
        planner.dropNullabilityHint(typeName, getPostfixHint(intRef.token)),
        'int x = 0;');
  }

  Future<void> test_dropNullabilityHint_space_before_must_be_kept() async {
    var code = 'int /*!*/x = 0;';
    await analyze(code);
    var intRef = findNode.simple('int');
    var typeName = planner.passThrough(intRef);
    var changes = checkPlan(
        planner.dropNullabilityHint(typeName, getPostfixHint(intRef.token)),
        'int x = 0;');
    expect(changes.keys, unorderedEquals([code.indexOf('/*')]));
  }

  Future<void> test_dropNullabilityHint_space_needed() async {
    var code = 'int/*!*/x = 0;';
    await analyze(code);
    var intRef = findNode.simple('int');
    var typeName = planner.passThrough(intRef);
    checkPlan(
        planner.dropNullabilityHint(typeName, getPostfixHint(intRef.token)),
        'int x = 0;');
  }

  Future<void> test_dropNullabilityHint_tight_no_space_needed() async {
    // We try to minimize how much we alter the source code, so we don't insert
    // a space in this example even though it would look prettier to do so.
    var code = 'void Function()/*!*/x = () {};';
    await analyze(code);
    var functionType = findNode.genericFunctionType('Function');
    var typeName = planner.passThrough(functionType);
    checkPlan(
        planner.dropNullabilityHint(
            typeName, getPostfixHint(functionType.endToken)),
        'void Function()x = () {};');
  }

  Future<void> test_explainNonNullable() async {
    await analyze('int x = 0;');
    checkPlan(
        planner.explainNonNullable(
            planner.passThrough(findNode.typeAnnotation('int'))),
        'int x = 0;',
        expectedIncludingInformative: 'int  x = 0;');
  }

  Future<void> test_extract_add_parens() async {
    await analyze('f(g) => 1 * g(2, 3 + 4, 5);');
    checkPlan(
        extract(
            findNode.binary('+'), findNode.functionExpressionInvocation('+')),
        'f(g) => 1 * (3 + 4);');
  }

  Future<void> test_extract_inner_endsInCascade() async {
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

  Future<void> test_extract_left() async {
    await analyze('var x = 1 + 2;');
    checkPlan(extract(findNode.integerLiteral('1'), findNode.binary('+')),
        'var x = 1;');
  }

  Future<void> test_extract_no_parens_needed() async {
    await analyze('var x = 1 + 2 * 3;');
    checkPlan(extract(findNode.integerLiteral('2'), findNode.binary('*')),
        'var x = 1 + 2;');
  }

  Future<void> test_extract_preserve_parens() async {
    // Note: extra spaces to verify that we are really preserving the parens
    // rather than removing them and adding new ones.
    await analyze('var x = ( 1 << 2 ) * 3 + 4;');
    checkPlan(extract(findNode.binary('<<'), findNode.binary('*')),
        'var x = ( 1 << 2 ) + 4;');
  }

  Future<void> test_extract_remove_parens() async {
    await analyze('var x = (1 + 2) * 3 << 4;');
    checkPlan(extract(findNode.binary('+'), findNode.binary('*')),
        'var x = 1 + 2 << 4;');
  }

  Future<void> test_extract_remove_redundant_parens() async {
    await analyze('var x = (1 * 2) + 3;');
    var times = findNode.binary('*');
    checkPlan(extract(times, times.parent), 'var x = 1 * 2 + 3;');
  }

  Future<void> test_extract_try_to_remove_necessary_parens() async {
    // This is a weird corner case.  We try to extract the expression `1 + 2`
    // from `( 1 + 2 )`, meaning we should remove parens.  But the parens are
    // necessary.  So we create fresh ones (without the spaces).
    await analyze('var x = ( 1 + 2 ) * 3;');
    var plus = findNode.binary('+');
    checkPlan(extract(plus, plus.parent), 'var x = (1 + 2) * 3;');
  }

  Future<void> test_extract_using_comments_inner() async {
    await analyze('var x = 1 + 2 * 3;');
    createPlanner(removeViaComments: true);
    checkPlan(extract(findNode.integerLiteral('2'), findNode.binary('+')),
        'var x = /* 1 + */ 2 /* * 3 */;');
  }

  Future<void> test_extract_using_comments_left() async {
    await analyze('var x = 1 + 2;');
    createPlanner(removeViaComments: true);
    checkPlan(extract(findNode.integerLiteral('1'), findNode.binary('+')),
        'var x = 1 /* + 2 */;');
  }

  Future<void> test_extract_using_comments_right() async {
    await analyze('var x = 1 + 2;');
    createPlanner(removeViaComments: true);
    checkPlan(extract(findNode.integerLiteral('2'), findNode.binary('+')),
        'var x = /* 1 + */ 2;');
  }

  Future<void> test_finalize_compilationUnit() async {
    // Verify that an edit plan referring to the entire compilation unit can be
    // finalized.  (This is an important corner case because the entire
    // compilation unit is an AstNode with no parent).
    await analyze('var x = 0;');
    checkPlan(
        planner.surround(planner.passThrough(testUnit),
            suffix: [AtomicEdit.insert(' var y = 0;')]),
        'var x = 0; var y = 0;');
  }

  Future<void> test_informativeMessageForToken() async {
    await analyze('f(x) => x + 1;');
    var sum = findNode.binary('+');
    var info = _MockInfo();
    var changes = checkPlan(
        planner.passThrough(sum, innerPlans: [
          planner.informativeMessageForToken(sum, sum.operator, info: info)
        ]),
        'f(x) => x + 1;',
        expectedIncludingInformative: 'f(x) => x  1;');
    var expectedOffset = sum.operator.offset;
    expect(changes.keys, unorderedEquals([expectedOffset]));
    expect(changes[expectedOffset], hasLength(1));
    expect(changes[expectedOffset][0].length, '+'.length);
    expect(changes[expectedOffset][0].replacement, '');
    expect(changes[expectedOffset][0].isInformative, isTrue);
    expect(changes[expectedOffset][0].info, same(info));
  }

  Future<void> test_insertText() async {
    await analyze('final x = 1;');
    var variableDeclarationList = findNode.variableDeclarationList('final');
    checkPlan(
        planner.insertText(
            variableDeclarationList,
            variableDeclarationList.variables.first.offset,
            [AtomicEdit.insert('int ')]),
        'final int x = 1;');
  }

  Future<void> test_makeNullable() async {
    await analyze('int x = 0;');
    checkPlan(
        planner
            .makeNullable(planner.passThrough(findNode.typeAnnotation('int'))),
        'int? x = 0;');
  }

  Future<void> test_passThrough_remove_statement() async {
    await analyze('''
void f() {
  var x = () {
    1;
    2;
    3;
  };
}
''');
    var innerPlan = planner.removeNode(findNode.statement('2'));
    var outerPlan = planner.passThrough(findNode.variableDeclaration('x'),
        innerPlans: [innerPlan]);
    checkPlan(outerPlan, '''
void f() {
  var x = () {
    1;
    3;
  };
}
''');
  }

  Future<void> test_remove_all_list_elements_with_trailing_separator() async {
    await analyze('var x = [ 1, 2, ];');
    var i1 = findNode.integerLiteral('1');
    var i2 = findNode.integerLiteral('2');
    checkPlan(
        planner.passThrough(i1.parent,
            innerPlans: [planner.removeNode(i1), planner.removeNode(i2)]),
        'var x = [];');
  }

  Future<void> test_remove_argument() async {
    await analyze('f(dynamic d) => d(1, 2, 3);');
    var i2 = findNode.integerLiteral('2');
    var changes = checkPlan(planner.removeNode(i2), 'f(dynamic d) => d(1, 3);');
    expect(changes.keys, [i2.offset]);
  }

  Future<void> test_remove_class_member() async {
    await analyze('''
class C {
  int? x;
  int? y;
  int? z;
}
''');
    var declaration = findNode.fieldDeclaration('y');
    var changes = checkPlan(planner.removeNode(declaration), '''
class C {
  int? x;
  int? z;
}
''');
    expect(changes.keys, [declaration.offset - 2]);
  }

  Future<void>
      test_remove_elements_of_related_lists_at_different_levels() async {
    await analyze('var x = [[1, 2], 3, 4];');
    var i2 = findNode.integerLiteral('2');
    var i3 = findNode.integerLiteral('3');
    checkPlan(
        planner.passThrough(testUnit,
            innerPlans: [planner.removeNode(i2), planner.removeNode(i3)]),
        'var x = [[1], 4];');
  }

  Future<void>
      test_remove_elements_of_sibling_lists_passThrough_container() async {
    await analyze('var x = [[1, 2], [3, 4]];');
    var i2 = findNode.integerLiteral('2');
    var i3 = findNode.integerLiteral('3');
    checkPlan(
        planner.passThrough(i2.parent.parent,
            innerPlans: [planner.removeNode(i2), planner.removeNode(i3)]),
        'var x = [[1], [4]];');
  }

  Future<void> test_remove_elements_of_sibling_lists_passThrough_unit() async {
    await analyze('var x = [[1, 2], [3, 4]];');
    var i2 = findNode.integerLiteral('2');
    var i3 = findNode.integerLiteral('3');
    checkPlan(
        planner.passThrough(testUnit,
            innerPlans: [planner.removeNode(i2), planner.removeNode(i3)]),
        'var x = [[1], [4]];');
  }

  Future<void> test_remove_enum_constant() async {
    await analyze('''
enum E {
  A,
  B,
  C
}
''');
    var enumConstant = findNode.simple('B').parent;
    var changes = checkPlan(planner.removeNode(enumConstant), '''
enum E {
  A,
  C
}
''');
    expect(changes.keys, [enumConstant.offset - 2]);
  }

  Future<void> test_remove_field_declaration() async {
    await analyze('''
class C {
  int? x, y, z;
}
''');
    var declaration = findNode.simple('y').parent;
    var changes = checkPlan(planner.removeNode(declaration), '''
class C {
  int? x, z;
}
''');
    expect(changes.keys, [declaration.offset]);
  }

  Future<void> test_remove_list_element() async {
    await analyze('var x = [1, 2, 3];');
    var i2 = findNode.integerLiteral('2');
    var changes = checkPlan(planner.removeNode(i2), 'var x = [1, 3];');
    expect(changes.keys, [i2.offset]);
  }

  Future<void> test_remove_list_element_at_list_end() async {
    await analyze('var x = [1, 2, 3];');
    var i2 = findNode.integerLiteral('2');
    var i3 = findNode.integerLiteral('3');
    var changes = checkPlan(planner.removeNode(i3), 'var x = [1, 2];');
    expect(changes.keys, [i2.end]);
  }

  Future<void> test_remove_list_element_singleton() async {
    await analyze('var x = [1];');
    var i1 = findNode.integerLiteral('1');
    checkPlan(planner.removeNode(i1), 'var x = [];');
  }

  Future<void> test_remove_list_element_with_trailing_separator() async {
    await analyze('var x = [1, 2, 3, ];');
    var i3 = findNode.integerLiteral('3');
    checkPlan(planner.removeNode(i3), 'var x = [1, 2, ];');
  }

  Future<void> test_remove_list_elements() async {
    await analyze('var x = [1, 2, 3, 4, 5];');
    var i2 = findNode.integerLiteral('2');
    var i4 = findNode.integerLiteral('4');
    var changes = checkPlan(
        planner.passThrough(i2.parent,
            innerPlans: [planner.removeNode(i2), planner.removeNode(i4)]),
        'var x = [1, 3, 5];');
    expect(changes.keys, unorderedEquals([i2.offset, i4.offset]));
  }

  Future<void> test_remove_list_elements_all() async {
    await analyze('var x = [1, 2];');
    var i1 = findNode.integerLiteral('1');
    var i2 = findNode.integerLiteral('2');
    checkPlan(
        planner.passThrough(i1.parent,
            innerPlans: [planner.removeNode(i1), planner.removeNode(i2)]),
        'var x = [];');
  }

  Future<void> test_remove_list_elements_all_asUnit() async {
    await analyze('var x = [1, 2];');
    var i1 = findNode.integerLiteral('1');
    var i2 = findNode.integerLiteral('2');
    checkPlan(planner.removeNodes(i1, i2), 'var x = [];');
  }

  Future<void> test_remove_list_elements_all_passThrough_unit() async {
    await analyze('var x = [1, 2];');
    var i1 = findNode.integerLiteral('1');
    var i2 = findNode.integerLiteral('2');
    checkPlan(
        planner.passThrough(testUnit,
            innerPlans: [planner.removeNode(i1), planner.removeNode(i2)]),
        'var x = [];');
  }

  Future<void> test_remove_list_elements_at_list_end() async {
    await analyze('var x = [1, 2, 3];');
    var i1 = findNode.integerLiteral('1');
    var i2 = findNode.integerLiteral('2');
    var i3 = findNode.integerLiteral('3');
    var changes = checkPlan(
        planner.passThrough(i2.parent,
            innerPlans: [planner.removeNode(i2), planner.removeNode(i3)]),
        'var x = [1];');
    expect(changes.keys, unorderedEquals([i1.end, i2.end]));
  }

  Future<void> test_remove_list_elements_at_list_end_asUnit() async {
    await analyze('var x = [1, 2, 3];');
    var i1 = findNode.integerLiteral('1');
    var i2 = findNode.integerLiteral('2');
    var i3 = findNode.integerLiteral('3');
    var changes = checkPlan(planner.removeNodes(i2, i3), 'var x = [1];');
    expect(changes.keys, [i1.end]);
  }

  Future<void> test_remove_list_elements_consecutive_asUnit() async {
    await analyze('var x = [1, 2, 3, 4];');
    var i2 = findNode.integerLiteral('2');
    var i3 = findNode.integerLiteral('3');
    var changes = checkPlan(planner.removeNodes(i2, i3), 'var x = [1, 4];');
    expect(changes.keys, [i2.offset]);
  }

  Future<void>
      test_remove_list_elements_consecutive_at_list_end_using_comments() async {
    await analyze('var x = [1, 2, 3];');
    var i2 = findNode.integerLiteral('2');
    var i3 = findNode.integerLiteral('3');
    createPlanner(removeViaComments: true);
    checkPlan(
        planner.passThrough(i2.parent,
            innerPlans: [planner.removeNode(i2), planner.removeNode(i3)]),
        'var x = [1/* , 2 *//* , 3 */];');
  }

  Future<void> test_remove_list_elements_consecutive_using_comments() async {
    await analyze('var x = [1, 2, 3, 4];');
    var i2 = findNode.integerLiteral('2');
    var i3 = findNode.integerLiteral('3');
    createPlanner(removeViaComments: true);
    checkPlan(
        planner.passThrough(i2.parent,
            innerPlans: [planner.removeNode(i2), planner.removeNode(i3)]),
        'var x = [1, /* 2, */ /* 3, */ 4];');
  }

  Future<void> test_remove_list_elements_using_comments() async {
    await analyze('var x = [1, 2, 3, 4, 5];');
    var i2 = findNode.integerLiteral('2');
    var i4 = findNode.integerLiteral('4');
    createPlanner(removeViaComments: true);
    checkPlan(
        planner.passThrough(i2.parent,
            innerPlans: [planner.removeNode(i2), planner.removeNode(i4)]),
        'var x = [1, /* 2, */ 3, /* 4, */ 5];');
  }

  Future<void> test_remove_map_element() async {
    await analyze('var x = {1: 2, 3: 4, 5: 6};');
    var entry = findNode.integerLiteral('3').parent;
    var changes = checkPlan(planner.removeNode(entry), 'var x = {1: 2, 5: 6};');
    expect(changes.keys, [entry.offset]);
  }

  Future<void> test_remove_parameter() async {
    await analyze('f(int x, int y, int z) => null;');
    var parameter = findNode.simple('y').parent;
    var changes =
        checkPlan(planner.removeNode(parameter), 'f(int x, int z) => null;');
    expect(changes.keys, [parameter.offset]);
  }

  Future<void> test_remove_set_element() async {
    await analyze('var x = {1, 2, 3};');
    var i2 = findNode.integerLiteral('2');
    var changes = checkPlan(planner.removeNode(i2), 'var x = {1, 3};');
    expect(changes.keys, [i2.offset]);
  }

  Future<void> test_remove_statement() async {
    await analyze('''
void f() {
  1;
  2;
  3;
}
''');
    checkPlan(planner.removeNode(findNode.statement('2')), '''
void f() {
  1;
  3;
}
''');
  }

  Future<void> test_remove_statement_first_of_many_on_line() async {
    await analyze('''
void f() {
  1;
  2; 3;
  4;
}
''');
    checkPlan(planner.removeNode(findNode.statement('2')), '''
void f() {
  1;
  3;
  4;
}
''');
  }

  Future<void> test_remove_statement_last_of_many_on_line() async {
    await analyze('''
void f() {
  1;
  2; 3;
  4;
}
''');
    checkPlan(planner.removeNode(findNode.statement('3')), '''
void f() {
  1;
  2;
  4;
}
''');
  }

  Future<void> test_remove_statement_middle_of_many_on_line() async {
    await analyze('''
void f() {
  1;
  2; 3; 4;
  5;
}
''');
    checkPlan(planner.removeNode(findNode.statement('3')), '''
void f() {
  1;
  2; 4;
  5;
}
''');
  }

  Future<void> test_remove_statement_using_comments() async {
    await analyze('''
void f() {
  1;
  2;
  3;
}
''');
    createPlanner(removeViaComments: true);
    checkPlan(planner.removeNode(findNode.statement('2')), '''
void f() {
  1;
  /* 2; */
  3;
}
''');
  }

  Future<void> test_remove_statements_asUnit() async {
    await analyze('''
void f() {
  1;
  2;

  3;
  4;
}
''');
    var s2 = findNode.statement('2');
    var s3 = findNode.statement('3');
    var changes = checkPlan(planner.removeNodes(s2, s3), '''
void f() {
  1;
  4;
}
''');
    expect(changes, hasLength(1));
  }

  Future<void> test_remove_statements_consecutive_three() async {
    await analyze('''
void f() {
  1;
  2;

  3;

  4;
  5;
}
''');
    var s2 = findNode.statement('2');
    var s3 = findNode.statement('3');
    var s4 = findNode.statement('4');
    var changes = checkPlan(
        planner.passThrough(s2.parent, innerPlans: [
          planner.removeNode(s2),
          planner.removeNode(s3),
          planner.removeNode(s4)
        ]),
        '''
void f() {
  1;
  5;
}
''');
    expect(changes.keys,
        unorderedEquals([s2.offset - 2, s3.offset - 2, s4.offset - 2]));
  }

  Future<void> test_remove_statements_consecutive_two() async {
    await analyze('''
void f() {
  1;
  2;

  3;
  4;
}
''');
    var s2 = findNode.statement('2');
    var s3 = findNode.statement('3');
    var changes = checkPlan(
        planner.passThrough(s2.parent,
            innerPlans: [planner.removeNode(s2), planner.removeNode(s3)]),
        '''
void f() {
  1;
  4;
}
''');
    expect(changes.keys, unorderedEquals([s2.offset - 2, s3.offset - 2]));
  }

  Future<void> test_remove_statements_nonconsecutive() async {
    await analyze('''
void f() {
  1;
  2;
  3;
  4;
  5;
}
''');
    var s2 = findNode.statement('2');
    var s4 = findNode.statement('4');
    var changes = checkPlan(
        planner.passThrough(s2.parent,
            innerPlans: [planner.removeNode(s2), planner.removeNode(s4)]),
        '''
void f() {
  1;
  3;
  5;
}
''');
    expect(changes, hasLength(2));
  }

  Future<void> test_remove_statements_singleton() async {
    await analyze('''
void f() {
  1;
}
''');
    checkPlan(planner.removeNode(findNode.statement('1')), '''
void f() {}
''');
  }

  Future<void> test_remove_statements_singleton_with_following_comment() async {
    await analyze('''
void f() {
  1;
  // Foo
}
''');
    checkPlan(planner.removeNode(findNode.statement('1')), '''
void f() {
  // Foo
}
''');
  }

  Future<void> test_remove_statements_singleton_with_preceding_comment() async {
    await analyze('''
void f() {
  // Foo
  1;
}
''');
    checkPlan(planner.removeNode(findNode.statement('1')), '''
void f() {
  // Foo
}
''');
  }

  Future<void> test_remove_statements_using_comments() async {
    await analyze('''
void f() {
  1;
  2;
  3;
  4;
}
''');
    createPlanner(removeViaComments: true);
    var s2 = findNode.statement('2');
    var s3 = findNode.statement('3');
    checkPlan(
        planner.passThrough(s2.parent,
            innerPlans: [planner.removeNode(s2), planner.removeNode(s3)]),
        '''
void f() {
  1;
  /* 2; */
  /* 3; */
  4;
}
''');
  }

  Future<void> test_remove_top_level_declaration() async {
    await analyze('''
class C {}
class D {}
class E {}
''');
    var declaration = findNode.classDeclaration('D');
    var changes = checkPlan(planner.removeNode(declaration), '''
class C {}
class E {}
''');
    expect(changes.keys, [declaration.offset]);
  }

  Future<void> test_remove_top_level_directive() async {
    await analyze('''
import 'dart:io';
import 'dart:async';
import 'dart:math';
''');
    var directive = findNode.import('async');
    var changes = checkPlan(planner.removeNode(directive), '''
import 'dart:io';
import 'dart:math';
''');
    expect(changes.keys, [directive.offset]);
  }

  Future<void> test_remove_type_argument() async {
    await analyze('''
class C<T, U, V> {}
C<int, double, String>? c;
''');
    var typeArgument = findNode.simple('double').parent;
    var changes = checkPlan(planner.removeNode(typeArgument), '''
class C<T, U, V> {}
C<int, String>? c;
''');
    expect(changes.keys, [typeArgument.offset]);
  }

  Future<void> test_remove_type_parameter() async {
    await analyze('class C<T, U, V> {}');
    var parameter = findNode.simple('U').parent;
    var changes = checkPlan(planner.removeNode(parameter), 'class C<T, V> {}');
    expect(changes.keys, [parameter.offset]);
  }

  Future<void> test_remove_variable_declaration() async {
    await analyze('int? x, y, z;');
    var declaration = findNode.simple('y').parent;
    var changes = checkPlan(planner.removeNode(declaration), 'int? x, z;');
    expect(changes.keys, [declaration.offset]);
  }

  Future<void>
      test_removeNullAwarenessFromMethodInvocation_change_arguments() async {
    await analyze('f(x) => x?.m(0);');
    var methodInvocation = findNode.methodInvocation('?.');
    checkPlan(
        planner.passThrough(methodInvocation, innerPlans: [
          planner.removeNullAwareness(methodInvocation),
          planner.passThrough(methodInvocation.argumentList, innerPlans: [
            planner
                .replace(findNode.integerLiteral('0'), [AtomicEdit.insert('1')])
          ])
        ]),
        'f(x) => x.m(1);');
  }

  Future<void>
      test_removeNullAwarenessFromMethodInvocation_change_methodName() async {
    await analyze('f(x) => x?.m();');
    var methodInvocation = findNode.methodInvocation('?.');
    checkPlan(
        planner.passThrough(methodInvocation, innerPlans: [
          planner.removeNullAwareness(methodInvocation),
          planner.replace(findNode.simple('m'), [AtomicEdit.insert('n')])
        ]),
        'f(x) => x.n();');
  }

  Future<void>
      test_removeNullAwarenessFromMethodInvocation_change_target() async {
    await analyze('f(x) => x?.m();');
    var methodInvocation = findNode.methodInvocation('?.');
    checkPlan(
        planner.passThrough(methodInvocation, innerPlans: [
          planner.replace(findNode.simple('x?.'), [AtomicEdit.insert('y')]),
          planner.removeNullAwareness(methodInvocation)
        ]),
        'f(x) => y.m();');
  }

  Future<void>
      test_removeNullAwarenessFromMethodInvocation_change_typeArguments() async {
    await analyze('f(x) => x?.m<int>();');
    var methodInvocation = findNode.methodInvocation('?.');
    checkPlan(
        planner.passThrough(methodInvocation, innerPlans: [
          planner.removeNullAwareness(methodInvocation),
          planner.passThrough(methodInvocation.typeArguments, innerPlans: [
            planner.replace(findNode.simple('int'), [AtomicEdit.insert('num')])
          ])
        ]),
        'f(x) => x.m<num>();');
  }

  Future<void> test_removeNullAwarenessFromMethodInvocation_simple() async {
    await analyze('f(x) => x?.m();');
    var methodInvocation = findNode.methodInvocation('?.');
    checkPlan(
        planner.passThrough(methodInvocation,
            innerPlans: [planner.removeNullAwareness(methodInvocation)]),
        'f(x) => x.m();');
  }

  Future<void> test_removeNullAwarenessFromPropertyAccess_change_both() async {
    await analyze('f(x) => x?.y;');
    var propertyAccess = findNode.propertyAccess('?.');
    checkPlan(
        planner.passThrough(propertyAccess, innerPlans: [
          (planner.replace(findNode.simple('x?.'), [AtomicEdit.insert('z')])),
          planner.removeNullAwareness(propertyAccess),
          planner.replace(findNode.simple('y'), [AtomicEdit.insert('w')])
        ]),
        'f(x) => z.w;');
  }

  Future<void>
      test_removeNullAwarenessFromPropertyAccess_change_propertyName() async {
    await analyze('f(x) => x?.y;');
    var propertyAccess = findNode.propertyAccess('?.');
    checkPlan(
        planner.passThrough(propertyAccess, innerPlans: [
          planner.removeNullAwareness(propertyAccess),
          planner.replace(findNode.simple('y'), [AtomicEdit.insert('w')])
        ]),
        'f(x) => x.w;');
  }

  Future<void>
      test_removeNullAwarenessFromPropertyAccess_change_target() async {
    await analyze('f(x) => x?.y;');
    var propertyAccess = findNode.propertyAccess('?.');
    checkPlan(
        planner.passThrough(propertyAccess, innerPlans: [
          planner.replace(findNode.simple('x?.'), [AtomicEdit.insert('z')]),
          planner.removeNullAwareness(propertyAccess)
        ]),
        'f(x) => z.y;');
  }

  Future<void> test_removeNullAwarenessFromPropertyAccess_simple() async {
    await analyze('f(x) => x?.y;');
    var propertyAccess = findNode.propertyAccess('?.');
    checkPlan(
        planner.passThrough(propertyAccess,
            innerPlans: [planner.removeNullAwareness(propertyAccess)]),
        'f(x) => x.y;');
  }

  Future<void> test_replace_expression() async {
    await analyze('var x = 1 + 2 * 3;');
    checkPlan(planner.replace(findNode.binary('*'), [AtomicEdit.insert('6')]),
        'var x = 1 + 6;');
  }

  Future<void> test_replace_expression_add_parens_due_to_cascade() async {
    await analyze('var x = 1 + 2 * 3;');
    checkPlan(
        planner.replace(findNode.binary('*'), [AtomicEdit.insert('4..isEven')],
            endsInCascade: true),
        'var x = 1 + (4..isEven);');
  }

  Future<void> test_replace_expression_add_parens_due_to_precedence() async {
    await analyze('var x = 1 + 2 * 3;');
    checkPlan(
        planner.replace(findNode.binary('*'), [AtomicEdit.insert('y = z')],
            precedence: Precedence.assignment),
        'var x = 1 + (y = z);');
  }

  Future<void> test_replaceToken() async {
    await analyze('var x = 1;');
    var variableDeclarationList = findNode.variableDeclarationList('var x');
    checkPlan(
        planner.replaceToken(
            variableDeclarationList, variableDeclarationList.keyword, 'int'),
        'int x = 1;');
  }

  Future<void> test_surround_allowCascade() async {
    await analyze('f(x) => 1..isEven;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.cascade('..')),
            prefix: [AtomicEdit.insert('x..y = ')]),
        'f(x) => x..y = (1..isEven);');
    checkPlan(
        planner.surround(planner.passThrough(findNode.cascade('..')),
            prefix: [AtomicEdit.insert('x = ')], allowCascade: true),
        'f(x) => x = 1..isEven;');
  }

  Future<void> test_surround_associative() async {
    await analyze('var x = 1 - 2;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.binary('-')),
            suffix: [AtomicEdit.insert(' - 3')],
            innerPrecedence: Precedence.additive,
            associative: true),
        'var x = 1 - 2 - 3;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.binary('-')),
            prefix: [AtomicEdit.insert('0 - ')],
            innerPrecedence: Precedence.additive),
        'var x = 0 - (1 - 2);');
  }

  Future<void> test_surround_endsInCascade() async {
    await analyze('f(x) => x..y = 1;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.integerLiteral('1')),
            suffix: [AtomicEdit.insert(' + 2')]),
        'f(x) => x..y = 1 + 2;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.integerLiteral('1')),
            suffix: [AtomicEdit.insert('..isEven')], endsInCascade: true),
        'f(x) => x..y = (1..isEven);');
  }

  Future<void>
      test_surround_endsInCascade_does_not_propagate_through_added_parens() async {
    await analyze('f(a) => a..b = 0;');
    checkPlan(
        planner.surround(
            planner.surround(planner.passThrough(findNode.cascade('..')),
                prefix: [AtomicEdit.insert('1 + ')],
                innerPrecedence: Precedence.additive),
            prefix: [AtomicEdit.insert('true ? ')],
            suffix: [AtomicEdit.insert(' : 2')]),
        'f(a) => true ? 1 + (a..b = 0) : 2;');
    checkPlan(
        planner.surround(
            planner.surround(planner.passThrough(findNode.cascade('..')),
                prefix: [AtomicEdit.insert('throw ')], allowCascade: true),
            prefix: [AtomicEdit.insert('true ? ')],
            suffix: [AtomicEdit.insert(' : 2')]),
        'f(a) => true ? (throw a..b = 0) : 2;');
  }

  Future<void> test_surround_endsInCascade_internal_throw() async {
    await analyze('f(x, g) => g(0, throw x, 1);');
    checkPlan(
        planner.surround(planner.passThrough(findNode.simple('x, 1')),
            suffix: [AtomicEdit.insert('..y')], endsInCascade: true),
        'f(x, g) => g(0, throw x..y, 1);');
  }

  Future<void> test_surround_endsInCascade_propagates() async {
    await analyze('f(a) => a..b = 0;');
    checkPlan(
        planner.surround(
            planner.surround(planner.passThrough(findNode.cascade('..')),
                prefix: [AtomicEdit.insert('throw ')], allowCascade: true),
            prefix: [AtomicEdit.insert('true ? ')],
            suffix: [AtomicEdit.insert(' : 2')]),
        'f(a) => true ? (throw a..b = 0) : 2;');
    checkPlan(
        planner.surround(
            planner.surround(planner.passThrough(findNode.integerLiteral('0')),
                prefix: [AtomicEdit.insert('throw ')], allowCascade: true),
            prefix: [AtomicEdit.insert('true ? ')],
            suffix: [AtomicEdit.insert(' : 2')]),
        'f(a) => a..b = true ? throw 0 : 2;');
  }

  Future<void> test_surround_precedence() async {
    await analyze('var x = 1 == true;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.integerLiteral('1')),
            suffix: [AtomicEdit.insert(' < 2')],
            outerPrecedence: Precedence.relational),
        'var x = 1 < 2 == true;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.integerLiteral('1')),
            suffix: [AtomicEdit.insert(' == 2')],
            outerPrecedence: Precedence.equality),
        'var x = (1 == 2) == true;');
  }

  Future<void> test_surround_prefix() async {
    await analyze('var x = 1;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.integerLiteral('1')),
            prefix: [AtomicEdit.insert('throw ')]),
        'var x = throw 1;');
  }

  Future<void> test_surround_suffix() async {
    await analyze('var x = 1;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.integerLiteral('1')),
            suffix: [AtomicEdit.insert('..isEven')]),
        'var x = 1..isEven;');
  }

  Future<void> test_surround_suffix_parenthesized() async {
    await analyze('var x = (1);');
    checkPlan(
        planner.surround(planner.passThrough(findNode.integerLiteral('1')),
            suffix: [AtomicEdit.insert('..isEven')]),
        'var x = 1..isEven;');
  }

  Future<void> test_surround_suffix_parenthesized_passThrough_unit() async {
    await analyze('var x = (1);');
    checkPlan(
        planner.passThrough(testUnit, innerPlans: [
          planner.surround(planner.passThrough(findNode.integerLiteral('1')),
              suffix: [AtomicEdit.insert('..isEven')])
        ]),
        'var x = 1..isEven;');
  }

  Future<void> test_surround_threshold() async {
    await analyze('var x = 1 < 2;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.binary('<')),
            suffix: [AtomicEdit.insert(' == true')],
            innerPrecedence: Precedence.equality),
        'var x = 1 < 2 == true;');
    checkPlan(
        planner.surround(planner.passThrough(findNode.binary('<')),
            suffix: [AtomicEdit.insert(' as bool')],
            innerPrecedence: Precedence.relational),
        'var x = (1 < 2) as bool;');
  }
}

@reflectiveTest
class EndsInCascadeTest extends AbstractSingleUnitTest {
  Future<void> test_ignore_subexpression_not_at_end() async {
    await resolveTestUnit('f(g) => g(0..isEven, 1);');
    expect(findNode.functionExpressionInvocation('g(').endsInCascade, false);
    expect(findNode.cascade('..').endsInCascade, true);
  }

  Future<void> test_no_cascade() async {
    await resolveTestUnit('var x = 0;');
    expect(findNode.integerLiteral('0').endsInCascade, false);
  }

  Future<void> test_stop_searching_when_parens_encountered() async {
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
/// recursively visit the AST of each snippet and use [EditPlanner.passThrough]
/// to create an edit plan based on each AST node.  Then we use
/// [EditPlanner.parensNeededFromContext] to check whether parentheses are
/// needed around each node, and assert that the result agrees with the set of
/// parentheses that are actually present.
@reflectiveTest
class PrecedenceTest extends AbstractSingleUnitTest {
  Future<void> checkPrecedence(String content) async {
    await resolveTestUnit(content);
    testUnit.accept(_PrecedenceChecker(testUnit.lineInfo, testCode));
  }

  Future<void> test_precedence_as() async {
    await checkPrecedence('''
f(a) => (a as num) as int;
g(a, b) => a | b as int;
''');
  }

  Future<void> test_precedence_assignment() async {
    await checkPrecedence('f(a, b, c) => a = b = c;');
  }

  Future<void> test_precedence_assignment_in_cascade_with_parens() async {
    await checkPrecedence('f(a, c, e) => a..b = (c..d = e);');
  }

  Future<void> test_precedence_await() async {
    await checkPrecedence('''
f(a) async => await -a;
g(a, b) async => await (a*b);
    ''');
  }

  Future<void> test_precedence_binary_equality() async {
    await checkPrecedence('''
f(a, b, c) => (a == b) == c;
g(a, b, c) => a == (b == c);
''');
  }

  Future<void> test_precedence_binary_left_associative() async {
    // Associativity logic is the same for all operators except relational and
    // equality, so we just test `+` as a stand-in for all the others.
    await checkPrecedence('''
f(a, b, c) => a + b + c;
g(a, b, c) => a + (b + c);
''');
  }

  Future<void> test_precedence_binary_relational() async {
    await checkPrecedence('''
f(a, b, c) => (a < b) < c;
g(a, b, c) => a < (b < c);
''');
  }

  Future<void> test_precedence_conditional() async {
    await checkPrecedence('''
g(a, b, c, d, e, f) => a ?? b ? c = d : e = f;
h(a, b, c, d, e) => (a ? b : c) ? d : e;
''');
  }

  Future<void> test_precedence_extension_override() async {
    await checkPrecedence('''
extension E on Object {
  void f() {}
}
void g(x) => E(x).f();
''');
  }

  Future<void> test_precedence_functionExpression_ifNotNull() async {
    await checkPrecedence('f(b, c) => ((a) => b) ?? c;');
  }

  Future<void> test_precedence_functionExpressionInvocation() async {
    await checkPrecedence('''
f(g) => g[0](1);
h(x) => (x + 2)(3);
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/40536')
  Future<void> test_precedence_ifNotNull_functionExpression() async {
    await checkPrecedence('f(a, c) => a ?? (b) => c;');
  }

  Future<void> test_precedence_is() async {
    await checkPrecedence('''
f(a) => (a as num) is int;
g(a, b) => a | b is int;
''');
  }

  Future<void> test_precedence_postfix_and_index() async {
    await checkPrecedence('''
f(a, b, c) => a[b][c];
g(a, b) => a[b]++;
h(a, b) => (-a)[b];
''');
  }

  Future<void> test_precedence_prefix() async {
    await checkPrecedence('''
f(a) => ~-a;
g(a, b) => -(a*b);
''');
  }

  Future<void> test_precedence_prefixedIdentifier() async {
    await checkPrecedence('f(a) => a.b;');
  }

  Future<void> test_precedence_propertyAccess() async {
    await checkPrecedence('''
f(a) => a?.b?.c;
g(a) => (-a)?.b;
''');
  }

  Future<void> test_precedence_throw() async {
    await checkPrecedence('''
f(a, b) => throw a = b;
g(a, c) => a..b = throw (c..d);
''');
  }

  Future<void> test_precedenceChecker_detects_unnecessary_paren() async {
    await resolveTestUnit('var x = (1);');
    expect(
        () => testUnit.accept(_PrecedenceChecker(testUnit.lineInfo, testCode)),
        throwsA(TypeMatcher<TestFailure>()));
  }
}

class _MockInfo implements AtomicEditInfo {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PrecedenceChecker extends UnifyingAstVisitor<void> {
  final EditPlanner planner;

  _PrecedenceChecker(LineInfo lineInfo, String sourceText)
      : planner = EditPlanner(lineInfo, sourceText);

  @override
  void visitNode(AstNode node) {
    expect(planner.passThrough(node).parensNeededFromContext(null), false);
    node.visitChildren(this);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    expect(planner.passThrough(node).parensNeededFromContext(null), true);
    node.expression.visitChildren(this);
  }
}
