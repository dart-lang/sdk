// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_documentation.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';

/// A computer for the signature at the specified offset of a Dart
/// [CompilationUnit].
class DartUnitSignatureComputer {
  final AstNode? _node;
  final int _offset;
  final DocumentationPreference documentationPreference;
  final DartDocumentationComputer _documentationComputer;

  DartUnitSignatureComputer(
    DartdocDirectiveInfo dartdocInfo,
    CompilationUnit unit,
    this._offset, {
    this.documentationPreference = DocumentationPreference.full,
  }) : _documentationComputer = DartDocumentationComputer(dartdocInfo),
       _node = unit.nodeCovering(offset: _offset);

  bool get offsetIsValid => _node != null;

  /// Returns the computed signature information, maybe `null`.
  SignatureInformation? compute() {
    var argumentAndList = _findArgumentAndList();
    if (argumentAndList == null) {
      return null;
    }
    var (argumentList, argument) = argumentAndList;
    String? name;
    Element2? element;
    List<FormalParameterElement>? parameters;
    var parent = argumentList.parent;
    if (parent is MethodInvocation) {
      name = parent.methodName.name;
      element = ElementLocator.locate2(parent);
      parameters =
          element is FunctionTypedElement2 ? element.formalParameters : null;
    } else if (parent is InstanceCreationExpression) {
      name = parent.constructorName.type.qualifiedName;
      var constructorName = parent.constructorName.name;
      if (constructorName != null) {
        name += '.${constructorName.name}';
      }
      element = ElementLocator.locate2(parent);
      parameters =
          element is FunctionTypedElement2 ? element.formalParameters : null;
    } else if (parent case FunctionExpressionInvocation(
      function: Identifier function,
    )) {
      name = function.name;

      if (function.staticType case FunctionType functionType) {
        // Standard function expression.
        element = function.element;
        parameters = functionType.formalParameters;
      } else if (parent.element case ExecutableElement2 executableElement) {
        // Callable class instance (where we'll look at the `call` method).
        element = executableElement;
        parameters = executableElement.formalParameters;
      }
    }

    if (name == null || element == null || parameters == null) {
      return null;
    }

    // Try to compute the active parameter so the IDE can highlight it.
    int? activeParameterIndex;
    if (argument case Expression(:var correspondingParameter?)) {
      // If we know the active parameter, use its index.
      activeParameterIndex = parameters.indexOf(correspondingParameter);
    } else if (argument is! NamedExpression) {
      // If we're not a named expression, then we can count how many positional
      // parameters there are before us, and then find the index of the same
      // index positional parameter.
      var positionalArgsToSkip =
          argumentList.arguments
              .where((argument) => argument is! NamedExpression)
              .takeWhile((argument) => argument.end < _offset)
              .length;
      for (var i = 0; i < parameters.length; i++) {
        if (parameters[i].isPositional) {
          // This is the first positional parameter after our skips, so this is
          // the active parameter.
          if (positionalArgsToSkip == 0) {
            activeParameterIndex = i;
            break;
          }
          positionalArgsToSkip--;
        }
      }
    }

    var dartdoc = _documentationComputer.computePreferred(
      element,
      documentationPreference,
    );

    return SignatureInformation(
      name: name,
      parameters: parameters,
      argumentList: argumentList,
      activeParameterIndex: activeParameterIndex,
      dartdoc: dartdoc,
    );
  }

  /// Return the closest argument list surrounding the [_node] and the node for
  /// the active argument (if there is one).
  (ArgumentList, AstNode?)? _findArgumentAndList() {
    var node = _node;
    while (node != null) {
      // Certain nodes don't make sense to search above for an argument list
      // (for example when inside a function expression).
      if (node is FunctionExpression) {
        return null;
      }

      if (node is ArgumentList) {
        return (node, null);
      }
      if (node.parent case ArgumentList list) {
        return (list, node);
      }

      node = node.parent;
    }
    return null;
  }
}

/// Information about a function signature.
class SignatureInformation {
  /// The name of the function/method.
  final String name;

  /// The parameters for the function/method.
  final List<FormalParameterElement> parameters;

  /// The current argument list at the invocation site.
  final ArgumentList argumentList;

  /// Documentation for the function/method.
  final String? dartdoc;

  /// The index in [parameters] for the parameter that matches where the offset
  /// was in the invocation list.
  ///
  /// This is only supplied when it can be computed. Positional arguments past
  /// the number of positional parameters or named arguments with no matching
  /// name will not be returned.
  final int? activeParameterIndex;

  SignatureInformation({
    required this.name,
    required this.parameters,
    required this.argumentList,
    required this.activeParameterIndex,
    required this.dartdoc,
  });

  AnalysisGetSignatureResult toLegacyProtocol() {
    return AnalysisGetSignatureResult(
      name,
      parameters.map(_convertParam).toList(),
      dartdoc: dartdoc,
    );
  }

  ParameterInfo _convertParam(FormalParameterElement param) {
    return ParameterInfo(
      param.isOptionalNamed
          ? ParameterKind.OPTIONAL_NAMED
          : param.isOptionalPositional
          ? ParameterKind.OPTIONAL_POSITIONAL
          : param.isRequiredNamed
          ? ParameterKind.REQUIRED_NAMED
          : ParameterKind.REQUIRED_POSITIONAL,
      param.displayName,
      param.type.getDisplayString(),
      defaultValue: param.defaultValueCode,
    );
  }
}
