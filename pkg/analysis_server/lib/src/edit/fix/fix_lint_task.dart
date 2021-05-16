// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/services/lint.dart';

/// A processor used by [EditDartFix] to manage [FixLintTask]s.
mixin FixLintProcessor implements FixErrorProcessor {
  final linters = <Linter>[];
  final lintTasks = <FixLintTask>[];

  void registerLintTask(LintRule lint, FixLintTask task) {
    linters.add(lint);
    lintTasks.add(task);
    errorTaskMap[lint.lintCode] = task;
  }
}

/// A task for fixing a particular lint.
class FixLintTask extends FixErrorTask {
  FixLintTask(DartFixListener listener) : super(listener);
}
