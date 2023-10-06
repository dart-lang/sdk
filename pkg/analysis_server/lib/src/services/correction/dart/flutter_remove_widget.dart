// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterRemoveWidget extends ResolvedCorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_REMOVE_WIDGET;

  /// todo(pq): find out why overlapping edits are not being applied (and enable)
  @override
  bool get canBeAppliedInBulk => false;

  @override
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_CONTAINER;

  @override
  FixKind? get multiFixKind => DartFixKind.REMOVE_UNNECESSARY_CONTAINER_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetCreation = flutter.identifyNewExpression(node);
    if (widgetCreation == null) {
      return;
    }

    // Prepare the list of our children.
    var childrenArgument = flutter.findChildrenArgument(widgetCreation);
    if (childrenArgument != null) {
      var childrenExpression = childrenArgument.expression;
      if (childrenExpression is ListLiteral &&
          childrenExpression.elements.isNotEmpty) {
        await _removeChildren(
            builder, widgetCreation, childrenExpression.elements);
      }
    } else {
      var childArgument = flutter.findChildArgument(widgetCreation);
      if (childArgument != null) {
        await _removeSingle(builder, widgetCreation, childArgument.expression);
      } else {
        var builderArgument = flutter.findBuilderArgument(widgetCreation);
        if (builderArgument != null) {
          await _removeBuilder(builder, widgetCreation, builderArgument);
        }
      }
    }
  }

  Future<void> _removeBuilder(
      ChangeBuilder builder,
      InstanceCreationExpression widgetCreation,
      NamedExpression builderArgument) async {
    var builderExpression = builderArgument.expression;
    if (builderExpression is! FunctionExpression) return;
    var parameterElement =
        builderExpression.parameters?.parameters.firstOrNull?.declaredElement;
    if (parameterElement == null) return;

    var visitor = _UsageFinder(parameterElement);
    var body = builderExpression.body;
    body.visitChildren(visitor);
    if (visitor.used) return;

    if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length != 1) return;
      var statement = statements.first;
      if (statement is! ReturnStatement) return;
      var expression = statement.expression;
      if (expression == null) return;
      await _removeSingle(builder, widgetCreation, expression);
    } else if (body is ExpressionFunctionBody) {
      await _removeSingle(builder, widgetCreation, body.expression);
    }
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
      childText = utils.replaceSourceIndent(
        childText,
        indentOld,
        indentNew,
      );
      builder.addSimpleReplacement(range.node(widgetCreation), childText);
    });
  }

  Future<void> _removeSingle(
    ChangeBuilder builder,
    InstanceCreationExpression widgetCreation,
    Expression expression,
  ) async {
    await builder.addDartFileEdit(file, (builder) {
      var childText = utils.getNodeText(expression);
      var indentOld = utils.getLinePrefix(expression.offset);
      var indentNew = utils.getLinePrefix(widgetCreation.offset);
      childText = utils.replaceSourceIndent(
        childText,
        indentOld,
        indentNew,
      );
      builder.addSimpleReplacement(range.node(widgetCreation), childText);
    });
  }
}

class _UsageFinder extends RecursiveAstVisitor<void> {
  final Element element;
  bool used = false;

  _UsageFinder(this.element);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.writeOrReadElement == element) {
      used = true;
    }
  }
}
