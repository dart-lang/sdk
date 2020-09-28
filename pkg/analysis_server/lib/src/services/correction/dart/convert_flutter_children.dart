// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertFlutterChildren extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.CONVERT_FLUTTER_CHILDREN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is SimpleIdentifier &&
        node.name == 'children' &&
        node.parent?.parent is NamedExpression) {
      NamedExpression named = node.parent?.parent;
      var expression = named.expression;
      if (expression is ListLiteral && expression.elements.length == 1) {
        var widget = expression.elements[0];
        if (flutter.isWidgetExpression(widget)) {
          var widgetText = utils.getNodeText(widget);
          var indentOld = utils.getLinePrefix(widget.offset);
          var indentNew = utils.getLinePrefix(named.offset);
          widgetText = _replaceSourceIndent(widgetText, indentOld, indentNew);

          await builder.addDartFileEdit(file, (builder) {
            builder.addReplacement(range.node(named), (builder) {
              builder.write('child: ');
              builder.write(widgetText);
            });
          });
        }
      }
    }
  }

  String _replaceSourceIndent(
      String source, String indentOld, String indentNew) {
    return source.replaceAll(RegExp('^$indentOld', multiLine: true), indentNew);
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertFlutterChildren newInstance() => ConvertFlutterChildren();
}
