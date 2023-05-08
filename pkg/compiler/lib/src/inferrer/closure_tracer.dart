// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.src.inferrer.closure_tracer;

import '../common/names.dart' show Identifiers, Names;
import '../elements/entities.dart';
import 'debug.dart' as debug;
import 'engine.dart';
import 'node_tracer.dart';
import 'type_graph_nodes.dart';

class ClosureTracerVisitor extends TracerVisitor {
  final Iterable<FunctionEntity> tracedElements;
  final List<CallSiteTypeInformation> _callsToAnalyze =
      <CallSiteTypeInformation>[];

  ClosureTracerVisitor(this.tracedElements, ApplyableTypeInformation tracedType,
      InferrerEngine inferrer)
      : super(tracedType, inferrer) {
    assert(
        tracedElements.every((f) => !f.isAbstract),
        "Tracing abstract methods: "
        "${tracedElements.where((f) => f.isAbstract)}");
  }

  @override
  ApplyableTypeInformation get tracedType =>
      super.tracedType as ApplyableTypeInformation;

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

  void _tagAsFunctionApplyTarget([String? reason]) {
    tracedType.mightBePassedToFunctionApply = true;
    if (debug.VERBOSE) {
      print("Closure $tracedType might be passed to apply: $reason");
    }
  }

  void _registerCallForLaterAnalysis(CallSiteTypeInformation info) {
    _callsToAnalyze.add(info);
  }

  void _analyzeCall(CallSiteTypeInformation info) {
    final selector = info.selector!;
    tracedElements.forEach((FunctionEntity functionElement) {
      if (!selector.callStructure
          .signatureApplies(functionElement.parameterStructure)) {
        return;
      }
      inferrer.updateParameterInputs(
          info, functionElement, info.arguments, selector,
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
      final name = called.name!;
      if (name == Identifiers.JS || name == Identifiers.DART_CLOSURE_TO_JS) {
        bailout('Used in JS ${info.debugName}');
      } else if (name == Identifiers.RAW_DART_FUNCTION_REF) {
        bailout('Escaped raw function reference');
      }
    }

    final selector = info.selector;
    if (called.isGetter &&
        selector != null &&
        selector.isCall &&
        inferrer.types.getInferredTypeOfMember(called) == currentUser) {
      // This node can be a closure call as well. For example, `foo()`
      // where `foo` is a getter.
      _registerCallForLaterAnalysis(info);
    }

    final arguments = info.arguments;
    if (_checkIfFunctionApply(called) &&
        arguments != null &&
        arguments.contains(currentUser)) {
      _tagAsFunctionApplyTarget("static call");
    }
  }

  bool _checkIfFunctionApply(MemberEntity element) {
    return inferrer.closedWorld.commonElements.isFunctionApplyMethod(element);
  }

  @override
  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
    super.visitDynamicCallSiteTypeInformation(info);
    final selector = info.selector!;
    final user = currentUser;
    if (selector.isCall) {
      if (info.arguments!.contains(user)) {
        if (info.hasClosureCallTargets || dynamicCallTargetsNonFunction(info)) {
          bailout('Passed to a closure');
        }
        if (info.targets.any((target) => inferrer.memberHierarchyBuilder
            .anyTargetMember(target, _checkIfFunctionApply))) {
          _tagAsFunctionApplyTarget("dynamic call");
        }
      } else {
        if (user is MemberTypeInformation) {
          final currentUserMember = user.member;
          if (info.targets.any((target) => inferrer.memberHierarchyBuilder
              .anyTargetMember(
                  target, (element) => element == currentUserMember))) {
            _registerCallForLaterAnalysis(info);
          }
        }
      }
    } else if (selector.isGetter && selector.memberName == Names.call) {
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

    final selector = info.selector;
    if (info.calledElement == tracedElements.first &&
        selector != null &&
        selector.isGetter) {
      addNewEscapeInformation(info);
    }
  }
}
