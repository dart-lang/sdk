// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_context.dart';
import 'api_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_InstrumentationTest);
  });
}

class _InstrumentationClient implements NullabilityMigrationInstrumentation {
  final _InstrumentationTestBase test;

  _InstrumentationClient(this.test);

  @override
  void changes(Source source, Map<int, List<AtomicEdit>> changes) {
    expect(test.changes, isNull);
    test.changes = {
      for (var entry in changes.entries)
        if (entry.value.any((edit) => !edit.isInformative))
          entry.key: entry.value
    };
  }

  @override
  void explicitTypeNullability(
      Source source, TypeAnnotation typeAnnotation, NullabilityNodeInfo node) {
    expect(source, test.source);
    expect(test.explicitTypeNullability, isNot(contains(typeAnnotation)));
    test.explicitTypeNullability[typeAnnotation] = node;
  }

  @override
  void externalDecoratedType(Element element, DecoratedTypeInfo decoratedType) {
    expect(test.externalDecoratedType, isNot(contains(element)));
    test.externalDecoratedType[element] = decoratedType;
  }

  @override
  void externalDecoratedTypeParameterBound(
      TypeParameterElement typeParameter, DecoratedTypeInfo decoratedType) {
    expect(test.externalDecoratedTypeParameterBound,
        isNot(contains(typeParameter)));
    test.externalDecoratedTypeParameterBound[typeParameter] = decoratedType;
  }

  @override
  void finished() {}

  @override
  void graphEdge(EdgeInfo edge, EdgeOriginInfo originInfo) {
    if (edge.destinationNode != test.always) {
      expect(test.edgeOrigin, isNot(contains(edge)));
      test.edges.add(edge);
      test.edgeOrigin[edge] = originInfo;
    }
  }

  @override
  void immutableNodes(NullabilityNodeInfo never, NullabilityNodeInfo always) {
    test.never = never;
    test.always = always;
  }

  @override
  void implicitReturnType(
      Source source, AstNode node, DecoratedTypeInfo decoratedReturnType) {
    expect(source, test.source);
    expect(test.implicitReturnType, isNot(contains(node)));
    test.implicitReturnType[node] = decoratedReturnType;
  }

  @override
  void implicitType(
      Source source, AstNode node, DecoratedTypeInfo decoratedType) {
    expect(source, test.source);
    expect(test.implicitType, isNot(contains(node)));
    test.implicitType[node] = decoratedType;
  }

  @override
  void implicitTypeArguments(
      Source source, AstNode node, Iterable<DecoratedTypeInfo> types) {
    expect(source, test.source);
    expect(test.implicitTypeArguments, isNot(contains(node)));
    test.implicitTypeArguments[node] = types.toList();
  }

  @override
  void prepareForUpdate() {
    test.changes = null;
  }
}

@reflectiveTest
class _InstrumentationTest extends _InstrumentationTestBase {}

abstract class _InstrumentationTestBase extends AbstractContextTest {
  NullabilityNodeInfo always;

  final Map<TypeAnnotation, NullabilityNodeInfo> explicitTypeNullability = {};

  final Map<Element, DecoratedTypeInfo> externalDecoratedType = {};

  final Map<TypeParameterElement, DecoratedTypeInfo>
      externalDecoratedTypeParameterBound = {};

  final List<EdgeInfo> edges = [];

  Map<int, List<AtomicEdit>> changes;

  final Map<AstNode, DecoratedTypeInfo> implicitReturnType = {};

  final Map<AstNode, DecoratedTypeInfo> implicitType = {};

  final Map<AstNode, List<DecoratedTypeInfo>> implicitTypeArguments = {};

  NullabilityNodeInfo never;

  final Map<EdgeInfo, EdgeOriginInfo> edgeOrigin = {};

  FindNode findNode;

  Source source;

  Future<void> analyze(String content,
      {bool removeViaComments = false, bool warnOnWeakCode = true}) async {
    var sourcePath = convertPath('$testsPath/lib/test.dart');
    newFile(sourcePath, content: content);
    var listener = TestMigrationListener();
    var migration = NullabilityMigration(listener, getLineInfo,
        instrumentation: _InstrumentationClient(this),
        removeViaComments: removeViaComments,
        warnOnWeakCode: warnOnWeakCode);
    var result = await session.getResolvedUnit(sourcePath);
    source = result.unit.declaredElement.source;
    findNode = FindNode(content, result.unit);
    migration.prepareInput(result);
    expect(migration.unmigratedDependencies, isEmpty);
    migration.processInput(result);
    migration.finalizeInput(result);
    migration.finish();
  }

  void assertEdit(AtomicEdit edit,
      {dynamic description = anything, dynamic fixReasons = anything}) {
    var info = edit.info;
    expect(info.description, description);
    expect(info.fixReasons, fixReasons);
  }

  Future<void> test_explicitTypeNullability() async {
    var content = '''
int x = 1;
int y = null;
''';
    await analyze(content);
    expect(explicitTypeNullability[findNode.typeAnnotation('int x')].isNullable,
        false);
    expect(explicitTypeNullability[findNode.typeAnnotation('int y')].isNullable,
        true);
  }

