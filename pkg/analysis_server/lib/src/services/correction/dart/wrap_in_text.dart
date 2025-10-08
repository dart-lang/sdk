// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class WrapInText extends ResolvedCorrectionProducer {
  WrapInText({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.wrapInText;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Extract the information needed to build the edit.
    //
    var context = _extractContextInformation(node);
    if (context == null) {
      return;
    }
    if (!context.parameterElement.type.isWidgetType) {
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

  static _Context? _extractContextInformation(AstNode node) {
    if (node is Expression) {
      var parent = node.parent;
      if (parent is NamedExpression) {
        if (node.typeOrThrow.isDartCoreString) {
          var parameterElement = parent.name.label.element;
          if (parameterElement is FormalParameterElement) {
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
  final FormalParameterElement parameterElement;

  _Context({required this.stringExpression, required this.parameterElement});
}
