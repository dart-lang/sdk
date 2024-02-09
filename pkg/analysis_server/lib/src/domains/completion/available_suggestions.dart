// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/services/available_declarations.dart';

class CompletionLibrariesWorker implements SchedulerWorker {
  // TODO(brianwilkerson): Rename this class. It's used for gathering dartdoc
  //  information, but isn't used for completion data.
  final DeclarationsTracker tracker;

  CompletionLibrariesWorker(this.tracker);

  @override
  AnalysisDriverPriority get workPriority {
    if (tracker.hasWork) {
      return AnalysisDriverPriority.priority;
    } else {
      return AnalysisDriverPriority.nothing;
    }
  }

  @override
  Future<void> performWork() async {
    tracker.doWork();
  }
}
