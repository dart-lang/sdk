// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterWrapStreamBuilder extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_STREAM_BUILDER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetExpr = flutter.identifyWidgetExpression(node);
    if (widgetExpr == null) {
      return;
    }
    if (flutter.isExactWidgetTypeStreamBuilder(widgetExpr.staticType)) {
      return;
    }
    var widgetSrc = utils.getNodeText(widgetExpr);

    var streamBuilderElement = await sessionHelper.getClass(
      flutter.widgetsUri,
      'StreamBuilder',
    );
    if (streamBuilderElement == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(widgetExpr), (builder) {
        builder.writeReference(streamBuilderElement);

        builder.write('<');
        builder.addSimpleLinkedEdit('type', 'Object');
        builder.writeln('>(');

        var indentOld = utils.getLinePrefix(widgetExpr.offset);
        var indentNew1 = indentOld + utils.getIndent(1);
        var indentNew2 = indentOld + utils.getIndent(2);

        builder.write(indentNew1);
        builder.writeln('stream: null,');

        builder.write(indentNew1);
        builder.writeln('builder: (context, snapshot) {');

        widgetSrc = widgetSrc.replaceAll(
          RegExp('^$indentOld', multiLine: true),
          indentNew2,
        );
        builder.write(indentNew2);
        builder.write('return $widgetSrc');
        builder.writeln(';');

        builder.write(indentNew1);
        builder.writeln('}');

        builder.write(indentOld);
        builder.write(')');
      });
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static FlutterWrapStreamBuilder newInstance() => FlutterWrapStreamBuilder();
}
