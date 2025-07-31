// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines AST visitors that support useful patterns for visiting the nodes in
/// an [AST structure](ast.dart).
///
/// Dart is an evolving language, and the AST structure must evolved with it.
/// When the AST structure changes, the visitor interface will sometimes change
/// as well. If it is desirable to get a compilation error when the structure of
/// the AST has been modified, then you should consider implementing the
/// interface [AstVisitor] directly. Doing so will ensure that changes that
/// introduce new classes of nodes will be flagged. (Of course, not all changes
/// to the AST structure require the addition of a new class of node, and hence
/// cannot be caught this way.)
///
/// But if automatic detection of these kinds of changes is not necessary then
/// you will probably want to extend one of the classes in this library because
/// doing so will simplify the task of writing your visitor and guard against
/// future changes to the AST structure. For example, the [RecursiveAstVisitor]
/// automates the process of visiting all of the descendants of a node.
library;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';

part 'visitor.g.dart';

/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure, similar to [GeneralizingAstVisitor]. This visitor uses a
/// breadth-first ordering rather than the depth-first ordering of
/// [GeneralizingAstVisitor].
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general visit method. Failure to
/// do so will cause the visit methods for superclasses of the node to not be
/// invoked and will cause the children of the visited node to not be visited.
///
/// In addition, subclasses should <b>not</b> explicitly visit the children of a
/// node, but should ensure that the method [visitNode] is used to visit the
/// children (either directly or indirectly). Failure to do will break the order
/// in which nodes are visited.
///
/// Note that, unlike other visitors that begin to visit a structure of nodes by
/// asking the root node in the structure to accept the visitor, this visitor
/// requires that clients start the visit by invoking the method [visitAllNodes]
/// defined on the visitor with the root node as the argument:
///
///     visitor.visitAllNodes(rootNode);
///
/// Clients may extend this class.
class BreadthFirstVisitor<R> extends GeneralizingAstVisitor<R> {
  /// A queue holding the nodes that have not yet been visited in the order in
  /// which they ought to be visited.
  final Queue<AstNode> _queue = Queue<AstNode>();

  /// A visitor, used to visit the children of the current node, that will add
  /// the nodes it visits to the [_queue].
  late final _BreadthFirstChildVisitor _childVisitor;

  /// Initialize a newly created visitor.
  BreadthFirstVisitor() {
    _childVisitor = _BreadthFirstChildVisitor(this);
  }

  /// Visit all nodes in the tree starting at the given [root] node, in
  /// breadth-first order.
  void visitAllNodes(AstNode root) {
    _queue.add(root);
    while (_queue.isNotEmpty) {
      AstNode next = _queue.removeFirst();
      next.accept(this);
    }
  }

  @override
  R? visitNode(AstNode node) {
    node.visitChildren(_childVisitor);
    return null;
  }
}

/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure. For each node that is visited, the corresponding visit method on
/// one or more other visitors (the 'delegates') will be invoked.
///
/// For example, if an instance of this class is created with two delegates V1
/// and V2, and that instance is used to visit the expression 'x + 1', then the
/// following visit methods will be invoked:
/// 1. V1.visitBinaryExpression
/// 2. V2.visitBinaryExpression
/// 3. V1.visitSimpleIdentifier
/// 4. V2.visitSimpleIdentifier
/// 5. V1.visitIntegerLiteral
/// 6. V2.visitIntegerLiteral
///
/// Clients may not extend, implement or mix-in this class.
class DelegatingAstVisitor<T> extends UnifyingAstVisitor<T> {
  /// The delegates whose visit methods will be invoked.
  final Iterable<AstVisitor<T>> delegates;

  /// Initialize a newly created visitor to use each of the given delegate
  /// visitors to visit the nodes of an AST structure.
  const DelegatingAstVisitor(this.delegates);

  @override
  T? visitNode(AstNode node) {
    delegates.forEach(node.accept);
    node.visitChildren(this);
    return null;
  }
}

/// A helper class used to implement the correct order of visits for a
/// [BreadthFirstVisitor].
class _BreadthFirstChildVisitor extends UnifyingAstVisitor<void> {
  /// The [BreadthFirstVisitor] being helped by this visitor.
  final BreadthFirstVisitor outerVisitor;

  /// Initialize a newly created visitor to help the [outerVisitor].
  _BreadthFirstChildVisitor(this.outerVisitor);

  @override
  void visitNode(AstNode node) {
    outerVisitor._queue.add(node);
  }
}
