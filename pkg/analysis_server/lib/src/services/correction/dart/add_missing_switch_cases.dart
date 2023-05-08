// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingSwitchCases extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => false;

  @override
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_SWITCH_CASES;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;

    final patternCode = _patternSuggestion();
    if (patternCode == null) {
      return;
    }

    if (node is SwitchExpression) {
      await _switchExpression(
        builder: builder,
        node: node,
        patternCode: patternCode,
      );
    }

    if (node is SwitchStatement) {
      await _switchStatement(
        builder: builder,
        node: node,
        patternCode: patternCode,
      );
    }
  }

  /// Extracts the pattern code suggestion from the correction message.
  ///
  /// TODO(scheglov) In general, this code might be not always valid code.
  String? _patternSuggestion() {
    final diagnostic = this.diagnostic;
    if (diagnostic == null) {
      return null;
    }

    final correctionMessage = diagnostic.correctionMessage;
    if (correctionMessage == null) {
      return null;
    }

    final regExp = RegExp("that match '(.+)'");
    final match = regExp.firstMatch(correctionMessage);
    if (match == null) {
      return null;
    }

    return match.group(1);
  }

  Future<void> _switchExpression({
    required ChangeBuilder builder,
    required SwitchExpression node,
    required String patternCode,
  }) async {
    final lineIndent = utils.getLinePrefix(node.offset);
    final singleIndent = utils.getIndent(1);
    final location = utils.newCaseClauseAtEndLocation(
      switchKeyword: node.switchKeyword,
      leftBracket: node.leftBracket,
      rightBracket: node.rightBracket,
    );

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        builder.write(lineIndent);
        builder.write(singleIndent);
        builder.writeln('// TODO: Handle this case.');
        builder.write(lineIndent);
        builder.write(singleIndent);
        builder.write(patternCode);
        builder.writeln(' => null,');
        builder.write(location.suffix);
      });
    });
  }

  Future<void> _switchStatement({
    required ChangeBuilder builder,
    required SwitchStatement node,
    required String patternCode,
  }) async {
    final lineIndent = utils.getLinePrefix(node.offset);
    final singleIndent = utils.getIndent(1);
    final location = utils.newCaseClauseAtEndLocation(
      switchKeyword: node.switchKeyword,
      leftBracket: node.leftBracket,
      rightBracket: node.rightBracket,
    );

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        builder.write(lineIndent);
        builder.write(singleIndent);
        builder.write('case ');
        builder.write(patternCode);
        builder.writeln(':');
        builder.write(lineIndent);
        builder.write(singleIndent);
        builder.write(singleIndent);
        builder.writeln('// TODO: Handle this case.');
        builder.write(location.suffix);
      });
    });
  }
}
