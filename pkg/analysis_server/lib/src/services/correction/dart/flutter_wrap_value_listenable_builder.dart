// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

// TODO(kenz): share common implementation between the various builder wrappers.
// See https://github.com/dart-lang/sdk/issues/60075.
class FlutterWrapValueListenableBuilder extends ResolvedCorrectionProducer {
  FlutterWrapValueListenableBuilder({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  AssistKind get assistKind =>
      DartAssistKind.FLUTTER_WRAP_VALUE_LISTENABLE_BUILDER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetExpr = node.findWidgetExpression;
    if (widgetExpr == null) {
      return;
    }

    var widgetSrc = utils.getNodeText(widgetExpr);

    var valueListenableBuilderElement = await sessionHelper.getFlutterClass(
      'ValueListenableBuilder',
    );
    if (valueListenableBuilderElement == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(widgetExpr), (builder) {
        builder.writeReference(valueListenableBuilderElement);

        builder.write('<');
        builder.addSimpleLinkedEdit('type', 'Object');
        builder.writeln('>(');

        var indentOld = utils.getLinePrefix(widgetExpr.offset);
        var indentNew1 = indentOld + utils.oneIndent;
        var indentNew2 = indentOld + utils.twoIndents;

        builder.write(indentNew1);
        builder.writeln('valueListenable: valueListenable,');

        builder.write(indentNew1);
        // If there is a ValueListenableBuilder above or below the Widget being
        // added that has a parameter named 'value', then this parameter named
        // 'value' will take precedence in the scope of this builder. This is a
        // known risk and is acceptable at this time. It is possible to improve
        // this logic in the future by looking for naming collisisons above and
        // below this Widget and giving the parameter a unique name.
        builder.writeln('builder: (context, value, child) {');

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
