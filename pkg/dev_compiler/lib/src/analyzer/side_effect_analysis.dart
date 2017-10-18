// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/error/listener.dart'
    show AnalysisErrorListener, ErrorReporter;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/dart/ast/ast.dart';

/// True is the expression can be evaluated multiple times without causing
/// code execution. This is true for final fields. This can be true for local
/// variables, if:
///
/// * they are not assigned within the [context] scope.
/// * they are not assigned in a function closure anywhere.
///
/// This method is used to avoid creating temporaries in cases where we know
/// we can safely re-evaluate [node] multiple times in [context]. This lets
/// us generate prettier code.
///
/// This method is conservative: it should never return `true` unless it is
/// certain the [node] is stateless, because generated code may rely on the
/// correctness of a `true` value. However it may return `false` for things
/// that are in fact, stateless.
bool isStateless(FunctionBody function, Expression node, [AstNode context]) {
  // `this` and `super` cannot be reassigned.
  if (node is ThisExpression || node is SuperExpression) return true;
  if (node is Identifier) {
    var e = node.staticElement;
    if (e is PropertyAccessorElement) {
      e = (e as PropertyAccessorElement).variable;
    }
    if (e is VariableElement && !e.isSynthetic) {
      if (e.isFinal) return true;
      if (e is LocalVariableElement || e is ParameterElement) {
        // make sure the local isn't mutated in the context.
        return !_isPotentiallyMutated(function, e, context);
      }
    }
  }
  return false;
}

/// Returns true if the local variable is potentially mutated within [context].
/// This accounts for closures that may have been created outside of [context].
bool _isPotentiallyMutated(FunctionBody function, VariableElement e,
    [AstNode context]) {
  if (function is FunctionBodyImpl && function.localVariableInfo == null) {
    // TODO(jmesserly): this is a caching bug in Analyzer. They don't restore
    // this info in some cases.
    return true;
  }

  if (function.isPotentiallyMutatedInClosure(e)) return true;
  if (function.isPotentiallyMutatedInScope(e)) {
    // Need to visit the context looking for assignment to this local.
    if (context != null) {
      var visitor = new _AssignmentFinder(e);
      context.accept(visitor);
      return visitor._potentiallyMutated;
    }
    return true;
  }
  return false;
}

/// Adapted from VariableResolverVisitor. Finds an assignment to a given
/// local variable.
class _AssignmentFinder extends RecursiveAstVisitor {
  final VariableElement _variable;
  bool _potentiallyMutated = false;

  _AssignmentFinder(this._variable);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    // Ignore if qualified.
    AstNode parent = node.parent;
    if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
      return;
    }
    if (parent is PropertyAccess && identical(parent.propertyName, node)) {
      return;
    }
    if (parent is MethodInvocation && identical(parent.methodName, node)) {
      return;
    }
    if (parent is ConstructorName) return;
    if (parent is Label) return;

    if (node.inSetterContext() && node.staticElement == _variable) {
      _potentiallyMutated = true;
    }
  }
}

class ConstFieldVisitor {
  final ConstantVisitor constantVisitor;

  ConstFieldVisitor(AnalysisContext context, {Source dummySource})
      : constantVisitor = new ConstantVisitor(
            new ConstantEvaluationEngine(
                context.typeProvider, context.declaredVariables),
            new ErrorReporter(
                AnalysisErrorListener.NULL_LISTENER, dummySource));

  // TODO(jmesserly): this is used to determine if the field initialization is
  // side effect free. We should make the check more general, as things like
  // list/map literals/regexp are also side effect free and fairly common
  // to use as field initializers.
  bool isFieldInitConstant(VariableDeclaration field) =>
      field.initializer == null || computeConstant(field) != null;

  DartObject computeConstant(VariableDeclaration field) {
    // If the constant is already computed by ConstantEvaluator, just return it.
    VariableElement element = field.element;
    var result = element.computeConstantValue();
    if (result != null) return result;

    // ConstantEvaluator will not compute constants for non-const fields,
    // so run ConstantVisitor for those to figure out if the initializer is
    // actually a constant (and therefore side effect free to evaluate).
    assert(!field.isConst);

    var initializer = field.initializer;
    if (initializer == null) return null;
    return initializer.accept(constantVisitor);
  }
}