  Future<void> test_externalDecoratedType() async {
    await analyze('''
main() {
  print(1);
}
''');
    expect(
        externalDecoratedType[findNode.simple('print').staticElement]
            .type
            .getDisplayString(withNullability: false),
        'void Function(Object)');
  }

  Future<void> test_externalDecoratedTypeParameterBound() async {
    await analyze('''
import 'dart:math';
f(Point<int> x) {}
''');
    var pointElement = findNode.simple('Point').staticElement as ClassElement;
    var pointElementTypeParameter = pointElement.typeParameters[0];
    expect(
        externalDecoratedTypeParameterBound[pointElementTypeParameter]
            .type
            .getDisplayString(withNullability: false),
        'num');
  }

  Future<void> test_externalType_nullability_dynamic_edge() async {
    await analyze('''
f(List<int> x) {}
''');
    var listElement = findNode.simple('List').staticElement as ClassElement;
    var listElementTypeParameter = listElement.typeParameters[0];
    var typeParameterBoundNode =
        externalDecoratedTypeParameterBound[listElementTypeParameter].node;
    var edge = edges
        .where((e) =>
            e.sourceNode == always &&
            e.destinationNode == typeParameterBoundNode)
        .single;
    var origin = edgeOrigin[edge];
    expect(origin.kind, EdgeOriginKind.alwaysNullableType);
    expect(origin.element, same(listElementTypeParameter));
    expect(origin.source, null);
    expect(origin.node, null);
  }

  Future<void> test_fix_reason_add_required_function() async {
    var content = '_f({int/*!*/ i) {}';
    await analyze(content);
    var intAnnotation = findNode.typeAnnotation('int');
    var intPos = content.indexOf('int');
    var commentPos = content.indexOf('/*');
    expect(changes.keys, unorderedEquals([intPos, commentPos]));
    assertEdit(changes[intPos].single,
        description: NullabilityFixDescription.addRequired(null, '_f', 'i'),
        fixReasons: {
          FixReasonTarget.root: same(explicitTypeNullability[intAnnotation])
        });
  }

  Future<void> test_fix_reason_add_required_method() async {
    var content = 'class C { _f({int/*!*/ i) {} }';
    await analyze(content);
    var intAnnotation = findNode.typeAnnotation('int');
    var intPos = content.indexOf('int');
    var commentPos = content.indexOf('/*');
    expect(changes.keys, unorderedEquals([intPos, commentPos]));
    assertEdit(changes[intPos].single,
        description: NullabilityFixDescription.addRequired('C', '_f', 'i'),
        fixReasons: {
          FixReasonTarget.root: same(explicitTypeNullability[intAnnotation])
        });
  }

  Future<void> test_fix_reason_discard_condition() async {
    var content = '''
_f(int/*!*/ i) {
  if (i != null) {
    return i;
  }
}
''';
    await analyze(content, warnOnWeakCode: false);
    var intAnnotation = findNode.typeAnnotation('int');
    var commentPos = content.indexOf('/*');
    var ifPos = content.indexOf('if');
    var afterReturnPos = content.indexOf('i;') + 2;
    expect(changes.keys, unorderedEquals([commentPos, ifPos, afterReturnPos]));
    var expectedFixReasons = {
      FixReasonTarget.root: same(explicitTypeNullability[intAnnotation])
    };
    assertEdit(changes[ifPos].single,
        description: NullabilityFixDescription.discardCondition,
        fixReasons: expectedFixReasons);
    assertEdit(changes[afterReturnPos].single,
        description: NullabilityFixDescription.discardCondition,
        fixReasons: expectedFixReasons);
  }

  Future<void> test_fix_reason_discard_condition_no_block() async {
    var content = '''
_f(int/*!*/ i) {
  if (i != null) return i;
}
''';
    await analyze(content, warnOnWeakCode: false);
    var intAnnotation = findNode.typeAnnotation('int');
    var commentPos = content.indexOf('/*');
    var ifPos = content.indexOf('if');
    expect(changes.keys, unorderedEquals([commentPos, ifPos]));
    assertEdit(changes[ifPos].single,
        description: NullabilityFixDescription.discardCondition,
        fixReasons: {
          FixReasonTarget.root: same(explicitTypeNullability[intAnnotation])
        });
  }

  Future<void> test_fix_reason_discard_else() async {
    var content = '''
_f(int/*!*/ i) {
  if (i != null) {
    return i;
  } else {
    return 'null';
  }
}
''';
    await analyze(content, warnOnWeakCode: false);
    var intAnnotation = findNode.typeAnnotation('int');
    var commentPos = content.indexOf('/*');
    var ifPos = content.indexOf('if');
    var afterReturnPos = content.indexOf('i;') + 2;
    expect(changes.keys, unorderedEquals([commentPos, ifPos, afterReturnPos]));
    var expectedFixReasons = {
      FixReasonTarget.root: same(explicitTypeNullability[intAnnotation])
    };
    assertEdit(changes[ifPos].single,
        description: NullabilityFixDescription.discardCondition,
        fixReasons: expectedFixReasons);
    assertEdit(changes[afterReturnPos].single,
        description: NullabilityFixDescription.discardElse,
        fixReasons: expectedFixReasons);
  }

