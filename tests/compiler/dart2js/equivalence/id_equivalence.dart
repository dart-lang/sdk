// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/resolution/access_semantics.dart';
import 'package:compiler/src/resolution/send_structure.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:kernel/ast.dart' as ir;

enum IdKind {
  element,
  node,
}

/// Id for a code point or element with type inference information.
abstract class Id {
  IdKind get kind;
}

/// Id for an element with type inference information.
// TODO(johnniwinther): Support local variables, functions and parameters.
class ElementId implements Id {
  final String className;
  final String memberName;

  factory ElementId(String text) {
    int dotPos = text.indexOf('.');
    if (dotPos != -1) {
      return new ElementId.internal(
          text.substring(dotPos + 1), text.substring(0, dotPos));
    } else {
      return new ElementId.internal(text);
    }
  }

  ElementId.internal(this.memberName, [this.className]);

  int get hashCode => className.hashCode * 13 + memberName.hashCode * 17;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ElementId) return false;
    return className == other.className && memberName == other.memberName;
  }

  IdKind get kind => IdKind.element;

  String toString() =>
      className != null ? '$className.$memberName' : memberName;
}

/// Id for a code point with type inference information.
// TODO(johnniwinther): Create an [NodeId]-based equivalence with the kernel IR.
class NodeId implements Id {
  final int value;

  const NodeId(this.value);

  int get hashCode => value.hashCode;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! NodeId) return false;
    return value == other.value;
  }

  IdKind get kind => IdKind.node;

  String toString() => '$kind:$value';
}

class ActualData {
  final Id id;
  final String value;
  final SourceSpan sourceSpan;
  final Object object;

  ActualData(this.id, this.value, this.sourceSpan, this.object);
}

/// Abstract AST  visitor for computing data corresponding to a node or element,
// and record it with a generic [Id].
abstract class AstDataExtractor extends ast.Visitor {
  final DiagnosticReporter reporter;
  final Map<Id, ActualData> actualMap;
  final ResolvedAst resolvedAst;

  AstDataExtractor(this.reporter, this.actualMap, this.resolvedAst);

  /// Implement this to compute the data corresponding to [element].
  ///
  /// If `null` is returned, [element] has no associated data.
  String computeElementValue(AstElement element);

  /// Implement this to compute the data corresponding to [node]. If [node] has
  /// a corresponding [AstElement] this is provided in [element].
  ///
  /// If `null` is returned, [node] has no associated data.
  String computeNodeValue(ast.Node node, AstElement element);

  TreeElements get elements => resolvedAst.elements;

  void registerValue(
      SourceSpan sourceSpan, Id id, String value, Object object) {
    if (value != null) {
      actualMap[id] = new ActualData(id, value, sourceSpan, object);
    }
  }

  ElementId computeElementId(AstElement element) {
    String memberName = element.name;
    if (element.isSetter) {
      memberName += '=';
    }
    String className = element.enclosingClass?.name;
    return new ElementId.internal(memberName, className);
  }

  NodeId computeAccessId(ast.Send node, AccessSemantics access) {
    switch (access.kind) {
      case AccessKind.THIS_PROPERTY:
      case AccessKind.DYNAMIC_PROPERTY:
      case AccessKind.LOCAL_VARIABLE:
      case AccessKind.FINAL_LOCAL_VARIABLE:
      case AccessKind.LOCAL_FUNCTION:
      case AccessKind.PARAMETER:
      case AccessKind.FINAL_PARAMETER:
      case AccessKind.EXPRESSION:
        return computeDefaultNodeId(node.selector);
      default:
        return null;
    }
  }

  void computeForElement(AstElement element) {
    ElementId id = computeElementId(element);
    if (id == null) return;
    String value = computeElementValue(element);
    registerValue(element.sourcePosition, id, value, element);
  }

  void computeForNode(ast.Node node, NodeId id, [AstElement element]) {
    if (id == null) return;
    String value = computeNodeValue(node, element);
    SourceSpan sourceSpan = computeSourceSpan(node);
    registerValue(sourceSpan, id, value, element ?? node);
  }

  SourceSpan computeSourceSpan(ast.Node node) {
    return new SourceSpan(resolvedAst.sourceUri,
        node.getBeginToken().charOffset, node.getEndToken().charEnd);
  }

  NodeId computeDefaultNodeId(ast.Node node) {
    return new NodeId(node.getBeginToken().charOffset);
  }

  NodeId computeLoopNodeId(ast.Node node) => computeDefaultNodeId(node);

  NodeId computeGotoNodeId(ast.Node node) => computeDefaultNodeId(node);

  NodeId computeSwitchNodeId(ast.SwitchStatement node) =>
      computeDefaultNodeId(node);

  NodeId computeSwitchCaseNodeId(ast.SwitchCase node) {
    ast.Node position;
    for (ast.Node child in node.labelsAndCases) {
      if (child.asCaseMatch() != null) {
        ast.CaseMatch caseMatch = child;
        position = caseMatch.expression;
        break;
      }
    }
    return computeDefaultNodeId(position);
  }

  void run() {
    resolvedAst.node.accept(this);
  }

  visitNode(ast.Node node) {
    node.visitChildren(this);
  }

  visitVariableDefinitions(ast.VariableDefinitions node) {
    for (ast.Node child in node.definitions) {
      AstElement element = elements[child];
      if (element == null) {
        reportHere(reporter, child, 'No element for variable.');
      } else if (!element.isLocal) {
        computeForElement(element);
      } else {
        computeForNode(child, computeDefaultNodeId(child), element);
      }
    }
    visitNode(node);
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    AstElement element = elements.getFunctionDefinition(node);
    if (!element.isLocal) {
      computeForElement(element);
    } else {
      computeForNode(node, computeDefaultNodeId(node), element);
    }
    visitNode(node);
  }

