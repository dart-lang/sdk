// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A value extractor used to extract a specified argument of an invocation.
class ArgumentExtractor extends ValueExtractor {
  /// The parameter that defines the argument to be extracted.
  final ParameterReference parameter;

  /// Initialize a newly created extractor to extract the argument that
  /// corresponds to the given [parameter].
  ArgumentExtractor(this.parameter);

  @override
  String from(AstNode node, CorrectionUtils utils) {
    if (node is InvocationExpression) {
      var expression = parameter.argumentFrom(node.argumentList);
      if (expression != null) {
        return utils.getNodeText(expression);
      }
    }
    return null;
  }
}

/// A value extractor that returns a pre-computed piece of code.
class LiteralExtractor extends ValueExtractor {
  /// The code to be returned.
  final String code;

  /// Initialize a newly created  extractor to return the given [code].
  LiteralExtractor(this.code);

  @override
  String from(AstNode node, CorrectionUtils utils) {
    return code;
  }
}

/// An object used to extract an expression from an AST node.
abstract class ValueExtractor {
  /// Return code extracted from the given [node], or `null` if no code could be
  /// extracted.
  String from(AstNode node, CorrectionUtils utils);
}
