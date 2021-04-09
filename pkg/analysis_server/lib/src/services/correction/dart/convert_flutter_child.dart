// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertFlutterChild extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.CONVERT_FLUTTER_CHILD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var named = flutter.findNamedExpression(node, 'child');
    if (named == null) {
      return;
    }

    // child: widget
    var expression = named.expression;
    if (flutter.isWidgetExpression(expression)) {
      await builder.addDartFileEdit(file, (builder) {
        flutter.convertChildToChildren2(
            builder,
            expression,
            named,
            eol,
            utils.getNodeText,
            utils.getLinePrefix,
            utils.getIndent,
            utils.getText,
            range.node);
      });
      return;
    }

    // child: [widget1, widget2]
    if (expression is ListLiteral &&
        expression.elements.every(flutter.isWidgetExpression)) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(named.name), 'children:');
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertFlutterChild newInstance() => ConvertFlutterChild();
}
