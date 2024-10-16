// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

abstract class FlutterParentAndChild extends ResolvedCorrectionProducer {
  FlutterParentAndChild({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  Future<void> swapParentAndChild(
      ChangeBuilder builder,
      InstanceCreationExpression parent,
      InstanceCreationExpression child,
      bool parentHadSingleChild) async {
    // The child must have its own single child.
    AstNode stableChild;
    if (_singleChildInChildren(child) case var first?) {
      stableChild = first;
    } else if (child.childArgument case var childArgument?) {
      stableChild = childArgument;
    } else {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(parent), (builder) {
        var childArgs = child.argumentList;
        var parentArgs = parent.argumentList;
        var childText = utils.getRangeText(range.startStart(child, childArgs));
        var parentText =
            utils.getRangeText(range.startStart(parent, parentArgs));

        var parentIndent = utils.getLinePrefix(parent.offset);
        var childIndent = '$parentIndent  ';

        // Write the beginning of the child.
        builder.write(childText);
        builder.writeln('(');

        // Write all the arguments of the parent.
        // Don't write the "child".
        for (var argument in childArgs.arguments) {
          if (argument != stableChild) {
            var text = utils.getNodeText(argument);
            text = utils.replaceSourceIndent(
              text,
              childIndent,
              parentIndent,
            );
            builder.write(parentIndent);
            builder.write('  ');
            builder.write(text);
            builder.writeln(',');
          }
        }

        // Write the parent as a new child.
        builder.write(parentIndent);
        builder.write('  ');
        builder.write('child: ');
        builder.write(parentText);
        builder.writeln('(');

        // Write all arguments of the parent.
        // Don't write its child/children.
        for (var argument in parentArgs.arguments) {
          if (!argument.isChildArgument && !argument.isChildrenArgument) {
            var text = utils.getNodeText(argument);
            text = utils.replaceSourceIndent(
              text,
              parentIndent,
              childIndent,
            );
            builder.write(childIndent);
            builder.write('  ');
            builder.write(text);
            builder.writeln(',');
          }
        }

        // Write the child(ren) of the "child" now, as the child(ren) of the "parent".
        {
          var text = utils.getNodeText(stableChild);
          if (text.trim().startsWith('child: ')) {
            text = text.substring('child: '.length);
          } else if (text.trim().startsWith('children: ')) {
            text = text.substring('children: '.length);
          }
          builder.write(childIndent);
          builder.write('  ');
          if (parentHadSingleChild) {
            builder.write('child: ');
          } else {
            builder.write('children: [');
            builder.writeln();
            builder.write(childIndent);
            builder.write('    ');
          }
          builder.write(text);
          builder.writeln(',');
        }

        // Close the parent expression.
        builder.write(childIndent);
        if (!parentHadSingleChild) {
          builder.write('  ');
          builder.write(']');
          builder.writeln(',');
          builder.write(childIndent);
        }
        builder.writeln('),');

        // Close the child expression.
        builder.write(parentIndent);
        builder.write(')');
      });
    });
  }

  InstanceCreationExpression? _singleChildInChildren(
      InstanceCreationExpression parent) {
    if (parent.childrenArgument case var childrenArgument?) {
      if (childrenArgument.expression case ListLiteral list) {
        if (list.elements case NodeList(length: 1, first: var first)) {
          if (first is InstanceCreationExpression) {
            return first;
          }
        }
      }
    }
    return null;
  }
}

class FlutterSwapWithChild extends FlutterParentAndChild {
  FlutterSwapWithChild({required super.context});

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_SWAP_WITH_CHILD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parent = node.findInstanceCreationExpression;
    if (parent == null || !parent.isWidgetCreation) {
      return;
    }
    var parentHasSingleChild = true;

    Expression? child;
    if (_singleChildInChildren(parent) case var first?) {
      child = first;
      parentHasSingleChild = false;
    }
    child ??= parent.childArgument?.expression;
    if (child is! InstanceCreationExpression || !child.isWidgetCreation) {
      return;
    }

    await swapParentAndChild(builder, parent, child, parentHasSingleChild);
  }
}
