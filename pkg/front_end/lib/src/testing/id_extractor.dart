// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'id.dart';

/// Compute a canonical [Id] for kernel-based nodes.
Id computeMemberId(Member node) {
  String className;
  if (node.enclosingClass != null) {
    className = node.enclosingClass.name;
  }
  String memberName = node.name.name;
  if (node is Procedure && node.kind == ProcedureKind.Setter) {
    memberName += '=';
  }
  return new MemberId.internal(memberName, className: className);
}

TreeNode computeTreeNodeWithOffset(TreeNode node) {
  while (node != null) {
    if (node.fileOffset != TreeNode.noOffset) {
      return node;
    }
    node = node.parent;
  }
  return null;
}

/// Abstract visitor for computing data corresponding to a node or element,
/// and record it with a generic [Id]
abstract class DataExtractor<T> extends Visitor with DataRegistry<T> {
  @override
  final Map<Id, ActualData<T>> actualMap;

  /// Implement this to compute the data corresponding to [library].
  ///
  /// If `null` is returned, [library] has no associated data.
  T computeLibraryValue(Id id, Library library) => null;

  /// Implement this to compute the data corresponding to [cls].
  ///
  /// If `null` is returned, [cls] has no associated data.
  T computeClassValue(Id id, Class cls) => null;

  /// Implement this to compute the data corresponding to [extension].
  ///
  /// If `null` is returned, [extension] has no associated data.
  T computeExtensionValue(Id id, Extension extension) => null;

  /// Implement this to compute the data corresponding to [member].
  ///
  /// If `null` is returned, [member] has no associated data.
  T computeMemberValue(Id id, Member member) => null;

  /// Implement this to compute the data corresponding to [node].
  ///
  /// If `null` is returned, [node] has no associated data.
  T computeNodeValue(Id id, TreeNode node) => null;

  DataExtractor(this.actualMap);

  void computeForLibrary(Library library) {
    LibraryId id = new LibraryId(library.fileUri);
    T value = computeLibraryValue(id, library);
    registerValue(library.fileUri, null, id, value, library);
  }

  void computeForClass(Class cls) {
    ClassId id = new ClassId(cls.name);
    T value = computeClassValue(id, cls);
    TreeNode nodeWithOffset = computeTreeNodeWithOffset(cls);
    registerValue(nodeWithOffset?.location?.file, nodeWithOffset?.fileOffset,
        id, value, cls);
  }

  void computeForExtension(Extension extension) {
    ClassId id = new ClassId(extension.name);
    T value = computeExtensionValue(id, extension);
    TreeNode nodeWithOffset = computeTreeNodeWithOffset(extension);
    registerValue(nodeWithOffset?.location?.file, nodeWithOffset?.fileOffset,
        id, value, extension);
  }

  void computeForMember(Member member) {
    MemberId id = computeMemberId(member);
    if (id == null) return;
    T value = computeMemberValue(id, member);
    TreeNode nodeWithOffset = computeTreeNodeWithOffset(member);
    registerValue(nodeWithOffset?.location?.file, nodeWithOffset?.fileOffset,
        id, value, member);
  }

  void computeForNode(TreeNode node, NodeId id) {
    if (id == null) return;
    T value = computeNodeValue(id, node);
    TreeNode nodeWithOffset = computeTreeNodeWithOffset(node);
    registerValue(nodeWithOffset?.location?.file, nodeWithOffset?.fileOffset,
        id, value, node);
  }

