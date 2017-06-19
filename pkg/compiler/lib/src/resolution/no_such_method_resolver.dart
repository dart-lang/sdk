// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/names.dart' show Identifiers, Names;
import '../elements/elements.dart';
import '../js_backend/no_such_method_registry.dart';
import '../tree/tree.dart';

/// AST-based implementation of [NoSuchMethodResolver].
class ResolutionNoSuchMethodResolver implements NoSuchMethodResolver {
  bool hasForwardingSyntax(MethodElement element) {
    // At this point we know that this is signature-compatible with
    // Object.noSuchMethod, but it may have more than one argument as long as
    // it only has one required argument.
    if (!element.hasResolvedAst) {
      // TODO(johnniwinther): Why do we see unresolved elements here?
      return false;
    }
    ResolvedAst resolvedAst = element.resolvedAst;
    if (resolvedAst.kind != ResolvedAstKind.PARSED) {
      return false;
    }
    String param = element.parameters.first.name;
    Statement body = resolvedAst.body;
    Expression expr;
    if (body is Return && body.isArrowBody) {
      expr = body.expression;
    } else if (body is Block &&
        !body.statements.isEmpty &&
        body.statements.nodes.tail.isEmpty) {
      Statement stmt = body.statements.nodes.head;
      if (stmt is Return && stmt.hasExpression) {
        expr = stmt.expression;
      }
    }
    if (expr is Send && expr.isTypeCast) {
      Send sendExpr = expr;
      var typeAnnotation = sendExpr.typeAnnotationFromIsCheckOrCast;
      var typeName = typeAnnotation.asNominalTypeAnnotation()?.typeName;
      if (typeName is Identifier && typeName.source == "dynamic") {
        expr = sendExpr.receiver;
      }
    }
    if (expr is Send &&
        expr.isSuperCall &&
        expr.selector is Identifier &&
        (expr.selector as Identifier).source == Identifiers.noSuchMethod_) {
      var arg = expr.arguments.head;
      if (expr.arguments.tail.isEmpty &&
          arg is Send &&
          arg.argumentsNode == null &&
          arg.receiver == null &&
          arg.selector is Identifier) {
        Identifier selector = arg.selector;
        if (selector.source == param) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasThrowingSyntax(MethodElement element) {
    if (!element.hasResolvedAst) {
      // TODO(johnniwinther): Why do we see unresolved elements here?
      return false;
    }
    ResolvedAst resolvedAst = element.resolvedAst;
    if (resolvedAst.kind != ResolvedAstKind.PARSED) {
      return false;
    }
    Statement body = resolvedAst.body;
    if (body is Return && body.isArrowBody) {
      if (body.expression is Throw) {
        return true;
      }
    } else if (body is Block &&
        !body.statements.isEmpty &&
        body.statements.nodes.tail.isEmpty) {
      if (body.statements.nodes.head is ExpressionStatement) {
        ExpressionStatement stmt = body.statements.nodes.head;
        return stmt.expression is Throw;
      }
    }
    return false;
  }

  MethodElement getSuperNoSuchMethod(MethodElement method) {
    return method.enclosingClass.lookupSuperByName(Names.noSuchMethod_);
  }
}
