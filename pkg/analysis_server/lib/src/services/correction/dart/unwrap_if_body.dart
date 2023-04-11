// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class UnwrapIfBody extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.UNWRAP_IF_BODY;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final ifStatement = node.enclosingIfStatement;
    if (ifStatement == null) {
      return;
    }

    // It might be confusing with `else`.
    if (ifStatement.elseStatement != null) {
      return;
    }

    final thenStatement = ifStatement.thenStatement;
    final thenStatements = getStatements(thenStatement);
    final lineRanges = utils.getLinesRangeStatements(thenStatements);
    final oldCode = utils.getRangeText(lineRanges);
    final newCode = utils.indentSourceLeftRight(oldCode).trim();

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(ifStatement), newCode);
    });
  }
}
