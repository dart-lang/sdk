// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.test_support;

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/task/model.dart';

class TestAnalysisTask extends AnalysisTask {
  TestAnalysisTask(AnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  String get description => 'Test task';

  @override
  TaskDescriptor get descriptor => null;

  @override
  internalPerform() {
  }
}
