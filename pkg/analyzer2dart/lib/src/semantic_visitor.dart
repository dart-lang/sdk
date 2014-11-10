// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.semantic_visitor;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/source.dart';

import 'util.dart';
import 'identifier_semantics.dart';

/// An AST visitor which uses the [AccessSemantics] of invocations and accesses
/// to fine-grain visitor methods.
abstract class SemanticVisitor<R> extends RecursiveAstVisitor<R> {

  Source get currentSource;

  void reportMessage(AstNode node, String message) {
    reportSourceMessage(currentSource, node, message);
  }

  giveUp(AstNode node, String message) {
    reportMessage(node, message);
    throw new UnimplementedError(message);
  }

  bool invariant(AstNode node, condition, String message) {
    if (condition is Function) {
      condition = condition();
    }
    if (!condition) {
      reportMessage(node, message);
      return false;
    }
    return true;
  }

  R visitDynamicInvocation(MethodInvocation node,
                           AccessSemantics semantics) {
    return giveUp(node, 'visitDynamicInvocation of $semantics');
  }

  R visitLocalFunctionInvocation(MethodInvocation node,
                                 AccessSemantics semantics) {
    return giveUp(node, 'visitLocalFunctionInvocation of $semantics');
  }

  R visitLocalVariableInvocation(MethodInvocation node,
                                 AccessSemantics semantics) {
    return giveUp(node, 'visitLocalVariableInvocation of $semantics');
  }

  R visitParameterInvocation(MethodInvocation node,
                             AccessSemantics semantics) {
    return giveUp(node, 'visitParameterInvocation of $semantics');
  }

  R visitStaticFieldInvocation(MethodInvocation node,
                               AccessSemantics semantics) {
    return giveUp(node, 'visitStaticFieldInvocation of $semantics');
  }

  R visitStaticMethodInvocation(MethodInvocation node,
                                AccessSemantics semantics) {
    return giveUp(node, 'visitStaticMethodInvocation of $semantics');
  }

  R visitStaticPropertyInvocation(MethodInvocation node,
                                  AccessSemantics semantics) {
    return giveUp(node, 'visitStaticPropertyInvocation of $semantics');
  }

  @override
  R visitMethodInvocation(MethodInvocation node) {
    if (node.target != null) {
      node.target.accept(this);
    }
    node.argumentList.accept(this);
    return handleMethodInvocation(node);
  }

  R handleMethodInvocation(MethodInvocation node) {
    AccessSemantics semantics = node.accept(ACCESS_SEMANTICS_VISITOR);
    switch (semantics.kind) {
      case AccessKind.DYNAMIC:
        return visitDynamicInvocation(node, semantics);
      case AccessKind.LOCAL_FUNCTION:
        return visitLocalFunctionInvocation(node, semantics);
      case AccessKind.LOCAL_VARIABLE:
        return visitLocalVariableInvocation(node, semantics);
      case AccessKind.PARAMETER:
        return visitParameterInvocation(node, semantics);
      case AccessKind.STATIC_FIELD:
        return visitStaticFieldInvocation(node, semantics);
      case AccessKind.STATIC_METHOD:
        return visitStaticMethodInvocation(node, semantics);
      case AccessKind.STATIC_PROPERTY:
        return visitStaticPropertyInvocation(node, semantics);
      default:
        // Unexpected access kind.
        return giveUp(node,
            'Unexpected ${semantics} in visitMethodInvocation.');
    }
  }

  @override
  R visitPropertyAccess(PropertyAccess node) {
    if (node.target != null) {
      node.target.accept(this);
    }
    return handlePropertyAccess(node);
  }

  R handlePropertyAccess(PropertyAccess node) {
    return _handlePropertyAccess(node, node.accept(ACCESS_SEMANTICS_VISITOR));
  }

