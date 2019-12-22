// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/fix_aggregator.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixAggregatorTest);
  });
}

@reflectiveTest
class FixAggregatorTest extends FixAggregatorTestBase {
  void test_adjacentFixes() async {
    await analyze('f(a, b) => a + b;');
    var aRef = findNode.simple('a +');
    var bRef = findNode.simple('b;');
    var previewInfo = run({
      aRef: const NullCheck(),
      bRef: const NullCheck(),
      findNode.binary('a + b'): const NullCheck()
    });
    expect(previewInfo.applyTo(code), 'f(a, b) => (a! + b!)!;');
  }

  void test_introduceAs_distant_parens_no_longer_needed() async {
    // Note: in principle it would be nice to delete the outer parens, but it's
    // difficult to see that they used to be necessary and aren't anymore, so we
    // leave them.
    await analyze('f(a, c) => a..b = (throw c..d);');
    var cd = findNode.cascade('c..d');
    var previewInfo = run({cd: const IntroduceAs('int')});
    expect(
        previewInfo.applyTo(code), 'f(a, c) => a..b = (throw (c..d) as int);');
  }

  void test_introduceAs_no_parens() async {
    await analyze('f(a, b) => a | b;');
    var expr = findNode.binary('a | b');
    var previewInfo = run({expr: const IntroduceAs('int')});
    expect(previewInfo.applyTo(code), 'f(a, b) => a | b as int;');
  }

  void test_introduceAs_parens() async {
    await analyze('f(a, b) => a < b;');
    var expr = findNode.binary('a < b');
    var previewInfo = run({expr: const IntroduceAs('bool')});
    expect(previewInfo.applyTo(code), 'f(a, b) => (a < b) as bool;');
  }

  void test_keep_redundant_parens() async {
    await analyze('f(a, b, c) => a + (b * c);');
    var previewInfo = run({});
    expect(previewInfo, isEmpty);
  }

  void test_makeNullable() async {
    await analyze('f(int x) {}');
    var typeName = findNode.typeName('int');
    var previewInfo = run({typeName: const MakeNullable()});
    expect(previewInfo.applyTo(code), 'f(int? x) {}');
  }

  void test_nullCheck_no_parens() async {
    await analyze('f(a) => a++;');
    var expr = findNode.postfix('a++');
    var previewInfo = run({expr: const NullCheck()});
    expect(previewInfo.applyTo(code), 'f(a) => a++!;');
  }

  void test_nullCheck_parens() async {
    await analyze('f(a) => -a;');
    var expr = findNode.prefix('-a');
    var previewInfo = run({expr: const NullCheck()});
    expect(previewInfo.applyTo(code), 'f(a) => (-a)!;');
  }

  void test_removeAs_in_cascade_target_no_parens_needed_cascade() async {
    await analyze('f(a) => ((a..b) as dynamic)..c;');
    var cascade = findNode.cascade('a..b');
    var cast = cascade.parent.parent;
    var previewInfo = run({cast: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a) => a..b..c;');
  }

  void test_removeAs_in_cascade_target_no_parens_needed_conditional() async {
    // TODO(paulberry): would it be better to keep the parens in this case for
    // clarity, even though they're not needed?
    await analyze('f(a, b, c) => ((a ? b : c) as dynamic)..d;');
    var conditional = findNode.conditionalExpression('a ? b : c');
    var cast = conditional.parent.parent;
    var previewInfo = run({cast: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a ? b : c..d;');
  }

  void test_removeAs_in_cascade_target_parens_needed_assignment() async {
    await analyze('f(a, b) => ((a = b) as dynamic)..c;');
    var assignment = findNode.assignment('a = b');
    var cast = assignment.parent.parent;
    var previewInfo = run({cast: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, b) => (a = b)..c;');
  }

  void test_removeAs_in_cascade_target_parens_needed_throw() async {
    await analyze('f(a) => ((throw a) as dynamic)..b;');
    var throw_ = findNode.throw_('throw a');
    var cast = throw_.parent.parent;
    var previewInfo = run({cast: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a) => (throw a)..b;');
  }

  void test_removeAs_lower_precedence_do_not_remove_inner_parens() async {
    await analyze('f(a, b, c) => (a == b) as Null == c;');
    var expr = findNode.binary('a == b');
    var previewInfo = run({expr.parent.parent: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => (a == b) == c;');
  }

  void test_removeAs_lower_precedence_remove_inner_parens() async {
    await analyze('f(a, b) => (a == b) as Null;');
    var expr = findNode.binary('a == b');
    var previewInfo = run({expr.parent.parent: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, b) => a == b;');
  }

  void test_removeAs_parens_needed_due_to_cascade() async {
    // Note: spaces around parens to verify that we don't remove the old parens
    // and create new ones.
    await analyze('f(a, c) => a..b = throw ( c..d ) as int;');
    var cd = findNode.cascade('c..d');
    var cast = cd.parent.parent;
    var previewInfo = run({cast: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, c) => a..b = throw ( c..d );');
  }

  void test_removeAs_parens_needed_due_to_cascade_in_conditional_else() async {
    await analyze('f(a, b, c) => a ? b : (c..d) as int;');
    var cd = findNode.cascade('c..d');
    var cast = cd.parent.parent;
    var previewInfo = run({cast: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a ? b : (c..d);');
  }

  void test_removeAs_parens_needed_due_to_cascade_in_conditional_then() async {
    await analyze('f(a, b, d) => a ? (b..c) as int : d;');
    var bc = findNode.cascade('b..c');
    var cast = bc.parent.parent;
    var previewInfo = run({cast: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, b, d) => a ? (b..c) : d;');
  }

  void test_removeAs_raise_precedence_do_not_remove_parens() async {
    await analyze('f(a, b, c) => a | (b | c as int);');
    var expr = findNode.binary('b | c');
    var previewInfo = run({expr.parent: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a | (b | c);');
  }

  void test_removeAs_raise_precedence_no_parens_to_remove() async {
    await analyze('f(a, b, c) => a = b | c as int;');
    var expr = findNode.binary('b | c');
    var previewInfo = run({expr.parent: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a = b | c;');
  }

  void test_removeAs_raise_precedence_remove_parens() async {
    await analyze('f(a, b, c) => a < (b | c as int);');
    var expr = findNode.binary('b | c');
    var previewInfo = run({expr.parent: const RemoveAs()});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a < b | c;');
  }
}

class FixAggregatorTestBase extends AbstractSingleUnitTest {
  String code;

  Future<void> analyze(String code) async {
    this.code = code;
    await resolveTestUnit(code);
  }

  Map<int, List<AtomicEdit>> run(Map<AstNode, NodeChange> changes) {
    return FixAggregator.run(testUnit, changes);
  }
}
