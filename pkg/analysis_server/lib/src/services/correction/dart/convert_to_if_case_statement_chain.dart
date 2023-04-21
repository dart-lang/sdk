// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToIfCaseStatementChain extends CorrectionProducer {
  @override
  AssistKind get assistKind =>
      DartAssistKind.CONVERT_TO_IF_CASE_STATEMENT_CHAIN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final switchStatement = node;
    if (switchStatement is! SwitchStatement) {
      return;
    }

    final ifIndent = utils.getLinePrefix(switchStatement.offset);
    final expressionCode = utils.getNodeText(switchStatement.expression);

    final switchPatternCases = <SwitchPatternCase>[];
    SwitchDefault? defaultCase;
    for (final member in switchStatement.members) {
      switch (member) {
        case SwitchPatternCase():
          switchPatternCases.add(member);
        case SwitchDefault():
          defaultCase = member;
        default:
          return;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(switchStatement), (builder) {
        var isFirst = true;
        for (final case_ in switchPatternCases) {
          if (isFirst) {
            isFirst = false;
          } else {
            builder.write(' else ');
          }
          final patternCode = utils.getNodeText(case_.guardedPattern);
          builder.writeln('if ($expressionCode case $patternCode) {');
          _writeStatements(
            builder: builder,
            blockIndent: ifIndent,
            statements: case_.statements,
          );
          builder.write('$ifIndent}');
        }
        if (defaultCase case final defaultCase?) {
          builder.writeln(' else {');
          _writeStatements(
            builder: builder,
            blockIndent: ifIndent,
            statements: defaultCase.statements,
          );
          builder.write('$ifIndent}');
        }
      });
    });
  }

  void _writeStatements({
    required DartEditBuilder builder,
    required List<Statement> statements,
    required String blockIndent,
  }) {
    final range = utils.getLinesRangeStatements(statements);

    final firstIndent = utils.getLinePrefix(statements.first.offset);
    final singleIndent = utils.getIndent(1);

    final code = utils.replaceSourceRangeIndent(
      range,
      firstIndent,
      blockIndent + singleIndent,
    );
    builder.write(code);
  }
}
