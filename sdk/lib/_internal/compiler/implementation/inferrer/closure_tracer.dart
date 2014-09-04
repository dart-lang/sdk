// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of type_graph_inferrer;

class ClosureTracerVisitor extends TracerVisitor<ApplyableTypeInformation> {
  final Iterable<FunctionElement> tracedElements;

  ClosureTracerVisitor(this.tracedElements, tracedType, inferrer)
      : super(tracedType, inferrer);

  void run() {
    for (FunctionElement e in tracedElements) {
      e.functionSignature.forEachParameter((Element parameter) {
        ElementTypeInformation info =
            inferrer.types.getInferredTypeOf(parameter);
        info.maybeResume();
      });
    }
    analyze();
    for(FunctionElement e in tracedElements) {
      e.functionSignature.forEachParameter((Element parameter) {
        ElementTypeInformation info =
            inferrer.types.getInferredTypeOf(parameter);
        if (continueAnalyzing) {
          info.disableInferenceForClosures = false;
        }
      });
    }
  }

  void tagAsFunctionApplyTarget([String reason]) {
    tracedType.mightBePassedToFunctionApply = true;
    if (_VERBOSE) {
      print("Closure $tracedType might be passed to apply: $reason");
    }
  }

  void analyzeCall(CallSiteTypeInformation info) {
    Selector selector = info.selector;
    tracedElements.forEach((FunctionElement functionElement) {
      if (!selector.signatureApplies(functionElement)) return;
      inferrer.updateParameterAssignments(info, functionElement, info.arguments,
          selector, remove: false, addToQueue: false);
    });
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
    if (called.isForeign(compiler.backend)) {
      String name = called.name;
      if (name == 'JS' || name == 'DART_CLOSURE_TO_JS') {
        bailout('Used in JS ${info.call}');
      }
    }
    if (called.isGetter
        && info.selector != null
        && info.selector.isCall
        && inferrer.types.getInferredTypeOf(called) == currentUser) {
      // This node can be a closure call as well. For example, `foo()`
      // where `foo` is a getter.
      analyzeCall(info);
    }
    if (checkIfFunctionApply(called) &&
        info.arguments != null &&
        info.arguments.contains(currentUser)) {
      tagAsFunctionApplyTarget("static call");
    }
  }

  bool checkIfCurrentUser(element) {
    return inferrer.types.getInferredTypeOf(element) == currentUser;
  }

  bool checkIfFunctionApply(element) {
    return compiler.functionApplyMethod == element;
  }

  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
    super.visitDynamicCallSiteTypeInformation(info);
    if (info.selector.isCall) {
      if (info.arguments.contains(currentUser)) {
        if (!info.targets.every((element) => element.isFunction)) {
          bailout('Passed to a closure');
        }
        if (info.targets.any(checkIfFunctionApply)) {
          tagAsFunctionApplyTarget("dynamic call");
        }
      } else if (info.targets.any((element) => checkIfCurrentUser(element))) {
        analyzeCall(info);
      }
    } else if (info.selector.isGetter &&
        info.selector.name == Compiler.CALL_OPERATOR_NAME) {
      // We are potentially tearing off ourself here
      addNewEscapeInformation(info);
    }
  }
}

class StaticTearOffClosureTracerVisitor extends ClosureTracerVisitor {
  StaticTearOffClosureTracerVisitor(tracedElement, tracedType, inferrer)
      : super([tracedElement], tracedType, inferrer);

  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    if (info.calledElement == tracedElements.first
        && info.selector != null
        && info.selector.isGetter) {
      addNewEscapeInformation(info);
    }
  }
}
