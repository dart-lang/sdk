// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/exhaustiveness.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
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

    final diagnostic = this.diagnostic;
    if (diagnostic is! AnalysisError) {
      return;
    }

    final patternParts = diagnostic.data;
    if (patternParts is! List<MissingPatternPart>) {
      return;
    }

    if (node is SwitchExpression) {
      await _switchExpression(
        builder: builder,
        node: node,
        patternParts: patternParts,
      );
    }

    if (node is SwitchStatement) {
      await _switchStatement(
        builder: builder,
        node: node,
        patternParts: patternParts,
      );
    }
  }

  Future<void> _switchExpression({
    required ChangeBuilder builder,
    required SwitchExpression node,
    required List<MissingPatternPart> patternParts,
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
        _writePatternParts(builder, patternParts);
        builder.writeln(' => null,');
        builder.write(location.suffix);
      });
    });
  }

  Future<void> _switchStatement({
    required ChangeBuilder builder,
    required SwitchStatement node,
    required List<MissingPatternPart> patternParts,
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
        _writePatternParts(builder, patternParts);
        builder.writeln(':');
        builder.write(lineIndent);
        builder.write(singleIndent);
        builder.write(singleIndent);
        builder.writeln('// TODO: Handle this case.');
        builder.write(location.suffix);
      });
    });
  }

  void _writePatternParts(
    DartEditBuilder builder,
    List<MissingPatternPart> parts,
  ) {
    for (final part in parts) {
      if (part is MissingPatternEnumValuePart) {
        builder.writeReference(part.enumElement);
        builder.write('.');
        builder.write(part.value.name);
      } else if (part is MissingPatternTextPart) {
        builder.write(part.text);
      } else if (part is MissingPatternTypePart) {
        builder.writeType(part.type);
      }
    }
  }
}
