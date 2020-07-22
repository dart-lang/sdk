// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterRemoveWidget extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_REMOVE_WIDGET;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetCreation = flutter.identifyNewExpression(node);
    if (widgetCreation == null) {
      return;
    }

    // Prepare the list of our children.
    var childrenArgument = flutter.findChildrenArgument(widgetCreation);
    if (childrenArgument != null) {
      var childrenExpression = childrenArgument?.expression;
      if (childrenExpression is ListLiteral &&
          childrenExpression.elements.isNotEmpty) {
        await _removeChildren(
            builder, widgetCreation, childrenExpression.elements);
      }
    } else {
      var childArgument = flutter.findChildArgument(widgetCreation);
      if (childArgument != null) {
        await _removeChild(builder, widgetCreation, childArgument);
      }
    }
  }

  Future<void> _removeChild(
      ChangeBuilder builder,
      InstanceCreationExpression widgetCreation,
      NamedExpression childArgument) async {
    // child: ThisWidget(child: ourChild)
    // children: [foo, ThisWidget(child: ourChild), bar]
    await builder.addDartFileEdit(file, (builder) {
      var childExpression = childArgument.expression;
      var childText = utils.getNodeText(childExpression);
      var indentOld = utils.getLinePrefix(childExpression.offset);
      var indentNew = utils.getLinePrefix(widgetCreation.offset);
      childText = replaceSourceIndent(childText, indentOld, indentNew);
      builder.addSimpleReplacement(range.node(widgetCreation), childText);
    });
  }

  Future<void> _removeChildren(
      ChangeBuilder builder,
      InstanceCreationExpression widgetCreation,
      List<CollectionElement> childrenExpressions) async {
    // We can inline the list of our children only into another list.
    var widgetParentNode = widgetCreation.parent;
    if (childrenExpressions.length > 1 && widgetParentNode is! ListLiteral) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      var firstChild = childrenExpressions.first;
      var lastChild = childrenExpressions.last;
      var childText = utils.getRangeText(range.startEnd(firstChild, lastChild));
      var indentOld = utils.getLinePrefix(firstChild.offset);
      var indentNew = utils.getLinePrefix(widgetCreation.offset);
      childText = replaceSourceIndent(childText, indentOld, indentNew);
      builder.addSimpleReplacement(range.node(widgetCreation), childText);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static FlutterRemoveWidget newInstance() => FlutterRemoveWidget();
}
