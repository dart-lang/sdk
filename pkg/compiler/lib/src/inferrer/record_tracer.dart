// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../common/names.dart';
import '../elements/entities.dart';

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

  @override
  void visitClosureCallSiteTypeInformation(
    ClosureCallSiteTypeInformation info,
  ) {
    bailout('Passed to a closure');
  }

  @override
  void visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    MemberEntity called = info.calledElement;
    if (inferrer.closedWorld.commonElements.isForeign(called) &&
        called.name == Identifiers.js) {
      bailout('Used in JS ${info.debugName}');
    }
  }

  @override
  void visitDynamicCallSiteTypeInformation(
    DynamicCallSiteTypeInformation info,
  ) {
    super.visitDynamicCallSiteTypeInformation(info);
    final selector = info.selector!;
    if (selector.isCall &&
        (info.hasClosureCallTargets || dynamicCallTargetsNonFunction(info))) {
      bailout('Passed to a closure');
      return;
    }
  }
}
