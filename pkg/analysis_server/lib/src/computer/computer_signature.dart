// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart'
    show AnalysisGetSignatureResult;
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

/**
 * A computer for the signature at the specified offset of a Dart [CompilationUnit].
 */
class DartUnitSignatureComputer {
  final CompilationUnit _unit;
  final int _offset;

  DartUnitSignatureComputer(this._unit, this._offset);

  /**
   * Returns the computed signature information, maybe `null`.
   */
  AnalysisGetSignatureResult compute() {
    AstNode node = new NodeLocator(_offset).searchWithin(_unit);
    if (node == null) {
      return null;
    }

    // Find the closest argument list.
    while (node != null && !(node is ArgumentList)) {
      node = node.parent;
    }

    if (node == null) {
      return null;
    }

    final args = node;
    String name;
    ExecutableElement execElement;
    if (args.parent is MethodInvocation) {
      MethodInvocation method = args.parent;
      name = method.methodName.name;
      execElement = ElementLocator.locate(method) as ExecutableElement;
    }

    if (execElement == null) {
      return null;
    }

    final parameters =
        execElement.parameters.map((p) => _convertParam(p)).toList();

    return new AnalysisGetSignatureResult(name,
        DartUnitHoverComputer.computeDocumentation(execElement), parameters, 0);
  }

  ParameterInfo _convertParam(ParameterElement param) {
    return new ParameterInfo(
        param.isOptionalPositional
            ? ParameterKind.OPTIONAL
            : param.isPositional ? ParameterKind.REQUIRED : ParameterKind.NAMED,
        param.displayName,
        param.type.displayName);
  }
}
