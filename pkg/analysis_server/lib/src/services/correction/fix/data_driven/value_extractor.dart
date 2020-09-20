// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A value extractor used to extract a specified argument from an invocation.
class ArgumentExtractor extends ValueExtractor {
  /// The parameter corresponding to the argument from the original invocation,
  /// or `null` if the value of the argument can't be taken from the original
  /// invocation.
  final ParameterReference parameter;

  /// Initialize a newly created extractor to extract the argument that
  /// corresponds to the given [parameter].
  ArgumentExtractor(this.parameter) : assert(parameter != null);

  @override
  String from(AstNode node, CorrectionUtils utils) {
    var argumentList = _getArgumentList(node);
    if (argumentList != null) {
      var expression = parameter.argumentFrom(argumentList);
      if (expression != null) {
        return utils.getNodeText(expression);
      }
    }
    return null;
  }

  /// Return the argument list associated with the given [node].
  ArgumentList _getArgumentList(AstNode node) {
    if (node is ArgumentList) {
      return node;
    } else if (node is InvocationExpression) {
      return node.argumentList;
    } else if (node is InstanceCreationExpression) {
      return node.argumentList;
    }
    return null;
  }
}

/// An object used to extract an expression from an AST node.
abstract class ValueExtractor {
  /// Return code extracted from the given [node], or `null` if no code could be
  /// extracted.
  String from(AstNode node, CorrectionUtils utils);
}
