// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' as ir;

import "../elements/elements.dart" show Element, ErroneousElement;
import "../elements/operators.dart"
    show AssignmentOperator, BinaryOperator, IncDecOperator, UnaryOperator;
import "../elements/resolution_types.dart" show ResolutionDartType;
import "../tree/tree.dart"
    show Expression, NewExpression, Node, NodeList, Operator, Send, SendSet;
import "../universe/call_structure.dart" show CallStructure;
import "../universe/selector.dart" show Selector;

abstract class KernelError {
  // TODO(ahe): Get rid of this method, each error should be handled according
  // to the semantics required by the Dart Language Specification.
  ir.Expression handleError(Expression node);

  ir.Expression errorInvalidBinary(Send node, ErroneousElement error,
      BinaryOperator operator, Node right, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidCompound(Send node, ErroneousElement error,
      AssignmentOperator operator, Node rhs, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidCompoundIndexSet(Send node, ErroneousElement error,
      Node index, AssignmentOperator operator, Node rhs, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidEquals(
      Send node, ErroneousElement error, Node right, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidGet(Send node, ErroneousElement error, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidIndex(
      Send node, ErroneousElement error, Node index, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidIndexPostfix(Send node, ErroneousElement error,
      Node index, IncDecOperator operator, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidIndexPrefix(Send node, ErroneousElement error,
      Node index, IncDecOperator operator, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidIndexSet(
      Send node, ErroneousElement error, Node index, Node rhs, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidInvoke(Send node, ErroneousElement error,
      NodeList arguments, Selector selector, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidNotEquals(
      Send node, ErroneousElement error, Node right, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidPostfix(
      Send node, ErroneousElement error, IncDecOperator operator, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidPrefix(
      Send node, ErroneousElement error, IncDecOperator operator, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidSet(
      Send node, ErroneousElement error, Node rhs, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidSetIfNull(
      Send node, ErroneousElement error, Node rhs, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidUnary(
      Send node, UnaryOperator operator, ErroneousElement error, _) {
    return handleError(node);
  }

  ir.Expression errorNonConstantConstructorInvoke(
      NewExpression node,
      Element element,
      ResolutionDartType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleError(node);
  }

  ir.Expression errorUndefinedBinaryExpression(
      Send node, Node left, Operator operator, Node right, _) {
    return handleError(node);
  }

  ir.Expression errorUndefinedUnaryExpression(
      Send node, Operator operator, Node expression, _) {
    return handleError(node);
  }

  ir.Expression errorUnresolvedFieldInitializer(
      SendSet node, Element element, Node initializer, _) {
    return handleError(node);
  }

  ir.Expression errorUnresolvedSuperConstructorInvoke(
      Send node, Element element, NodeList arguments, Selector selector, _) {
    return handleError(node);
  }

  ir.Expression errorUnresolvedThisConstructorInvoke(
      Send node, Element element, NodeList arguments, Selector selector, _) {
    return handleError(node);
  }

  ir.Expression errorInvalidIndexSetIfNull(
      SendSet node, ErroneousElement error, Node index, Node rhs, _) {
    return handleError(node);
  }
}
