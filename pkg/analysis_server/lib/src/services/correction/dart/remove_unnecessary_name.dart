// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnnecessaryName extends ResolvedCorrectionProducer {
  RemoveUnnecessaryName({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.removeUnnecessaryName;

  @override
  FixKind get fixKind => DartFixKind.removeUnnecessaryName;

  @override
  FixKind? get multiFixKind => DartFixKind.removeUnnecessaryNameMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node.parent case PatternField patternField) {
      node = patternField;
    }
    if (node is! PatternField) {
      return;
    }

    var pattern = node.pattern;
    if (pattern is! DeclaredVariablePattern) return;

    var name = node.name;
    if (name?.name case Token(:var isSynthetic, :var lexeme) && var name
        when !isSynthetic && pattern.name.lexeme == lexeme) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.token(name));
      });
    }
  }
}
