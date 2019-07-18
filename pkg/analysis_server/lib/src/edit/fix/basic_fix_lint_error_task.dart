// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_lint_task.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:front_end/src/scanner/token.dart';

class BasicFixLintErrorTask extends FixLintTask {
  final FixKind fixKind;
  final errors = <AnalysisError>[];

  BasicFixLintErrorTask(this.fixKind, DartFixListener listener)
      : super(listener);

  @override
  Future<void> applyLocalFixes(ResolvedUnitResult result) async {
    while (errors.isNotEmpty) {
      AnalysisError error = errors.removeLast();
      final workspace = DartChangeWorkspace(listener.server.currentSessions);
      final dartContext = new DartFixContextImpl(workspace, result, error);
      final processor = new FixProcessor(dartContext);
      Fix fix = await processor.computeFix();
      final location = listener.locationFor(result, error.offset, error.length);
      if (fix != null) {
        listener.addSourceChange(fix.change.message, location, fix.change);
      } else {
        // TODO(danrubel): Determine why the fix could not be applied
        // and report that in the description.
        listener.addRecommendation(
            'Could not fix "${error.message}"', location);
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
  void reportErrorForNode(ErrorCode code, AstNode node,
      [List<Object> arguments]) {
    if (source.fullName != null) {
      errors.add(new AnalysisError(source, node.offset, node.length, code));
    }
  }

  @override
  void reportErrorForToken(ErrorCode code, Token token,
      [List<Object> arguments]) {
    if (source.fullName != null) {
      errors.add(new AnalysisError(source, token.offset, token.length, code));
    }
  }

  static void nullClosures(
      DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['null_closures'],
      new BasicFixLintErrorTask(
          DartFixKind.REPLACE_NULL_WITH_CLOSURE, listener),
    );
  }

  static void preferEqualForDefaultValues(
      DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_equal_for_default_values'],
      new BasicFixLintErrorTask(
          DartFixKind.REPLACE_COLON_WITH_EQUALS, listener),
    );
  }

  static void preferIsEmpty(
      DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_is_empty'],
      new BasicFixLintErrorTask(DartFixKind.REPLACE_WITH_IS_EMPTY, listener),
    );
  }

  static void preferIsNotEmpty(
      DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_is_not_empty'],
      new BasicFixLintErrorTask(
          DartFixKind.REPLACE_WITH_IS_NOT_EMPTY, listener),
    );
  }
}
