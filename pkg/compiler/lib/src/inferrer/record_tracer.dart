// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'node_tracer.dart';
import 'type_graph_nodes.dart';

class RecordTracerVisitor extends TracerVisitor {
  RecordTracerVisitor(super.tracedType, super.inferrer);

  bool run() {
    analyze();
    final record = tracedType as RecordTypeInformation;
    if (continueAnalyzing) {
      record.addFlowsIntoTargets(flowsInto);
      return true;
    }
    return false;
  }
}
