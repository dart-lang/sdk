// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.src.inferrer.closure_tracer;

import '../common/names.dart' show Identifiers, Names;
import '../elements/entities.dart';
import '../universe/selector.dart' show Selector;
import 'abstract_value_domain.dart';
import 'debug.dart' as debug;
import 'inferrer_engine.dart';
import 'node_tracer.dart';
import 'type_graph_nodes.dart';

class ClosureTracerVisitor extends TracerVisitor {
  final Iterable<FunctionEntity> tracedElements;
  final List<CallSiteTypeInformation> _callsToAnalyze =
      new List<CallSiteTypeInformation>();

  ClosureTracerVisitor(this.tracedElements, ApplyableTypeInformation tracedType,
      InferrerEngine inferrer)
      : super(tracedType, inferrer) {
    assert(
        tracedElements.every((f) => !f.isAbstract),
        "Tracing abstract methods: "
        "${tracedElements.where((f) => f.isAbstract)}");
  }

  @override
  ApplyableTypeInformation get tracedType => super.tracedType;

  void run() {
    analyze();
    if (!continueAnalyzing) return;
    _callsToAnalyze.forEach(_analyzeCall);
    for (FunctionEntity element in tracedElements) {
      inferrer.types.strategy.forEachParameter(element, (Local parameter) {
        ElementTypeInformation info =
            inferrer.types.getInferredTypeOfParameter(parameter);
        info.disableInferenceForClosures = false;
      });
    }
  }

  void _tagAsFunctionApplyTarget([String reason]) {
    tracedType.mightBePassedToFunctionApply = true;
    if (debug.VERBOSE) {
      print("Closure $tracedType might be passed to apply: $reason");
    }
  }

  void _registerCallForLaterAnalysis(CallSiteTypeInformation info) {
    _callsToAnalyze.add(info);
  }

  void _analyzeCall(CallSiteTypeInformation info) {
    Selector selector = info.selector;
    AbstractValue mask = info.mask;
    tracedElements.forEach((FunctionEntity functionElement) {
      if (!selector.callStructure
          .signatureApplies(functionElement.parameterStructure)) {
        return;
      }
      inferrer.updateParameterAssignments(
          info, functionElement, info.arguments, selector, mask,
          remove: false, addToQueue: false);
    });
  }

  @override
  visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info) {
    super.visitClosureCallSiteTypeInformation(info);
    if (info.closure == currentUser) {
      _registerCallForLaterAnalysis(info);
    } else {
      bailout('Passed to a closure');
    }
  }

  @override
  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    MemberEntity called = info.calledElement;
    if (inferrer.closedWorld.commonElements.isForeign(called)) {
      String name = called.name;
      if (name == Identifiers.JS || name == Identifiers.DART_CLOSURE_TO_JS) {
        bailout('Used in JS ${info.debugName}');
      }
    }
    if (called.isGetter &&
        info.selector != null &&
        info.selector.isCall &&
        inferrer.types.getInferredTypeOfMember(called) == currentUser) {
      // This node can be a closure call as well. For example, `foo()`
      // where `foo` is a getter.
      _registerCallForLaterAnalysis(info);
    }
    if (_checkIfFunctionApply(called) &&
        info.arguments != null &&
        info.arguments.contains(currentUser)) {
      _tagAsFunctionApplyTarget("static call");
    }
  }

  bool _checkIfCurrentUser(MemberEntity element) =>
      inferrer.types.getInferredTypeOfMember(element) == currentUser;

  bool _checkIfFunctionApply(MemberEntity element) {
    return inferrer.closedWorld.commonElements.isFunctionApplyMethod(element);
  }

  @override
  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
    super.visitDynamicCallSiteTypeInformation(info);
    if (info.selector.isCall) {
      if (info.arguments.contains(currentUser)) {
        if (info.hasClosureCallTargets ||
            info.concreteTargets.any((element) => !element.isFunction)) {
          bailout('Passed to a closure');
        }
        if (info.concreteTargets.any(_checkIfFunctionApply)) {
          _tagAsFunctionApplyTarget("dynamic call");
        }
      } else if (info.concreteTargets.any(_checkIfCurrentUser)) {
        _registerCallForLaterAnalysis(info);
      }
    } else if (info.selector.isGetter &&
        info.selector.memberName == Names.call) {
      // We are potentially tearing off ourself here
      addNewEscapeInformation(info);
    }
  }
}

class StaticTearOffClosureTracerVisitor extends ClosureTracerVisitor {
  StaticTearOffClosureTracerVisitor(
      FunctionEntity tracedElement, tracedType, inferrer)
      : super([tracedElement], tracedType, inferrer);

  @override
  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    if (info.calledElement == tracedElements.first &&
        info.selector != null &&
        info.selector.isGetter) {
      addNewEscapeInformation(info);
    }
  }
}
