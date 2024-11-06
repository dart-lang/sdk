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
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

/// A computer for the signature at the specified offset of a Dart
/// [CompilationUnit].
class DartUnitSignatureComputer {
  final AstNode? _node;
  late ArgumentList _argumentList;
  final DocumentationPreference documentationPreference;
  final DartDocumentationComputer _documentationComputer;

  DartUnitSignatureComputer(
    DartdocDirectiveInfo dartdocInfo,
    CompilationUnit unit,
    int offset, {
    this.documentationPreference = DocumentationPreference.full,
  }) : _documentationComputer = DartDocumentationComputer(dartdocInfo),
       _node = NodeLocator(offset).searchWithin(unit);

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

    _argumentList = argumentList;
    var convertedParameters = parameters.map((p) => _convertParam(p)).toList();
    var dartdoc = _documentationComputer.computePreferred2(
      element,
      documentationPreference,
    );

    return AnalysisGetSignatureResult(
      name,
      convertedParameters,
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
