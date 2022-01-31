// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class WrapInText extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.WRAP_IN_TEXT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Extract the information needed to build the edit.
    //
    var context = _extractContextInformation(node);
    if (context == null) {
      return;
    }
    if (!flutter.isWidgetType(context.parameterElement.type)) {
      return;
    }

    //
    // Extract the information needed to build the edit.
    //
    var stringExpressionCode = utils.getNodeText(context.stringExpression);

    //
    // Build the edit.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(context.stringExpression),
        'Text($stringExpressionCode)',
      );
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static WrapInText newInstance() => WrapInText();

  static _Context? _extractContextInformation(AstNode node) {
    if (node is Expression) {
      var parent = node.parent;
      if (parent is NamedExpression) {
        if (node.typeOrThrow.isDartCoreString) {
          var parameterElement = parent.name.label.staticElement;
          if (parameterElement is ParameterElement) {
            return _Context(
              stringExpression: node,
              parameterElement: parameterElement,
            );
          }
        }
      }
    }

    return null;
  }
}

class _Context {
  final Expression stringExpression;
  final ParameterElement parameterElement;

  _Context({
    required this.stringExpression,
    required this.parameterElement,
  });
}
