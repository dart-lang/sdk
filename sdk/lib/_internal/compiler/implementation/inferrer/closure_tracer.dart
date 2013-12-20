// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of type_graph_inferrer;

class ClosureTracerVisitor extends TracerVisitor {
  ClosureTracerVisitor(tracedType, inferrer) : super(tracedType, inferrer);

  void run() {
    ClosureTypeInformation closure = tracedType;
    FunctionElement element = closure.element;
    element.functionSignature.forEachParameter((Element parameter) {
      ElementTypeInformation info = inferrer.types.getInferredTypeOf(parameter);
      info.abandonInferencing = false;
    });
    analyze();
    element.functionSignature.forEachParameter((Element parameter) {
      ElementTypeInformation info = inferrer.types.getInferredTypeOf(parameter);
      if (continueAnalyzing) {
        info.disableHandleSpecialCases = true;
      } else {
        info.giveUp(inferrer);
      }
    });
  }

  visitMapTypeInformation(MapTypeInformation info) {
    bailout('Stored in a map');
  }

  void analyzeCall(CallSiteTypeInformation info) {
    ClosureTypeInformation closure = tracedType;
    FunctionElement element = closure.element;
    Selector selector = info.selector;
    if (!selector.signatureApplies(element, compiler)) return;
    inferrer.updateParameterAssignments(
        info, element, info.arguments, selector, remove: false,
        addToQueue: false);
  }

  visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info) {
    super.visitClosureCallSiteTypeInformation(info);
    if (info.closure == currentUser) {
      analyzeCall(info);
    } else {
      bailout('Passed to a closure');
    }
  }

  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    Element called = info.calledElement;
    if (called.isForeign(compiler) && called.name == 'JS') {
      bailout('Used in JS ${info.call}');
    }
    if (inferrer.types.getInferredTypeOf(called) == currentUser) {
      // This node can be a closure call as well. For example, `foo()`
      // where `foo` is a getter.
      analyzeCall(info);
    }
  }

  bool checkIfCurrentUser(element) {
    return inferrer.types.getInferredTypeOf(element) == currentUser;
  }

  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
    super.visitDynamicCallSiteTypeInformation(info);
    if (info.selector.isCall()) {
      if (info.arguments.contains(currentUser)
          && !info.targets.every((element) => element.isFunction())) {
        bailout('Passed to a closure');
      } else if (info.targets.any((element) => checkIfCurrentUser(element))) {
        analyzeCall(info);
      }
    }
  }
}
