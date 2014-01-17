// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of type_graph_inferrer;

class ClosureTracerVisitor extends TracerVisitor {
  final FunctionElement tracedElement;

  ClosureTracerVisitor(this.tracedElement, tracedType, inferrer)
      : super(tracedType, inferrer);

  void run() {
    tracedElement.functionSignature.forEachParameter((Element parameter) {
      ElementTypeInformation info = inferrer.types.getInferredTypeOf(parameter);
      info.abandonInferencing = false;
    });
    analyze();
    tracedElement.functionSignature.forEachParameter((Element parameter) {
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
    Selector selector = info.selector;
    if (!selector.signatureApplies(tracedElement, compiler)) return;
    inferrer.updateParameterAssignments(
        info, tracedElement, info.arguments, selector, remove: false,
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
    if (called.isForeign(compiler)) {
      String name = called.name;
      if (name == 'JS' || name == 'DART_CLOSURE_TO_JS') {
        bailout('Used in JS ${info.call}');
      }
    }
    if (called.isGetter()
        && info.selector != null
        && info.selector.isCall()
        && inferrer.types.getInferredTypeOf(called) == currentUser) {
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

class StaticTearOffClosureTracerVisitor extends ClosureTracerVisitor {
  StaticTearOffClosureTracerVisitor(tracedElement, tracedType, inferrer)
      : super(tracedElement, tracedType, inferrer);

  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    if (info.calledElement == tracedElement
        && info.selector != null
        && info.selector.isGetter()) {
      addNewEscapeInformation(info);
    }
  }
}
