// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PassThroughMergingTest);
  });
}

/// Tests to make sure the algorithm used by [EditPlaner.passThrough] is
/// correct.
@reflectiveTest
class PassThroughMergingTest extends AbstractSingleUnitTest {
  Future<void> test_creates_pass_through_plans_stepwise() async {
    await resolveTestUnit('var x = [[[1]]];');
    var plan = _EditPlannerForTesting(testCode).passThrough(
        findNode.listLiteral('[[['),
        innerPlans: [_MockPlan(findNode.integerLiteral('1'))]);
    expect(plan.toString(),
        'plan([[[1]]], [plan([[1]], [plan([1], [plan(1)])])])');
  }

  Future<void> test_merge_plans_at_lower_level() async {
    await resolveTestUnit('var x = [[1, 2]];');
    var plan = _EditPlannerForTesting(testCode)
        .passThrough(findNode.listLiteral('[['), innerPlans: [
      _MockPlan(findNode.integerLiteral('1')),
      _MockPlan(findNode.integerLiteral('2'))
    ]);
    expect(
        plan.toString(), 'plan([[1, 2]], [plan([1, 2], [plan(1), plan(2)])])');
  }

  Future<void> test_merge_plans_at_top_level() async {
    await resolveTestUnit('var x = [[1], [2]];');
    var plan = _EditPlannerForTesting(testCode)
        .passThrough(findNode.listLiteral('[['), innerPlans: [
      _MockPlan(findNode.integerLiteral('1')),
      _MockPlan(findNode.integerLiteral('2'))
    ]);
    expect(plan.toString(),
        'plan([[1], [2]], [plan([1], [plan(1)]), plan([2], [plan(2)])])');
  }

  Future<void> test_merge_plans_at_varying_levels() async {
    await resolveTestUnit('var x = [1, [2, 3], 4];');
    var plan = _EditPlannerForTesting(testCode)
        .passThrough(findNode.listLiteral('[1'), innerPlans: [
      _MockPlan(findNode.integerLiteral('1')),
      _MockPlan(findNode.integerLiteral('2')),
      _MockPlan(findNode.integerLiteral('3')),
      _MockPlan(findNode.integerLiteral('4'))
    ]);
    expect(
        plan.toString(),
        'plan([1, [2, 3], 4], [plan(1), plan([2, 3], [plan(2), plan(3)]), '
        'plan(4)])');
  }
}

class _EditPlannerForTesting extends EditPlanner {
  _EditPlannerForTesting(String content)
      : super(LineInfo.fromContent(content), content);

  @override
  PassThroughBuilder createPassThroughBuilder(AstNode node) =>
      _MockPassThroughBuilder(node);
}

class _MockPassThroughBuilder implements PassThroughBuilder {
  final List<EditPlan> _innerPlans = [];

  @override
  final AstNode node;

  _MockPassThroughBuilder(this.node);

  @override
  void add(EditPlan innerPlan) {
    _innerPlans.add(innerPlan);
  }

  @override
  NodeProducingEditPlan finish(EditPlanner planner) {
    return _MockPlan(node, _innerPlans);
  }
}

class _MockPlan implements NodeProducingEditPlan {
  final AstNode _node;

  final List<EditPlan> _innerPlans;

  _MockPlan(this._node, [List<EditPlan> innerPlans = const []])
      : _innerPlans = innerPlans;

  @override
  AstNode get parentNode => _node.parent;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() =>
      _innerPlans.isEmpty ? 'plan($_node)' : 'plan($_node, $_innerPlans)';
}