  Future<void> test_fix_reason_discard_else_empty_then() async {
    var content = '''
_f(int/*!*/ i) {
  if (i != null) {} else {
    return 'null';
  }
}
''';
    await analyze(content, warnOnWeakCode: false);
    var intAnnotation = findNode.typeAnnotation('int');
    var commentPos = content.indexOf('/*');
    var bodyPos = content.indexOf('i) {') + 4;
    expect(changes.keys, unorderedEquals([commentPos, bodyPos]));
    assertEdit(changes[bodyPos].single,
        description: NullabilityFixDescription.discardIf,
        fixReasons: {
          FixReasonTarget.root: same(explicitTypeNullability[intAnnotation])
        });
  }

  Future<void> test_fix_reason_discard_then() async {
    var content = '''
_f(int/*!*/ i) {
  if (i == null) {
    return 'null';
  } else {
    return i;
  }
}
''';
    await analyze(content, warnOnWeakCode: false);
    var intAnnotation = findNode.typeAnnotation('int');
    var commentPos = content.indexOf('/*');
    var ifPos = content.indexOf('if');
    var afterReturnPos = content.indexOf('i;') + 2;
    expect(changes.keys, unorderedEquals([commentPos, ifPos, afterReturnPos]));
    var expectedFixReasons = {
      FixReasonTarget.root: same(explicitTypeNullability[intAnnotation])
    };
    assertEdit(changes[ifPos].single,
        description: NullabilityFixDescription.discardThen,
        fixReasons: expectedFixReasons);
    assertEdit(changes[afterReturnPos].single,
        description: NullabilityFixDescription.discardThen,
        fixReasons: expectedFixReasons);
  }

  Future<void> test_fix_reason_discard_then_no_else() async {
    var content = '''
_f(int/*!*/ i) {
  if (i == null) {
    return 'null';
  }
}
''';
    await analyze(content, warnOnWeakCode: false);
    var intAnnotation = findNode.typeAnnotation('int');
    var commentPos = content.indexOf('/*');
    var bodyPos = content.indexOf('i) {') + 4;
    expect(changes.keys, unorderedEquals([commentPos, bodyPos]));
    assertEdit(changes[bodyPos].single,
        description: NullabilityFixDescription.discardIf,
        fixReasons: {
          FixReasonTarget.root: same(explicitTypeNullability[intAnnotation])
        });
  }

  Future<void> test_fix_reason_edge() async {
    await analyze('''
void f(int x) {
  print(x.isEven);
}
void g(int y, bool b) {
  if (b) {
    f(y);
  }
}
main() {
  g(null, false);
}
''');
    var yUsage = findNode.simple('y);');
    var edit = changes[yUsage.end].single;
    expect(edit.isInsertion, true);
    expect(edit.replacement, '!');
    var info = edit.info;
    expect(info.description, NullabilityFixDescription.checkExpression);
    var reasons = info.fixReasons;
    expect(reasons, hasLength(1));
    var edge = reasons[FixReasonTarget.root] as EdgeInfo;
    expect(edge.sourceNode,
        same(explicitTypeNullability[findNode.typeAnnotation('int y')]));
    expect(edge.destinationNode,
        same(explicitTypeNullability[findNode.typeAnnotation('int x')]));
    expect(edge.isSatisfied, false);
    expect(edgeOrigin[edge].node, same(yUsage));
  }

  Future<void> test_fix_reason_node() async {
    await analyze('''
int x = null;
''');
    var intAnnotation = findNode.typeAnnotation('int');
    var entries = changes.entries.toList();
    expect(entries, hasLength(1));
    expect(entries.single.key, intAnnotation.end);
    var edit = entries.single.value.single;
    expect(edit.isInsertion, true);
    expect(edit.replacement, '?');
    var info = edit.info;
    expect(info.description, NullabilityFixDescription.makeTypeNullable('int'));
    var reasons = info.fixReasons;
    expect(reasons, hasLength(1));
    expect(reasons[FixReasonTarget.root],
        same(explicitTypeNullability[intAnnotation]));
  }

  Future<void> test_fix_reason_remove_question_from_question_dot() async {
    var content = '_f(int/*!*/ i) => i?.isEven;';
    await analyze(content, warnOnWeakCode: false);
    var commentPos = content.indexOf('/*');
    var questionDotPos = content.indexOf('?.');
    expect(changes.keys, unorderedEquals([commentPos, questionDotPos]));
    assertEdit(changes[questionDotPos].single,
        description: NullabilityFixDescription.removeNullAwareness,
        fixReasons: isEmpty);
  }

  Future<void>
      test_fix_reason_remove_question_from_question_dot_method() async {
    var content = '_f(int/*!*/ i) => i?.abs();';
    await analyze(content, warnOnWeakCode: false);
    var commentPos = content.indexOf('/*');
    var questionDotPos = content.indexOf('?.');
    expect(changes.keys, unorderedEquals([commentPos, questionDotPos]));
    assertEdit(changes[questionDotPos].single,
        description: NullabilityFixDescription.removeNullAwareness,
        fixReasons: isEmpty);
  }

