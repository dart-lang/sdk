// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToIfCaseStatementChain extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind =>
      DartAssistKind.CONVERT_TO_IF_CASE_STATEMENT_CHAIN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var switchStatement = node;
    if (switchStatement is! SwitchStatementImpl) {
      return;
    }

    if (switchStatement.members.isEmpty) {
      return;
    }

    var groups = _groups(switchStatement);
    if (groups == null) {
      return;
    }

    var ifIndent = utils.getLinePrefix(switchStatement.offset);
    var expressionCode = utils.getNodeText(switchStatement.expression);

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(switchStatement), (builder) {
        var isFirst = true;
        for (var group in groups) {
          if (isFirst) {
            isFirst = false;
          } else {
            builder.write(' else ');
          }
          switch (group) {
            case _SingleCaseGroup():
              var patternCode = utils.getNodeText(group.guardedPattern);
              builder.writeln('if ($expressionCode case $patternCode) {');
            case _JoinedCaseGroup():
              var patternCode = group.patterns
                  .map((pattern) => utils.getNodeText(pattern))
                  .join(' || ');
              builder.writeln('if ($expressionCode case $patternCode) {');
            case _DefaultGroup():
              builder.writeln('{');
          }
          _writeStatements(
            builder: builder,
            blockIndent: ifIndent,
            statements: group.statements,
          );
          builder.write('$ifIndent}');
        }
      });
    });
  }

  List<_Group>? _groups(SwitchStatementImpl switchStatement) {
    var result = <_Group>[];
    for (var group in switchStatement.memberGroups) {
      var members = group.members;

      // Support `default`, if alone.
      if (members.any((e) => e is SwitchDefault)) {
        if (members.length != 1) {
          return null;
        }
        result.add(
          _DefaultGroup(
            statements: group.statements,
          ),
        );
        continue;
      }

      // We expect only `SwitchPatternCase`s.
      var guardedPatterns = members
          .whereType<SwitchPatternCase>()
          .map((e) => e.guardedPattern)
          .toList();
      if (guardedPatterns.length != members.length) {
        return null;
      }

      // For single `GuardedPattern` we allow `when`.
      var singleGuardedPattern = guardedPatterns.singleOrNull;
      if (singleGuardedPattern != null) {
        result.add(
          _SingleCaseGroup(
            guardedPattern: singleGuardedPattern,
            statements: group.statements,
          ),
        );
        continue;
      }

      // For joined `GuardedPattern`s, we cannot support any `when`.
      if (guardedPatterns.hasWhen) {
        return null;
      }

      result.add(
        _JoinedCaseGroup(
          patterns: guardedPatterns.map((e) => e.pattern).toList(),
          statements: group.statements,
        ),
      );
    }
    return result;
  }

  void _writeStatements({
    required DartEditBuilder builder,
    required List<Statement> statements,
    required String blockIndent,
  }) {
    var first = statements.firstOrNull;
    if (first == null) {
      return;
    }

    var range = utils.getLinesRangeStatements(statements);
    var firstIndent = utils.getLinePrefix(first.offset);
    var singleIndent = utils.oneIndent;

    var code = utils.replaceSourceRangeIndent(
      range,
      firstIndent,
      blockIndent + singleIndent,
      includeLeading: true,
      ensureTrailingNewline: true,
    );
    builder.write(code);
  }
}

class _DefaultGroup extends _Group {
  _DefaultGroup({
    required super.statements,
  });
}

sealed class _Group {
  final List<Statement> statements;

  _Group({
    required this.statements,
  });
}

/// Joined [Pattern]s, without `when`, before statements.
class _JoinedCaseGroup extends _Group {
  final List<DartPattern> patterns;

  _JoinedCaseGroup({
    required this.patterns,
    required super.statements,
  });
}

/// A single [GuardedPattern] before statements.
class _SingleCaseGroup extends _Group {
  final GuardedPattern guardedPattern;

  _SingleCaseGroup({
    required this.guardedPattern,
    required super.statements,
  });
}

extension on List<GuardedPattern> {
  bool get hasWhen => any((e) => e.whenClause != null);
}