  @override
  R visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    return handlePrefixedIdentifier(node);
  }

  R handlePrefixedIdentifier(PrefixedIdentifier node) {
    return _handlePropertyAccess(node, node.accept(ACCESS_SEMANTICS_VISITOR));
  }

  @override
  R visitSimpleIdentifier(SimpleIdentifier node) {
    AccessSemantics semantics = node.accept(ACCESS_SEMANTICS_VISITOR);
    if (semantics != null) {
      return _handlePropertyAccess(node, semantics);
    } else {
      return null;
    }
  }

  R visitDynamicAccess(AstNode node, AccessSemantics semantics) {
    return giveUp(node, 'visitDynamicAccess of $semantics');
  }

  R visitLocalFunctionAccess(AstNode node, AccessSemantics semantics) {
    return giveUp(node, 'visitLocalFunctionAccess of $semantics');
  }

  R visitLocalVariableAccess(AstNode node, AccessSemantics semantics) {
    return giveUp(node, 'visitLocalVariableAccess of $semantics');
  }

  R visitParameterAccess(AstNode node, AccessSemantics semantics) {
    return giveUp(node, 'visitParameterAccess of $semantics');
  }

  R visitStaticFieldAccess(AstNode node, AccessSemantics semantics) {
    return giveUp(node, 'visitStaticFieldAccess of $semantics');
  }

  R visitStaticMethodAccess(AstNode node, AccessSemantics semantics) {
    return giveUp(node, 'visitStaticMethodAccess of $semantics');
  }

  R visitStaticPropertyAccess(AstNode node, AccessSemantics semantics) {
    return giveUp(node, 'visitStaticPropertyAccess of $semantics');
  }

  R visitToplevelClassAccess(AstNode node, AccessSemantics semantics) {
    return giveUp(node, 'visitToplevelClassAccess of $semantics');
  }

  R visitTypeParameterAccess(AstNode node, AccessSemantics semantics) {
    return giveUp(node, 'visitTypeParameterAccess of $semantics');
  }

  R _handlePropertyAccess(AstNode node, AccessSemantics semantics) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC:
        return visitDynamicAccess(node, semantics);
      case AccessKind.LOCAL_FUNCTION:
        return visitLocalFunctionAccess(node, semantics);
      case AccessKind.LOCAL_VARIABLE:
        return visitLocalVariableAccess(node, semantics);
      case AccessKind.PARAMETER:
        return visitParameterAccess(node, semantics);
      case AccessKind.STATIC_FIELD:
        return visitStaticFieldAccess(node, semantics);
      case AccessKind.STATIC_METHOD:
        return visitStaticMethodAccess(node, semantics);
      case AccessKind.STATIC_PROPERTY:
        return visitStaticPropertyAccess(node, semantics);
      case AccessKind.TOPLEVEL_CLASS:
        return visitToplevelClassAccess(node, semantics);
      case AccessKind.TYPE_PARAMETER:
        return visitTypeParameterAccess(node, semantics);
      default:
        // Unexpected access kind.
        return giveUp(node,
            'Unexpected ${semantics} in _handlePropertyAccess.');
    }
  }

  R visitDynamicPropertyAssignment(AssignmentExpression node,
                                   AccessSemantics semantics) {
    return giveUp(node, 'visitDynamicPropertyAssignment of $semantics');
  }

  R visitLocalFunctionAssignment(AssignmentExpression node,
                                 AccessSemantics semantics) {
    return giveUp(node, 'visitLocalFunctionAssignment of $semantics');
  }

  R visitLocalVariableAssignment(AssignmentExpression node,
                                 AccessSemantics semantics) {
    return giveUp(node, 'visitLocalVariableAssignment of $semantics');
  }

  R visitParameterAssignment(AssignmentExpression node,
                             AccessSemantics semantics) {
    return giveUp(node, 'visitParameterAssignment of $semantics');
  }

  R visitStaticFieldAssignment(AssignmentExpression node,
                               AccessSemantics semantics) {
    return giveUp(node, 'visitStaticFieldAssignment of $semantics');
  }

  R visitStaticMethodAssignment(AssignmentExpression node,
                                AccessSemantics semantics) {
    return giveUp(node, 'visitStaticMethodAssignment of $semantics');
  }

  R visitStaticPropertyAssignment(AssignmentExpression node,
                                  AccessSemantics semantics) {
    return giveUp(node, 'visitStaticPropertyAssignment of $semantics');
  }

  @override
  R visitAssignmentExpression(AssignmentExpression node) {
    super.visitAssignmentExpression(node);
    return handleAssignmentExpression(node);
  }

  R handleAssignmentExpression(AssignmentExpression node) {
    AccessSemantics semantics =
        node.leftHandSide.accept(ACCESS_SEMANTICS_VISITOR);
    if (semantics == null) {
      return giveUp(node, 'handleAssignmentExpression with no AccessSemantics');
    } else {
      switch (semantics.kind) {
        case AccessKind.DYNAMIC:
          return visitDynamicPropertyAssignment(node, semantics);
        case AccessKind.LOCAL_FUNCTION:
          return visitLocalFunctionAssignment(node, semantics);
        case AccessKind.LOCAL_VARIABLE:
          return visitLocalVariableAssignment(node, semantics);
        case AccessKind.PARAMETER:
          return visitParameterAssignment(node, semantics);
        case AccessKind.STATIC_FIELD:
          return visitStaticFieldAssignment(node, semantics);
        case AccessKind.STATIC_METHOD:
          return visitStaticMethodAssignment(node, semantics);
        case AccessKind.STATIC_PROPERTY:
          return visitStaticPropertyAssignment(node, semantics);
        default:
          // Unexpected access kind.
          return giveUp(node,
              'Unexpected ${semantics} in _handlePropertyAccess.');
      }
    }
  }
}
