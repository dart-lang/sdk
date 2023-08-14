// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

/// A computer for the signature at the specified offset of a Dart
/// [CompilationUnit].
class DartUnitSignatureComputer {
  final DartdocDirectiveInfo _dartdocInfo;
  final AstNode? _node;
  late ArgumentList _argumentList;
  final bool _isNonNullableByDefault;
  final DocumentationPreference documentationPreference;

  DartUnitSignatureComputer(
    this._dartdocInfo,
    CompilationUnit unit,
    int offset, {
    this.documentationPreference = DocumentationPreference.full,
  })  : _node = NodeLocator(offset).searchWithin(unit),
        _isNonNullableByDefault = unit.isNonNullableByDefault;

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
    ExecutableElement? execElement;
    final parent = argumentList.parent;
    if (parent is MethodInvocation) {
      name = parent.methodName.name;
      var element = ElementLocator.locate(parent);
      execElement = element is ExecutableElement ? element : null;
    } else if (parent is InstanceCreationExpression) {
      name = parent.constructorName.type.qualifiedName;
      var constructorName = parent.constructorName.name;
      if (constructorName != null) {
        name += '.${constructorName.name}';
      }
      execElement = ElementLocator.locate(parent) as ExecutableElement?;
    }

    if (name == null || execElement == null) {
      return null;
    }

    _argumentList = argumentList;

    final parameters =
        execElement.parameters.map((p) => _convertParam(p)).toList();

    return AnalysisGetSignatureResult(name, parameters,
        dartdoc: DartUnitHoverComputer.computePreferredDocumentation(
            _dartdocInfo, execElement, documentationPreference));
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
        param.type.getDisplayString(withNullability: _isNonNullableByDefault),
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
