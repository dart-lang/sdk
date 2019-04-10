// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
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

class PreferIfElementsToConditionalExpressionsFix extends FixLintTask {
  final List<AstNode> nodes = <AstNode>[];

  PreferIfElementsToConditionalExpressionsFix(DartFixListener listener)
      : super(listener);

  @override
  Future<void> applyLocalFixes(ResolvedUnitResult result) async {
    while (nodes.isNotEmpty) {
      AstNode node = nodes.removeLast();
      AssistProcessor processor = new AssistProcessor(
        new DartAssistContextImpl(
            DartChangeWorkspace(listener.server.currentSessions),
            result,
            node.offset,
            node.length),
      );
      List<Assist> assists =
          await processor.computeAssist(DartAssistKind.CONVERT_TO_IF_ELEMENT);

      final location = listener.locationFor(result, node.offset, node.length);
      if (assists.isNotEmpty) {
        for (Assist assist in assists) {
          listener.addSourceChange(
              assist.kind.message, location, assist.change);
        }
      } else {
        listener.addRecommendation(
            'Convert to if elements assist not found', location);
      }
    }

    return null;
  }

  @override
  Future<void> applyRemainingFixes() {
    return null;
  }

  @override
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    nodes.add(node);
  }

  static void task(DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_if_elements_to_conditional_expressions'],
      new PreferIfElementsToConditionalExpressionsFix(listener),
    );
  }
}
