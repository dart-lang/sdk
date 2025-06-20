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

class FlutterWrapGeneric extends ResolvedCorrectionProducer {
  FlutterWrapGeneric({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.flutterWrapGeneric;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! ListLiteral) {
      return;
    }
    if ((node as ListLiteral).elements.any(
      (CollectionElement element) =>
          !(element is InstanceCreationExpression && element.isWidgetCreation),
    )) {
      return;
    }
    var literalSrc = utils.getNodeText(node);
    var newlineIdx = literalSrc.lastIndexOf(eol);
    if (newlineIdx < 0 || newlineIdx == literalSrc.length - 1) {
      return; // Lists need to be in multi-line format already.
    }
    var indentOld = utils.getLinePrefix(node.offset + eol.length + newlineIdx);
    var indentArg = '$indentOld${utils.oneIndent}';
    var indentList = '$indentOld${utils.twoIndents}';

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(node), (builder) {
        builder.write('[');
        builder.write(eol);
        builder.write(indentArg);
        builder.addSimpleLinkedEdit('WIDGET', 'widget');
        builder.write('(');
        builder.write(eol);
        builder.write(indentList);
        // Linked editing not needed since arg is always a list.
        builder.write('children: ');
        builder.write(
          utils.replaceSourceIndent(literalSrc, indentOld, indentList),
        );
        builder.write(',');
        builder.write(eol);
        builder.write(indentArg);
        builder.write('),');
        builder.write(eol);
        builder.write(indentOld);
        builder.write(']');
      });
    });
  }
}
