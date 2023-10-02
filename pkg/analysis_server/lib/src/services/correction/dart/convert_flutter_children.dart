// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertFlutterChildren extends ResolvedCorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.CONVERT_FLUTTER_CHILDREN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var identifier = node;
    if (identifier is SimpleIdentifier && identifier.name == 'children') {
      var namedExpression = identifier.parent?.parent;
      if (namedExpression is NamedExpression) {
        var expression = namedExpression.expression;
        if (expression is ListLiteral && expression.elements.length == 1) {
          var widget = expression.elements[0];
          if (flutter.isWidgetExpression(widget)) {
            var widgetText = utils.getNodeText(widget);
            var indentOld = utils.getLinePrefix(widget.offset);
            var indentNew = utils.getLinePrefix(namedExpression.offset);
            widgetText = utils.replaceSourceIndent(
              widgetText,
              indentOld,
              indentNew,
              includeLeading: false,
              includeTrailingNewline: false,
            );

            await builder.addDartFileEdit(file, (builder) {
              builder.addReplacement(range.node(namedExpression), (builder) {
                builder.write('child: ');
                builder.write(widgetText);
              });
            });
          }
        }
      }
    }
  }
}
