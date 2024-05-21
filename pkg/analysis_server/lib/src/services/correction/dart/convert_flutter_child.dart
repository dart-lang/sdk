// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertFlutterChild extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_FLUTTER_CHILD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var named = node.findArgumentNamed('child');
    if (named == null) {
      return;
    }

    // child: widget
    var expression = named.expression;
    if (expression.isWidgetExpression) {
      await builder.addDartFileEdit(file, (builder) {
        var childLoc = named.offset + 'child'.length;
        builder.addSimpleInsertion(childLoc, 'ren');
        var listLoc = expression.offset;
        var childArgSrc = utils.getNodeText(expression);
        if (!childArgSrc.contains(eol)) {
          builder.addSimpleInsertion(listLoc, '[');
          builder.addSimpleInsertion(listLoc + expression.length, ']');
        } else {
          var newlineLoc = childArgSrc.lastIndexOf(eol);
          if (newlineLoc == childArgSrc.length) {
            newlineLoc -= 1;
          }
          var indentOld =
              utils.getLinePrefix(expression.offset + eol.length + newlineLoc);
          var indentNew = '$indentOld${utils.oneIndent}';
          // The separator includes 'child:' but that has no newlines.
          var separator =
              utils.getText(named.offset, expression.offset - named.offset);
          var prefix = separator.contains(eol) ? '' : '$eol$indentNew';
          if (prefix.isEmpty) {
            builder.addSimpleInsertion(named.offset + 'child:'.length, ' [');
            builder.addDeletion(SourceRange(expression.offset - 2, 2));
          } else {
            builder.addSimpleInsertion(listLoc, '[');
          }
          var newChildArgSrc = utils.replaceSourceIndent(
            childArgSrc,
            indentOld,
            indentNew,
          );
          newChildArgSrc = '$prefix$newChildArgSrc,$eol$indentOld]';
          builder.addSimpleReplacement(range.node(expression), newChildArgSrc);
        }
      });
      return;
    }

    // child: [widget1, widget2]
    if (expression is ListLiteral &&
        expression.elements.every((e) => e.isWidgetExpression)) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(named.name), 'children:');
      });
    }
  }
}
