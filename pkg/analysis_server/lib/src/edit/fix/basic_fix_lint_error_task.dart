// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_lint_task.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class BasicFixLintErrorTask extends FixLintTask {
  final FixKind fixKind;

  BasicFixLintErrorTask(this.fixKind, DartFixListener listener)
      : super(listener);

  static void nullClosures(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) {
    registrar.registerLintTask(
      Registry.ruleRegistry['null_closures'],
      new BasicFixLintErrorTask(
          DartFixKind.REPLACE_NULL_WITH_CLOSURE, listener),
    );
  }

  static void preferEqualForDefaultValues(DartFixRegistrar registrar,
      DartFixListener listener, EditDartfixParams params) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_equal_for_default_values'],
      new BasicFixLintErrorTask(
          DartFixKind.REPLACE_COLON_WITH_EQUALS, listener),
    );
  }

  static void preferIsEmpty(DartFixRegistrar registrar,
      DartFixListener listener, EditDartfixParams params) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_is_empty'],
      new BasicFixLintErrorTask(DartFixKind.REPLACE_WITH_IS_EMPTY, listener),
    );
  }

  static void preferIsNotEmpty(DartFixRegistrar registrar,
      DartFixListener listener, EditDartfixParams params) {
    registrar.registerLintTask(
      Registry.ruleRegistry['prefer_is_not_empty'],
      new BasicFixLintErrorTask(
          DartFixKind.REPLACE_WITH_IS_NOT_EMPTY, listener),
    );
  }

  static void unnecessaryConst(DartFixRegistrar registrar,
      DartFixListener listener, EditDartfixParams params) {
    registrar.registerLintTask(
      Registry.ruleRegistry['unnecessary_const'],
      new BasicFixLintErrorTask(DartFixKind.REMOVE_UNNECESSARY_CONST, listener),
    );
  }

  static void unnecessaryNew(DartFixRegistrar registrar,
      DartFixListener listener, EditDartfixParams params) {
    registrar.registerLintTask(
      Registry.ruleRegistry['unnecessary_new'],
      new BasicFixLintErrorTask(DartFixKind.REMOVE_UNNECESSARY_NEW, listener),
    );
  }
}
