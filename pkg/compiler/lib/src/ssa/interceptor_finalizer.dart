// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../constants/values.dart';
import '../elements/entities.dart';
import '../inferrer/abstract_value_domain.dart';
import '../js_backend/interceptor_data.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show JClosedWorld;
import 'nodes.dart';
import 'optimize.dart';

/// SsaFinalizeInterceptors makes adjustments for the interceptor calling
/// convention.
///
/// 1. If the method cannot be invoked with an intercepted receiver, the
///    receiver and interceptor are the same. In this case ignore the explicit
///    receiver argument and use the interceptor (this) as the receiver.
///
/// 2. The call-site dual of the above is if a method ignores the explicit
///    receiver, it can be replaced with a dummy value, i.e. a dummy receiver
///    optimization.
///
/// 3. If an interceptor is used once for a call, replace the
///    getInterceptor-call pair with a call to a 'one-shot interceptor' outlined
///    method.
///
class SsaFinalizeInterceptors extends HBaseVisitor
    implements OptimizationPhase {
  @override
  String get name => "SsaFinalizeInterceptors";
  final JClosedWorld _closedWorld;
  HGraph _graph;

  SsaFinalizeInterceptors(this._closedWorld);

  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  @override
  void visitGraph(HGraph graph) {
    _graph = graph;
    MemberEntity element = graph.element;

    if (usesSelfInterceptor(element)) {
      _redirectReceiver();
    }
    visitDominatorTree(graph);
  }

  @override
  bool validPostcondition(HGraph graph) => true;

  @override
  visitBasicBlock(HBasicBlock node) {
    HInstruction instruction = node.first;
    while (instruction != null) {
      final next = instruction.next;
      instruction.accept(this);
      instruction = next;
    }
  }

  /// Returns `true` if [element] is an instance method that uses the
  /// interceptor calling convention but the instance and interceptor arguments
  /// will always be the same value.
  bool usesSelfInterceptor(MemberEntity element) {
    if (!_interceptorData.isInterceptedMethod(element)) return false;
    ClassEntity cls = element.enclosingClass;
    return !_interceptorData.isInterceptedClass(cls);
  }

  void _redirectReceiver() {
    // The entry block contains the parameters in order, starting with `this`,
    // and then the explicit receiver. There are other instructions in the
    // block, like constants, which we ignore.
    HThis thisParameter;
    HParameterValue receiverParameter;
    for (HInstruction node = _graph.entry.first;
        node != null;
        node = node.next) {
      if (node is HParameterValue) {
        if (node is HThis) {
          thisParameter = node;
        } else {
          receiverParameter = node;
          break;
        }
      }
    }
    assert(thisParameter != null,
        '`this` parameter should be before other parameters');
    assert(receiverParameter != null,
        'Intercepted convention requires explicit receiver');
    thisParameter.instructionType = receiverParameter.instructionType;
    receiverParameter.block.rewrite(receiverParameter, thisParameter);
    receiverParameter.sourceElement = const _RenameToUnderscore();
  }

  @override
  void visitInvokeDynamic(HInvokeDynamic node) {
    if (!node.isInterceptedCall) return;

    if (_interceptorIsReceiver(node)) {
      if (node.element != null) {
        tryReplaceExplicitReceiverForTargetWithDummy(
            node, node.selector, node.element);
      } else {
        tryReplaceExplicitReceiverForSelectorWithDummy(
            node, node.selector, node.receiverType);
      }
      return;
    }

    // Try to replace
    //
    //     getInterceptor(o).method(o, ...)
    //
    // with a 'one shot interceptor' which is a call to a synthesized static
    // helper function that combines the two operations.
    //
    //     oneShotMethod(o, 1, 2)
    //
    // This saves code size and makes the receiver of an intercepted call a
    // candidate for being generated at use site.
    //
    // Avoid combining a hoisted interceptor back into a loop, and the faster
    // almost-constant kind of interceptor.

    HInstruction interceptor = node.inputs[0];
    if (interceptor is HInterceptor &&
        interceptor.usedBy.length == 1 &&
        !interceptor.isConditionalConstantInterceptor &&
        interceptor.hasSameLoopHeaderAs(node)) {
      // Copy inputs and replace interceptor with `null`.
      List<HInstruction> inputs = List.of(node.inputs);
      inputs[0] = _graph.addConstantNull(_closedWorld);

      HOneShotInterceptor oneShot = HOneShotInterceptor(
          node.selector,
          node.receiverType,
          inputs,
          node.instructionType,
          node.typeArguments,
          interceptor.interceptedClasses);
      oneShot.sourceInformation = node.sourceInformation;
      oneShot.sourceElement = node.sourceElement;
      oneShot.sideEffects.setTo(node.sideEffects);

      HBasicBlock block = node.block;
      block.addAfter(node, oneShot);
      block.rewrite(node, oneShot);
      block.remove(node);
      interceptor.block.remove(interceptor);
    }
  }

  @override
  void visitInvokeSuper(HInvokeSuper node) {
    if (!node.isInterceptedCall) return;
    if (_interceptorIsReceiver(node)) {
      tryReplaceExplicitReceiverForTargetWithDummy(
          node, node.selector, node.element);
    }
  }

  @override
  void visitInvokeGeneratorBody(HInvokeGeneratorBody node) {
    // [HInvokeGeneratorBody] does not have an accurate [isInterceptorCall].
    // Test the target first to ensure there are enough inputs.
    if (usesSelfInterceptor(node.element) && _interceptorIsReceiver(node)) {
      tryReplaceExplicitReceiverForTargetWithDummy(node, null, node.element);
    }
  }

  @override
  void visitOneShotInterceptor(HOneShotInterceptor node) {
    throw StateError('Should not see HOneShotInterceptor: $node');
  }

  bool _interceptorIsReceiver(HInvoke node) {
    // This assignment of inputs is uniform for HInvokeDynamic, HInvokeSuper and
    // HInvokeGeneratorBody.
    HInstruction interceptor = node.inputs[0];
    HInstruction receiverArgument = node.inputs[1];
    return interceptor.nonCheck() == receiverArgument.nonCheck();
  }

  void tryReplaceExplicitReceiverForTargetWithDummy(
      HInvoke node, Selector selector, MemberEntity target) {
    assert(target != null);

    // TODO(15933): Make automatically generated property extraction closures
    // work with the dummy receiver optimization.
    if (selector != null && selector.isGetter) return;

    if (usesSelfInterceptor(target)) {
      _replaceReceiverArgumentWithDummy(node, 1);
    }
  }

  void tryReplaceExplicitReceiverForSelectorWithDummy(
      HInvoke node, Selector selector, AbstractValue mask) {
    assert(mask != null);
    // Calls of the form
    //
    //     a.foo$1(a, x)
    //
    // where the interceptor calling convention is used come from recognizing
    // that 'a' is a 'self-interceptor'.  If the selector matches only methods
    // that ignore the explicit receiver parameter, replace occurrences of the
    // receiver argument with a dummy receiver '0':
    //
    //     a.foo$1(a, x)   --->   a.foo$1(0, x)
    //
    // This often reduces the number of references to 'a' to one, allowing 'a'
    // to be generated at use to avoid a temporary, e.g.
    //
    //     t1 = b.get$thing();
    //     t1.foo$1(t1, x)
    // --->
    //     b.get$thing().foo$1(0, x)
    //

    // TODO(15933): Make automatically generated property extraction closures
    // work with the dummy receiver optimization.
    if (selector.isGetter) return;

    // TODO(sra): Should this be an assert?
    if (!_interceptorData.isInterceptedSelector(selector)) return;

    if (!_interceptorData.isInterceptedMixinSelector(
        selector, mask, _closedWorld)) {
      _replaceReceiverArgumentWithDummy(node, 1);
    }
  }

  void _replaceReceiverArgumentWithDummy(HInvoke node, int receiverIndex) {
    ConstantValue constant = DummyInterceptorConstantValue();
    HConstant dummy = _graph.addConstant(constant, _closedWorld);
    node.replaceInput(receiverIndex, dummy);
  }
}

/// A simple Entity to rename the unused receiver to `_` in non-minified code.
class _RenameToUnderscore implements Entity {
  const _RenameToUnderscore();
  @override
  String get name => '_';
}