  NodeId computeDefaultNodeId(TreeNode node,
      {bool skipNodeWithNoOffset: false}) {
    if (skipNodeWithNoOffset && node.fileOffset == TreeNode.noOffset) {
      return null;
    }
    assert(node.fileOffset != TreeNode.noOffset,
        "No fileOffset on $node (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.node);
  }

  NodeId createInvokeId(TreeNode node) {
    assert(node.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.invoke);
  }

  NodeId createUpdateId(TreeNode node) {
    assert(node.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.update);
  }

  NodeId createIteratorId(ForInStatement node) {
    assert(node.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.iterator);
  }

  NodeId createCurrentId(ForInStatement node) {
    assert(node.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.current);
  }

  NodeId createMoveNextId(ForInStatement node) {
    assert(node.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${node} (${node.runtimeType})");
    return new NodeId(node.fileOffset, IdKind.moveNext);
  }

  NodeId createLabeledStatementId(LabeledStatement node) =>
      computeDefaultNodeId(node.body);
  NodeId createLoopId(TreeNode node) => computeDefaultNodeId(node);
  NodeId createGotoId(TreeNode node) => computeDefaultNodeId(node);
  NodeId createSwitchId(SwitchStatement node) => computeDefaultNodeId(node);
  NodeId createSwitchCaseId(SwitchCase node) =>
      new NodeId(node.expressionOffsets.first, IdKind.node);

  NodeId createImplicitAsId(AsExpression node) {
    if (node.fileOffset == TreeNode.noOffset) {
      // TODO(johnniwinther): Find out why we something have no offset.
      return null;
    }
    return new NodeId(node.fileOffset, IdKind.implicitAs);
  }

  void run(Node root) {
    root.accept(this);
  }

  @override
  defaultNode(Node node) {
    node.visitChildren(this);
  }

  @override
  visitProcedure(Procedure node) {
    // Avoid visiting annotations.
    node.function.accept(this);
    computeForMember(node);
  }

  @override
  visitConstructor(Constructor node) {
    // Avoid visiting annotations.
    visitList(node.initializers, this);
    node.function.accept(this);
    computeForMember(node);
  }

  @override
  visitField(Field node) {
    // Avoid visiting annotations.
    node.initializer?.accept(this);
    computeForMember(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    TreeNode receiver = node.receiver;
    if (receiver is VariableGet &&
        receiver.variable.parent is FunctionDeclaration) {
      // This is an invocation of a named local function.
      computeForNode(node, createInvokeId(node.receiver));
      node.arguments.accept(this);
    } else if (node.name.name == '==' &&
        receiver is VariableGet &&
        receiver.variable.name == null) {
      // This is a desugared `?.`.
    } else if (node.name.name == '[]') {
      computeForNode(node, computeDefaultNodeId(node));
      super.visitMethodInvocation(node);
    } else if (node.name.name == '[]=') {
      computeForNode(node, createUpdateId(node));
      super.visitMethodInvocation(node);
    } else {
      computeForNode(node, createInvokeId(node));
      super.visitMethodInvocation(node);
    }
  }

  @override
  visitLoadLibrary(LoadLibrary node) {
    computeForNode(node, createInvokeId(node));
  }

  @override
  visitPropertyGet(PropertyGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitPropertyGet(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.name != null && node.parent is! FunctionDeclaration) {
      // Skip synthetic variables and function declaration variables.
      computeForNode(node, computeDefaultNodeId(node));
    }
    // Avoid visiting annotations.
    node.initializer?.accept(this);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitFunctionDeclaration(node);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitFunctionExpression(node);
  }

  @override
  visitVariableGet(VariableGet node) {
    if (node.variable.name != null && !node.variable.isFieldFormal) {
      // Skip use of synthetic variables.
      computeForNode(node, computeDefaultNodeId(node));
    }
    super.visitVariableGet(node);
  }

  @override
  visitPropertySet(PropertySet node) {
    computeForNode(node, createUpdateId(node));
    super.visitPropertySet(node);
  }

  @override
  visitVariableSet(VariableSet node) {
    if (node.variable.name != null) {
      // Skip use of synthetic variables.
      computeForNode(node, createUpdateId(node));
    }
    super.visitVariableSet(node);
  }

  @override
  visitDoStatement(DoStatement node) {
    computeForNode(node, createLoopId(node));
    super.visitDoStatement(node);
  }

  @override
  visitForStatement(ForStatement node) {
    computeForNode(node, createLoopId(node));
    super.visitForStatement(node);
  }

  @override
  visitForInStatement(ForInStatement node) {
    computeForNode(node, createLoopId(node));
    computeForNode(node, createIteratorId(node));
    computeForNode(node, createCurrentId(node));
    computeForNode(node, createMoveNextId(node));
    super.visitForInStatement(node);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    computeForNode(node, createLoopId(node));
    super.visitWhileStatement(node);
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    // TODO(johnniwinther): Call computeForNode for label statements that are
    // not placeholders for loop and switch targets.
    super.visitLabeledStatement(node);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    computeForNode(node, createGotoId(node));
    super.visitBreakStatement(node);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    computeForNode(node, createSwitchId(node));
    super.visitSwitchStatement(node);
  }

  @override
  visitSwitchCase(SwitchCase node) {
    if (node.expressionOffsets.isNotEmpty) {
      computeForNode(node, createSwitchCaseId(node));
    }
    super.visitSwitchCase(node);
  }

  @override
  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    computeForNode(node, createGotoId(node));
    super.visitContinueSwitchStatement(node);
  }

  @override
  visitConstantExpression(ConstantExpression node) {
    // Implicit constants (for instance omitted field initializers, implicit
    // default values) and synthetic constants (for instance in noSuchMethod
    // forwarders) have no offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitConstantExpression(node);
  }

  @override
  visitNullLiteral(NullLiteral node) {
    // Synthetic null literals, for instance in locals and fields without
    // initializers, have no offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitNullLiteral(node);
  }

  @override
  visitBoolLiteral(BoolLiteral node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitBoolLiteral(node);
  }

  @override
  visitIntLiteral(IntLiteral node) {
    // Synthetic ints literals, for instance in enum fields, have no offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitIntLiteral(node);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitDoubleLiteral(node);
  }

  @override
  visitStringLiteral(StringLiteral node) {
    // Synthetic string literals, for instance in enum fields, have no offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitStringLiteral(node);
  }

  @override
  visitListLiteral(ListLiteral node) {
    // Synthetic list literals,for instance in noSuchMethod forwarders, have no
    // offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitListLiteral(node);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    // Synthetic map literals, for instance in noSuchMethod forwarders, have no
    // offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitMapLiteral(node);
  }

  @override
  visitSetLiteral(SetLiteral node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitSetLiteral(node);
  }

  @override
  visitThisExpression(ThisExpression node) {
    TreeNode parent = node.parent;
    if (node.fileOffset == TreeNode.noOffset ||
        (parent is PropertyGet ||
                parent is PropertySet ||
                parent is MethodInvocation) &&
            parent.fileOffset == node.fileOffset) {
      // Skip implicit this expressions.
    } else {
      computeForNode(node, computeDefaultNodeId(node));
    }
    super.visitThisExpression(node);
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitAwaitExpression(node);
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    // Skip synthetic constructor invocations like for enum constants.
    // TODO(johnniwinther): Can [skipNodeWithNoOffset] be removed when dart2js
    // no longer test with cfe constants?
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitConstructorInvocation(node);
  }

  @override
  visitStaticGet(StaticGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitStaticGet(node);
  }

  @override
  visitStaticSet(StaticSet node) {
    computeForNode(node, createUpdateId(node));
    super.visitStaticSet(node);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    computeForNode(node, createInvokeId(node));
    super.visitStaticInvocation(node);
  }

  @override
  visitAsExpression(AsExpression node) {
    if (node.isTypeError) {
      computeForNode(node, createImplicitAsId(node));
    } else {
      computeForNode(node, computeDefaultNodeId(node));
    }
    return super.visitAsExpression(node);
  }

  @override
  visitArguments(Arguments node) {
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    return super.visitArguments(node);
  }
}
