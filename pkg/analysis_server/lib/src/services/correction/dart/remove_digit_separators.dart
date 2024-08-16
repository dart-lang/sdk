// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/util.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDigitSeparators extends ResolvedCorrectionProducer {
  RemoveDigitSeparators({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.REMOVE_DIGIT_SEPARATORS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node case IntegerLiteral(:var literal) || DoubleLiteral(:var literal)) {
      var source = literal.lexeme;

      var withoutSeparators = stripSeparators(source);
      // Don't offer the correction if the result is unchanged.
      if (withoutSeparators == source) return;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(node), withoutSeparators);
      });
    }
  }
}
