// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:kernel/ast.dart';

/// Compute a canonical [Id] for kernel-based nodes.
MemberId computeMemberId(Member node) {
  String? className;
  if (node.enclosingClass != null) {
    className = node.enclosingClass!.name;
  }
  String memberName = node.name.text;
  if (node is Procedure && node.kind == ProcedureKind.Setter) {
    memberName += '=';
  }
  return new MemberId.internal(memberName, className: className);
}

TreeNode? computeTreeNodeWithOffset(TreeNode? node) {
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
abstract class DataExtractor<T> extends Visitor<void>
    with VisitorVoidMixin, DataRegistry<T> {
  @override
  final Map<Id, ActualData<T>> actualMap;

  /// Implement this to compute the data corresponding to [library].
  ///
  /// If `null` is returned, [library] has no associated data.
  T? computeLibraryValue(Id id, Library library) => null;

  /// Implement this to compute the data corresponding to [cls].
  ///
  /// If `null` is returned, [cls] has no associated data.
  T? computeClassValue(Id id, Class cls) => null;

  /// Implement this to compute the data corresponding to [extension].
  ///
  /// If `null` is returned, [extension] has no associated data.
  T? computeExtensionValue(Id id, Extension extension) => null;

  /// Implement this to compute the data corresponding to [member].
  ///
  /// If `null` is returned, [member] has no associated data.
  T? computeMemberValue(Id id, Member member) => null;

  /// Implement this to compute the data corresponding to [node].
  ///
  /// If `null` is returned, [node] has no associated data.
  T? computeNodeValue(Id id, TreeNode node) => null;

  DataExtractor(this.actualMap);

  void computeForLibrary(Library library) {
    LibraryId id = new LibraryId(library.fileUri);
    T? value = computeLibraryValue(id, library);
    registerValue(library.fileUri, -1, id, value, library);
  }

  void computeForClass(Class cls) {
    ClassId id = new ClassId(cls.name);
    T? value = computeClassValue(id, cls);
    registerValue(cls.fileUri, cls.fileOffset, id, value, cls);
  }

  void computeForExtension(Extension extension) {
    ClassId id = new ClassId(extension.name);
    T? value = computeExtensionValue(id, extension);
    registerValue(
        extension.fileUri, extension.fileOffset, id, value, extension);
  }

  void computeForMember(Member member) {
    MemberId id = computeMemberId(member);
    // ignore: unnecessary_null_comparison
    if (id == null) return;
    T? value = computeMemberValue(id, member);
    registerValue(member.fileUri, member.fileOffset, id, value, member);
  }

  void computeForNode(TreeNode node, NodeId? id) {
    if (id == null) return;
    T? value = computeNodeValue(id, node);
    TreeNode nodeWithOffset = computeTreeNodeWithOffset(node)!;
    registerValue(nodeWithOffset.location!.file, nodeWithOffset.fileOffset, id,
        value, node);
  }

  NodeId? computeDefaultNodeId(TreeNode node,
      {bool skipNodeWithNoOffset = false}) {
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

  NodeId? createExpressionStatementId(ExpressionStatement node) {
    if (node.expression.fileOffset == TreeNode.noOffset) {
      // TODO(johnniwinther): Find out why we something have no offset.
      return null;
    }
    return new NodeId(node.expression.fileOffset, IdKind.stmt);
  }

  NodeId? createLabeledStatementId(LabeledStatement node) =>
      computeDefaultNodeId(node.body);
  NodeId? createLoopId(TreeNode node) => computeDefaultNodeId(node);
  NodeId? createGotoId(TreeNode node) => computeDefaultNodeId(node);
  NodeId? createSwitchId(SwitchStatement node) => computeDefaultNodeId(node);
  NodeId createSwitchCaseId(SwitchCase node) =>
      new NodeId(node.expressionOffsets.first, IdKind.node);

  NodeId? createImplicitAsId(AsExpression node) {
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
  void defaultNode(Node node) {
    node.visitChildren(this);
  }

  @override
  void visitProcedure(Procedure node) {
    // Avoid visiting annotations.
    node.function.accept(this);
    computeForMember(node);
  }

  @override
  void visitConstructor(Constructor node) {
    // Avoid visiting annotations.
    visitList(node.initializers, this);
    node.function.accept(this);
    computeForMember(node);
  }

  @override
  void visitField(Field node) {
    // Avoid visiting annotations.
    node.initializer?.accept(this);
    computeForMember(node);
  }

  void _visitInvocation(Expression node, Name name) {
    if (name.text == '[]') {
      computeForNode(node, computeDefaultNodeId(node));
    } else if (name.text == '[]=') {
      computeForNode(node, createUpdateId(node));
    } else {
      if (node.fileOffset != TreeNode.noOffset) {
        // TODO(johnniwinther): Ensure file offset on all method invocations.
        // Skip synthetic invocation created in the collection transformer.
        computeForNode(node, createInvokeId(node));
      }
    }
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    _visitInvocation(node, node.name);
    super.visitDynamicInvocation(node);
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    _visitInvocation(node, node.name);
    super.visitFunctionInvocation(node);
  }

  @override
  void visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    computeForNode(node, createInvokeId(node));
    super.visitLocalFunctionInvocation(node);
  }

  @override
  void visitEqualsCall(EqualsCall node) {
    _visitInvocation(node, Name.equalsName);
    super.visitEqualsCall(node);
  }

  @override
  void visitEqualsNull(EqualsNull node) {
    Expression receiver = node.expression;
    if (receiver is VariableGet && receiver.variable.name == null) {
      // This is a desugared `?.`.
    } else {
      _visitInvocation(node, Name.equalsName);
    }
    super.visitEqualsNull(node);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    _visitInvocation(node, node.name);
    super.visitInstanceInvocation(node);
  }

  @override
  void visitInstanceGetterInvocation(InstanceGetterInvocation node) {
    _visitInvocation(node, node.name);
    super.visitInstanceGetterInvocation(node);
  }

  @override
  void visitLoadLibrary(LoadLibrary node) {
    computeForNode(node, createInvokeId(node));
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitDynamicGet(node);
  }

  @override
  void visitFunctionTearOff(FunctionTearOff node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitFunctionTearOff(node);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitInstanceGet(node);
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitInstanceTearOff(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name != null && node.parent is! FunctionDeclaration) {
      // Skip synthetic variables and function declaration variables.
      computeForNode(
          node,
          computeDefaultNodeId(node,
              // Some synthesized nodes don't have an offset.
              skipNodeWithNoOffset: true));
    }
    // Avoid visiting annotations.
    node.initializer?.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    computeForNode(
        node,
        computeDefaultNodeId(node,
            // TODO(johnniwinther): Remove this when synthesized local functions
            //  can have (same) offsets without breaking the VM.
            skipNodeWithNoOffset: true));
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitFunctionExpression(node);
  }

  @override
  void visitVariableGet(VariableGet node) {
    if (node.variable.name != null && !node.variable.isInitializingFormal) {
      // Skip use of synthetic variables.
      computeForNode(
          node,
          computeDefaultNodeId(node,
              // Some synthesized nodes don't have an offset.
              skipNodeWithNoOffset: true));
    }
    super.visitVariableGet(node);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    computeForNode(node, createUpdateId(node));
    super.visitDynamicSet(node);
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    computeForNode(node, createUpdateId(node));
    super.visitInstanceSet(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    if (node.variable.name != null) {
      // Skip use of synthetic variables.
      computeForNode(node, createUpdateId(node));
    }
    super.visitVariableSet(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    computeForNode(node, createExpressionStatementId(node));
    return super.visitExpressionStatement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    computeForNode(node, computeDefaultNodeId(node));
    return super.visitIfStatement(node);
  }

  @override
  void visitTryCatch(TryCatch node) {
    computeForNode(node, computeDefaultNodeId(node));
    return super.visitTryCatch(node);
  }

  @override
  void visitTryFinally(TryFinally node) {
    computeForNode(node, computeDefaultNodeId(node));
    return super.visitTryFinally(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    computeForNode(node, createLoopId(node));
    super.visitDoStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    computeForNode(node, createLoopId(node));
    super.visitForStatement(node);
  }

  @override
  void visitForInStatement(ForInStatement node) {
    computeForNode(node, createLoopId(node));
    computeForNode(node, createIteratorId(node));
    computeForNode(node, createCurrentId(node));
    computeForNode(node, createMoveNextId(node));
    super.visitForInStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    computeForNode(node, createLoopId(node));
    super.visitWhileStatement(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    // TODO(johnniwinther): Call computeForNode for label statements that are
    // not placeholders for loop and switch targets.
    super.visitLabeledStatement(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    computeForNode(node, createGotoId(node));
    super.visitBreakStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    computeForNode(node, createSwitchId(node));
    super.visitSwitchStatement(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    if (node.expressionOffsets.isNotEmpty) {
      computeForNode(node, createSwitchCaseId(node));
    }
    super.visitSwitchCase(node);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    computeForNode(node, createGotoId(node));
    super.visitContinueSwitchStatement(node);
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    // Implicit constants (for instance omitted field initializers, implicit
    // default values) and synthetic constants (for instance in noSuchMethod
    // forwarders) have no offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitConstantExpression(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    // Synthetic null literals, for instance in locals and fields without
    // initializers, have no offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitNullLiteral(node);
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitBoolLiteral(node);
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    // Synthetic ints literals, for instance in enum fields, have no offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitIntLiteral(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitDoubleLiteral(node);
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    // Synthetic string literals, for instance in enum fields, have no offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitStringLiteral(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    // Synthetic list literals,for instance in noSuchMethod forwarders, have no
    // offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    // Synthetic map literals, for instance in noSuchMethod forwarders, have no
    // offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitMapLiteral(node);
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitSetLiteral(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    TreeNode parent = node.parent!;
    if (node.fileOffset == TreeNode.noOffset ||
        (parent is InstanceGet ||
                parent is InstanceSet ||
                parent is InstanceInvocation) &&
            parent.fileOffset == node.fileOffset) {
      // Skip implicit this expressions.
    } else {
      computeForNode(node, computeDefaultNodeId(node));
    }
    super.visitThisExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitAwaitExpression(node);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    // Skip synthetic constructor invocations like for enum constants.
    // TODO(johnniwinther): Can [skipNodeWithNoOffset] be removed when dart2js
    // no longer test with cfe constants?
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    super.visitConstructorInvocation(node);
  }

  @override
  void visitStaticGet(StaticGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitStaticGet(node);
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitStaticTearOff(node);
  }

  @override
  void visitStaticSet(StaticSet node) {
    computeForNode(node, createUpdateId(node));
    super.visitStaticSet(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    computeForNode(node, createInvokeId(node));
    super.visitStaticInvocation(node);
  }

  @override
  void visitThrow(Throw node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitThrow(node);
  }

  @override
  void visitRethrow(Rethrow node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitRethrow(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (node.isTypeError) {
      computeForNode(node, createImplicitAsId(node));
    } else {
      computeForNode(node, computeDefaultNodeId(node));
    }
    return super.visitAsExpression(node);
  }

  @override
  void visitArguments(Arguments node) {
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    return super.visitArguments(node);
  }

  @override
  void visitBlock(Block node) {
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    return super.visitBlock(node);
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    return super.visitBlockExpression(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    computeForNode(node, computeDefaultNodeId(node));
    return super.visitConditionalExpression(node);
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    computeForNode(node, computeDefaultNodeId(node));
    return super.visitLogicalExpression(node);
  }

  @override
  void visitRecordIndexGet(RecordIndexGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitRecordIndexGet(node);
  }

  @override
  void visitRecordNameGet(RecordNameGet node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitRecordNameGet(node);
  }

  @override
  void visitInvalidExpression(InvalidExpression node) {
    // Invalid expressions produced in the constant evaluator don't have a
    // file offset.
    computeForNode(
        node, computeDefaultNodeId(node, skipNodeWithNoOffset: true));
    return super.visitInvalidExpression(node);
  }
}
