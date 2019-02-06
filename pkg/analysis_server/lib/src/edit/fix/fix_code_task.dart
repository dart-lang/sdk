// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analyzer/dart/analysis/results.dart';

/// A general task for performing a fix.
abstract class FixCodeTask {
  Future<void> processUnit(ResolvedUnitResult result);

  Future<void> finish();
}

/// A processor used by [EditDartFix] to manage [FixCodeTask]s.
mixin FixCodeProcessor {
  final codeTasks = <FixCodeTask>[];

  Future<void> finishCodeTasks() async {
    for (FixCodeTask task in codeTasks) {
      await task.finish();
    }
  }

  Future<void> processCodeTasks(ResolvedUnitResult result) async {
    for (FixCodeTask task in codeTasks) {
      await task.processUnit(result);
    }
  }

  void registerCodeTask(FixCodeTask task) {
    codeTasks.add(task);
  }
}
