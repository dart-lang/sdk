// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterWrapBuilders extends MultiCorrectionProducer {
  FlutterWrapBuilders({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var producers = <ResolvedCorrectionProducer>[];
    var widgetExpr = node.findWidgetExpression;
    if (widgetExpr != null) {
      producers.add(_FlutterWrapBuilder(context: context));
      producers.add(_FlutterWrapValueListenableBuilder(context: context));
      producers.add(_FlutterWrapStreamBuilder(context: context));
      producers.add(_FlutterWrapFutureBuilder(context: context));
    }
    return producers;
  }
}

abstract class _FlutterBaseWrapBuilder extends ResolvedCorrectionProducer {
  final List<String> extraBuilderParams;
  final List<String> extraNamedParams;
  final String builderName;

  _FlutterBaseWrapBuilder({
    required super.context,
    required this.builderName,
    required this.extraNamedParams,
    required this.extraBuilderParams,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  bool canWrapOn(TypeImpl typeOrThrow) {
    return !typeOrThrow.isExactWidgetTypeBuilder;
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetExpr = node.findWidgetExpression;
    if (widgetExpr == null) {
      return;
    }
    if (!canWrapOn(widgetExpr.typeOrThrow)) {
      return;
    }
    var widgetSrc = utils.getNodeText(widgetExpr);

    var builderElement = await sessionHelper.getFlutterClass(builderName);
    if (builderElement == null) {
      return;
    }

    var params = ['context', ...extraBuilderParams];

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(widgetExpr), (builder) {
        builder.writeReference(builderElement);

        builder.writeln('(');

        var indentOld = utils.getLinePrefix(widgetExpr.offset);
        var indentNew1 = indentOld + utils.oneIndent;
        var indentNew2 = indentOld + utils.twoIndents;

        var namedParams = extraNamedParams.join(', ');

        if (namedParams.isNotEmpty) {
          builder.write(indentNew1);
          builder.write('$namedParams: ');
          builder.addSimpleLinkedEdit('variable', namedParams);
          builder.writeln(',');
        }

        builder.write(indentNew1);
        builder.writeln('builder: (${params.join(', ')}) {');

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

class _FlutterWrapBuilder extends _FlutterBaseWrapBuilder {
  _FlutterWrapBuilder({required super.context})
    : super(
        builderName: 'Builder',
        extraNamedParams: const [],
        extraBuilderParams: const [],
      );

  @override
  AssistKind get assistKind => DartAssistKind.flutterWrapBuilder;
}

class _FlutterWrapFutureBuilder extends _FlutterBaseWrapBuilder {
  _FlutterWrapFutureBuilder({required super.context})
    : super(
        builderName: 'FutureBuilder',
        extraNamedParams: const ['future'],
        extraBuilderParams: const ['asyncSnapshot'],
      );

  @override
  AssistKind get assistKind => DartAssistKind.flutterWrapFutureBuilder;
}

class _FlutterWrapStreamBuilder extends _FlutterBaseWrapBuilder {
  _FlutterWrapStreamBuilder({required super.context})
    : super(
        builderName: 'StreamBuilder',
        extraNamedParams: const ['stream'],
        extraBuilderParams: const ['asyncSnapshot'],
      );

  @override
  AssistKind get assistKind => DartAssistKind.flutterWrapStreamBuilder;
}

class _FlutterWrapValueListenableBuilder extends _FlutterBaseWrapBuilder {
  _FlutterWrapValueListenableBuilder({required super.context})
    : super(
        builderName: 'ValueListenableBuilder',
        extraNamedParams: const ['valueListenable'],
        extraBuilderParams: const ['value', 'child'],
      );

  @override
  AssistKind get assistKind => DartAssistKind.flutterWrapValueListenableBuilder;
}
