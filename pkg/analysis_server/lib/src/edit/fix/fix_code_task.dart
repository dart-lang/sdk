// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analyzer/dart/analysis/results.dart';

/// A general task for performing a fix.
abstract class FixCodeTask {
  /// [processUnit] is called for each compilation unit.
  Future<void> processUnit(ResolvedUnitResult result);

  /// [finish] is called after [processUnit] (and [processUnit2] if this
  /// is a FixCodeTask2) has been called for each compilation unit.
  Future<void> finish();
}

/// A general task for performing a fix which needs a 2nd pass.
abstract class FixCodeTask2 extends FixCodeTask {
  /// [processUnit2] is called for each compilation unit
  /// after [processUnit] has been called for each compilation unit.
  Future<void> processUnit2(ResolvedUnitResult result);
}

/// A processor used by [EditDartFix] to manage [FixCodeTask]s.
mixin FixCodeProcessor {
  final codeTasks = <FixCodeTask>[];
  final codeTasks2 = <FixCodeTask2>[];

  Future<void> finishCodeTasks() async {
    for (FixCodeTask task in codeTasks) {
      await task.finish();
    }
  }

  bool get needsSecondPass => codeTasks2.isNotEmpty;

  Future<void> processCodeTasks(ResolvedUnitResult result) async {
    for (FixCodeTask task in codeTasks) {
      await task.processUnit(result);
    }
  }

  Future<void> processCodeTasks2(ResolvedUnitResult result) async {
    for (FixCodeTask2 task in codeTasks) {
      await task.processUnit2(result);
    }
  }

  void registerCodeTask(FixCodeTask task) {
    codeTasks.add(task);
    if (task is FixCodeTask2) {
      codeTasks2.add(task);
    }
  }
}
