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
import 'package:analyzer_plugin/utilities/assist/assist.dart';

class BasicFixLintAssistTask extends FixLintTask {
  final AssistKind assistKind;
  final nodes = <AstNode>[];

  BasicFixLintAssistTask(this.assistKind, DartFixListener listener)
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
          node.length,
        ),
      );
      List<Assist> assists = await processor.computeAssist(assistKind);

      final location = listener.locationFor(result, node.offset, node.length);
      if (assists.isNotEmpty) {
        for (Assist assist in assists) {
          listener.addSourceChange(
              assist.kind.message, location, assist.change);
        }
      } else {
        // TODO(danrubel): If assists is empty, then determine why
        // assist could not be performed and report that in the description.
        listener.addRecommendation(
            'Fix not found: ${assistKind.message}', location);
      }
    }

    return null;
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
      nodes.add(node);
    }
  }

  static void preferForElementsToMapFromIterable(
      DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_for_elements_to_map_fromIterable'],
      new BasicFixLintAssistTask(
          DartAssistKind.CONVERT_TO_FOR_ELEMENT, listener),
    );
  }

  static void preferIfElementsToConditionalExpressions(
      DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_if_elements_to_conditional_expressions'],
      new BasicFixLintAssistTask(
          DartAssistKind.CONVERT_TO_IF_ELEMENT, listener),
    );
  }

  static void preferIntLiterals(
      DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_int_literals'],
      new BasicFixLintAssistTask(
          DartAssistKind.CONVERT_TO_INT_LITERAL, listener),
    );
  }

  static void preferSpreadCollections(
      DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_spread_collections'],
      new BasicFixLintAssistTask(DartAssistKind.CONVERT_TO_SPREAD, listener),
    );
  }
}
