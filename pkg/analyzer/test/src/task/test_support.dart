// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.test_support;

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/task/model.dart';

/**
 * A configurable analysis task that can be used by tests.
 */
class TestAnalysisTask extends AnalysisTask {
  /**
   * The descriptor describing this task.
   */
  TaskDescriptor descriptor;

  /**
   * The exception that is to be "thrown" by this task.
   */
  CaughtException exception;

  /**
   * The results whose values are to be provided as outputs from this task.
   */
  List<ResultDescriptor> results;

  /**
   * The next value that is to be used for a result.
   */
  int value;

  @override
  final bool handlesDependencyCycles;

  TestAnalysisTask(AnalysisContext context, AnalysisTarget target,
      {this.descriptor,
      this.exception,
      this.handlesDependencyCycles: false,
      this.results,
      this.value: 1})
      : super(context, target);

  @override
  String get description => 'Test task';

  @override
  internalPerform() {
    if (exception != null) {
      caughtException = exception;
    } else if (results != null) {
      for (ResultDescriptor result in results) {
        outputs[result] = value++;
      }
    } else if (descriptor != null) {
      for (ResultDescriptor result in descriptor.results) {
        outputs[result] = value++;
      }
    }
  }
}