  visitSend(ast.Send node) {
    dynamic sendStructure = elements.getSendStructure(node);
    if (sendStructure != null) {
      switch (sendStructure.kind) {
        case SendStructureKind.GET:
        case SendStructureKind.INVOKE:
        case SendStructureKind.BINARY:
        case SendStructureKind.EQUALS:
        case SendStructureKind.NOT_EQUALS:
          computeForNode(node, computeAccessId(node, sendStructure.semantics));
          break;
        default:
      }
    }
    visitNode(node);
  }

  visitLoop(ast.Loop node) {
    computeForNode(node, computeLoopNodeId(node));
    visitNode(node);
  }

  visitGotoStatement(ast.GotoStatement node) {
    computeForNode(node, computeGotoNodeId(node));
    visitNode(node);
  }

  visitSwitchStatement(ast.SwitchStatement node) {
    computeForNode(node, computeSwitchNodeId(node));
    visitNode(node);
  }

  visitSwitchCase(ast.SwitchCase node) {
    computeForNode(node, computeSwitchCaseNodeId(node));
    visitNode(node);
  }
}

/// Abstract IR visitor for computing data corresponding to a node or element,
/// and record it with a generic [Id]
abstract class IrDataExtractor extends ir.Visitor {
  final Map<Id, ActualData> actualMap;

  void registerValue(
      SourceSpan sourceSpan, Id id, String value, Object object) {
    if (value != null) {
      actualMap[id] = new ActualData(id, value, sourceSpan, object);
    }
  }

  /// Implement this to compute the data corresponding to [member].
  ///
  /// If `null` is returned, [member] has no associated data.
  String computeMemberValue(ir.Member member);

  /// Implement this to compute the data corresponding to [node].
  ///
  /// If `null` is returned, [node] has no associated data.
  String computeNodeValue(ir.TreeNode node);

  IrDataExtractor(this.actualMap);
  Id computeElementId(ir.Member node) {
    String className;
    if (node.enclosingClass != null) {
      className = node.enclosingClass.name;
    }
    String memberName = node.name.name;
    if (node is ir.Procedure && node.kind == ir.ProcedureKind.Setter) {
      memberName += '=';
    }
    return new ElementId.internal(memberName, className);
  }

  void computeForMember(ir.Member member) {
    ElementId id = computeElementId(member);
    if (id == null) return;
    String value = computeMemberValue(member);
    registerValue(computeSourceSpan(member), id, value, member);
  }

  void computeForNode(ir.TreeNode node, NodeId id) {
    if (id == null) return;
    String value = computeNodeValue(node);
    registerValue(computeSourceSpan(node), id, value, node);
  }

  SourceSpan computeSourceSpan(ir.TreeNode node) {
    return new SourceSpan(
        Uri.parse(node.location.file), node.fileOffset, node.fileOffset + 1);
  }

  NodeId computeDefaultNodeId(ir.TreeNode node) {
    assert(node.fileOffset != ir.TreeNode.noOffset);
    return new NodeId(node.fileOffset);
  }

  NodeId computeLoopNodeId(ir.TreeNode node) => computeDefaultNodeId(node);
  NodeId computeGotoNodeId(ir.TreeNode node) => computeDefaultNodeId(node);
  NodeId computeSwitchNodeId(ir.SwitchStatement node) =>
      computeDefaultNodeId(node);
  NodeId computeSwitchCaseNodeId(ir.SwitchCase node) =>
      new NodeId(node.expressionOffsets.first);

  void run(ir.Node root) {
    root.accept(this);
  }

  defaultNode(ir.Node node) {
    node.visitChildren(this);
  }

  defaultMember(ir.Member node) {
    computeForMember(node);
    super.defaultMember(node);
  }

  visitMethodInvocation(ir.MethodInvocation node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitMethodInvocation(node);
  }

  visitPropertyGet(ir.PropertyGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitPropertyGet(node);
  }

  visitVariableDeclaration(ir.VariableDeclaration node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitVariableDeclaration(node);
  }

  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitFunctionDeclaration(node);
  }

  visitFunctionExpression(ir.FunctionExpression node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitFunctionExpression(node);
  }

  visitVariableGet(ir.VariableGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitVariableGet(node);
  }

  visitDoStatement(ir.DoStatement node) {
    computeForNode(node, computeLoopNodeId(node));
    super.visitDoStatement(node);
  }

  visitForStatement(ir.ForStatement node) {
    computeForNode(node, computeLoopNodeId(node));
    super.visitForStatement(node);
  }

  visitForInStatement(ir.ForInStatement node) {
    computeForNode(node, computeLoopNodeId(node));
    super.visitForInStatement(node);
  }

  visitWhileStatement(ir.WhileStatement node) {
    computeForNode(node, computeLoopNodeId(node));
    super.visitWhileStatement(node);
  }

  visitBreakStatement(ir.BreakStatement node) {
    computeForNode(node, computeGotoNodeId(node));
    super.visitBreakStatement(node);
  }

  visitSwitchStatement(ir.SwitchStatement node) {
    computeForNode(node, computeSwitchNodeId(node));
    super.visitSwitchStatement(node);
  }

  visitSwitchCase(ir.SwitchCase node) {
    computeForNode(node, computeSwitchCaseNodeId(node));
    super.visitSwitchCase(node);
  }

  visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    computeForNode(node, computeGotoNodeId(node));
    super.visitContinueSwitchStatement(node);
  }
}
