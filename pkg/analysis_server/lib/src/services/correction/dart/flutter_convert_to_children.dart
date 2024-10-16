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

class FlutterConvertToChildren extends ResolvedCorrectionProducer {
  FlutterConvertToChildren({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_CONVERT_TO_CHILDREN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Find "child: widget" under selection.
    NamedExpression namedExp;
    {
      var node = this.node;
      var parent = node.parent;
      var parent2 = parent?.parent;
      if (node is SimpleIdentifier &&
          parent is Label &&
          parent2 is NamedExpression &&
          node.name == 'child' &&
          node.element != null &&
          parent2.expression.isWidgetExpression) {
        namedExp = parent2;
      } else {
        return;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      _convertFlutterChildToChildren(namedExp, eol, utils.getNodeText,
          utils.getLinePrefix, utils.getText, builder);
    });
  }

  void _convertFlutterChildToChildren(
      NamedExpression namedExp,
      String eol,
      String Function(Expression) getNodeText,
      String Function(int) getLinePrefix,
      String Function(int, int) getText,
      FileEditBuilder builder) {
    var childArg = namedExp.expression;
    var childLoc = namedExp.offset + 'child'.length;
    builder.addSimpleInsertion(childLoc, 'ren');
    var listLoc = childArg.offset;
    var childArgSrc = getNodeText(childArg);
    if (!childArgSrc.contains(eol)) {
      builder.addSimpleInsertion(listLoc, '[');
      builder.addSimpleInsertion(listLoc + childArg.length, ']');
    } else {
      var newlineLoc = childArgSrc.lastIndexOf(eol);
      if (newlineLoc == childArgSrc.length) {
        newlineLoc -= 1;
      }
      var indentOld = getLinePrefix(childArg.offset + eol.length + newlineLoc);
      var indentNew = '$indentOld${utils.oneIndent}';
      // The separator includes 'child:' but that has no newlines.
      var separator =
          getText(namedExp.offset, childArg.offset - namedExp.offset);
      var prefix = separator.contains(eol) ? '' : '$eol$indentNew';
      if (prefix.isEmpty) {
        builder.addSimpleInsertion(namedExp.offset + 'child:'.length, ' [');
        var argOffset = childArg.offset;
        builder
            .addDeletion(range.startOffsetEndOffset(argOffset - 2, argOffset));
      } else {
        builder.addSimpleInsertion(listLoc, '[');
      }
      var newChildArgSrc = utils.replaceSourceIndent(
        childArgSrc,
        indentOld,
        indentNew,
      );
      newChildArgSrc = '$prefix$newChildArgSrc,$eol$indentOld]';
      builder.addSimpleReplacement(range.node(childArg), newChildArgSrc);
    }
  }
}
