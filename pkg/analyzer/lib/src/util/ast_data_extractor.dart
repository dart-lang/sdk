// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

MemberId computeMemberId(Element element) {
  var enclosingElement = element.enclosingElement;
  if (enclosingElement is LibraryElement) {
    var memberName = element.name!;
    if (element is SetterElement) {
      memberName += '=';
    }
    return MemberId.internal(memberName);
  } else if (enclosingElement is InterfaceElement) {
    var memberName = element.lookupName!;
    var className = enclosingElement.name;
    return MemberId.internal(memberName, className: className);
  } else if (enclosingElement is ExtensionElement) {
    var memberName = element.name!;
    var extensionName = enclosingElement.name;
    if (element is PropertyAccessorElement) {
      if (element is GetterElement) {
        memberName = 'get#$memberName';
      } else {
        memberName = 'set#$memberName';
      }
    }
    return MemberId.internal('$extensionName|$memberName');
  }
  throw UnimplementedError(
    'TODO(paulberry): $element (${element.runtimeType})',
  );
}

/// Abstract IR visitor for computing data corresponding to a node, token, or
/// element, and recording it with a generic [Id].
abstract class AstDataExtractor<T> extends UnifyingAstVisitor2<void>
    with DataRegistry<T> {
  final Uri uri;

  @override
  final ActualDataMap<T> actualMap;

  new(this.uri, this.actualMap);

  NodeId computeDefaultNodeId(AstNode node) =>
      NodeId(_nodeOffset(node), IdKind.node);

  T? computeElementValue(Id id, Element element) => null;

  void computeForClass(Declaration node, Id? id) {
    if (id == null) return;
    FutureOr<T?> value = computeNodeValue(id, node);
    asyncRegisterValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForFormalParameter(FormalParameter node, NodeId? id) {
    if (id == null) return;
    FutureOr<T?> value = computeNodeValue(id, node);
    asyncRegisterValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForLibrary(LibraryElement library, Id? id) {
    if (id == null) return;
    FutureOr<T?> value = computeElementValue(id, library);
    asyncRegisterValue(uri, 0, id, value, library);
  }

  void computeForLocalVariable(LocalVariable node, NodeId? id) {
    if (id == null) return;
    FutureOr<T?> value = computeNodeValue(id, node);
    asyncRegisterValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForMember(AstNode node, Id? id) {
    if (id == null) return;
    FutureOr<T?> value = computeNodeValue(id, node);
    asyncRegisterValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForNode(AstNode node, NodeId? id) {
    if (id == null) return;
    FutureOr<T?> value = computeNodeValue(id, node);
    asyncRegisterValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForStatement(Statement node, NodeId? id) {
    if (id == null) return;
    FutureOr<T?> value = computeNodeValue(id, node);
    asyncRegisterValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForToken(Token token, NodeId? id) {
    if (id == null) return;
    FutureOr<T?> value = computeTokenValue(id, token);
    asyncRegisterValue(uri, token.offset, id, value, token);
  }

  /// Implement this to compute the data corresponding to [node].
  ///
  /// If `null` is returned, [node] has no associated data.
  FutureOr<T?> computeNodeValue(Id id, AstNode node);

  /// Computes the data corresponding to [token], if any.
  FutureOr<T?> computeTokenValue(Id id, Token token) => null;

  Id createClassId(Declaration node) {
    var element = node.declaredFragment!.element;
    return ClassId(element.name!);
  }

  Id createLibraryId(LibraryElement node) {
    Uri uri = node.uri;
    if (uri.path.startsWith(r'/C:')) {
      // The `MemoryResourceProvider.convertPath` inserts '/C:' on Windows.
      uri = Uri(scheme: uri.scheme, path: uri.path.substring(3));
    }
    return LibraryId(uri);
  }

  Id createMemberId(FragmentDeclaringNode node) {
    var element = node.declaredFragment!.element;
    return computeMemberId(element);
  }

  NodeId createStatementId(Statement node) =>
      NodeId(_nodeOffset(node), IdKind.stmt);

  @override
  void fail(String message) {
    throw _Failure(message);
  }

  @override
  void report(Uri uri, int offset, String message) {
    // TODO(paulberry): find a way to print the error more nicely.
    print('$uri:$offset: $message');
  }

  void run(CompilationUnit unit) {
    unit.accept2(this);
  }

  @override
  void visitCascadePropertyExtraction(CascadePropertyExtraction node) {
    var propertyName = node.name;
    computeForToken(propertyName, NodeId(propertyName.offset, IdKind.node));
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    computeForClass(node, createClassId(node));
    super.visitClassDeclaration(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var library = node.declaredFragment!.element;
    computeForLibrary(library, createLibraryId(library));
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    computeForMember(node, createMemberId(node));
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    // A for-in loop has no enclosing expression to attribute the write of its
    // variable to, so flow analysis attributes it to the target.
    var target = node.target;
    computeForNode(target, computeDefaultNodeId(target));
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitForElement(node);
  }

  @override
  void visitGetterDeclaration(covariant GetterDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitGetterDeclaration(node));
  }

  @override
  void visitIfElement(IfElement node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitIfElement(node);
  }

  @override
  void visitLocalVariable(LocalVariable node) {
    computeForLocalVariable(node, computeDefaultNodeId(node));
    super.visitLocalVariable(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMethodDeclaration2(covariant MethodDeclaration2Impl node) {
    _visitMethodDeclaration(node, () => super.visitMethodDeclaration2(node));
  }

  @override
  void visitNode(AstNode node) {
    switch (node) {
      case Expression():
        computeForNode(node, computeDefaultNodeId(node));
      case FormalParameter():
        computeForFormalParameter(node, computeDefaultNodeId(node));
      case ExpressionStatement():
        computeForStatement(node, createStatementId(node));
      case Statement():
        computeForStatement(node, computeDefaultNodeId(node));
      case SwitchMember():
        computeForNode(node, computeDefaultNodeId(node));
    }
    super.visitNode(node);
  }

  @override
  void visitNullAwareElement(NullAwareElement node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitNullAwareElement(node);
  }

  @override
  void visitOperatorDeclaration(covariant OperatorDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitOperatorDeclaration(node));
  }

  @override
  void visitReceiverMethodInvocation(ReceiverMethodInvocation node) {
    var name = node.name;
    computeForToken(name, NodeId(name.offset, IdKind.node));
    super.visitReceiverMethodInvocation(node);
  }

  @override
  void visitReceiverPropertyExtraction(ReceiverPropertyExtraction node) {
    // The property name is token-valued, but is a source location to which
    // `IdKind.node` annotations can be attached.
    var propertyName = node.name;
    computeForToken(propertyName, NodeId(propertyName.offset, IdKind.node));
    super.visitReceiverPropertyExtraction(node);
  }

  @override
  void visitSetterDeclaration(covariant SetterDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitSetterDeclaration(node));
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitSpreadElement(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    computeForNode(node, computeDefaultNodeId(node));
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitTopLevelFunctionDeclaration(TopLevelFunctionDeclaration node) {
    computeForMember(node, createMemberId(node));
    super.visitTopLevelFunctionDeclaration(node);
  }

  @override
  void visitTopLevelGetterDeclaration(TopLevelGetterDeclaration node) {
    computeForMember(node, createMemberId(node));
    super.visitTopLevelGetterDeclaration(node);
  }

  @override
  void visitTopLevelSetterDeclaration(TopLevelSetterDeclaration node) {
    computeForMember(node, createMemberId(node));
    super.visitTopLevelSetterDeclaration(node);
  }

  @override
  void visitTopLevelVariable2(TopLevelVariable2 node) {
    computeForMember(node, createMemberId(node));
    super.visitTopLevelVariable2(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    computeForMember(node, createMemberId(node));
    super.visitVariableDeclaration(node);
  }

  int _nodeOffset(AstNode node) {
    int offset;
    if (node is ConditionalExpression) {
      offset = node.question.offset;
    } else if (node is BinaryOperatorInvocation) {
      offset = node.operator.offset;
    } else if (node is IfNull) {
      offset = node.operator.offset;
    } else if (node is LogicalAnd) {
      offset = node.operator.offset;
    } else if (node is LogicalOr) {
      offset = node.operator.offset;
    } else if (node is ConstructorInvocation) {
      offset = node.argumentList.leftParenthesis.offset;
    } else if (node is FunctionInvocation) {
      offset = node.argumentList.leftParenthesis.offset;
    } else if (node is InvocationExpression) {
      offset = node.argumentList.leftParenthesis.offset;
    } else if (node is ReceiverPropertyExtraction) {
      offset = node.name.offset;
    } else if (node is SwitchExpressionCase) {
      offset = node.arrow.offset;
    } else {
      offset = node.offset;
    }
    assert(offset >= 0, "No fileOffset on $node (${node.runtimeType})");
    return offset;
  }

  void _visitMethodDeclaration(
    MethodDeclarationV1OriginImpl node,
    void Function() visitSuper,
  ) {
    computeForMember(node, createMemberId(node));
    visitSuper();
  }
}

class _Failure implements Exception {
  final String? message;

  new([this.message]);

  @override
  String toString() {
    if (message == null) return "Exception";
    return "Exception: $message";
  }
}
