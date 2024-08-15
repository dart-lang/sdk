// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

/// A computer for the signature at the specified offset of a Dart
/// [CompilationUnit].
class DartUnitSignatureComputer {
  final DartdocDirectiveInfo _dartdocInfo;
  final AstNode? _node;
  late ArgumentList _argumentList;
  final DocumentationPreference documentationPreference;

  DartUnitSignatureComputer(
    this._dartdocInfo,
    CompilationUnit unit,
    int offset, {
    this.documentationPreference = DocumentationPreference.full,
  }) : _node = NodeLocator(offset).searchWithin(unit);

  /// The [ArgumentList] node located by [compute].
  ArgumentList get argumentList => _argumentList;

  bool get offsetIsValid => _node != null;

  /// Returns the computed signature information, maybe `null`.
  AnalysisGetSignatureResult? compute() {
    var argumentList = _findArgumentList();
    if (argumentList == null) {
      return null;
    }
    String? name;
    Element? element;
    List<ParameterElement>? parameters;
    var parent = argumentList.parent;
    if (parent is MethodInvocation) {
      name = parent.methodName.name;
      element = ElementLocator.locate(parent);
      parameters = element is FunctionTypedElement ? element.parameters : null;
    } else if (parent is InstanceCreationExpression) {
      name = parent.constructorName.type.qualifiedName;
      var constructorName = parent.constructorName.name;
      if (constructorName != null) {
        name += '.${constructorName.name}';
      }
      element = ElementLocator.locate(parent);
      parameters = element is FunctionTypedElement ? element.parameters : null;
    } else if (parent
        case FunctionExpressionInvocation(function: Identifier function)) {
      name = function.name;

      if (function.staticType case FunctionType functionType) {
        // Standard function expression.
        element = function.staticElement;
        parameters = functionType.parameters;
      } else if (parent.staticElement case ExecutableElement staticElement) {
        // Callable class instance (where we'll look at the `call` method).
        element = staticElement;
        parameters = staticElement.parameters;
      }
    }

    if (name == null || element == null || parameters == null) {
      return null;
    }

    _argumentList = argumentList;
    var convertedParameters = parameters.map((p) => _convertParam(p)).toList();
    var dartdoc = DartUnitHoverComputer.computePreferredDocumentation(
      _dartdocInfo,
      element,
      documentationPreference,
    );

    return AnalysisGetSignatureResult(
      name,
      convertedParameters,
      dartdoc: dartdoc,
    );
  }

  ParameterInfo _convertParam(ParameterElement param) {
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
        defaultValue: param.defaultValueCode);
  }

  /// Return the closest argument list surrounding the [_node].
  ArgumentList? _findArgumentList() {
    var node = _node;
    while (node != null && node is! ArgumentList) {
      // Certain nodes don't make sense to search above for an argument list
      // (for example when inside a function expression).
      if (node is FunctionExpression) {
        return null;
      }
      node = node.parent;
    }
    return node as ArgumentList?;
  }
}
