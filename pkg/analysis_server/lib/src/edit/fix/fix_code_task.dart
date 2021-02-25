// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show max;

import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';

/// A processor used by [EditDartFix] to manage [FixCodeTask]s.
mixin FixCodeProcessor {
  final _codeTasks = <FixCodeTask>[];

  int _numPhases = 0;

  int get numPhases => _numPhases;

  Future<void> finishCodeTasks() async {
    for (var task in _codeTasks) {
      await task.finish();
    }
  }

  Future<void> processCodeTasks(int phase, ResolvedUnitResult result) async {
    for (var task in _codeTasks) {
      await task.processUnit(phase, result);
    }
  }

  Future<void> processPackage(Folder pkgFolder) async {
    for (var task in _codeTasks) {
      await task.processPackage(pkgFolder);
    }
  }

  void registerCodeTask(FixCodeTask task) {
    _codeTasks.add(task);
    _numPhases = max(_numPhases, task.numPhases);
  }
}

/// A general task for performing a fix.
abstract class FixCodeTask {
  /// Number of times [processUnit] should be called for each compilation unit.
  int get numPhases;

  /// [finish] is called after [processUnit] has been called for each
  /// phase and compilation unit.
  Future<void> finish();

  /// [processPackage] is called once for each package
  /// before [processUnit] is called for any compilation unit in any package.
  Future<void> processPackage(Folder pkgFolder);

  /// [processUnit] is called for each phase and compilation unit.
  ///
  /// First [processUnit] will be called once for each compilation unit with
  /// [phase] set to 0; then it will be called for each compilation unit with
  /// [phase] set to 1; and so on through `numPhases-1`.
  Future<void> processUnit(int phase, ResolvedUnitResult result);
}
