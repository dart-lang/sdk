// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.tree_elements;

import '../common.dart';
import '../constants/expressions.dart';
import '../elements/resolution_types.dart';
import '../diagnostics/source_span.dart';
import '../elements/elements.dart';
import '../elements/jumps.dart';
import '../tree/tree.dart';
import '../universe/selector.dart' show Selector;

abstract class TreeElements {
  AnalyzableElement get analyzedElement;
  Iterable<SourceSpan> get superUses;

  void forEachConstantNode(f(Node n, ConstantExpression c));

  Element operator [](Node node);
  Map<Node, ResolutionDartType> get typesCache;

  // TODO(johnniwinther): Investigate whether [Node] could be a [Send].
  Selector getSelector(Node node);
  Selector getGetterSelectorInComplexSendSet(SendSet node);
  Selector getOperatorSelectorInComplexSendSet(SendSet node);
  ResolutionDartType getType(Node node);

  /// Returns the for-in loop variable for [node].
  Element getForInVariable(ForIn node);
  void setConstant(Node node, ConstantExpression constant);
  ConstantExpression getConstant(Node node);

  /// Returns the [FunctionElement] defined by [node].
  FunctionElement getFunctionDefinition(FunctionExpression node);

  /// Returns target constructor for the redirecting factory body [node].
  ConstructorElement getRedirectingTargetConstructor(
      RedirectingFactoryBody node);

  /**
   * Returns [:true:] if [node] is a type literal.
   *
   * Resolution marks this by setting the type on the node to be the
   * type that the literal refers to.
   */
  bool isTypeLiteral(Send node);

  /// Returns the type that the type literal [node] refers to.
  ResolutionDartType getTypeLiteralType(Send node);

  /// Returns a list of nodes that potentially mutate [element] anywhere in its
  /// scope.
  List<Node> getPotentialMutations(VariableElement element);

  /// Returns a list of nodes that potentially mutate [element] in [node].
  List<Node> getPotentialMutationsIn(Node node, VariableElement element);

  /// Returns a list of nodes that potentially mutate [element] in a closure.
  List<Node> getPotentialMutationsInClosure(VariableElement element);

  /// Returns a list of nodes that access [element] within a closure in [node].
  List<Node> getAccessesByClosureIn(Node node, VariableElement element);

  /// Returns the jump target defined by [node].
  JumpTarget getTargetDefinition(Node node);

  /// Returns the jump target of the [node].
  JumpTarget getTargetOf(GotoStatement node);

  /// Returns the label defined by [node].
  LabelDefinition getLabelDefinition(Label node);

  /// Returns the label that [node] targets.
  LabelDefinition getTargetLabel(GotoStatement node);

  /// `true` if the [analyzedElement]'s source code contains a [TryStatement].
  bool get containsTryStatement;

  /// Returns native data stored with [node].
  getNativeData(Node node);
}
