// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class ConvertToMultilineString extends ResolvedCorrectionProducer {
  ConvertToMultilineString({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.convertToMultilineString;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = node;
    if (targetNode is InterpolationElement) {
      targetNode = targetNode.parent!;
    }
    if (targetNode is SingleStringLiteral) {
      var literal = targetNode;
      if (!literal.isSynthetic && !literal.isMultiline) {
        await builder.addDartFileEdit(file, (builder) {
          var newQuote = literal.isSingleQuoted ? "'''" : '"""';
          builder.addReplacement(
            SourceRange(literal.offset + (literal.isRaw ? 1 : 0), 1),
            (builder) {
              builder.writeln(newQuote);
            },
          );
          builder.addSimpleReplacement(
            SourceRange(literal.end - 1, 1),
            newQuote,
          );
        });
      }
    }
  }
}
