// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Reports, under `strict-inference`, that the type arguments for invoking or
/// instantiating the value of [expression] can't be inferred.
///
/// For example `(m ?? n)()` and `g()()`, where [expression] is `m ?? n` and
/// `g()`, or `h(g())` that instantiates the generic function returned by
/// `g()`. A name, for example `m` in `m()` or `f` in `use(callback: f)`, is
/// reported as the invocation of that name.
void reportExpressionInferenceFailure(
  DiagnosticReporter diagnosticReporter,
  Expression expression,
) {
  if (expression is NameExpression) {
    reportFunctionInvocationInferenceFailure(
      diagnosticReporter,
      entity: expression,
      name: expression.name.lexeme,
      invokedElement: expression.resolution?.elementOrRecovery,
      invokedType: expression.typeOrThrow,
    );
    return;
  }
  diagnosticReporter.report(
    diag.inferenceFailureOnGenericInvocation
        .withArguments(function: expression.typeOrThrow.getDisplayString())
        .at(expression),
  );
}

/// Reports, under `strict-inference`, that the type arguments of the
/// invocation of the function or method [name] can't be inferred, unless the
/// invoked declaration has `@optionalTypeArgs`.
///
/// The [invokedElement] is `null` if the invoked entity has no declaration,
/// for example `call` of a function type.
void reportFunctionInvocationInferenceFailure(
  DiagnosticReporter diagnosticReporter, {
  required SyntacticEntity entity,
  required String name,
  required Element? invokedElement,
  required DartType invokedType,
}) {
  // Without a declaration, only the type alias can have `@optionalTypeArgs`.
  var annotatedElement = invokedElement ?? invokedType.alias?.element;
  if (annotatedElement != null && _hasOptionalTypeArgs(annotatedElement)) {
    return;
  }
  diagnosticReporter.report(
    diag.inferenceFailureOnFunctionInvocation
        .withArguments(function: name)
        .at(entity),
  );
}

bool _hasOptionalTypeArgs(Element element) {
  if (element is VariableElement) {
    // For variable elements, check the declaration of their type or its
    // alias in addition to the variable itself.
    var type = element.type;
    var typeElement = type is InterfaceType ? type.element : null;
    if (typeElement != null && typeElement.metadata.hasOptionalTypeArgs) {
      return true;
    }
    var typeAliasElement = type.alias?.element;
    if (typeAliasElement != null &&
        typeAliasElement.metadata.hasOptionalTypeArgs) {
      return true;
    }
  }
  return element.metadata.hasOptionalTypeArgs;
}