  Future<void> test_fix_reason_remove_unnecessary_cast() async {
    await analyze('''
_f(Object x) {
  if (x is! int) return;
  print((x as int) + 1);
}
''');
    var xRef = findNode.simple('x as');
    var asExpression = xRef.parent as Expression;
    expect(changes, hasLength(3));
    // Change #1: drop the `(` before the cast
    var dropLeadingParen = changes[asExpression.offset - 1].single;
    expect(dropLeadingParen.isDeletion, true);
    expect(dropLeadingParen.length, 1);
    expect(dropLeadingParen.info, null);
    // Change #2: drop the text ` as int`
    var dropAsInt = changes[xRef.end].single;
    expect(dropAsInt.isDeletion, true);
    expect(dropAsInt.length, 7);
    expect(dropAsInt.info.description, NullabilityFixDescription.removeAs);
    expect(dropAsInt.info.fixReasons, isEmpty);
    // Change #3: drop the `)` after the cast
    var dropTrailingParen = changes[asExpression.end].single;
    expect(dropTrailingParen.isDeletion, true);
    expect(dropTrailingParen.length, 1);
    expect(dropTrailingParen.info, null);
  }

  Future<void> test_fix_reason_rewrite_required() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
_f({@required int i}) {}
''');
    var intAnnotation = findNode.typeAnnotation('int');
    expect(changes, isNotEmpty);
    for (var change in changes.values) {
      expect(change, isNotEmpty);
      for (var edit in change) {
        var info = edit.info;
        expect(info.description,
            NullabilityFixDescription.addRequired(null, '_f', 'i'));
        expect(info.fixReasons[FixReasonTarget.root],
            same(explicitTypeNullability[intAnnotation]));
      }
    }
  }

  Future<void> test_graphEdge() async {
    await analyze('''
int f(int x) => x;
''');
    var xNode = explicitTypeNullability[findNode.typeAnnotation('int x')];
    var returnNode = explicitTypeNullability[findNode.typeAnnotation('int f')];
    expect(
        edges.where(
            (e) => e.sourceNode == xNode && e.destinationNode == returnNode),
        hasLength(1));
  }

  Future<void> test_graphEdge_guards() async {
    await analyze('''
int f(int i, int j) {
  if (i == null) {
    return j;
  }
  return 1;
}
''');
    var iNode = explicitTypeNullability[findNode.typeAnnotation('int i')];
    var jNode = explicitTypeNullability[findNode.typeAnnotation('int j')];
    var returnNode = explicitTypeNullability[findNode.typeAnnotation('int f')];
    var matchingEdges = edges
        .where((e) => e.sourceNode == jNode && e.destinationNode == returnNode)
        .toList();
    expect(matchingEdges, hasLength(1));
    expect(matchingEdges.single.guards, hasLength(1));
    expect(matchingEdges.single.guards.single, iNode);
  }

  Future<void> test_graphEdge_hard() async {
    await analyze('''
int f(int x) => x;
''');
    var xNode = explicitTypeNullability[findNode.typeAnnotation('int x')];
    var returnNode = explicitTypeNullability[findNode.typeAnnotation('int f')];
    var matchingEdges = edges
        .where((e) => e.sourceNode == xNode && e.destinationNode == returnNode)
        .toList();
    expect(matchingEdges, hasLength(1));
    expect(matchingEdges.single.isUnion, false);
    expect(matchingEdges.single.isHard, true);
  }

  Future<void> test_graphEdge_isSatisfied() async {
    await analyze('''
void f1(int i, bool b) {
  f2(i, b);
}
void f2(int j, bool b) {
  if (b) {
    f3(j);
  }
}
void f3(int k) {
  f4(k);
}
void f4(int l) {
  print(l.isEven);
}
main() {
  f1(null, false);
}
''');
    var iNode = explicitTypeNullability[findNode.typeAnnotation('int i')];
    var jNode = explicitTypeNullability[findNode.typeAnnotation('int j')];
    var kNode = explicitTypeNullability[findNode.typeAnnotation('int k')];
    var lNode = explicitTypeNullability[findNode.typeAnnotation('int l')];
    var iToJ = edges
        .where((e) => e.sourceNode == iNode && e.destinationNode == jNode)
        .single;
    var jToK = edges
        .where((e) => e.sourceNode == jNode && e.destinationNode == kNode)
        .single;
    var kToL = edges
        .where((e) => e.sourceNode == kNode && e.destinationNode == lNode)
        .single;
    expect(iNode.isNullable, true);
    expect(jNode.isNullable, true);
    expect(kNode.isNullable, false);
    expect(lNode.isNullable, false);
    expect(iToJ.isSatisfied, true);
    expect(jToK.isSatisfied, false);
    expect(kToL.isSatisfied, true);
  }

  Future<void> test_graphEdge_isUpstreamTriggered() async {
    await analyze('''
void f(int i, bool b) {
  assert(i != null);
  i.isEven; // unconditional
  g(i);
  h(i);
  if (b) {
    i.isEven; // conditional
  }
}
void g(int/*?*/ j) {}
void h(int k) {}
''');
    var iNode = explicitTypeNullability[findNode.typeAnnotation('int i')];
    var jNode = explicitTypeNullability[findNode.typeAnnotation('int/*?*/ j')];
    var kNode = explicitTypeNullability[findNode.typeAnnotation('int k')];
    var assertNode = findNode.statement('assert');
    var unconditionalUsageNode = findNode.simple('i.isEven; // unconditional');
    var conditionalUsageNode = findNode.simple('i.isEven; // conditional');
    var nonNullEdges = edgeOrigin.entries
        .where((entry) =>
            entry.key.sourceNode == iNode && entry.key.destinationNode == never)
        .toList();
    var assertEdge = nonNullEdges
        .where((entry) => entry.value.node == assertNode)
        .single
        .key;
    var unconditionalUsageEdge = edgeOrigin.entries
        .where((entry) => entry.value.node == unconditionalUsageNode)
        .single
        .key;
    var gCallEdge = edges
        .where((e) => e.sourceNode == iNode && e.destinationNode == jNode)
        .single;
    var hCallEdge = edges
        .where((e) => e.sourceNode == iNode && e.destinationNode == kNode)
        .single;
    var conditionalUsageEdge = edgeOrigin.entries
        .where((entry) => entry.value.node == conditionalUsageNode)
        .single
        .key;
    // Both assertEdge and unconditionalUsageEdge are upstream triggered because
    // either of them would have been sufficient to cause i to be marked as
    // non-nullable.
    expect(assertEdge.isUpstreamTriggered, true);
    expect(unconditionalUsageEdge.isUpstreamTriggered, true);
    // conditionalUsageEdge is not upstream triggered because it is a soft edge,
    // so it would not have caused i to be marked as non-nullable.
    expect(conditionalUsageEdge.isUpstreamTriggered, false);
    // Even though gCallEdge is a hard edge, it is not upstream triggered
    // because its destination node is nullable.
    expect(gCallEdge.isHard, true);
    expect(gCallEdge.isUpstreamTriggered, false);
    // Even though hCallEdge is a hard edge and its destination node is
    // non-nullable, it is not upstream triggered because k could have been made
    // nullable without causing any problems, so the presence of this edge would
    // not have caused i to be marked as non-nullable.
    expect(hCallEdge.isHard, true);
    expect(hCallEdge.isUpstreamTriggered, false);
  }

  Future<void> test_graphEdge_origin() async {
    await analyze('''
int f(int x) => x;
''');
    var xNode = explicitTypeNullability[findNode.typeAnnotation('int x')];
    var returnNode = explicitTypeNullability[findNode.typeAnnotation('int f')];
    var matchingEdges = edges
        .where((e) => e.sourceNode == xNode && e.destinationNode == returnNode)
        .toList();
    var origin = edgeOrigin[matchingEdges.single];
    expect(origin.source, source);
    expect(origin.node, findNode.simple('x;'));
  }

  Future<void> test_graphEdge_origin_dynamic_assignment() async {
    await analyze('''
int f(dynamic x) => x;
''');
    var xNode = explicitTypeNullability[findNode.typeAnnotation('dynamic x')];
    var returnNode = explicitTypeNullability[findNode.typeAnnotation('int f')];
    var matchingEdges = edges
        .where((e) => e.sourceNode == xNode && e.destinationNode == returnNode)
        .toList();
    var origin = edgeOrigin[matchingEdges.single];
    expect(origin.kind, EdgeOriginKind.dynamicAssignment);
    expect(origin.source, source);
    expect(origin.node, findNode.simple('x;'));
  }

  Future<void> test_graphEdge_soft() async {
    await analyze('''
int f(int x, bool b) {
  if (b) return x;
  return 0;
}
''');
    var xNode = explicitTypeNullability[findNode.typeAnnotation('int x')];
    var returnNode = explicitTypeNullability[findNode.typeAnnotation('int f')];
    var matchingEdges = edges
        .where((e) => e.sourceNode == xNode && e.destinationNode == returnNode)
        .toList();
    expect(matchingEdges, hasLength(1));
    expect(matchingEdges.single.isUnion, false);
    expect(matchingEdges.single.isHard, false);
  }

  Future<void> test_immutableNode_always() async {
    await analyze('''
int x = null;
''');
    expect(always.isImmutable, true);
    expect(always.isNullable, true);
    var xNode = explicitTypeNullability[findNode.typeAnnotation('int')];
    var edge = edges.where((e) => e.destinationNode == xNode).single;
    var edgeSource = edge.sourceNode;
    var upstreamEdge =
        edges.where((e) => e.destinationNode == edgeSource).single;
    expect(upstreamEdge.sourceNode, always);
  }

  Future<void> test_immutableNode_never() async {
    await analyze('''
bool f(int x) => x.isEven;
''');
    expect(never.isImmutable, true);
    expect(never.isNullable, false);
    var xNode = explicitTypeNullability[findNode.typeAnnotation('int')];
    var edge = edges.where((e) => e.sourceNode == xNode).single;
    expect(edge.destinationNode, never);
  }

  Future<void> test_implicitReturnType_constructor() async {
    await analyze('''
class C {
  factory C() => f(true);
  C.named();
}
C f(bool b) => b ? C.named() : null;
''');
    var factoryReturnNode = implicitReturnType[findNode.constructor('C(')].node;
    var fReturnNode = explicitTypeNullability[findNode.typeAnnotation('C f')];
    expect(
        edges.where((e) =>
            e.sourceNode == fReturnNode &&
            e.destinationNode == factoryReturnNode),
        hasLength(1));
  }

  Future<void> test_implicitReturnType_formalParameter() async {
    await analyze('''
Object f(callback()) => callback();
''');
    var paramReturnNode =
        implicitReturnType[findNode.functionTypedFormalParameter('callback())')]
            .node;
    var fReturnNode =
        explicitTypeNullability[findNode.typeAnnotation('Object')];
    expect(
        edges.where((e) =>
            e.sourceNode == paramReturnNode &&
            e.destinationNode == fReturnNode),
        hasLength(1));
  }

  Future<void> test_implicitReturnType_function() async {
    await analyze('''
f() => 1;
Object g() => f();
''');
    var fReturnNode =
        implicitReturnType[findNode.functionDeclaration('f() =>')].node;
    var gReturnNode =
        explicitTypeNullability[findNode.typeAnnotation('Object')];
    expect(
        edges.where((e) =>
            e.sourceNode == fReturnNode && e.destinationNode == gReturnNode),
        hasLength(1));
  }

  Future<void> test_implicitReturnType_functionExpression() async {
    await analyze('''
main() {
  int Function() f = () => g();
}
int g() => 1;
''');
    var fReturnNode =
        explicitTypeNullability[findNode.typeAnnotation('int Function')];
    var functionExpressionReturnNode =
        implicitReturnType[findNode.functionExpression('() => g()')].node;
    var gReturnNode = explicitTypeNullability[findNode.typeAnnotation('int g')];
    expect(
        edges.where((e) =>
            e.sourceNode == gReturnNode &&
            e.destinationNode == functionExpressionReturnNode),
        hasLength(1));
    expect(
        edges.where((e) =>
            e.sourceNode == functionExpressionReturnNode &&
            e.destinationNode == fReturnNode),
        hasLength(1));
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/39370')
  Future<void> test_implicitReturnType_functionTypeAlias() async {
    await analyze('''
typedef F();
Object f(F callback) => callback();
''');
    var typedefReturnNode =
        implicitReturnType[findNode.functionTypeAlias('F()')].node;
    var fReturnNode =
        explicitTypeNullability[findNode.typeAnnotation('Object')];
    expect(
        edges.where((e) =>
            e.sourceNode == typedefReturnNode &&
            e.destinationNode == fReturnNode),
        hasLength(1));
  }

  Future<void> test_implicitReturnType_genericFunctionType() async {
    await analyze('''
Object f(Function() callback) => callback();
''');
    var callbackReturnNode =
        implicitReturnType[findNode.genericFunctionType('Function()')].node;
    var fReturnNode =
        explicitTypeNullability[findNode.typeAnnotation('Object')];
    expect(
        edges.where((e) =>
            e.sourceNode == callbackReturnNode &&
            e.destinationNode == fReturnNode),
        hasLength(1));
  }

  Future<void> test_implicitReturnType_method() async {
    await analyze('''
abstract class Base {
  int f();
}
abstract class Derived extends Base {
  f /*derived*/();
}
''');
    var baseReturnNode =
        explicitTypeNullability[findNode.typeAnnotation('int')];
    var derivedReturnNode =
        implicitReturnType[findNode.methodDeclaration('f /*derived*/')].node;
    expect(
        edges.where((e) =>
            e.sourceNode == derivedReturnNode &&
            e.destinationNode == baseReturnNode),
        hasLength(1));
  }

  Future<void> test_implicitType_catch_exception() async {
    await analyze('''
void f() {
  try {} catch (e) {
    Object o = e;
  }
}
''');
    var oNode = explicitTypeNullability[findNode.typeAnnotation('Object')];
    var eNode = implicitType[findNode.simple('e)')].node;
    expect(
        edges.where((e) => e.sourceNode == eNode && e.destinationNode == oNode),
        hasLength(1));
  }

  Future<void> test_implicitType_catch_stackTrace() async {
    await analyze('''
void f() {
  try {} catch (e, st) {
    Object o = st;
  }
}
''');
    var oNode = explicitTypeNullability[findNode.typeAnnotation('Object')];
    var stNode = implicitType[findNode.simple('st)')].node;
    expect(
        edges
            .where((e) => e.sourceNode == stNode && e.destinationNode == oNode),
        hasLength(1));
  }

  Future<void>
      test_implicitType_declaredIdentifier_forEachPartsWithDeclaration() async {
    await analyze('''
void f(List<int> l) {
  for (var x in l) {
    int y = x;
  }
}
''');
    var xNode = implicitType[(findNode.forStatement('for').forLoopParts
                as ForEachPartsWithDeclaration)
            .loopVariable]
        .node;
    var yNode = explicitTypeNullability[findNode.typeAnnotation('int y')];
    expect(
        edges.where((e) => e.sourceNode == xNode && e.destinationNode == yNode),
        hasLength(1));
  }

  Future<void> test_implicitType_formalParameter() async {
    await analyze('''
abstract class Base {
  void f(int i);
}
abstract class Derived extends Base {
  void f(i); /*derived*/
}
''');
    var baseParamNode =
        explicitTypeNullability[findNode.typeAnnotation('int i')];
    var derivedParamNode =
        implicitType[findNode.simpleParameter('i); /*derived*/')].node;
    expect(
        edges.where((e) =>
            e.sourceNode == baseParamNode &&
            e.destinationNode == derivedParamNode),
        hasLength(1));
  }

  Future<void> test_implicitType_namedParameter() async {
    await analyze('''
abstract class Base {
  void f(void callback({int i}));
}
abstract class Derived extends Base {
  void f(callback);
}
''');
    var baseParamParamNode =
        explicitTypeNullability[findNode.typeAnnotation('int i')];
    var derivedParamParamNode =
        implicitType[findNode.simpleParameter('callback)')]
            .namedParameter('i')
            .node;
    expect(
        edges.where((e) =>
            e.sourceNode == baseParamParamNode &&
            e.destinationNode == derivedParamParamNode),
        hasLength(1));
  }

  Future<void> test_implicitType_positionalParameter() async {
    await analyze('''
abstract class Base {
  void f(void callback(int i));
}
abstract class Derived extends Base {
  void f(callback);
}
''');
    var baseParamParamNode =
        explicitTypeNullability[findNode.typeAnnotation('int i')];
    var derivedParamParamNode =
        implicitType[findNode.simpleParameter('callback)')]
            .positionalParameter(0)
            .node;
    expect(
        edges.where((e) =>
            e.sourceNode == baseParamParamNode &&
            e.destinationNode == derivedParamParamNode),
        hasLength(1));
  }

  Future<void> test_implicitType_returnType() async {
    await analyze('''
abstract class Base {
  void f(int callback());
}
abstract class Derived extends Base {
  void f(callback);
}
''');
    var baseParamReturnNode =
        explicitTypeNullability[findNode.typeAnnotation('int callback')];
    var derivedParamReturnNode =
        implicitType[findNode.simpleParameter('callback)')].returnType.node;
    expect(
        edges.where((e) =>
            e.sourceNode == baseParamReturnNode &&
            e.destinationNode == derivedParamReturnNode),
        hasLength(1));
  }

  Future<void> test_implicitType_typeArgument() async {
    await analyze('''
abstract class Base {
  void f(List<int> x);
}
abstract class Derived extends Base {
  void f(x); /*derived*/
}
''');
    var baseParamArgNode =
        explicitTypeNullability[findNode.typeAnnotation('int>')];
    var derivedParamArgNode =
        implicitType[findNode.simpleParameter('x); /*derived*/')]
            .typeArgument(0)
            .node;
    expect(
        edges.where((e) =>
            e.sourceNode == baseParamArgNode &&
            e.destinationNode == derivedParamArgNode),
        hasLength(1));
  }

  Future<void> test_implicitType_variableDeclarationList() async {
    await analyze('''
void f(int i) {
  var j = i;
}
''');
    var iNode = explicitTypeNullability[findNode.typeAnnotation('int')];
    var jNode = implicitType[findNode.variableDeclarationList('j')].node;
    expect(
        edges.where((e) => e.sourceNode == iNode && e.destinationNode == jNode),
        hasLength(1));
  }

  Future<void> test_implicitTypeArguments_genericFunctionCall() async {
    await analyze('''
List<T> g<T>(T t) {}
List<int> f() => g(null);
''');
    var implicitInvocationTypeArgumentNode =
        implicitTypeArguments[findNode.methodInvocation('g(null)')].single.node;
    var returnElementNode =
        explicitTypeNullability[findNode.typeAnnotation('int')];
    expect(edges.where((e) {
      var destination = e.destinationNode;
      return _isPointedToByAlways(e.sourceNode) &&
          destination is SubstitutionNodeInfo &&
          destination.innerNode == implicitInvocationTypeArgumentNode;
    }), hasLength(1));
    expect(edges.where((e) {
      var source = e.sourceNode;
      return source is SubstitutionNodeInfo &&
          source.innerNode == implicitInvocationTypeArgumentNode &&
          e.destinationNode == returnElementNode;
    }), hasLength(1));
  }

  Future<void> test_implicitTypeArguments_genericMethodCall() async {
    await analyze('''
class C {
  List<T> g<T>(T t) {}
}
List<int> f(C c) => c.g(null);
''');
    var implicitInvocationTypeArgumentNode =
        implicitTypeArguments[findNode.methodInvocation('c.g(null)')]
            .single
            .node;
    var returnElementNode =
        explicitTypeNullability[findNode.typeAnnotation('int')];
    expect(edges.where((e) {
      var destination = e.destinationNode;
      return _isPointedToByAlways(e.sourceNode) &&
          destination is SubstitutionNodeInfo &&
          destination.innerNode == implicitInvocationTypeArgumentNode;
    }), hasLength(1));
    expect(edges.where((e) {
      var source = e.sourceNode;
      return source is SubstitutionNodeInfo &&
          source.innerNode == implicitInvocationTypeArgumentNode &&
          e.destinationNode == returnElementNode;
    }), hasLength(1));
  }

  Future<void> test_implicitTypeArguments_instanceCreationExpression() async {
    await analyze('''
class C<T> {
  C(T t);
}
C<int> f() => C(null);
''');
    var implicitInvocationTypeArgumentNode =
        implicitTypeArguments[findNode.instanceCreation('C(null)')].single.node;
    var returnElementNode =
        explicitTypeNullability[findNode.typeAnnotation('int')];
    expect(edges.where((e) {
      var destination = e.destinationNode;
      return _isPointedToByAlways(e.sourceNode) &&
          destination is SubstitutionNodeInfo &&
          destination.innerNode == implicitInvocationTypeArgumentNode;
    }), hasLength(1));
    expect(
        edges.where((e) =>
            e.sourceNode == implicitInvocationTypeArgumentNode &&
            e.destinationNode == returnElementNode),
        hasLength(1));
  }

  Future<void> test_implicitTypeArguments_listLiteral() async {
    await analyze('''
List<int> f() => [null];
''');
    var implicitListLiteralElementNode =
        implicitTypeArguments[findNode.listLiteral('[null]')].single.node;
    var returnElementNode =
        explicitTypeNullability[findNode.typeAnnotation('int')];
    expect(
        edges.where((e) =>
            _isPointedToByAlways(e.sourceNode) &&
            e.destinationNode == implicitListLiteralElementNode),
        hasLength(1));
    expect(
        edges.where((e) =>
            e.sourceNode == implicitListLiteralElementNode &&
            e.destinationNode == returnElementNode),
        hasLength(1));
  }

  Future<void> test_implicitTypeArguments_mapLiteral() async {
    await analyze('''
Map<int, String> f() => {1: null};
''');
    var implicitMapLiteralTypeArguments =
        implicitTypeArguments[findNode.setOrMapLiteral('{1: null}')];
    expect(implicitMapLiteralTypeArguments, hasLength(2));
    var implicitMapLiteralKeyNode = implicitMapLiteralTypeArguments[0].node;
    var implicitMapLiteralValueNode = implicitMapLiteralTypeArguments[1].node;
    var returnKeyNode = explicitTypeNullability[findNode.typeAnnotation('int')];
    var returnValueNode =
        explicitTypeNullability[findNode.typeAnnotation('String')];
    expect(
        edges.where((e) =>
            _pointsToNeverHard(e.sourceNode) &&
            e.destinationNode == implicitMapLiteralKeyNode),
        hasLength(1));
    expect(
        edges.where((e) =>
            e.sourceNode == implicitMapLiteralKeyNode &&
            e.destinationNode == returnKeyNode),
        hasLength(1));
    expect(
        edges.where((e) =>
            _isPointedToByAlways(e.sourceNode) &&
            e.destinationNode == implicitMapLiteralValueNode),
        hasLength(1));
    expect(
        edges.where((e) =>
            e.sourceNode == implicitMapLiteralValueNode &&
            e.destinationNode == returnValueNode),
        hasLength(1));
  }

  Future<void> test_implicitTypeArguments_setLiteral() async {
    await analyze('''
Set<int> f() => {null};
''');
    var implicitSetLiteralElementNode =
        implicitTypeArguments[findNode.setOrMapLiteral('{null}')].single.node;
    var returnElementNode =
        explicitTypeNullability[findNode.typeAnnotation('int')];
    expect(
        edges.where((e) =>
            _isPointedToByAlways(e.sourceNode) &&
            e.destinationNode == implicitSetLiteralElementNode),
        hasLength(1));
    expect(
        edges.where((e) =>
            e.sourceNode == implicitSetLiteralElementNode &&
            e.destinationNode == returnElementNode),
        hasLength(1));
  }

  Future<void> test_implicitTypeArguments_typeAnnotation() async {
    await analyze('''
List<Object> f(List l) => l;
''');
    var implicitListElementType =
        implicitTypeArguments[findNode.typeAnnotation('List l')].single.node;
    var implicitReturnElementType =
        explicitTypeNullability[findNode.typeAnnotation('Object')];
    expect(
        edges.where((e) =>
            e.sourceNode == implicitListElementType &&
            e.destinationNode == implicitReturnElementType),
        hasLength(1));
  }

  Future<void> test_substitutionNode() async {
    await analyze('''
class C<T> {
  void f(T t) {}
}
void g(C<int> x, int y) {
  x.f(y);
}
''');
    var yNode = explicitTypeNullability[findNode.typeAnnotation('int y')];
    var edge = edges.where((e) => e.sourceNode == yNode).single;
    var sNode = edge.destinationNode as SubstitutionNodeInfo;
    expect(sNode.innerNode,
        explicitTypeNullability[findNode.typeAnnotation('int>')]);
    expect(sNode.outerNode,
        explicitTypeNullability[findNode.typeAnnotation('T t')]);
  }

  bool _isPointedToByAlways(NullabilityNodeInfo node) {
    return edges
        .any((e) => e.sourceNode == always && e.destinationNode == node);
  }

  bool _pointsToNeverHard(NullabilityNodeInfo node) {
    return edges.any(
        (e) => e.sourceNode == node && e.destinationNode == never && e.isHard);
  }
}
