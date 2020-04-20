// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// Abstract IR visitor for computing data corresponding to a node or element,
/// and record it with a generic [Id]
/// TODO(paulberry): if I try to extend GeneralizingAstVisitor<void>, the VM
/// crashes.
abstract class AstDataExtractor<T> extends GeneralizingAstVisitor<dynamic>
    with DataRegistry<T> {
  final Uri uri;

  @override
  final Map<Id, ActualData<T>> actualMap;

  AstDataExtractor(this.uri, this.actualMap);

  NodeId computeDefaultNodeId(AstNode node) =>
      NodeId(_nodeOffset(node), IdKind.node);

  void computeForCollectionElement(CollectionElement node, NodeId id) {
    if (id == null) return;
    T value = computeNodeValue(id, node);
    registerValue(uri, node.offset, id, value, node);
  }

  void computeForLibrary(LibraryElement library, Id id) {
    if (id == null) return;
    T value = computeElementValue(id, library);
    registerValue(uri, 0, id, value, library);
  }

  void computeForClass(Declaration node, Id id) {
    if (id == null) return;
    T value = computeNodeValue(id, node);
    registerValue(uri, node.offset, id, value, node);
  }

  void computeForMember(Declaration node, Id id) {
    if (id == null) return;
    T value = computeNodeValue(id, node);
    registerValue(uri, node.offset, id, value, node);
  }

  void computeForStatement(Statement node, NodeId id) {
    if (id == null) return;
    T value = computeNodeValue(id, node);
    registerValue(uri, node.offset, id, value, node);
  }

  /// Implement this to compute the data corresponding to [node].
  ///
  /// If `null` is returned, [node] has no associated data.
  T computeNodeValue(Id id, AstNode node);

  T computeElementValue(Id id, Element element) => null;

  Id createLibraryId(LibraryElement node) {
    Uri uri = node.source.uri;
    if (uri.path.startsWith(r'/C:')) {
      // The `MemoryResourceProvider.convertPath` inserts '/C:' on Windows.
      uri = Uri(scheme: uri.scheme, path: uri.path.substring(3));
    }
    return LibraryId(uri);
  }

  Id createClassId(Declaration node) {
    var element = node.declaredElement;
    return ClassId(element.name);
  }

  Id createMemberId(Declaration node) {
    var element = node.declaredElement;
    if (element.enclosingElement is CompilationUnitElement) {
      var memberName = element.name;
      if (element is PropertyAccessorElement && element.isSetter) {
        memberName += '=';
      }
      return MemberId.internal(memberName);
    } else if (element.enclosingElement is ClassElement) {
      var memberName = element.name;
      var className = element.enclosingElement.name;
      return MemberId.internal(memberName, className: className);
    }
    throw UnimplementedError(
        'TODO(paulberry): $element (${element.runtimeType})');
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
    unit.accept(this);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    var library = node.declaredElement.library;
    computeForLibrary(library, createLibraryId(library));
    return super.visitCompilationUnit(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    computeForClass(node, createClassId(node));
    return super.visitClassDeclaration(node);
  }

  @override
  visitCollectionElement(CollectionElement node) {
    computeForCollectionElement(node, computeDefaultNodeId(node));
    super.visitCollectionElement(node);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    computeForMember(node, createMemberId(node));
    return super.visitConstructorDeclaration(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is CompilationUnit) {
      computeForMember(node, createMemberId(node));
    }
    return super.visitFunctionDeclaration(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    computeForMember(node, createMemberId(node));
    return super.visitMethodDeclaration(node);
  }

  @override
  visitStatement(Statement node) {
    computeForStatement(
        node,
        node is ExpressionStatement
            ? createStatementId(node)
            : computeDefaultNodeId(node));
    super.visitStatement(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.parent.parent is TopLevelVariableDeclaration) {
      computeForMember(node, createMemberId(node));
    } else if (node.parent.parent is FieldDeclaration) {
      computeForMember(node, createMemberId(node));
    }
    return super.visitVariableDeclaration(node);
  }

  int _nodeOffset(AstNode node) {
    var offset = node.offset;
    assert(offset != null && offset >= 0,
        "No fileOffset on $node (${node.runtimeType})");
    return offset;
  }
}

class _Failure implements Exception {
  final String message;

  _Failure([this.message]);

  @override
  String toString() {
    if (message == null) return "Exception";
    return "Exception: $message";
  }
}
