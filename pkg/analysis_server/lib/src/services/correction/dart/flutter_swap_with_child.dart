// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

abstract class FlutterParentAndChild extends CorrectionProducer {
  Future<void> swapParentAndChild(
      ChangeBuilder builder,
      InstanceCreationExpression parent,
      InstanceCreationExpression child) async {
    // The child must have its own child.
    if (flutter.findChildArgument(child) == null) {
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
        var childIndent = parentIndent + '  ';

        // Write the beginning of the child.
        builder.write(childText);
        builder.writeln('(');

        // Write all the arguments of the parent.
        // Don't write the "child".
        Expression stableChild;
        for (var argument in childArgs.arguments) {
          if (flutter.isChildArgument(argument)) {
            stableChild = argument;
          } else {
            var text = utils.getNodeText(argument);
            text = replaceSourceIndent(text, childIndent, parentIndent);
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
        // Don't write its child.
        for (var argument in parentArgs.arguments) {
          if (!flutter.isChildArgument(argument)) {
            var text = utils.getNodeText(argument);
            text = replaceSourceIndent(text, parentIndent, childIndent);
            builder.write(childIndent);
            builder.write('  ');
            builder.write(text);
            builder.writeln(',');
          }
        }

        // Write the child of the "child" now, as the child of the "parent".
        {
          var text = utils.getNodeText(stableChild);
          builder.write(childIndent);
          builder.write('  ');
          builder.write(text);
          builder.writeln(',');
        }

        // Close the parent expression.
        builder.write(childIndent);
        builder.writeln('),');

        // Close the child expression.
        builder.write(parentIndent);
        builder.write(')');
      });
    });
  }
}

class FlutterSwapWithChild extends FlutterParentAndChild {
  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_SWAP_WITH_CHILD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parent = flutter.identifyNewExpression(node);
    if (!flutter.isWidgetCreation(parent)) {
      return;
    }

    var childArgument = flutter.findChildArgument(parent);
    if (childArgument?.expression is! InstanceCreationExpression ||
        !flutter.isWidgetCreation(childArgument.expression)) {
      return;
    }
    InstanceCreationExpression child = childArgument.expression;

    await swapParentAndChild(builder, parent, child);
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static FlutterSwapWithChild newInstance() => FlutterSwapWithChild();
}
