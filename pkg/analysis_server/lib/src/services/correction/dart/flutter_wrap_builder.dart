// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterWrapBuilder extends ResolvedCorrectionProducer {
  FlutterWrapBuilder({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_BUILDER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetExpr = node.findWidgetExpression;
    if (widgetExpr == null) {
      return;
    }
    if (widgetExpr.typeOrThrow.isExactWidgetTypeBuilder) {
      return;
    }
    var widgetSrc = utils.getNodeText(widgetExpr);

    var builderElement = await sessionHelper.getFlutterClass2('Builder');
    if (builderElement == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(widgetExpr), (builder) {
        builder.writeReference2(builderElement);

        builder.writeln('(');

        var indentOld = utils.getLinePrefix(widgetExpr.offset);
        var indentNew1 = indentOld + utils.oneIndent;
        var indentNew2 = indentOld + utils.twoIndents;

        builder.write(indentNew1);
        builder.writeln('builder: (context) {');

        widgetSrc = utils.replaceSourceIndent(widgetSrc, indentOld, indentNew2);
        builder.write(indentNew2);
        builder.write('return $widgetSrc');
        builder.writeln(';');

        builder.write(indentNew1);
        var addTrailingCommas =
            getCodeStyleOptions(unitResult.file).addTrailingCommas;
        builder.writeln('}${addTrailingCommas ? "," : ""}');

        builder.write(indentOld);
        builder.write(')');
      });
    });
  }
}
