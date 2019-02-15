// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_lint_task.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/registry.dart';

class PreferIntLiteralsFix extends FixLintTask {
  static void task(DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_int_literals'],
      new PreferIntLiteralsFix(listener),
    );
  }

  final literalsToConvert = <DoubleLiteral>[];

  PreferIntLiteralsFix(DartFixListener listener) : super(listener);

  @override
  Future<void> applyLocalFixes(ResolvedUnitResult result) async {
    while (literalsToConvert.isNotEmpty) {
      DoubleLiteral literal = literalsToConvert.removeLast();
      AssistProcessor processor = new AssistProcessor(
        new DartAssistContextImpl(
          DartChangeWorkspace(listener.server.currentSessions),
          result,
          literal.offset,
          0,
        ),
      );
      List<Assist> assists =
          await processor.computeAssist(DartAssistKind.CONVERT_TO_INT_LITERAL);
      final location =
          listener.locationFor(result, literal.offset, literal.length);
      if (assists.isNotEmpty) {
        for (Assist assist in assists) {
          listener.addSourceChange(
              'Replace a double literal with an int literal',
              location,
              assist.change);
        }
      } else {
        // TODO(danrubel): If assists is empty, then determine why
        // assist could not be performed and report that in the description.
        listener.addRecommendation(
            'Could not replace a double literal with an int literal', location);
      }
    }
  }

  @override
  Future<void> applyRemainingFixes() {
    // All fixes applied in [applyLocalFixes]
    return null;
  }

  @override
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    if (source.fullName != null) {
      literalsToConvert.add(node);
    }
  }
}
