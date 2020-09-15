// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../inferrer/abstract_value_domain.dart';
import '../js_backend/interceptor_data.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show JClosedWorld;
import 'nodes.dart';
import 'optimize.dart';

/// This phase simplifies interceptors in multiple ways:
///
/// 1) If the interceptor is for an object whose type is known, it
/// tries to use a constant interceptor instead.
///
/// 2) Interceptors are specialized based on the selector it is used with.
///
/// 3) If we know the object is not intercepted, we just use the object
/// instead.
///
/// 4) Single use interceptors at dynamic invoke sites are replaced with 'one
/// shot interceptors' which are synthesized static helper functions that fetch
/// the interceptor and then call the method.  This saves code size and makes the
/// receiver of an intercepted call a candidate for being generated at use site.
///
class SsaSimplifyInterceptors extends HBaseVisitor
    implements OptimizationPhase {
  @override
  final String name = "SsaSimplifyInterceptors";
  final JClosedWorld _closedWorld;
  final ClassEntity _enclosingClass;
  HGraph _graph;

  SsaSimplifyInterceptors(this._closedWorld, this._enclosingClass);

  CommonElements get _commonElements => _closedWorld.commonElements;

  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

  @override
  void visitGraph(HGraph graph) {
    this._graph = graph;
    visitDominatorTree(graph);
  }

  @override
  void visitBasicBlock(HBasicBlock node) {
    currentBlock = node;

    HInstruction instruction = node.first;
    while (instruction != null) {
      bool shouldRemove = instruction.accept(this);
      HInstruction next = instruction.next;
      if (shouldRemove) {
        instruction.block.remove(instruction);
      }
      instruction = next;
    }
  }

  @override
  bool visitInstruction(HInstruction instruction) => false;

  @override
  bool visitInvoke(HInvoke invoke) {
    if (!invoke.isInterceptedCall) return false;
    dynamic interceptor = invoke.inputs[0];
    if (interceptor is! HInterceptor) return false;

    // TODO(sra): Move this per-call code to visitInterceptor.
    //
    // The interceptor is visited first, so we get here only when the
    // interceptor was not rewritten to a single shared replacement.  I'm not
    // sure we should substitute a constant interceptor on a per-call basis if
    // the interceptor is already available in a local variable, but it is
    // possible that all uses can be rewritten to use different constants.

    HInstruction constant = tryComputeConstantInterceptor(
        invoke.inputs[1], interceptor.interceptedClasses);
    if (constant != null) {
      invoke.changeUse(interceptor, constant);
    }
    return false;
  }

  bool canUseSelfForInterceptor(HInstruction receiver,
      {Set<ClassEntity> interceptedClasses}) {
    if (receiver.isNull(_abstractValueDomain).isPotentiallyTrue) {
      if (interceptedClasses == null ||
          interceptedClasses.contains(_commonElements.jsNullClass)) {
        // Need the JSNull interceptor.
        return false;
      }
    }

    // All intercepted classes extend `Interceptor`, so if the receiver can't be
    // a class extending `Interceptor` then it can be called directly.
    return _abstractValueDomain
        .isInterceptor(receiver.instructionType)
        .isDefinitelyFalse;
  }

  HInstruction tryComputeConstantInterceptor(
      HInstruction input, Set<ClassEntity> interceptedClasses) {
    ClassEntity constantInterceptor = tryComputeConstantInterceptorFromType(
        input.instructionType, interceptedClasses);

    if (constantInterceptor == null) return null;

    // If we just happen to be in an instance method of the constant
    // interceptor, `this` is a shorter alias.
    if (constantInterceptor == _enclosingClass &&
        _graph.thisInstruction != null) {
      return _graph.thisInstruction;
    }

    ConstantValue constant = new InterceptorConstantValue(constantInterceptor);
    return _graph.addConstant(constant, _closedWorld);
  }

  ClassEntity tryComputeConstantInterceptorFromType(
      AbstractValue type, Set<ClassEntity> interceptedClasses) {
    if (_abstractValueDomain.isNull(type).isPotentiallyTrue) {
      if (_abstractValueDomain.isNull(type).isDefinitelyTrue) {
        return _commonElements.jsNullClass;
      }
    } else if (_abstractValueDomain.isIntegerOrNull(type).isDefinitelyTrue) {
      return _commonElements.jsIntClass;
    } else if (_abstractValueDomain.isDoubleOrNull(type).isDefinitelyTrue) {
      return _commonElements.jsDoubleClass;
    } else if (_abstractValueDomain.isBooleanOrNull(type).isDefinitelyTrue) {
      return _commonElements.jsBoolClass;
    } else if (_abstractValueDomain.isStringOrNull(type).isDefinitelyTrue) {
      return _commonElements.jsStringClass;
    } else if (_abstractValueDomain.isArray(type).isDefinitelyTrue) {
      return _commonElements.jsArrayClass;
    } else if (_abstractValueDomain.isNumberOrNull(type).isDefinitelyTrue &&
        !interceptedClasses.contains(_commonElements.jsIntClass) &&
        !interceptedClasses.contains(_commonElements.jsDoubleClass)) {
      // If the method being intercepted is not defined in [int] or [double] we
      // can safely use the number interceptor.  This is because none of the
      // [int] or [double] methods are called from a method defined on [num].
      return _commonElements.jsNumberClass;
    } else {
      // Try to find constant interceptor for a native class.  If the receiver
      // is constrained to a leaf native class, we can use the class's
      // interceptor directly.

      // TODO(sra): Key DOM classes like Node, Element and Event are not leaf
      // classes.  When the receiver type is not a leaf class, we might still be
      // able to use the receiver class as a constant interceptor.  It is
      // usually the case that methods defined on a non-leaf class don't test
      // for a subclass or call methods defined on a subclass.  Provided the
      // code is completely insensitive to the specific instance subclasses, we
      // can use the non-leaf class directly.
      ClassEntity element = _abstractValueDomain.getExactClass(type);
      if (element != null && _closedWorld.nativeData.isNativeClass(element)) {
        return element;
      }
    }

    return null;
  }

  // Returns the element of [instructions] that dominates all other elements, if
  // such an instruction exists.  [dominator] is an optional hint of an
  // instruction that dominates all elements of [instructions], but that is not
  // one of [instructions].
  HInstruction findDominatingInstruction(List<HInstruction> instructions,
      [HInstruction dominator]) {
    // If there is a single dominator instruction, it will be in a block which
    // dominates all the other instruction's blocks. This means that the
    // dominatorDfsIn..dominatorDfsOut range will include all the other ranges,
    // i.e. the block must have the minimum dominatorDfsIn and maximum
    // dominatorDfsOut.  We can test this in a single pass over the candidates.
    HInstruction bestInstruction = instructions.first;
    HBasicBlock bestBlock = bestInstruction.block;
    int maxDfsOut = bestBlock.dominatorDfsOut;
    for (int i = 1; i < instructions.length; i++) {
      HInstruction candidate = instructions[i];
      if (candidate == bestInstruction) continue; // ignore repeated uses
      HBasicBlock block = candidate.block;
      if (block == bestBlock) {
        bestInstruction = null; // There are two instructions in bestBlock
        continue;
      }
      if (maxDfsOut < block.dominatorDfsOut) maxDfsOut = block.dominatorDfsOut;
      if (block.dominatorDfsIn < bestBlock.dominatorDfsIn) {
        bestInstruction = candidate;
        bestBlock = block;
      }
    }

    // [bestBlock] only dominates if all other blocks are in range.
    if (maxDfsOut > bestBlock.dominatorDfsOut) return null;

    // If best block had a single candidate instruction, we can return it.
    if (bestInstruction != null) return bestInstruction;

    // If multiple instructions are present in bestBlock, we scan bestBlock from
    // the start to find first instruction. If the [dominator] hint is in the
    // same block, can start from there instead.
    Set<HInstruction> set =
        instructions.where((i) => i.block == bestBlock).toSet();
    HInstruction current =
        (dominator?.block == bestBlock) ? dominator : bestBlock.first;
    while (current != null && !set.contains(current)) current = current.next;
    assert(current != null);
    return current;
  }

  static int useCount(HInstruction user, HInstruction used) =>
      user.inputs.where((input) => input == used).length;

  @override
  bool visitInterceptor(HInterceptor node) {
    if (node.receiver.nonCheck() == _graph.explicitReceiverParameter) {
      // If `explicitReceiverParameter` is set it means the current method is an
      // interceptor method, and `this` is the interceptor.  The caller just did
      // `getInterceptor(foo).currentMethod(foo)` to enter the current method.
      node.block.rewrite(node, _graph.thisInstruction);
      return true;
    }

    rewriteSelfInterceptorUses(node);

    if (node.usedBy.isEmpty) return true;

    // Specialize the interceptor with set of classes it intercepts, considering
    // all uses.  (The specialized interceptor has a shorter dispatch chain).
    // This operation applies only where the interceptor is used to dispatch a
    // method.  Other uses, e.g. as an ordinary argument use the most general
    // interceptor.
    //
    // TODO(sra): Take into account the receiver type at each call.  e.g:
    //
    //     (a) => a.length + a.hashCode
    //
    // Currently we use the most general interceptor since all intercepted types
    // implement `hashCode`. But in this example, `a.hashCode` is only reached
    // if `a.length` succeeds, which is indicated by the hashCode receiver being
    // a HTypeKnown instruction.

    Set<ClassEntity> interceptedClasses;
    HInstruction dominator = findDominatingInstruction(node.usedBy, node);
    // If there is a call that dominates all other uses, we can use just the
    // selector of that instruction.
    if (dominator is HInvokeDynamic &&
        dominator.isCallOnInterceptor(_closedWorld) &&
        node == dominator.receiver &&
        useCount(dominator, node) == 1) {
      interceptedClasses = _interceptorData.getInterceptedClassesOn(
          dominator.selector.name, _closedWorld);
      // If we found that we need number, we must still go through all
      // uses to check if they require int, or double.
      if (interceptedClasses.contains(_commonElements.jsNumberClass) &&
          !(interceptedClasses.contains(_commonElements.jsDoubleClass) ||
              interceptedClasses.contains(_commonElements.jsIntClass))) {
        Set<ClassEntity> required;
        for (HInstruction user in node.usedBy) {
          if (user is HInvokeDynamic) {
            Set<ClassEntity> intercepted = _interceptorData
                .getInterceptedClassesOn(user.selector.name, _closedWorld);
            if (intercepted.contains(_commonElements.jsIntClass)) {
              required ??= {};
              required.add(_commonElements.jsIntClass);
            }
            if (intercepted.contains(_commonElements.jsDoubleClass)) {
              required ??= {};
              required.add(_commonElements.jsDoubleClass);
            }
          }
        }
        // Don't modify the result of
        // [_interceptorData.getInterceptedClassesOn].
        if (required != null) {
          interceptedClasses = interceptedClasses.union(required);
        }
      }
    } else {
      interceptedClasses = {};
      for (HInstruction user in node.usedBy) {
        if (user is HInvokeDynamic &&
            user.isCallOnInterceptor(_closedWorld) &&
            node == user.receiver &&
            useCount(user, node) == 1) {
          interceptedClasses.addAll(_interceptorData.getInterceptedClassesOn(
              user.selector.name, _closedWorld));
        } else if (user is HInvokeSuper &&
            user.isCallOnInterceptor(_closedWorld) &&
            node == user.receiver &&
            useCount(user, node) == 1) {
          interceptedClasses.addAll(_interceptorData.getInterceptedClassesOn(
              user.selector.name, _closedWorld));
        } else {
          // Use a most general interceptor for other instructions, example,
          // is-checks and escaping interceptors.
          interceptedClasses.addAll(_interceptorData.interceptedClasses);
          break;
        }
      }
    }

    node.interceptedClasses = interceptedClasses;

    HInstruction receiver = node.receiver;

    // Try computing a constant interceptor.
    HInstruction constantInterceptor =
        tryComputeConstantInterceptor(receiver, interceptedClasses);
    if (constantInterceptor != null) {
      node.block.rewrite(node, constantInterceptor);
      return false;
    }

    // If it is a conditional constant interceptor and was not strengthened to a
    // constant interceptor then there is nothing more we can do.
    if (node.isConditionalConstantInterceptor) return false;

    // Do we have an 'almost constant' interceptor?  The receiver could be
    // `null` but not any other JavaScript falsy value, `null` values cause
    // `NoSuchMethodError`s, and if the receiver was not null we would have a
    // constant interceptor `C`.  Then we can use `(receiver && C)` for the
    // interceptor.
    if (receiver.isNull(_abstractValueDomain).isPotentiallyTrue) {
      if (!interceptedClasses.contains(_commonElements.jsNullClass)) {
        // Can use `(receiver && C)` only if receiver is either null or truthy.
        if (!(receiver
                .isPrimitiveNumber(_abstractValueDomain)
                .isPotentiallyTrue ||
            receiver
                .isPrimitiveBoolean(_abstractValueDomain)
                .isPotentiallyTrue ||
            receiver
                .isPrimitiveString(_abstractValueDomain)
                .isPotentiallyTrue)) {
          ClassEntity interceptorClass = tryComputeConstantInterceptorFromType(
              _abstractValueDomain.excludeNull(receiver.instructionType),
              interceptedClasses);
          if (interceptorClass != null) {
            HInstruction constantInstruction = _graph.addConstant(
                new InterceptorConstantValue(interceptorClass), _closedWorld);
            node.conditionalConstantInterceptor = constantInstruction;
            constantInstruction.usedBy.add(node);
            return false;
          }
        }
      }
    }

    // Try creating a one-shot interceptor or optimized is-check
    if (node.usedBy.length != 1) return false;
    HInstruction user = node.usedBy.single;

    // If the interceptor [node] was loop hoisted, we keep the interceptor.
    if (!user.hasSameLoopHeaderAs(node)) return false;

    bool replaceUserWith(HInstruction replacement) {
      HBasicBlock block = user.block;
      block.addAfter(user, replacement);
      block.rewrite(user, replacement);
      block.remove(user);
      return false;
    }

    if (user is HInvokeDynamic) {
      if (node == user.inputs[0]) {
        // Replace the user with a [HOneShotInterceptor].
        HConstant nullConstant = _graph.addConstantNull(_closedWorld);
        List<HInstruction> inputs = new List<HInstruction>.from(user.inputs);
        inputs[0] = nullConstant;
        HOneShotInterceptor oneShotInterceptor = new HOneShotInterceptor(
            _abstractValueDomain,
            user.selector,
            user.receiverType,
            inputs,
            user.instructionType,
            user.typeArguments,
            interceptedClasses);
        oneShotInterceptor.sourceInformation = user.sourceInformation;
        oneShotInterceptor.sourceElement = user.sourceElement;
        return replaceUserWith(oneShotInterceptor);
      }
    }

    return false;
  }

  void rewriteSelfInterceptorUses(HInterceptor node) {
    HInstruction receiver = node.receiver;

    // At instructions that use the interceptor and its receiver, the receiver
    // might be refined at the use site.

    //     dynamic x = ...
    //     if (x is Mumble) {
    //       print(x.length);  // Self-interceptor here.
    //     } else {
    //       print(x.length);  //
    //     }

    finishInvoke(HInvoke invoke, Selector selector) {
      HInstruction callReceiver = invoke.getDartReceiver(_closedWorld);
      if (receiver.nonCheck() == callReceiver.nonCheck()) {
        Set<ClassEntity> interceptedClasses = _interceptorData
            .getInterceptedClassesOn(selector.name, _closedWorld);

        if (canUseSelfForInterceptor(callReceiver,
            interceptedClasses: interceptedClasses)) {
          invoke.changeUse(node, callReceiver);
        }
      }
    }

    for (HInstruction user in node.usedBy.toList()) {
      if (user is HInvokeDynamic) {
        if (user.isCallOnInterceptor(_closedWorld) &&
            node == user.inputs[0] &&
            useCount(user, node) == 1) {
          finishInvoke(user, user.selector);
        }
      } else if (user is HInvokeSuper) {
        if (user.isCallOnInterceptor(_closedWorld) &&
            node == user.inputs[0] &&
            useCount(user, node) == 1) {
          finishInvoke(user, user.selector);
        }
      } else {
        // TODO(sra): Are there other paired uses of the receiver and
        // interceptor where we can make use of a strengthened receiver?
      }
    }
  }

  @override
  bool visitOneShotInterceptor(HOneShotInterceptor node) {
    // 'Undo' the one-shot transformation if the receiver has a constant
    // interceptor.
    HInstruction constant =
        tryComputeConstantInterceptor(node.inputs[1], node.interceptedClasses);

    if (constant == null) return false;

    Selector selector = node.selector;
    AbstractValue receiverType = node.receiverType;
    HInstruction instruction;
    if (selector.isGetter) {
      instruction = new HInvokeDynamicGetter(
          selector,
          receiverType,
          node.element,
          <HInstruction>[constant, node.inputs[1]],
          true,
          node.instructionType,
          node.sourceInformation);
    } else if (selector.isSetter) {
      instruction = new HInvokeDynamicSetter(
          selector,
          receiverType,
          node.element,
          <HInstruction>[constant, node.inputs[1], node.inputs[2]],
          true,
          node.instructionType,
          node.sourceInformation);
    } else {
      List<HInstruction> inputs = new List<HInstruction>.from(node.inputs);
      inputs[0] = constant;
      instruction = new HInvokeDynamicMethod(selector, receiverType, inputs,
          node.instructionType, node.typeArguments, node.sourceInformation,
          isIntercepted: true);
    }

    HBasicBlock block = node.block;
    block.addAfter(node, instruction);
    block.rewrite(node, instruction);
    return true;
  }
}
