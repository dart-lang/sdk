// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class WrapInText extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.WRAP_IN_TEXT;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    //
    // Extract the information needed to build the edit.
    //
    var value = _findStringToWrap(node);
    if (value == null) {
      return;
    }
    var parameter = (value.parent as Expression).staticParameterElement;
    if (parameter == null || !flutter.isWidget(parameter.type.element)) {
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    var literalSource = utils.getNodeText(value);
    //
    // Build the edit.
    //
    await builder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(value), 'Text($literalSource)');
    });
  }

  /// Return the expression that should be wrapped in an invocation of the
  /// constructor for `Text`.
  Expression _findStringToWrap(AstNode node) {
    if (node is SimpleIdentifier) {
      var label = node.parent;
      if (label is Label) {
        var namedExpression = label.parent;
        if (namedExpression is NamedExpression) {
          var expression = namedExpression.expression;
          if (expression.staticType.isDartCoreString) {
            return expression;
          }
        }
      }
    }
    return null;
  }
}
