// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/codegen.dart' show CodegenRegistry, CodegenWorkItem;
import '../common/names.dart' show Selectors;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../common_elements.dart' show CommonElements;
import '../elements/elements.dart'
    show ClassElement, FieldElement, MethodElement;
import '../elements/entities.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart';
import '../js_backend/native_data.dart' show NativeData;
import '../js_backend/runtime_types.dart';
import '../native/native.dart' as native;
import '../options.dart';
import '../types/types.dart';
import '../universe/selector.dart' show Selector;
import '../universe/side_effects.dart' show SideEffects;
import '../util/util.dart';
import '../world.dart' show ClosedWorld;
import 'interceptor_simplifier.dart';
import 'nodes.dart';
import 'types.dart';
import 'types_propagation.dart';
import 'value_range_analyzer.dart';
import 'value_set.dart';

abstract class OptimizationPhase {
  String get name;
  void visitGraph(HGraph graph);
}

class SsaOptimizerTask extends CompilerTask {
  final JavaScriptBackend _backend;

  Map<HInstruction, Range> ranges = <HInstruction, Range>{};

  SsaOptimizerTask(this._backend) : super(_backend.compiler.measurer);

  String get name => 'SSA optimizer';

  Compiler get _compiler => _backend.compiler;

  GlobalTypeInferenceResults get _results => _compiler.globalInference.results;

  CompilerOptions get _options => _compiler.options;

  RuntimeTypesSubstitutions get _rtiSubstitutions => _backend.rtiSubstitutions;

  void optimize(CodegenWorkItem work, HGraph graph, ClosedWorld closedWorld) {
    void runPhase(OptimizationPhase phase) {
      measureSubtask(phase.name, () => phase.visitGraph(graph));
      _backend.tracer.traceGraph(phase.name, graph);
      assert(graph.isValid(), 'Graph not valid after ${phase.name}');
    }

    bool trustPrimitives = _options.trustPrimitives;
    CodegenRegistry registry = work.registry;
    Set<HInstruction> boundsChecked = new Set<HInstruction>();
    SsaCodeMotion codeMotion;
    SsaLoadElimination loadElimination;
    measure(() {
      List<OptimizationPhase> phases = <OptimizationPhase>[
        // Run trivial instruction simplification first to optimize
        // some patterns useful for type conversion.
        new SsaInstructionSimplifier(
            _results, _options, _rtiSubstitutions, closedWorld, registry),
        new SsaTypeConversionInserter(closedWorld),
        new SsaRedundantPhiEliminator(),
        new SsaDeadPhiEliminator(),
        new SsaTypePropagator(
            _results, _options, closedWorld.commonElements, closedWorld),
        // After type propagation, more instructions can be
        // simplified.
        new SsaInstructionSimplifier(
            _results, _options, _rtiSubstitutions, closedWorld, registry),
        new SsaCheckInserter(trustPrimitives, closedWorld, boundsChecked),
        new SsaInstructionSimplifier(
            _results, _options, _rtiSubstitutions, closedWorld, registry),
        new SsaCheckInserter(trustPrimitives, closedWorld, boundsChecked),
        new SsaTypePropagator(
            _results, _options, closedWorld.commonElements, closedWorld),
        // Run a dead code eliminator before LICM because dead
        // interceptors are often in the way of LICM'able instructions.
        new SsaDeadCodeEliminator(closedWorld, this),
        new SsaGlobalValueNumberer(),
        // After GVN, some instructions might need their type to be
        // updated because they now have different inputs.
        new SsaTypePropagator(
            _results, _options, closedWorld.commonElements, closedWorld),
        codeMotion = new SsaCodeMotion(),
        loadElimination = new SsaLoadElimination(_compiler, closedWorld),
        new SsaRedundantPhiEliminator(),
        new SsaDeadPhiEliminator(),
        // After GVN and load elimination the same value may be used in code
        // controlled by a test on the value, so redo 'conversion insertion' to
        // learn from the refined type.
        new SsaTypeConversionInserter(closedWorld),
        new SsaTypePropagator(
            _results, _options, closedWorld.commonElements, closedWorld),
        new SsaValueRangeAnalyzer(closedWorld, this),
        // Previous optimizations may have generated new
        // opportunities for instruction simplification.
        new SsaInstructionSimplifier(
            _results, _options, _rtiSubstitutions, closedWorld, registry),
        new SsaCheckInserter(trustPrimitives, closedWorld, boundsChecked),
      ];
      phases.forEach(runPhase);

      // Simplifying interceptors is not strictly just an optimization, it is
      // required for implementation correctness because the code generator
      // assumes it is always performed.
      runPhase(new SsaSimplifyInterceptors(
          closedWorld, work.element.enclosingClass));

      SsaDeadCodeEliminator dce = new SsaDeadCodeEliminator(closedWorld, this);
      runPhase(dce);
      if (codeMotion.movedCode ||
          dce.eliminatedSideEffects ||
          loadElimination.newGvnCandidates) {
        phases = <OptimizationPhase>[
          new SsaTypePropagator(
              _results, _options, closedWorld.commonElements, closedWorld),
          new SsaGlobalValueNumberer(),
          new SsaCodeMotion(),
          new SsaValueRangeAnalyzer(closedWorld, this),
          new SsaInstructionSimplifier(
              _results, _options, _rtiSubstitutions, closedWorld, registry),
          new SsaCheckInserter(trustPrimitives, closedWorld, boundsChecked),
          new SsaSimplifyInterceptors(closedWorld, work.element.enclosingClass),
          new SsaDeadCodeEliminator(closedWorld, this),
        ];
      } else {
        phases = <OptimizationPhase>[
          new SsaTypePropagator(
              _results, _options, closedWorld.commonElements, closedWorld),
          // Run the simplifier to remove unneeded type checks inserted by
          // type propagation.
          new SsaInstructionSimplifier(
              _results, _options, _rtiSubstitutions, closedWorld, registry),
        ];
      }
      phases.forEach(runPhase);
    });
  }
}

/// Returns `true` if [mask] represents only types that have a length that
/// cannot change.  The current implementation is conservative for the purpose
/// of identifying gvn-able lengths and mis-identifies some unions of fixed
/// length indexables (see TODO) as not fixed length.
bool isFixedLength(mask, ClosedWorld closedWorld) {
  if (mask.isContainer && mask.length != null) {
    // A container on which we have inferred the length.
    return true;
  }
  // TODO(sra): Recognize any combination of fixed length indexables.
  if (mask.containsOnly(closedWorld.commonElements.jsFixedArrayClass) ||
      mask.containsOnly(closedWorld.commonElements.jsUnmodifiableArrayClass) ||
      mask.containsOnlyString(closedWorld) ||
      closedWorld.commonMasks.isTypedArray(mask)) {
    return true;
  }
  return false;
}

/**
 * If both inputs to known operations are available execute the operation at
 * compile-time.
 */
class SsaInstructionSimplifier extends HBaseVisitor
    implements OptimizationPhase {
  // We don't produce constant-folded strings longer than this unless they have
  // a single use.  This protects against exponentially large constant folded
  // strings.
  static const MAX_SHARED_CONSTANT_FOLDED_STRING_LENGTH = 512;

  final String name = "SsaInstructionSimplifier";
  final GlobalTypeInferenceResults _globalInferenceResults;
  final CompilerOptions _options;
  final RuntimeTypesSubstitutions _rtiSubstitutions;
  final ClosedWorld _closedWorld;
  final CodegenRegistry _registry;
  HGraph _graph;

  SsaInstructionSimplifier(this._globalInferenceResults, this._options,
      this._rtiSubstitutions, this._closedWorld, this._registry);

  CommonElements get commonElements => _closedWorld.commonElements;

  ConstantSystem get constantSystem => _closedWorld.constantSystem;

  NativeData get _nativeData => _closedWorld.nativeData;

  void visitGraph(HGraph visitee) {
    _graph = visitee;
    visitDominatorTree(visitee);
  }

  visitBasicBlock(HBasicBlock block) {
    HInstruction instruction = block.first;
    while (instruction != null) {
      HInstruction next = instruction.next;
      HInstruction replacement = instruction.accept(this);
      if (replacement != instruction) {
        block.rewrite(instruction, replacement);

        // The intersection of double and int return conflicting, and
        // because of our number implementation for JavaScript, it
        // might be that an operation thought to return double, can be
        // simplified to an int. For example:
        // `2.5 * 10`.
        if (!(replacement.isNumberOrNull(_closedWorld) &&
            instruction.isNumberOrNull(_closedWorld))) {
          // If we can replace [instruction] with [replacement], then
          // [replacement]'s type can be narrowed.
          TypeMask newType = replacement.instructionType
              .intersection(instruction.instructionType, _closedWorld);
          replacement.instructionType = newType;
        }

        // If the replacement instruction does not know its
        // source element, use the source element of the
        // instruction.
        replacement.sourceElement ??= instruction.sourceElement;
        replacement.sourceInformation ??= instruction.sourceInformation;
        if (!replacement.isInBasicBlock()) {
          // The constant folding can return an instruction that is already
          // part of the graph (like an input), so we only add the replacement
          // if necessary.
          block.addAfter(instruction, replacement);
          // Visit the replacement as the next instruction in case it
          // can also be constant folded away.
          next = replacement;
        }
        block.remove(instruction);
      }
      instruction = next;
    }
  }

  HInstruction visitInstruction(HInstruction node) {
    return node;
  }

  ConstantValue getConstantFromType(HInstruction node) {
    if (node.isValue() && !node.canBeNull()) {
      ValueTypeMask valueMask = node.instructionType;
      if (valueMask.value.isBool) {
        return valueMask.value;
      }
      // TODO(het): consider supporting other values (short strings?)
    }
    return null;
  }

  void propagateConstantValueToUses(HInstruction node) {
    if (node.usedBy.isEmpty) return;
    ConstantValue value = getConstantFromType(node);
    if (value != null) {
      HConstant constant = _graph.addConstant(value, _closedWorld);
      for (HInstruction user in node.usedBy.toList()) {
        user.changeUse(node, constant);
      }
    }
  }

  HInstruction visitParameterValue(HParameterValue node) {
    // [HParameterValue]s are either the value of the parameter (in fully SSA
    // converted code), or the mutable variable containing the value (in
    // incompletely SSA converted code, e.g. methods containing exceptions).
    //
    // If the parameter is used as a mutable variable we cannot replace the
    // variable with a value.
    //
    // If the parameter is used as a mutable variable but never written, first
    // convert to a value parameter.

    if (node.usedAsVariable()) {
      if (!node.usedBy.every((user) => user is HLocalGet)) return node;
      // Trivial SSA-conversion. Replace all HLocalGet instructions with the
      // parameter.
      for (HLocalGet user in node.usedBy.toList()) {
        user.block.rewrite(user, node);
        user.block.remove(user);
      }
    }

    propagateConstantValueToUses(node);
    return node;
  }

  HInstruction visitBoolify(HBoolify node) {
    List<HInstruction> inputs = node.inputs;
    assert(inputs.length == 1);
    HInstruction input = inputs[0];
    if (input.isBoolean(_closedWorld)) return input;

    // If the code is unreachable, remove the HBoolify.  This can happen when
    // there is a throw expression in a short-circuit conditional.  Removing the
    // unreachable HBoolify makes it easier to reconstruct the short-circuit
    // operation.
    if (input.instructionType.isEmpty) return input;

    // All values that cannot be 'true' are boolified to false.
    TypeMask mask = input.instructionType;
    if (!mask.contains(commonElements.jsBoolClass, _closedWorld)) {
      return _graph.addConstantBool(false, _closedWorld);
    }
    return node;
  }

  HInstruction visitNot(HNot node) {
    List<HInstruction> inputs = node.inputs;
    assert(inputs.length == 1);
    HInstruction input = inputs[0];
    if (input is HConstant) {
      HConstant constant = input;
      bool isTrue = constant.constant.isTrue;
      return _graph.addConstantBool(!isTrue, _closedWorld);
    } else if (input is HNot) {
      return input.inputs[0];
    }
    return node;
  }

  HInstruction visitInvokeUnary(HInvokeUnary node) {
    HInstruction folded =
        foldUnary(node.operation(constantSystem), node.operand);
    return folded != null ? folded : node;
  }

  HInstruction foldUnary(UnaryOperation operation, HInstruction operand) {
    if (operand is HConstant) {
      HConstant receiver = operand;
      ConstantValue folded = operation.fold(receiver.constant);
      if (folded != null) return _graph.addConstant(folded, _closedWorld);
    }
    return null;
  }

  HInstruction tryOptimizeLengthInterceptedGetter(HInvokeDynamic node) {
    HInstruction actualReceiver = node.inputs[1];
    if (actualReceiver.isIndexablePrimitive(_closedWorld)) {
      if (actualReceiver.isConstantString()) {
        HConstant constantInput = actualReceiver;
        StringConstantValue constant = constantInput.constant;
        return _graph.addConstantInt(constant.length, _closedWorld);
      } else if (actualReceiver.isConstantList()) {
        HConstant constantInput = actualReceiver;
        ListConstantValue constant = constantInput.constant;
        return _graph.addConstantInt(constant.length, _closedWorld);
      }
      bool isFixed =
          isFixedLength(actualReceiver.instructionType, _closedWorld);
      TypeMask actualType = node.instructionType;
      TypeMask resultType = _closedWorld.commonMasks.positiveIntType;
      // If we already have computed a more specific type, keep that type.
      if (HInstruction.isInstanceOf(
          actualType, commonElements.jsUInt31Class, _closedWorld)) {
        resultType = _closedWorld.commonMasks.uint31Type;
      } else if (HInstruction.isInstanceOf(
          actualType, commonElements.jsUInt32Class, _closedWorld)) {
        resultType = _closedWorld.commonMasks.uint32Type;
      }
      HGetLength result =
          new HGetLength(actualReceiver, resultType, isAssignable: !isFixed);
      return result;
    } else if (actualReceiver.isConstantMap()) {
      HConstant constantInput = actualReceiver;
      MapConstantValue constant = constantInput.constant;
      return _graph.addConstantInt(constant.length, _closedWorld);
    }
    return null;
  }

  HInstruction handleInterceptedCall(HInvokeDynamic node) {
    // Try constant folding the instruction.
    Operation operation = node.specializer.operation(constantSystem);
    if (operation != null) {
      HInstruction instruction = node.inputs.length == 2
          ? foldUnary(operation, node.inputs[1])
          : foldBinary(operation, node.inputs[1], node.inputs[2]);
      if (instruction != null) return instruction;
    }

    // Try converting the instruction to a builtin instruction.
    HInstruction instruction = node.specializer.tryConvertToBuiltin(
        node,
        _graph,
        _globalInferenceResults,
        _options,
        commonElements,
        _closedWorld);
    if (instruction != null) return instruction;

    Selector selector = node.selector;
    TypeMask mask = node.mask;
    HInstruction input = node.inputs[1];

    bool applies(MemberEntity element) {
      return selector.applies(element) &&
          (mask == null || mask.canHit(element, selector, _closedWorld));
    }

    if (selector.isCall || selector.isOperator) {
      FunctionEntity target;
      if (input.isExtendableArray(_closedWorld)) {
        if (applies(commonElements.jsArrayRemoveLast)) {
          target = commonElements.jsArrayRemoveLast;
        } else if (applies(commonElements.jsArrayAdd)) {
          // The codegen special cases array calls, but does not
          // inline argument type checks.
          if (!_options.enableTypeAssertions) {
            target = commonElements.jsArrayAdd;
          }
        }
      } else if (input.isStringOrNull(_closedWorld)) {
        if (applies(commonElements.jsStringSplit)) {
          HInstruction argument = node.inputs[2];
          if (argument.isString(_closedWorld)) {
            target = commonElements.jsStringSplit;
          }
        } else if (applies(commonElements.jsStringOperatorAdd)) {
          // `operator+` is turned into a JavaScript '+' so we need to
          // make sure the receiver and the argument are not null.
          // TODO(sra): Do this via [node.specializer].
          HInstruction argument = node.inputs[2];
          if (argument.isString(_closedWorld) && !input.canBeNull()) {
            return new HStringConcat(input, argument, node.instructionType);
          }
        } else if (applies(commonElements.jsStringToString) &&
            !input.canBeNull()) {
          return input;
        }
      }
      if (target != null) {
        // TODO(ngeoffray): There is a strong dependency between codegen
        // and this optimization that the dynamic invoke does not need an
        // interceptor. We currently need to keep a
        // HInvokeDynamicMethod and not create a HForeign because
        // HForeign is too opaque for the SsaCheckInserter (that adds a
        // bounds check on removeLast). Once we start inlining, the
        // bounds check will become explicit, so we won't need this
        // optimization.
        HInvokeDynamicMethod result = new HInvokeDynamicMethod(node.selector,
            node.mask, node.inputs.sublist(1), node.instructionType);
        result.element = target;
        return result;
      }
    } else if (selector.isGetter) {
      if (selector.applies(commonElements.jsIndexableLength)) {
        HInstruction optimized = tryOptimizeLengthInterceptedGetter(node);
        if (optimized != null) return optimized;
      }
    }

    return node;
  }

  HInstruction visitInvokeDynamicMethod(HInvokeDynamicMethod node) {
    propagateConstantValueToUses(node);
    if (node.isInterceptedCall) {
      HInstruction folded = handleInterceptedCall(node);
      if (folded != node) return folded;
    }

    TypeMask receiverType = node.getDartReceiver(_closedWorld).instructionType;
    MemberEntity element =
        _closedWorld.locateSingleElement(node.selector, receiverType);
    // TODO(ngeoffray): Also fold if it's a getter or variable.
    if (element != null &&
        element.isFunction
        // If we found out that the only target is an implicitly called
        // [:noSuchMethod:] we just ignore it.
        &&
        node.selector.applies(element)) {
      FunctionEntity method = element;

      if (_nativeData.isNativeMember(method)) {
        HInstruction folded = tryInlineNativeMethod(node, method);
        if (folded != null) return folded;
      } else {
        // TODO(ngeoffray): If the method has optional parameters,
        // we should pass the default values.
        ParameterStructure parameters = method.parameterStructure;
        if (parameters.optionalParameters == 0 ||
            parameters.requiredParameters + parameters.optionalParameters ==
                node.selector.argumentCount) {
          node.element = method;
        }
      }
      return node;
    }

    // Replace method calls through fields with a closure call on the value of
    // the field. This usually removes the demand for the call-through stub and
    // makes the field load available to further optimization, e.g. LICM.

    if (element != null &&
        element.isField &&
        element.name == node.selector.name) {
      FieldEntity field = element;
      if (!_nativeData.isNativeMember(field) &&
          !node.isCallOnInterceptor(_closedWorld)) {
        HInstruction receiver = node.getDartReceiver(_closedWorld);
        TypeMask type = TypeMaskFactory.inferredTypeForMember(
            // ignore: UNNECESSARY_CAST
            field as Entity,
            _globalInferenceResults);
        HInstruction load = new HFieldGet(field, receiver, type);
        node.block.addBefore(node, load);
        Selector callSelector = new Selector.callClosureFrom(node.selector);
        List<HInstruction> inputs = <HInstruction>[load]
          ..addAll(node.inputs.skip(node.isInterceptedCall ? 2 : 1));
        HInstruction closureCall =
            new HInvokeClosure(callSelector, inputs, node.instructionType)
              ..sourceInformation = node.sourceInformation;
        node.block.addAfter(load, closureCall);
        return closureCall;
      }
    }

    return node;
  }

  HInstruction tryInlineNativeMethod(
      HInvokeDynamicMethod node, MethodElement method) {
    // Enable direct calls to a native method only if we don't run in checked
    // mode, where the Dart version may have type annotations on parameters and
    // return type that it should check.
    // Also check that the parameters are not functions: it's the callee that
    // will translate them to JS functions.
    //
    // TODO(ngeoffray): There are some cases where we could still inline in
    // checked mode if we know the arguments have the right type. And we could
    // do the closure conversion as well as the return type annotation check.

    if (!node.isInterceptedCall) return null;

    // TODO(sra): Check for legacy methods with bodies in the native strings.
    //   foo() native 'return something';
    // They should not be used.

    ResolutionFunctionType type = method.type;
    if (type.namedParameters.isNotEmpty) return null;

    // Return types on native methods don't need to be checked, since the
    // declaration has to be truthful.

    // The call site might omit optional arguments. The inlined code must
    // preserve the number of arguments, so check only the actual arguments.

    List<HInstruction> inputs = node.inputs.sublist(1);
    bool canInline = true;
    if (_options.enableTypeAssertions && inputs.length > 1) {
      // TODO(sra): Check if [input] is guaranteed to pass the parameter
      // type check.  Consider using a strengthened type check to avoid
      // passing `null` to primitive types since the native methods usually
      // have non-nullable primitive parameter types.
      canInline = false;
    } else {
      int inputPosition = 1; // Skip receiver.
      void checkParameterType(ResolutionDartType type) {
        if (inputPosition++ < inputs.length && canInline) {
          if (type.unaliased.isFunctionType) {
            canInline = false;
          }
        }
      }

      type.parameterTypes.forEach(checkParameterType);
      type.optionalParameterTypes.forEach(checkParameterType);
      type.namedParameterTypes.forEach(checkParameterType);
    }

    if (!canInline) return null;

    // Strengthen instruction type from annotations to help optimize
    // dependent instructions.
    native.NativeBehavior nativeBehavior =
        _nativeData.getNativeMethodBehavior(method);
    TypeMask returnType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, _closedWorld);
    HInvokeDynamicMethod result =
        new HInvokeDynamicMethod(node.selector, node.mask, inputs, returnType);
    result.element = method;
    return result;
  }

  HInstruction visitBoundsCheck(HBoundsCheck node) {
    HInstruction index = node.index;
    if (index.isInteger(_closedWorld)) return node;
    if (index.isConstant()) {
      HConstant constantInstruction = index;
      assert(!constantInstruction.constant.isInt);
      if (!constantSystem.isInt(constantInstruction.constant)) {
        // -0.0 is a double but will pass the runtime integer check.
        node.staticChecks = HBoundsCheck.ALWAYS_FALSE;
      }
    }
    return node;
  }

  HInstruction foldBinary(
      BinaryOperation operation, HInstruction left, HInstruction right) {
    if (left is HConstant && right is HConstant) {
      HConstant op1 = left;
      HConstant op2 = right;
      ConstantValue folded = operation.fold(op1.constant, op2.constant);
      if (folded != null) return _graph.addConstant(folded, _closedWorld);
    }
    return null;
  }

  HInstruction visitAdd(HAdd node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    // We can only perform this rewriting on Integer, as it is not
    // valid for -0.0.
    if (left.isInteger(_closedWorld) && right.isInteger(_closedWorld)) {
      if (left is HConstant && left.constant.isZero) return right;
      if (right is HConstant && right.constant.isZero) return left;
    }
    return super.visitAdd(node);
  }

  HInstruction visitMultiply(HMultiply node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    if (left.isNumber(_closedWorld) && right.isNumber(_closedWorld)) {
      if (left is HConstant && left.constant.isOne) return right;
      if (right is HConstant && right.constant.isOne) return left;
    }
    return super.visitMultiply(node);
  }

  HInstruction visitInvokeBinary(HInvokeBinary node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    BinaryOperation operation = node.operation(constantSystem);
    HConstant folded = foldBinary(operation, left, right);
    if (folded != null) return folded;
    return node;
  }

  bool allUsersAreBoolifies(HInstruction instruction) {
    List<HInstruction> users = instruction.usedBy;
    int length = users.length;
    for (int i = 0; i < length; i++) {
      if (users[i] is! HBoolify) return false;
    }
    return true;
  }

  HInstruction visitRelational(HRelational node) {
    if (allUsersAreBoolifies(node)) {
      // TODO(ngeoffray): Call a boolified selector.
      // This node stays the same, but the Boolify node will go away.
    }
    // Note that we still have to call [super] to make sure that we end up
    // in the remaining optimizations.
    return super.visitRelational(node);
  }

  HInstruction handleIdentityCheck(HRelational node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    TypeMask leftType = left.instructionType;
    TypeMask rightType = right.instructionType;

    HInstruction makeTrue() => _graph.addConstantBool(true, _closedWorld);
    HInstruction makeFalse() => _graph.addConstantBool(false, _closedWorld);

    // Intersection of int and double return conflicting, so
    // we don't optimize on numbers to preserve the runtime semantics.
    if (!(left.isNumberOrNull(_closedWorld) &&
        right.isNumberOrNull(_closedWorld))) {
      if (leftType.isDisjoint(rightType, _closedWorld)) {
        return makeFalse();
      }
    }

    if (left.isNull() && right.isNull()) {
      return makeTrue();
    }

    HInstruction compareConstant(HConstant constant, HInstruction input) {
      if (constant.constant.isTrue) {
        return input;
      } else {
        return new HNot(input, _closedWorld.commonMasks.boolType);
      }
    }

    if (left.isConstantBoolean() && right.isBoolean(_closedWorld)) {
      return compareConstant(left, right);
    }

    if (right.isConstantBoolean() && left.isBoolean(_closedWorld)) {
      return compareConstant(right, left);
    }

    if (identical(left.nonCheck(), right.nonCheck())) {
      // Avoid constant-folding `identical(x, x)` when `x` might be double.  The
      // dart2js runtime has not always been consistent with the Dart
      // specification (section 16.0.1), which makes distinctions on NaNs and
      // -0.0 that are hard to implement efficiently.
      if (left.isIntegerOrNull(_closedWorld)) return makeTrue();
      if (!left.canBePrimitiveNumber(_closedWorld)) return makeTrue();
    }

    return null;
  }

  HInstruction visitIdentity(HIdentity node) {
    HInstruction newInstruction = handleIdentityCheck(node);
    return newInstruction == null ? super.visitIdentity(node) : newInstruction;
  }

  void simplifyCondition(
      HBasicBlock block, HInstruction condition, bool value) {
    // `excludePhiOutEdges: true` prevents replacing a partially dominated phi
    // node input with a constant. This tends to add unnecessary assignments, by
    // transforming the following, which has phi(false, x),
    //
    //    if (x) { init(); x = false; }
    //
    // into this, which has phi(false, false)
    //
    //    if (x) { init(); x = false; } else { x = false; }
    //
    // which is further simplifed to:
    //
    //    if (x) { init(); }
    //    ...
    //    x = false;
    //
    // This is mostly harmless (if a little confusing) but does cause a lot of
    // `x = false;` copies to be inserted when a loop body has many continue
    // statements or ends with a switch.
    var uses =
        DominatedUses.of(condition, block.first, excludePhiOutEdges: true);
    if (uses.isEmpty) return;
    uses.replaceWith(_graph.addConstantBool(value, _closedWorld));
  }

  HInstruction visitIf(HIf node) {
    HInstruction condition = node.condition;
    if (condition.isConstant()) return node;
    bool isNegated = condition is HNot;

    if (isNegated) {
      condition = condition.inputs[0];
    } else {
      // It is possible for LICM to move a negated version of the
      // condition out of the loop where it used. We still want to
      // simplify the nested use of the condition in that case, so
      // we look for all dominating negated conditions and replace
      // nested uses of them with true or false.
      Iterable<HInstruction> dominating = condition.usedBy
          .where((user) => user is HNot && user.dominates(node));
      dominating.forEach((hoisted) {
        simplifyCondition(node.thenBlock, hoisted, false);
        simplifyCondition(node.elseBlock, hoisted, true);
      });
    }
    simplifyCondition(node.thenBlock, condition, !isNegated);
    simplifyCondition(node.elseBlock, condition, isNegated);
    return node;
  }

  HInstruction visitIs(HIs node) {
    DartType type = node.typeExpression;

    if (!node.isRawCheck) {
      return node;
    } else if (type.isTypedef) {
      return node;
    } else if (type.isFunctionType) {
      return node;
    }

    if (type == commonElements.objectType || type.treatAsDynamic) {
      return _graph.addConstantBool(true, _closedWorld);
    }
    InterfaceType interfaceType = type;
    ClassEntity element = interfaceType.element;
    HInstruction expression = node.expression;
    if (expression.isInteger(_closedWorld)) {
      if (element == commonElements.intClass ||
          element == commonElements.numClass ||
          commonElements.isNumberOrStringSupertype(element)) {
        return _graph.addConstantBool(true, _closedWorld);
      } else if (element == commonElements.doubleClass) {
        // We let the JS semantics decide for that check. Currently
        // the code we emit will always return true.
        return node;
      } else {
        return _graph.addConstantBool(false, _closedWorld);
      }
    } else if (expression.isDouble(_closedWorld)) {
      if (element == commonElements.doubleClass ||
          element == commonElements.numClass ||
          commonElements.isNumberOrStringSupertype(element)) {
        return _graph.addConstantBool(true, _closedWorld);
      } else if (element == commonElements.intClass) {
        // We let the JS semantics decide for that check. Currently
        // the code we emit will return true for a double that can be
        // represented as a 31-bit integer and for -0.0.
        return node;
      } else {
        return _graph.addConstantBool(false, _closedWorld);
      }
    } else if (expression.isNumber(_closedWorld)) {
      if (element == commonElements.numClass) {
        return _graph.addConstantBool(true, _closedWorld);
      } else {
        // We cannot just return false, because the expression may be of
        // type int or double.
      }
    } else if (expression.canBePrimitiveNumber(_closedWorld) &&
        element == commonElements.intClass) {
      // We let the JS semantics decide for that check.
      return node;
      // We need the [:hasTypeArguments:] check because we don't have
      // the notion of generics in the backend. For example, [:this:] in
      // a class [:A<T>:], is currently always considered to have the
      // raw type.
    } else if (!RuntimeTypesSubstitutions.hasTypeArguments(type)) {
      TypeMask expressionMask = expression.instructionType;
      assert(TypeMask.assertIsNormalized(expressionMask, _closedWorld));
      TypeMask typeMask = (element == commonElements.nullClass)
          ? new TypeMask.subtype(element, _closedWorld)
          : new TypeMask.nonNullSubtype(element, _closedWorld);
      if (expressionMask.union(typeMask, _closedWorld) == typeMask) {
        return _graph.addConstantBool(true, _closedWorld);
      } else if (expressionMask.isDisjoint(typeMask, _closedWorld)) {
        return _graph.addConstantBool(false, _closedWorld);
      }
    }
    return node;
  }

  HInstruction visitTypeConversion(HTypeConversion node) {
    ResolutionDartType type = node.typeExpression;
    if (type != null) {
      if (type.isMalformed) {
        // Malformed types are treated as dynamic statically, but should
        // throw a type error at runtime.
        return node;
      }
      if (type.isTypeVariable) {
        return node;
      }
      if (!type.treatAsRaw) {
        HInstruction input = node.checkedInput;
        // `null` always passes type conversion.
        if (input.isNull()) return input;
        // TODO(sra): We can statically check [input] if it is a constructor.
        // TODO(sra): We can statically check [input] if it is load from a field
        // of the same ground type, or load from a field of a parameterized type
        // with the same receiver.
        return node;
      }
      if (type.isFunctionType) {
        HInstruction input = node.checkedInput;
        // `null` always passes type conversion.
        if (input.isNull()) return input;
        // TODO(johnniwinther): Optimize function type conversions.
        // TODO(sra): We can statically check [input] if it is a closure getter.
        return node;
      }
    }
    return removeIfCheckAlwaysSucceeds(node, node.checkedType);
  }

  HInstruction visitTypeKnown(HTypeKnown node) {
    return removeIfCheckAlwaysSucceeds(node, node.knownType);
  }

  HInstruction removeIfCheckAlwaysSucceeds(HCheck node, TypeMask checkedType) {
    if (checkedType.containsAll(_closedWorld)) return node;
    HInstruction input = node.checkedInput;
    TypeMask inputType = input.instructionType;
    return inputType.isInMask(checkedType, _closedWorld) ? input : node;
  }

  FieldEntity findConcreteFieldForDynamicAccess(
      HInstruction receiver, Selector selector) {
    TypeMask receiverType = receiver.instructionType;
    return _closedWorld.locateSingleField(selector, receiverType);
  }

  HInstruction visitFieldGet(HFieldGet node) {
    if (node.isNullCheck) return node;
    var receiver = node.receiver;

    // HFieldGet of a constructed constant can be replaced with the constant's
    // field.
    if (receiver is HConstant) {
      ConstantValue constant = receiver.constant;
      if (constant.isConstructedObject) {
        ConstructedConstantValue constructedConstant = constant;
        Map<FieldEntity, ConstantValue> fields = constructedConstant.fields;
        ConstantValue value = fields[node.element];
        if (value != null) {
          return _graph.addConstant(value, _closedWorld);
        }
      }
    }

    return node;
  }

  HInstruction visitGetLength(HGetLength node) {
    dynamic receiver = node.receiver;
    if (_graph.allocatedFixedLists.contains(receiver)) {
      // TODO(ngeoffray): checking if the second input is an integer
      // should not be necessary but it currently makes it easier for
      // other optimizations to reason about a fixed length constructor
      // that we know takes an int.
      if (receiver.inputs[0].isInteger(_closedWorld)) {
        return receiver.inputs[0];
      }
    } else if (receiver.isConstantList() || receiver.isConstantString()) {
      return _graph.addConstantInt(receiver.constant.length, _closedWorld);
    } else {
      dynamic type = receiver.instructionType;
      if (type.isContainer && type.length != null) {
        HInstruction constant =
            _graph.addConstantInt(type.length, _closedWorld);
        if (type.isNullable) {
          // If the container can be null, we update all uses of the length
          // access to use the constant instead, but keep the length access in
          // the graph, to ensure we still have a null check.
          node.block.rewrite(node, constant);
          return node;
        } else {
          return constant;
        }
      }
    }

    if (node.isAssignable &&
        isFixedLength(receiver.instructionType, _closedWorld)) {
      // The input type has changed to fixed-length so change to an unassignable
      // HGetLength to allow more GVN optimizations.
      return new HGetLength(receiver, node.instructionType,
          isAssignable: false);
    }
    return node;
  }

  HInstruction visitIndex(HIndex node) {
    if (node.receiver.isConstantList() && node.index.isConstantInteger()) {
      dynamic instruction = node.receiver;
      List<ConstantValue> entries = instruction.constant.entries;
      instruction = node.index;
      int index = instruction.constant.primitiveValue;
      if (index >= 0 && index < entries.length) {
        return _graph.addConstant(entries[index], _closedWorld);
      }
    }
    return node;
  }

  HInstruction visitInvokeDynamicGetter(HInvokeDynamicGetter node) {
    propagateConstantValueToUses(node);
    if (node.isInterceptedCall) {
      HInstruction folded = handleInterceptedCall(node);
      if (folded != node) return folded;
    }
    HInstruction receiver = node.getDartReceiver(_closedWorld);
    FieldEntity field =
        findConcreteFieldForDynamicAccess(receiver, node.selector);
    if (field != null) return directFieldGet(receiver, field);

    if (node.element == null) {
      MemberEntity element = _closedWorld.locateSingleElement(
          node.selector, receiver.instructionType);
      if (element != null && element.name == node.selector.name) {
        node.element = element;
        if (element.isFunction) {
          // A property extraction getter, aka a tear-off.
          node.sideEffects.clearAllDependencies();
          node.sideEffects.clearAllSideEffects();
          node.setUseGvn(); // We don't care about identity of tear-offs.
        }
      }
    }
    return node;
  }

  HInstruction directFieldGet(HInstruction receiver, FieldEntity field) {
    bool isAssignable = !_closedWorld.fieldNeverChanges(field);

    TypeMask type;
    if (_nativeData.isNativeClass(field.enclosingClass)) {
      type = TypeMaskFactory.fromNativeBehavior(
          _nativeData.getNativeFieldLoadBehavior(field), _closedWorld);
    } else {
      type = TypeMaskFactory.inferredTypeForMember(
          // ignore: UNNECESSARY_CAST
          field as Entity,
          _globalInferenceResults);
    }

    return new HFieldGet(field, receiver, type, isAssignable: isAssignable);
  }

  HInstruction visitInvokeDynamicSetter(HInvokeDynamicSetter node) {
    if (node.isInterceptedCall) {
      HInstruction folded = handleInterceptedCall(node);
      if (folded != node) return folded;
    }

    HInstruction receiver = node.getDartReceiver(_closedWorld);
    FieldEntity field =
        findConcreteFieldForDynamicAccess(receiver, node.selector);
    if (field == null || !field.isAssignable) return node;
    // Use `node.inputs.last` in case the call follows the interceptor calling
    // convention, but is not a call on an interceptor.
    HInstruction value = node.inputs.last;
    if (_options.enableTypeAssertions) {
      // TODO(johnniwinther): Support field entities.
      FieldElement element = field;
      DartType type = element.type;
      if (!type.treatAsRaw ||
          type.isTypeVariable ||
          type.unaliased.isFunctionType) {
        // We cannot generate the correct type representation here, so don't
        // inline this access.
        // TODO(sra): If the input is such that we don't need a type check, we
        // can skip the test an generate the HFieldSet.
        return node;
      }
      HInstruction other = value.convertType(
          _closedWorld, type, HTypeConversion.CHECKED_MODE_CHECK);
      if (other != value) {
        node.block.addBefore(node, other);
        value = other;
      }
    }
    return new HFieldSet(field, receiver, value);
  }

  HInstruction visitInvokeStatic(HInvokeStatic node) {
    propagateConstantValueToUses(node);
    MemberEntity element = node.element;

    if (element == commonElements.identicalFunction) {
      if (node.inputs.length == 2) {
        return new HIdentity(node.inputs[0], node.inputs[1], null,
            _closedWorld.commonMasks.boolType)
          ..sourceInformation = node.sourceInformation;
      }
    } else if (element == commonElements.checkConcurrentModificationError) {
      if (node.inputs.length == 2) {
        HInstruction firstArgument = node.inputs[0];
        if (firstArgument is HConstant) {
          HConstant constant = firstArgument;
          if (constant.constant.isTrue) return constant;
        }
      }
    } else if (element == commonElements.checkInt) {
      if (node.inputs.length == 1) {
        HInstruction argument = node.inputs[0];
        if (argument.isInteger(_closedWorld)) return argument;
      }
    } else if (element == commonElements.checkNum) {
      if (node.inputs.length == 1) {
        HInstruction argument = node.inputs[0];
        if (argument.isNumber(_closedWorld)) return argument;
      }
    } else if (element == commonElements.checkString) {
      if (node.inputs.length == 1) {
        HInstruction argument = node.inputs[0];
        if (argument.isString(_closedWorld)) return argument;
      }
    }
    return node;
  }

  HInstruction visitStringConcat(HStringConcat node) {
    // Simplify string concat:
    //
    //     "" + R                ->  R
    //     L + ""                ->  L
    //     "L" + "R"             ->  "LR"
    //     (prefix + "L") + "R"  ->  prefix + "LR"
    //
    StringConstantValue getString(HInstruction instruction) {
      if (!instruction.isConstantString()) return null;
      HConstant constant = instruction;
      return constant.constant;
    }

    StringConstantValue leftString = getString(node.left);
    if (leftString != null && leftString.primitiveValue.length == 0) {
      return node.right;
    }

    StringConstantValue rightString = getString(node.right);
    if (rightString == null) return node;
    if (rightString.primitiveValue.length == 0) return node.left;

    HInstruction prefix = null;
    if (leftString == null) {
      if (node.left is! HStringConcat) return node;
      HStringConcat leftConcat = node.left;
      // Don't undo CSE.
      if (leftConcat.usedBy.length != 1) return node;
      prefix = leftConcat.left;
      leftString = getString(leftConcat.right);
      if (leftString == null) return node;
    }

    if (leftString.primitiveValue.length + rightString.primitiveValue.length >
        MAX_SHARED_CONSTANT_FOLDED_STRING_LENGTH) {
      if (node.usedBy.length > 1) return node;
    }

    HInstruction folded = _graph.addConstant(
        constantSystem.createString(
            leftString.primitiveValue + rightString.primitiveValue),
        _closedWorld);
    if (prefix == null) return folded;
    return new HStringConcat(
        prefix, folded, _closedWorld.commonMasks.stringType);
  }

  HInstruction visitStringify(HStringify node) {
    HInstruction input = node.inputs[0];
    if (input.isString(_closedWorld)) return input;

    HInstruction tryConstant() {
      if (!input.isConstant()) return null;
      HConstant constant = input;
      if (!constant.constant.isPrimitive) return null;
      if (constant.constant.isInt) {
        // Only constant-fold int.toString() when Dart and JS results the same.
        // TODO(18103): We should be able to remove this work-around when issue
        // 18103 is resolved by providing the correct string.
        IntConstantValue intConstant = constant.constant;
        // Very conservative range.
        if (!intConstant.isUInt32()) return null;
      }
      PrimitiveConstantValue primitive = constant.constant;
      return _graph.addConstant(
          constantSystem.createString('${primitive.primitiveValue}'),
          _closedWorld);
    }

    HInstruction tryToString() {
      // If the `toString` method is guaranteed to return a string we can call
      // it directly. Keep the stringifier for primitives (since they have fast
      // path code in the stringifier) and for classes requiring interceptors
      // (since SsaInstructionSimplifier runs after SsaSimplifyInterceptors).
      if (input.canBePrimitive(_closedWorld)) return null;
      if (input.canBeNull()) return null;
      Selector selector = Selectors.toString_;
      TypeMask toStringType = TypeMaskFactory.inferredTypeForSelector(
          selector, input.instructionType, _globalInferenceResults);
      if (!toStringType.containsOnlyString(_closedWorld)) return null;
      // All intercepted classes extend `Interceptor`, so if the receiver can't
      // be a class extending `Interceptor` then it can be called directly.
      if (new TypeMask.nonNullSubclass(
              commonElements.jsInterceptorClass, _closedWorld)
          .isDisjoint(input.instructionType, _closedWorld)) {
        var inputs = <HInstruction>[input, input]; // [interceptor, receiver].
        HInstruction result = new HInvokeDynamicMethod(
            selector,
            input.instructionType, // receiver mask.
            inputs,
            toStringType)
          ..sourceInformation = node.sourceInformation;
        return result;
      }
      return null;
    }

    return tryConstant() ?? tryToString() ?? node;
  }

  HInstruction visitOneShotInterceptor(HOneShotInterceptor node) {
    return handleInterceptedCall(node);
  }

  bool needsSubstitutionForTypeVariableAccess(ClassEntity cls) {
    if (_closedWorld.isUsedAsMixin(cls)) return true;

    return _closedWorld.anyStrictSubclassOf(cls, (ClassEntity subclass) {
      return !_rtiSubstitutions.isTrivialSubstitution(subclass, cls);
    });
  }

  HInstruction visitTypeInfoExpression(HTypeInfoExpression node) {
    // Identify the case where the type info expression would be of the form:
    //
    //  [getTypeArgumentByIndex(this, 0), .., getTypeArgumentByIndex(this, k)]
    //
    // and k is the number of type arguments of 'this'.  We can simply copy the
    // list from 'this'.
    HInstruction tryCopyInfo() {
      if (node.kind != TypeInfoExpressionKind.INSTANCE) return null;

      HInstruction source;
      int expectedIndex = 0;

      for (HInstruction argument in node.inputs) {
        if (argument is HTypeInfoReadVariable) {
          HInstruction nextSource = argument.object;
          if (nextSource is HThis) {
            if (source == null) {
              source = nextSource;
              ClassElement contextClass =
                  nextSource.sourceElement.enclosingClass;
              if (node.inputs.length != contextClass.typeVariables.length) {
                return null;
              }
              if (needsSubstitutionForTypeVariableAccess(contextClass)) {
                return null;
              }
            }
            if (nextSource != source) return null;
            // Check that the index is the one we expect.
            int index = argument.variable.element.index;
            if (index != expectedIndex++) return null;
          } else {
            // TODO(sra): Handle non-this cases (i.e. inlined code). Some
            // non-this cases will have a TypeMask that does not need
            // substitution, even though the general case does, e.g. inlining a
            // method on an exact class.
            return null;
          }
        } else {
          return null;
        }
      }

      if (source == null) return null;
      return new HTypeInfoReadRaw(source, _closedWorld.commonMasks.dynamicType);
    }

    // TODO(sra): Consider fusing type expression trees with no type variables,
    // as these could be represented like constants.

    return tryCopyInfo() ?? node;
  }

  HInstruction visitTypeInfoReadVariable(HTypeInfoReadVariable node) {
    ResolutionTypeVariableType variable = node.variable;
    HInstruction object = node.object;

    HInstruction finishGroundType(ResolutionInterfaceType groundType) {
      ResolutionInterfaceType typeAtVariable =
          groundType.asInstanceOf(variable.element.enclosingClass);
      if (typeAtVariable != null) {
        int index = variable.element.index;
        ResolutionDartType typeArgument = typeAtVariable.typeArguments[index];
        HInstruction replacement = new HTypeInfoExpression(
            TypeInfoExpressionKind.COMPLETE,
            typeArgument,
            const <HInstruction>[],
            _closedWorld.commonMasks.dynamicType);
        return replacement;
      }
      return node;
    }

    /// Read the type variable from an allocation of type [createdClass], where
    /// [selectTypeArgumentFromObjectCreation] extracts the type argument from
    /// the allocation for factory constructor call.
    HInstruction finishSubstituted(ClassElement createdClass,
        HInstruction selectTypeArgumentFromObjectCreation(int index)) {
      HInstruction instructionForTypeVariable(ResolutionTypeVariableType tv) {
        return selectTypeArgumentFromObjectCreation(
            createdClass.thisType.typeArguments.indexOf(tv));
      }

      ResolutionDartType type = createdClass.thisType
          .asInstanceOf(variable.element.enclosingClass)
          .typeArguments[variable.element.index];
      if (type is ResolutionTypeVariableType) {
        return instructionForTypeVariable(type);
      }
      List<HInstruction> arguments = <HInstruction>[];
      type.forEachTypeVariable((v) {
        arguments.add(instructionForTypeVariable(v));
      });
      HInstruction replacement = new HTypeInfoExpression(
          TypeInfoExpressionKind.COMPLETE,
          type,
          arguments,
          _closedWorld.commonMasks.dynamicType);
      return replacement;
    }

    // Type variable evaluated in the context of a constant can be replaced with
    // a ground term type.
    if (object is HConstant) {
      ConstantValue value = object.constant;
      if (value is ConstructedConstantValue) {
        return finishGroundType(value.type);
      }
      return node;
    }

    // Look for an allocation with type information and re-write type variable
    // as a function of the type parameters of the allocation.  This effectively
    // store-forwards a type variable read through an allocation.

    // Match:
    //
    //     HCreate(ClassElement,
    //       [arg_i,
    //        ...,
    //        HTypeInfoExpression(t_0, t_1, t_2, ...)]);
    //
    // The `t_i` are the values of the type parameters of ClassElement.

    if (object is HCreate) {
      void registerInstantiations() {
        // Forwarding the type variable references might cause the HCreate to
        // become dead. This breaks the algorithm for generating the per-type
        // runtime type information, so we instantiate them here in case the
        // HCreate becomes dead.
        object.instantiatedTypes?.forEach(_registry.registerInstantiation);
      }

      if (object.hasRtiInput) {
        HInstruction typeInfo = object.rtiInput;
        if (typeInfo is HTypeInfoExpression) {
          registerInstantiations();
          return finishSubstituted(
              object.element, (int index) => typeInfo.inputs[index]);
        }
      } else {
        // Non-generic type (which extends or mixes in a generic type, for
        // example CodeUnits extends UnmodifiableListBase<int>).  Also used for
        // raw-type when the type parameters are elided.
        registerInstantiations();
        return finishSubstituted(
            object.element,
            // If there are type arguments, all type arguments are 'dynamic'.
            (int i) => _graph.addConstantNull(_closedWorld));
      }
    }

    // TODO(sra): Factory constructors pass type arguments after the value
    // arguments. The [selectTypeArgumentFromObjectCreation] argument of
    // [finishSubstituted] indexes into these type arguments.

    return node;
  }
}

class SsaCheckInserter extends HBaseVisitor implements OptimizationPhase {
  final Set<HInstruction> boundsChecked;
  final bool trustPrimitives;
  final ClosedWorld closedWorld;
  final String name = "SsaCheckInserter";
  HGraph graph;

  SsaCheckInserter(this.trustPrimitives, this.closedWorld, this.boundsChecked);

  void visitGraph(HGraph graph) {
    this.graph = graph;

    // In --trust-primitives mode we don't add bounds checks.  This is better
    // than trying to remove them later as the limit expression would become
    // dead and require DCE.
    if (trustPrimitives) return;

    visitDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    HInstruction instruction = block.first;
    while (instruction != null) {
      HInstruction next = instruction.next;
      instruction = instruction.accept(this);
      instruction = next;
    }
  }

  HBoundsCheck insertBoundsCheck(
      HInstruction indexNode, HInstruction array, HInstruction indexArgument) {
    HGetLength length = new HGetLength(
        array, closedWorld.commonMasks.positiveIntType,
        isAssignable: !isFixedLength(array.instructionType, closedWorld));
    indexNode.block.addBefore(indexNode, length);

    TypeMask type = indexArgument.isPositiveInteger(closedWorld)
        ? indexArgument.instructionType
        : closedWorld.commonMasks.positiveIntType;
    HBoundsCheck check = new HBoundsCheck(indexArgument, length, array, type);
    indexNode.block.addBefore(indexNode, check);
    // If the index input to the bounds check was not known to be an integer
    // then we replace its uses with the bounds check, which is known to be an
    // integer.  However, if the input was already an integer we don't do this
    // because putting in a check instruction might obscure the real nature of
    // the index eg. if it is a constant.  The range information from the
    // BoundsCheck instruction is attached to the input directly by
    // visitBoundsCheck in the SsaValueRangeAnalyzer.
    if (!indexArgument.isInteger(closedWorld)) {
      indexArgument.replaceAllUsersDominatedBy(indexNode, check);
    }
    boundsChecked.add(indexNode);
    return check;
  }

  void visitIndex(HIndex node) {
    if (boundsChecked.contains(node)) return;
    HInstruction index = node.index;
    index = insertBoundsCheck(node, node.receiver, index);
  }

  void visitIndexAssign(HIndexAssign node) {
    if (boundsChecked.contains(node)) return;
    HInstruction index = node.index;
    index = insertBoundsCheck(node, node.receiver, index);
  }

  void visitInvokeDynamicMethod(HInvokeDynamicMethod node) {
    MemberEntity element = node.element;
    if (node.isInterceptedCall) return;
    if (element != closedWorld.commonElements.jsArrayRemoveLast) return;
    if (boundsChecked.contains(node)) return;
    // `0` is the index we want to check, but we want to report `-1`, as if we
    // executed `a[a.length-1]`
    HBoundsCheck check = insertBoundsCheck(
        node, node.receiver, graph.addConstantInt(0, closedWorld));
    HInstruction minusOne = graph.addConstantInt(-1, closedWorld);
    check.inputs.add(minusOne);
    minusOne.usedBy.add(check);
  }
}

class SsaDeadCodeEliminator extends HGraphVisitor implements OptimizationPhase {
  final String name = "SsaDeadCodeEliminator";

  final ClosedWorld closedWorld;
  final SsaOptimizerTask optimizer;
  HGraph _graph;
  SsaLiveBlockAnalyzer analyzer;
  Map<HInstruction, bool> trivialDeadStoreReceivers =
      new Maplet<HInstruction, bool>();
  bool eliminatedSideEffects = false;

  SsaDeadCodeEliminator(this.closedWorld, this.optimizer);

  HInstruction zapInstructionCache;
  HInstruction get zapInstruction {
    if (zapInstructionCache == null) {
      // A constant with no type does not pollute types at phi nodes.
      ConstantValue constant = new SyntheticConstantValue(
          SyntheticConstantKind.EMPTY_VALUE, const TypeMask.nonNullEmpty());
      zapInstructionCache = analyzer.graph.addConstant(constant, closedWorld);
    }
    return zapInstructionCache;
  }

  /// Returns true of [foreign] will throw an noSuchMethod error if
  /// receiver is `null` before having any other side-effects.
  bool templateThrowsNSMonNull(HForeignCode foreign, HInstruction receiver) {
    if (foreign.inputs.length < 1) return false;
    if (foreign.inputs.first != receiver) return false;
    if (foreign.throwBehavior.isNullNSMGuard) return true;

    // TODO(sra): Fix NativeThrowBehavior to distinguish MAY from
    // throws-nsm-on-null-followed-by-MAY and remove all the code below.

    // We look for a template of the form
    //
    // #.something -or- #.something()
    //
    // where # is substituted by receiver.
    js.Template template = foreign.codeTemplate;
    js.Node node = template.ast;
    // #.something = ...
    if (node is js.Assignment) {
      js.Assignment assignment = node;
      node = assignment.leftHandSide;
    }

    // #.something
    if (node is js.PropertyAccess) {
      js.PropertyAccess access = node;
      if (access.receiver is js.InterpolatedExpression) {
        js.InterpolatedExpression hole = access.receiver;
        return hole.isPositional && hole.nameOrPosition == 0;
      }
    }
    return false;
  }

  /// Returns whether the next throwing instruction that may have side
  /// effects after [instruction], throws [NoSuchMethodError] on the
  /// same receiver of [instruction].
  bool hasFollowingThrowingNSM(HInstruction instruction) {
    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    HInstruction current = instruction.next;
    do {
      if ((current.getDartReceiver(closedWorld) == receiver) &&
          current.canThrow()) {
        return true;
      }
      if (current is HForeignCode &&
          templateThrowsNSMonNull(current, receiver)) {
        return true;
      }
      if (current.canThrow() || current.sideEffects.hasSideEffects()) {
        return false;
      }
      HInstruction next = current.next;
      if (next == null) {
        // We do not merge blocks in our SSA graph, so if this block just jumps
        // to a single successor, visit the successor, avoiding back-edges.
        HBasicBlock successor;
        if (current is HGoto) {
          successor = current.block.successors.single;
        } else if (current is HIf) {
          // We also leave HIf nodes in place when one branch is dead.
          HInstruction condition = current.inputs.first;
          if (condition is HConstant) {
            bool isTrue = condition.constant.isTrue;
            successor = isTrue ? current.thenBlock : current.elseBlock;
            assert(!analyzer.isDeadBlock(successor));
          }
        }
        if (successor != null && successor.id > current.block.id) {
          next = successor.first;
        }
      }
      current = next;
    } while (current != null);
    return false;
  }

  bool isTrivialDeadStoreReceiver(HInstruction instruction) {
    // For an allocation, if all the loads are dead (awaiting removal after
    // SsaLoadElimination) and the only other uses are stores, then the
    // allocation does not escape which makes all the stores dead too.
    bool isDeadUse(HInstruction use) {
      if (use is HFieldSet) {
        // The use must be the receiver.  Even if the use is also the argument,
        // i.e.  a.x = a, the store is still dead if all other uses are dead.
        if (use.getDartReceiver(closedWorld) == instruction) return true;
      } else if (use is HFieldGet) {
        assert(use.getDartReceiver(closedWorld) == instruction);
        if (isDeadCode(use)) return true;
      }
      return false;
    }

    return instruction.isAllocation &&
        instruction.isPure() &&
        trivialDeadStoreReceivers.putIfAbsent(
            instruction, () => instruction.usedBy.every(isDeadUse));
  }

  bool isTrivialDeadStore(HInstruction instruction) {
    return instruction is HFieldSet &&
        isTrivialDeadStoreReceiver(instruction.getDartReceiver(closedWorld));
  }

  bool isDeadCode(HInstruction instruction) {
    if (!instruction.usedBy.isEmpty) return false;
    if (isTrivialDeadStore(instruction)) return true;
    if (instruction.sideEffects.hasSideEffects()) return false;
    if (instruction.canThrow() &&
        instruction.onlyThrowsNSM() &&
        hasFollowingThrowingNSM(instruction)) {
      return true;
    }
    return !instruction.canThrow() &&
        instruction is! HParameterValue &&
        instruction is! HLocalSet;
  }

  void visitGraph(HGraph graph) {
    _graph = graph;
    analyzer = new SsaLiveBlockAnalyzer(graph, closedWorld, optimizer);
    analyzer.analyze();
    visitPostDominatorTree(graph);
    cleanPhis();
  }

  void visitBasicBlock(HBasicBlock block) {
    bool isDeadBlock = analyzer.isDeadBlock(block);
    block.isLive = !isDeadBlock;
    simplifyControlFlow(block);
    // Start from the last non-control flow instruction in the block.
    HInstruction instruction = block.last.previous;
    while (instruction != null) {
      var previous = instruction.previous;
      if (isDeadBlock) {
        eliminatedSideEffects =
            eliminatedSideEffects || instruction.sideEffects.hasSideEffects();
        removeUsers(instruction);
        block.remove(instruction);
      } else if (isDeadCode(instruction)) {
        block.remove(instruction);
      }
      instruction = previous;
    }
    block.forEachPhi(simplifyPhi);
    evacuateTakenBranch(block);
  }

  void simplifyPhi(HPhi phi) {
    // If the phi is of the form `phi(x, HTypeKnown(x))`, it does not strengthen
    // `x`.  We can replace the phi with `x` to potentially make the HTypeKnown
    // refinement node dead and potentially make a HIf control no HPhis.

    // TODO(sra): Implement version of this test that works for a subgraph of
    // HPhi nodes.
    HInstruction base = null;
    bool seenUnrefinedBase = false;
    for (HInstruction input in phi.inputs) {
      HInstruction value = input;
      while (value is HTypeKnown) {
        HTypeKnown refinement = value;
        value = refinement.checkedInput;
      }
      if (value == input) seenUnrefinedBase = true;
      base ??= value;
      if (base != value) return;
    }

    if (seenUnrefinedBase) {
      HBasicBlock block = phi.block;
      block.rewrite(phi, base);
      block.removePhi(phi);
    }
  }

  void simplifyControlFlow(HBasicBlock block) {
    HControlFlow instruction = block.last;
    if (instruction is HIf) {
      HInstruction condition = instruction.condition;
      if (condition.isConstant()) return;

      // We want to remove an if-then-else diamond when the then- and else-
      // branches are empty and the condition does not control a HPhi. We cannot
      // change the CFG structure so we replace the HIf condition with a
      // constant. This may leave the original condition unused. i.e. a
      // candidate for being dead code.

      List<HBasicBlock> dominated = block.dominatedBlocks;
      // Diamond-like control flow dominates the then-, else- and join- blocks.
      if (dominated.length != 3) return;
      HBasicBlock join = dominated.last;
      if (!join.phis.isEmpty) return; // condition controls a phi.
      // Ignore exit block - usually the join in `if (...) return ...`
      if (join.isExitBlock()) return;

      int thenSize = measureEmptyInterval(instruction.thenBlock, join);
      if (thenSize == null) return;
      int elseSize = measureEmptyInterval(instruction.elseBlock, join);
      if (elseSize == null) return;

      // Pick the 'live' branch to be the smallest subgraph.
      bool value = thenSize <= elseSize;
      HInstruction newCondition = _graph.addConstantBool(value, closedWorld);
      instruction.inputs[0] = newCondition;
      condition.usedBy.remove(instruction);
      newCondition.usedBy.add(instruction);
    }
  }

  /// Returns the number of blocks from [start] up to but not including [end].
  /// Returns `null` if any of the blocks is non-empty (other than control
  /// flow).  Returns `null` if there is an exit from the region other than
  /// [end] or via control flow other than HGoto and HIf.
  int measureEmptyInterval(HBasicBlock start, HBasicBlock end) {
    if (start.first != start.last) return null; // start is not empty.
    // Do a simple single-block region test first.
    if (start.last is HGoto &&
        start.successors.length == 1 &&
        start.successors.single == end) {
      return 1;
    }
    // TODO(sra): Implement fuller test.
    return null;
  }

  /// If [block] is an always-taken branch, move the code from the taken branch
  /// into [block]. This has the effect of making the instructions available for
  /// further optimizations by moving them to a position that dominates the join
  /// point of the if-then-else.
  // TODO(29475): Delete dead blocks instead.
  void evacuateTakenBranch(HBasicBlock block) {
    if (!block.isLive) return;
    HControlFlow branch = block.last;
    if (branch is HIf) {
      if (branch.thenBlock.isLive == branch.elseBlock.isLive) return;
      assert(branch.condition.isConstant());
      HBasicBlock target =
          branch.thenBlock.isLive ? branch.thenBlock : branch.elseBlock;
      HInstruction instruction = target.first;
      while (!instruction.isControlFlow()) {
        HInstruction next = instruction.next;
        if (instruction is HTypeKnown && instruction.isPinned) break;
        instruction.block.detach(instruction);
        block.moveAtExit(instruction);
        instruction = next;
      }
    }
  }

  void cleanPhis() {
    L:
    for (HBasicBlock block in _graph.blocks) {
      List<HBasicBlock> predecessors = block.predecessors;
      // Zap all inputs to phis that correspond to dead blocks.
      block.forEachPhi((HPhi phi) {
        for (int i = 0; i < phi.inputs.length; ++i) {
          if (!predecessors[i].isLive && phi.inputs[i] != zapInstruction) {
            replaceInput(i, phi, zapInstruction);
          }
        }
      });
      if (predecessors.length < 2) continue L;
      // Find the index of the single live predecessor if it exists.
      int indexOfLive = -1;
      for (int i = 0; i < predecessors.length; i++) {
        if (predecessors[i].isLive) {
          if (indexOfLive >= 0) continue L;
          indexOfLive = i;
        }
      }
      // Run through the phis of the block and replace them with their input
      // that comes from the only live predecessor if that dominates the phi.
      //
      // TODO(sra): If the input is directly in the only live predecessor, it
      // might be possible to move it into [block] (e.g. all its inputs are
      // dominating.)
      block.forEachPhi((HPhi phi) {
        HInstruction replacement =
            (indexOfLive >= 0) ? phi.inputs[indexOfLive] : zapInstruction;
        if (replacement.dominates(phi)) {
          block.rewrite(phi, replacement);
          block.removePhi(phi);
          if (replacement.sourceElement == null &&
              phi.sourceElement != null &&
              replacement is! HThis) {
            replacement.sourceElement = phi.sourceElement;
          }
        }
      });
    }
  }

  void replaceInput(int i, HInstruction from, HInstruction by) {
    from.inputs[i].usedBy.remove(from);
    from.inputs[i] = by;
    by.usedBy.add(from);
  }

  void removeUsers(HInstruction instruction) {
    instruction.usedBy.forEach((user) {
      removeInput(user, instruction);
    });
    instruction.usedBy.clear();
  }

  void removeInput(HInstruction user, HInstruction input) {
    List<HInstruction> inputs = user.inputs;
    for (int i = 0, length = inputs.length; i < length; i++) {
      if (input == inputs[i]) {
        user.inputs[i] = zapInstruction;
        zapInstruction.usedBy.add(user);
      }
    }
  }
}

class SsaLiveBlockAnalyzer extends HBaseVisitor {
  final HGraph graph;
  final Set<HBasicBlock> live = new Set<HBasicBlock>();
  final List<HBasicBlock> worklist = <HBasicBlock>[];
  final SsaOptimizerTask optimizer;
  final ClosedWorld closedWorld;

  SsaLiveBlockAnalyzer(this.graph, this.closedWorld, this.optimizer);

  Map<HInstruction, Range> get ranges => optimizer.ranges;

  bool isDeadBlock(HBasicBlock block) => !live.contains(block);

  void analyze() {
    markBlockLive(graph.entry);
    while (!worklist.isEmpty) {
      HBasicBlock live = worklist.removeLast();
      live.last.accept(this);
    }
  }

  void markBlockLive(HBasicBlock block) {
    if (!live.contains(block)) {
      worklist.add(block);
      live.add(block);
    }
  }

  void visitControlFlow(HControlFlow instruction) {
    instruction.block.successors.forEach(markBlockLive);
  }

  void visitIf(HIf instruction) {
    HInstruction condition = instruction.condition;
    if (condition.isConstant()) {
      if (condition.isConstantTrue()) {
        markBlockLive(instruction.thenBlock);
      } else {
        markBlockLive(instruction.elseBlock);
      }
    } else {
      visitControlFlow(instruction);
    }
  }

  void visitSwitch(HSwitch node) {
    if (node.expression.isInteger(closedWorld)) {
      Range switchRange = ranges[node.expression];
      if (switchRange != null &&
          switchRange.lower is IntValue &&
          switchRange.upper is IntValue) {
        IntValue lowerValue = switchRange.lower;
        IntValue upperValue = switchRange.upper;
        int lower = lowerValue.value;
        int upper = upperValue.value;
        Set<int> liveLabels = new Set<int>();
        for (int pos = 1; pos < node.inputs.length; pos++) {
          HConstant input = node.inputs[pos];
          if (!input.isConstantInteger()) continue;
          IntConstantValue constant = input.constant;
          int label = constant.primitiveValue;
          if (!liveLabels.contains(label) && label <= upper && label >= lower) {
            markBlockLive(node.block.successors[pos - 1]);
            liveLabels.add(label);
          }
        }
        if (liveLabels.length != upper - lower + 1) {
          markBlockLive(node.defaultTarget);
        }
        return;
      }
    }
    visitControlFlow(node);
  }
}

class SsaDeadPhiEliminator implements OptimizationPhase {
  final String name = "SsaDeadPhiEliminator";

  void visitGraph(HGraph graph) {
    final List<HPhi> worklist = <HPhi>[];
    // A set to keep track of the live phis that we found.
    final Set<HPhi> livePhis = new Set<HPhi>();

    // Add to the worklist all live phis: phis referenced by non-phi
    // instructions.
    for (final block in graph.blocks) {
      block.forEachPhi((HPhi phi) {
        for (final user in phi.usedBy) {
          if (user is! HPhi) {
            worklist.add(phi);
            livePhis.add(phi);
            break;
          }
        }
      });
    }

    // Process the worklist by propagating liveness to phi inputs.
    while (!worklist.isEmpty) {
      HPhi phi = worklist.removeLast();
      for (final input in phi.inputs) {
        if (input is HPhi && !livePhis.contains(input)) {
          worklist.add(input);
          livePhis.add(input);
        }
      }
    }

    // Remove phis that are not live.
    // Traverse in reverse order to remove phis with no uses before the
    // phis that they might use.
    // NOTICE: Doesn't handle circular references, but we don't currently
    // create any.
    List<HBasicBlock> blocks = graph.blocks;
    for (int i = blocks.length - 1; i >= 0; i--) {
      HBasicBlock block = blocks[i];
      HPhi current = block.phis.first;
      HPhi next = null;
      while (current != null) {
        next = current.next;
        if (!livePhis.contains(current)
            // TODO(ahe): Not sure the following is correct.
            &&
            current.usedBy.isEmpty) {
          block.removePhi(current);
        }
        current = next;
      }
    }
  }
}

class SsaRedundantPhiEliminator implements OptimizationPhase {
  final String name = "SsaRedundantPhiEliminator";

  void visitGraph(HGraph graph) {
    final List<HPhi> worklist = <HPhi>[];

    // Add all phis in the worklist.
    for (final block in graph.blocks) {
      block.forEachPhi((HPhi phi) => worklist.add(phi));
    }

    while (!worklist.isEmpty) {
      HPhi phi = worklist.removeLast();

      // If the phi has already been processed, continue.
      if (!phi.isInBasicBlock()) continue;

      // Find if the inputs of the phi are the same instruction.
      // The builder ensures that phi.inputs[0] cannot be the phi
      // itself.
      assert(!identical(phi.inputs[0], phi));
      HInstruction candidate = phi.inputs[0];
      for (int i = 1; i < phi.inputs.length; i++) {
        HInstruction input = phi.inputs[i];
        // If the input is the phi, the phi is still candidate for
        // elimination.
        if (!identical(input, candidate) && !identical(input, phi)) {
          candidate = null;
          break;
        }
      }

      // If the inputs are not the same, continue.
      if (candidate == null) continue;

      // Because we're updating the users of this phi, we may have new
      // phis candidate for elimination. Add phis that used this phi
      // to the worklist.
      for (final user in phi.usedBy) {
        if (user is HPhi) worklist.add(user);
      }
      phi.block.rewrite(phi, candidate);
      phi.block.removePhi(phi);
      if (candidate.sourceElement == null &&
          phi.sourceElement != null &&
          candidate is! HThis) {
        candidate.sourceElement = phi.sourceElement;
      }
    }
  }
}

class GvnWorkItem {
  final HBasicBlock block;
  final ValueSet valueSet;
  GvnWorkItem(this.block, this.valueSet);
}

class SsaGlobalValueNumberer implements OptimizationPhase {
  final String name = "SsaGlobalValueNumberer";
  final Set<int> visited;

  List<int> blockChangesFlags;
  List<int> loopChangesFlags;

  SsaGlobalValueNumberer() : visited = new Set<int>();

  void visitGraph(HGraph graph) {
    computeChangesFlags(graph);
    moveLoopInvariantCode(graph);
    List<GvnWorkItem> workQueue = <GvnWorkItem>[
      new GvnWorkItem(graph.entry, new ValueSet())
    ];
    do {
      GvnWorkItem item = workQueue.removeLast();
      visitBasicBlock(item.block, item.valueSet, workQueue);
    } while (!workQueue.isEmpty);
  }

  void moveLoopInvariantCode(HGraph graph) {
    for (int i = graph.blocks.length - 1; i >= 0; i--) {
      HBasicBlock block = graph.blocks[i];
      if (block.isLoopHeader()) {
        int changesFlags = loopChangesFlags[block.id];
        HLoopInformation info = block.loopInformation;
        // Iterate over all blocks of this loop. Note that blocks in
        // inner loops are not visited here, but we know they
        // were visited before because we are iterating in post-order.
        // So instructions that are GVN'ed in an inner loop are in their
        // loop entry, and [info.blocks] contains this loop entry.
        moveLoopInvariantCodeFromBlock(block, block, changesFlags);
        for (HBasicBlock other in info.blocks) {
          moveLoopInvariantCodeFromBlock(other, block, changesFlags);
        }
      }
    }
  }

  void moveLoopInvariantCodeFromBlock(
      HBasicBlock block, HBasicBlock loopHeader, int changesFlags) {
    assert(block.parentLoopHeader == loopHeader || block == loopHeader);
    HBasicBlock preheader = loopHeader.predecessors[0];
    int dependsFlags = SideEffects.computeDependsOnFlags(changesFlags);
    HInstruction instruction = block.first;
    bool isLoopAlwaysTaken() {
      HInstruction instruction = loopHeader.last;
      assert(instruction is HGoto || instruction is HLoopBranch);
      return instruction is HGoto || instruction.inputs[0].isConstantTrue();
    }

    bool firstInstructionInLoop = block == loopHeader
        // Compensate for lack of code motion.
        ||
        (blockChangesFlags[loopHeader.id] == 0 &&
            isLoopAlwaysTaken() &&
            loopHeader.successors[0] == block);
    while (instruction != null) {
      HInstruction next = instruction.next;
      if (instruction.useGvn() &&
          instruction.isMovable &&
          (!instruction.canThrow() || firstInstructionInLoop) &&
          !instruction.sideEffects.dependsOn(dependsFlags)) {
        bool loopInvariantInputs = true;
        List<HInstruction> inputs = instruction.inputs;
        for (int i = 0, length = inputs.length; i < length; i++) {
          if (isInputDefinedAfterDominator(inputs[i], preheader)) {
            loopInvariantInputs = false;
            break;
          }
        }

        // If the inputs are loop invariant, we can move the
        // instruction from the current block to the pre-header block.
        if (loopInvariantInputs) {
          block.detach(instruction);
          preheader.moveAtExit(instruction);
        } else {
          firstInstructionInLoop = false;
        }
      }
      int oldChangesFlags = changesFlags;
      changesFlags |= instruction.sideEffects.getChangesFlags();
      if (oldChangesFlags != changesFlags) {
        dependsFlags = SideEffects.computeDependsOnFlags(changesFlags);
      }
      instruction = next;
    }
  }

  bool isInputDefinedAfterDominator(HInstruction input, HBasicBlock dominator) {
    return input.block.id > dominator.id;
  }

  void visitBasicBlock(
      HBasicBlock block, ValueSet values, List<GvnWorkItem> workQueue) {
    HInstruction instruction = block.first;
    if (block.isLoopHeader()) {
      int flags = loopChangesFlags[block.id];
      values.kill(flags);
    }
    while (instruction != null) {
      HInstruction next = instruction.next;
      int flags = instruction.sideEffects.getChangesFlags();
      assert(flags == 0 || !instruction.useGvn());
      values.kill(flags);
      if (instruction.useGvn()) {
        HInstruction other = values.lookup(instruction);
        if (other != null) {
          assert(other.gvnEquals(instruction) && instruction.gvnEquals(other));
          block.rewriteWithBetterUser(instruction, other);
          block.remove(instruction);
        } else {
          values.add(instruction);
        }
      }
      instruction = next;
    }

    List<HBasicBlock> dominatedBlocks = block.dominatedBlocks;
    for (int i = 0, length = dominatedBlocks.length; i < length; i++) {
      HBasicBlock dominated = dominatedBlocks[i];
      // No need to copy the value set for the last child.
      ValueSet successorValues = (i == length - 1) ? values : values.copy();
      // If we have no values in our set, we do not have to kill
      // anything. Also, if the range of block ids from the current
      // block to the dominated block is empty, there is no blocks on
      // any path from the current block to the dominated block so we
      // don't have to do anything either.
      assert(block.id < dominated.id);
      if (!successorValues.isEmpty && block.id + 1 < dominated.id) {
        visited.clear();
        List<HBasicBlock> workQueue = <HBasicBlock>[dominated];
        int changesFlags = 0;
        do {
          HBasicBlock current = workQueue.removeLast();
          changesFlags |=
              getChangesFlagsForDominatedBlock(block, current, workQueue);
        } while (!workQueue.isEmpty);
        successorValues.kill(changesFlags);
      }
      workQueue.add(new GvnWorkItem(dominated, successorValues));
    }
  }

  void computeChangesFlags(HGraph graph) {
    // Create the changes flags lists. Make sure to initialize the
    // loop changes flags list to zero so we can use bitwise or when
    // propagating loop changes upwards.
    final int length = graph.blocks.length;
    blockChangesFlags = new List<int>(length);
    loopChangesFlags = new List<int>(length);
    for (int i = 0; i < length; i++) loopChangesFlags[i] = 0;

    // Run through all the basic blocks in the graph and fill in the
    // changes flags lists.
    for (int i = length - 1; i >= 0; i--) {
      final HBasicBlock block = graph.blocks[i];
      final int id = block.id;

      // Compute block changes flags for the block.
      int changesFlags = 0;
      HInstruction instruction = block.first;
      while (instruction != null) {
        changesFlags |= instruction.sideEffects.getChangesFlags();
        instruction = instruction.next;
      }
      assert(blockChangesFlags[id] == null);
      blockChangesFlags[id] = changesFlags;

      // Loop headers are part of their loop, so update the loop
      // changes flags accordingly.
      if (block.isLoopHeader()) {
        loopChangesFlags[id] |= changesFlags;
      }

      // Propagate loop changes flags upwards.
      HBasicBlock parentLoopHeader = block.parentLoopHeader;
      if (parentLoopHeader != null) {
        loopChangesFlags[parentLoopHeader.id] |=
            (block.isLoopHeader()) ? loopChangesFlags[id] : changesFlags;
      }
    }
  }

  int getChangesFlagsForDominatedBlock(HBasicBlock dominator,
      HBasicBlock dominated, List<HBasicBlock> workQueue) {
    int changesFlags = 0;
    List<HBasicBlock> predecessors = dominated.predecessors;
    for (int i = 0, length = predecessors.length; i < length; i++) {
      HBasicBlock block = predecessors[i];
      int id = block.id;
      // If the current predecessor block is on the path from the
      // dominator to the dominated, it must have an id that is in the
      // range from the dominator to the dominated.
      if (dominator.id < id && id < dominated.id && !visited.contains(id)) {
        visited.add(id);
        changesFlags |= blockChangesFlags[id];
        // Loop bodies might not be on the path from dominator to dominated,
        // but they can invalidate values.
        changesFlags |= loopChangesFlags[id];
        workQueue.add(block);
      }
    }
    return changesFlags;
  }
}

// This phase merges equivalent instructions on different paths into
// one instruction in a dominator block. It runs through the graph
// post dominator order and computes a ValueSet for each block of
// instructions that can be moved to a dominator block. These
// instructions are the ones that:
// 1) can be used for GVN, and
// 2) do not use definitions of their own block.
//
// A basic block looks at its sucessors and finds the intersection of
// these computed ValueSet. It moves all instructions of the
// intersection into its own list of instructions.
class SsaCodeMotion extends HBaseVisitor implements OptimizationPhase {
  final String name = "SsaCodeMotion";

  bool movedCode = false;
  List<ValueSet> values;

  void visitGraph(HGraph graph) {
    values = new List<ValueSet>(graph.blocks.length);
    for (int i = 0; i < graph.blocks.length; i++) {
      values[graph.blocks[i].id] = new ValueSet();
    }
    visitPostDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    List<HBasicBlock> successors = block.successors;

    // Phase 1: get the ValueSet of all successors (if there are more than one),
    // compute the intersection and move the instructions of the intersection
    // into this block.
    if (successors.length > 1) {
      ValueSet instructions = values[successors[0].id];
      for (int i = 1; i < successors.length; i++) {
        ValueSet other = values[successors[i].id];
        instructions = instructions.intersection(other);
      }

      if (!instructions.isEmpty) {
        List<HInstruction> list = instructions.toList();
        for (HInstruction instruction in list) {
          // Move the instruction to the current block.
          instruction.block.detach(instruction);
          block.moveAtExit(instruction);
          // Go through all successors and rewrite their instruction
          // to the shared one.
          for (final successor in successors) {
            HInstruction toRewrite = values[successor.id].lookup(instruction);
            if (toRewrite != instruction) {
              successor.rewriteWithBetterUser(toRewrite, instruction);
              successor.remove(toRewrite);
              movedCode = true;
            }
          }
        }
      }
    }

    // Don't try to merge instructions to a dominator if we have
    // multiple predecessors.
    if (block.predecessors.length != 1) return;

    // Phase 2: Go through all instructions of this block and find
    // which instructions can be moved to a dominator block.
    ValueSet set_ = values[block.id];
    HInstruction instruction = block.first;
    int flags = 0;
    while (instruction != null) {
      int dependsFlags = SideEffects.computeDependsOnFlags(flags);
      flags |= instruction.sideEffects.getChangesFlags();

      HInstruction current = instruction;
      instruction = instruction.next;
      if (!current.useGvn() || !current.isMovable) continue;
      // TODO(sra): We could move throwing instructions provided we keep the
      // exceptions in the same order.  This requires they are in the same order
      // in all successors, which is not tracked by the ValueSet.
      if (current.canThrow()) continue;
      if (current.sideEffects.dependsOn(dependsFlags)) continue;

      bool canBeMoved = true;
      for (final HInstruction input in current.inputs) {
        if (input.block == block) {
          canBeMoved = false;
          break;
        }
      }
      if (!canBeMoved) continue;

      HInstruction existing = set_.lookup(current);
      if (existing == null) {
        set_.add(current);
      } else {
        block.rewriteWithBetterUser(current, existing);
        block.remove(current);
        movedCode = true;
      }
    }
  }
}

class SsaTypeConversionInserter extends HBaseVisitor
    implements OptimizationPhase {
  final String name = "SsaTypeconversionInserter";
  final ClosedWorld closedWorld;

  SsaTypeConversionInserter(this.closedWorld);

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  // Update users of [input] that are dominated by [:dominator.first:]
  // to use [TypeKnown] of [input] instead. As the type information depends
  // on the control flow, we mark the inserted [HTypeKnown] nodes as
  // non-movable.
  void insertTypePropagationForDominatedUsers(
      HBasicBlock dominator, HInstruction input, TypeMask convertedType) {
    DominatedUses dominatedUses = DominatedUses.of(input, dominator.first);
    if (dominatedUses.isEmpty) return;

    // Check to avoid adding a duplicate HTypeKnown node.
    if (dominatedUses.isSingleton) {
      HInstruction user = dominatedUses.single;
      if (user is HTypeKnown &&
          user.isPinned &&
          user.knownType == convertedType &&
          user.checkedInput == input) {
        return;
      }
    }

    HTypeKnown newInput = new HTypeKnown.pinned(convertedType, input);
    dominator.addBefore(dominator.first, newInput);
    dominatedUses.replaceWith(newInput);
  }

  void visitIs(HIs instruction) {
    DartType type = instruction.typeExpression;
    if (!instruction.isRawCheck) {
      return;
    } else if (type.isTypedef) {
      return;
    }
    InterfaceType interfaceType = type;
    ClassEntity cls = interfaceType.element;

    List<HBasicBlock> trueTargets = <HBasicBlock>[];
    List<HBasicBlock> falseTargets = <HBasicBlock>[];

    collectTargets(instruction, trueTargets, falseTargets);

    if (trueTargets.isEmpty && falseTargets.isEmpty) return;

    TypeMask convertedType = new TypeMask.nonNullSubtype(cls, closedWorld);
    HInstruction input = instruction.expression;

    for (HBasicBlock block in trueTargets) {
      insertTypePropagationForDominatedUsers(block, input, convertedType);
    }
    // TODO(sra): Also strengthen uses for when the condition is known
    // false. Avoid strengthening to `null`.
  }

  void visitIdentity(HIdentity instruction) {
    // At HIf(HIdentity(x, null)) strengthens x to non-null on else branch.
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    HInstruction input;

    if (left.isConstantNull()) {
      input = right;
    } else if (right.isConstantNull()) {
      input = left;
    } else {
      return;
    }

    if (!input.instructionType.isNullable) return;

    List<HBasicBlock> trueTargets = <HBasicBlock>[];
    List<HBasicBlock> falseTargets = <HBasicBlock>[];

    collectTargets(instruction, trueTargets, falseTargets);

    if (trueTargets.isEmpty && falseTargets.isEmpty) return;

    TypeMask nonNullType = input.instructionType.nonNullable();

    for (HBasicBlock block in falseTargets) {
      insertTypePropagationForDominatedUsers(block, input, nonNullType);
    }
    // We don't strengthen the known-true references. It doesn't happen often
    // and we don't want "if (x==null) return x;" to convert between JavaScript
    // 'null' and 'undefined'.
  }

  collectTargets(HInstruction instruction, List<HBasicBlock> trueTargets,
      List<HBasicBlock> falseTargets) {
    for (HInstruction user in instruction.usedBy) {
      if (user is HIf) {
        trueTargets?.add(user.thenBlock);
        falseTargets?.add(user.elseBlock);
      } else if (user is HLoopBranch) {
        trueTargets?.add(user.block.successors.first);
        // Don't insert refinements on else-branch - may be a critical edge
        // block which we currently need to keep empty (except for phis).
      } else if (user is HNot) {
        collectTargets(user, falseTargets, trueTargets);
      } else if (user is HPhi) {
        List<HInstruction> inputs = user.inputs;
        if (inputs.length == 2) {
          assert(inputs.contains(instruction));
          HInstruction other = inputs[(inputs[0] == instruction) ? 1 : 0];
          if (other.isConstantTrue()) {
            // The condition flows to a HPhi(true, user), which means that a
            // downstream HIf has true-branch control flow that does not depend
            // on the original instruction, so stop collecting [trueTargets].
            collectTargets(user, null, falseTargets);
          } else if (other.isConstantFalse()) {
            // Ditto for false.
            collectTargets(user, trueTargets, null);
          }
        }
      } else if (user is HBoolify) {
        // We collect targets for strictly boolean operations so HBoolify cannot
        // change the result.
        collectTargets(user, trueTargets, falseTargets);
      }
    }
  }
}

/**
 * Optimization phase that tries to eliminate memory loads (for example
 * [HFieldGet]), when it knows the value stored in that memory location, and
 * stores that overwrite with the same value.
 */
class SsaLoadElimination extends HBaseVisitor implements OptimizationPhase {
  final Compiler compiler;
  final ClosedWorld closedWorld;
  final String name = "SsaLoadElimination";
  MemorySet memorySet;
  List<MemorySet> memories;
  bool newGvnCandidates = false;

  SsaLoadElimination(this.compiler, this.closedWorld);

  void visitGraph(HGraph graph) {
    memories = new List<MemorySet>(graph.blocks.length);
    List<HBasicBlock> blocks = graph.blocks;
    for (int i = 0; i < blocks.length; i++) {
      HBasicBlock block = blocks[i];
      visitBasicBlock(block);
      if (block.successors.isNotEmpty && block.successors[0].isLoopHeader()) {
        // We've reached the ending block of a loop. Iterate over the
        // blocks of the loop again to take values that flow from that
        // ending block into account.
        for (int j = block.successors[0].id; j <= block.id; j++) {
          visitBasicBlock(blocks[j]);
        }
      }
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    if (block.predecessors.length == 0) {
      // Entry block.
      memorySet = new MemorySet(closedWorld);
    } else if (block.predecessors.length == 1 &&
        block.predecessors[0].successors.length == 1) {
      // No need to clone, there is no other successor for
      // `block.predecessors[0]`, and this block has only one
      // predecessor. Since we are not going to visit
      // `block.predecessors[0]` again, we can just re-use its
      // [memorySet].
      memorySet = memories[block.predecessors[0].id];
    } else if (block.predecessors.length == 1) {
      // Clone the memorySet of the predecessor, because it is also used
      // by other successors of it.
      memorySet = memories[block.predecessors[0].id].clone();
    } else {
      // Compute the intersection of all predecessors.
      memorySet = memories[block.predecessors[0].id];
      for (int i = 1; i < block.predecessors.length; i++) {
        memorySet = memorySet.intersectionFor(
            memories[block.predecessors[i].id], block, i);
      }
    }

    memories[block.id] = memorySet;
    HInstruction instruction = block.first;
    while (instruction != null) {
      HInstruction next = instruction.next;
      instruction.accept(this);
      instruction = next;
    }
  }

  void checkNewGvnCandidates(HInstruction instruction, HInstruction existing) {
    if (newGvnCandidates) return;
    bool hasUseGvn(HInstruction insn) => insn.nonCheck().useGvn();
    if (instruction.usedBy.any(hasUseGvn) && existing.usedBy.any(hasUseGvn)) {
      newGvnCandidates = true;
    }
  }

  void visitFieldGet(HFieldGet instruction) {
    if (instruction.isNullCheck) return;
    FieldEntity element = instruction.element;
    HInstruction receiver = instruction.getDartReceiver(closedWorld).nonCheck();
    _visitFieldGet(element, receiver, instruction);
  }

  void visitGetLength(HGetLength instruction) {
    _visitFieldGet(closedWorld.commonElements.jsIndexableLength,
        instruction.receiver.nonCheck(), instruction);
  }

  void _visitFieldGet(
      MemberEntity element, HInstruction receiver, HInstruction instruction) {
    HInstruction existing = memorySet.lookupFieldValue(element, receiver);
    if (existing != null) {
      checkNewGvnCandidates(instruction, existing);
      instruction.block.rewriteWithBetterUser(instruction, existing);
      instruction.block.remove(instruction);
    } else {
      memorySet.registerFieldValue(element, receiver, instruction);
    }
  }

  void visitFieldSet(HFieldSet instruction) {
    FieldEntity element = instruction.element;
    HInstruction receiver = instruction.getDartReceiver(closedWorld).nonCheck();
    if (memorySet.registerFieldValueUpdate(
        element, receiver, instruction.value)) {
      instruction.block.remove(instruction);
    }
  }

  void visitCreate(HCreate instruction) {
    memorySet.registerAllocation(instruction);
    if (shouldTrackInitialValues(instruction)) {
      int argumentIndex = 0;
      compiler.codegenWorldBuilder.forEachInstanceField(instruction.element,
          (_, FieldEntity member) {
        if (compiler.elementHasCompileTimeError(
            // ignore: UNNECESSARY_CAST
            member as Entity)) return;
        memorySet.registerFieldValue(
            member, instruction, instruction.inputs[argumentIndex++]);
      });
    }
    // In case this instruction has as input non-escaping objects, we
    // need to mark these objects as escaping.
    memorySet.killAffectedBy(instruction);
  }

  bool shouldTrackInitialValues(HCreate instruction) {
    // Don't track initial field values of an allocation that are
    // unprofitable. We search the chain of single uses in allocations for a
    // limited depth.

    const MAX_HEAP_DEPTH = 5;

    bool interestingUse(HInstruction instruction, int heapDepth) {
      // Heuristic: if the allocation is too deep in heap it is unlikely we will
      // recover a field by load-elimination.
      // TODO(sra): We can measure this depth by looking at load chains.
      if (heapDepth == MAX_HEAP_DEPTH) return false;
      // There are multiple uses so do the full store analysis.
      if (instruction.usedBy.length != 1) return true;
      HInstruction use = instruction.usedBy.single;
      // When the only use is an allocation, the allocation becomes the only
      // heap alias for the current instruction.
      if (use is HCreate) return interestingUse(use, heapDepth + 1);
      if (use is HLiteralList) return interestingUse(use, heapDepth + 1);
      if (use is HInvokeStatic) {
        // Assume the argument escapes. All we do with our initial allocation is
        // have it escape or store it into an object that escapes.
        return false;
        // TODO(sra): Handle library functions that we know do not modify or
        // leak the inputs. For example `setRuntimeTypeInfo` is used to mark
        // list literals with type information.
      }
      if (use is HPhi) {
        // The initial allocation (it's only alias) gets merged out of the model
        // of the heap before load.
        return false;
      }
      return true;
    }

    return interestingUse(instruction, 0);
  }

  void visitInstruction(HInstruction instruction) {
    if (instruction.isAllocation) {
      memorySet.registerAllocation(instruction);
    }
    memorySet.killAffectedBy(instruction);
  }

  void visitLazyStatic(HLazyStatic instruction) {
    FieldEntity field = instruction.element;
    handleStaticLoad(field, instruction);
  }

  void handleStaticLoad(MemberEntity element, HInstruction instruction) {
    HInstruction existing = memorySet.lookupFieldValue(element, null);
    if (existing != null) {
      checkNewGvnCandidates(instruction, existing);
      instruction.block.rewriteWithBetterUser(instruction, existing);
      instruction.block.remove(instruction);
    } else {
      memorySet.registerFieldValue(element, null, instruction);
    }
  }

  void visitStatic(HStatic instruction) {
    handleStaticLoad(instruction.element, instruction);
  }

  void visitStaticStore(HStaticStore instruction) {
    if (memorySet.registerFieldValueUpdate(
        instruction.element, null, instruction.inputs.last)) {
      instruction.block.remove(instruction);
    }
  }

  void visitLiteralList(HLiteralList instruction) {
    memorySet.registerAllocation(instruction);
    memorySet.killAffectedBy(instruction);
    // TODO(sra): Set initial keyed values.
    // TODO(sra): Set initial length.
  }

  void visitIndex(HIndex instruction) {
    HInstruction receiver = instruction.receiver.nonCheck();
    HInstruction existing =
        memorySet.lookupKeyedValue(receiver, instruction.index);
    if (existing != null) {
      checkNewGvnCandidates(instruction, existing);
      instruction.block.rewriteWithBetterUser(instruction, existing);
      instruction.block.remove(instruction);
    } else {
      memorySet.registerKeyedValue(receiver, instruction.index, instruction);
    }
  }

  void visitIndexAssign(HIndexAssign instruction) {
    HInstruction receiver = instruction.receiver.nonCheck();
    memorySet.registerKeyedValueUpdate(
        receiver, instruction.index, instruction.value);
  }

  // Pure operations that do not escape their inputs.
  void visitBinaryArithmetic(HBinaryArithmetic instruction) {}
  void visitConstant(HConstant instruction) {}
  void visitIf(HIf instruction) {}
  void visitInterceptor(HInterceptor instruction) {}
  void visitIs(HIs instruction) {}
  void visitIsViaInterceptor(HIsViaInterceptor instruction) {}
  void visitNot(HNot instruction) {}
  void visitParameterValue(HParameterValue instruction) {}
  void visitRelational(HRelational instruction) {}
  void visitStringConcat(HStringConcat instruction) {}
  void visitTypeKnown(HTypeKnown instruction) {}
  void visitTypeInfoReadRaw(HTypeInfoReadRaw instruction) {}
  void visitTypeInfoReadVariable(HTypeInfoReadVariable instruction) {}
  void visitTypeInfoExpression(HTypeInfoExpression instruction) {}
}

/**
 * Holds values of memory places.
 *
 * Generally, values that name a place (a receiver) have type refinements and
 * other checks removed to ensure that checks and type refinements do not
 * confuse aliasing.  Values stored into a memory place keep the type
 * refinements to help further optimizations.
 */
class MemorySet {
  final ClosedWorld closedWorld;

  /**
   * Maps a field to a map of receiver to value.
   */
  // The key is [MemberEntity] rather than [FieldEntity] so that HGetLength can
  // be modeled as the JSIndexable.length abstract getter.
  // TODO(25544): Split length effects from other effects and model lengths
  // separately.
  final Map<MemberEntity, Map<HInstruction, HInstruction>> fieldValues =
      <MemberEntity, Map<HInstruction, HInstruction>>{};

  /**
   * Maps a receiver to a map of keys to value.
   */
  final Map<HInstruction, Map<HInstruction, HInstruction>> keyedValues =
      <HInstruction, Map<HInstruction, HInstruction>>{};

  /**
   * Set of objects that we know don't escape the current function.
   */
  final Setlet<HInstruction> nonEscapingReceivers = new Setlet<HInstruction>();

  MemorySet(this.closedWorld);

  /**
   * Returns whether [first] and [second] always alias to the same object.
   */
  bool mustAlias(HInstruction first, HInstruction second) {
    return first == second;
  }

  /**
   * Returns whether [first] and [second] may alias to the same object.
   */
  bool mayAlias(HInstruction first, HInstruction second) {
    if (mustAlias(first, second)) return true;
    if (isConcrete(first) && isConcrete(second)) return false;
    if (nonEscapingReceivers.contains(first)) return false;
    if (nonEscapingReceivers.contains(second)) return false;
    // Typed arrays of different types might have a shared buffer.
    if (couldBeTypedArray(first) && couldBeTypedArray(second)) return true;
    return !first.instructionType
        .isDisjoint(second.instructionType, closedWorld);
  }

  bool isFinal(MemberEntity element) {
    return closedWorld.fieldNeverChanges(element);
  }

  bool isConcrete(HInstruction instruction) {
    return instruction is HCreate ||
        instruction is HConstant ||
        instruction is HLiteralList;
  }

  bool couldBeTypedArray(HInstruction receiver) {
    return closedWorld.commonMasks.couldBeTypedArray(receiver.instructionType);
  }

  /**
   * Returns whether [receiver] escapes the current function.
   */
  bool escapes(HInstruction receiver) {
    assert(receiver == null || receiver == receiver.nonCheck());
    return !nonEscapingReceivers.contains(receiver);
  }

  void registerAllocation(HInstruction instruction) {
    assert(instruction == instruction.nonCheck());
    nonEscapingReceivers.add(instruction);
  }

  /**
   * Sets `receiver.element` to contain [value]. Kills all potential places that
   * may be affected by this update. Returns `true` if the update is redundant.
   */
  bool registerFieldValueUpdate(
      MemberEntity element, HInstruction receiver, HInstruction value) {
    assert(receiver == null || receiver == receiver.nonCheck());
    if (closedWorld.nativeData.isNativeMember(element)) {
      return false; // TODO(14955): Remove this restriction?
    }
    // [value] is being set in some place in memory, we remove it from the
    // non-escaping set.
    nonEscapingReceivers.remove(value.nonCheck());
    Map<HInstruction, HInstruction> map =
        fieldValues.putIfAbsent(element, () => <HInstruction, HInstruction>{});
    bool isRedundant = map[receiver] == value;
    map.forEach((key, value) {
      if (mayAlias(receiver, key)) map[key] = null;
    });
    map[receiver] = value;
    return isRedundant;
  }

  /**
   * Registers that `receiver.element` is now [value].
   */
  void registerFieldValue(
      MemberEntity element, HInstruction receiver, HInstruction value) {
    assert(receiver == null || receiver == receiver.nonCheck());
    if (closedWorld.nativeData.isNativeMember(element)) {
      return; // TODO(14955): Remove this restriction?
    }
    Map<HInstruction, HInstruction> map =
        fieldValues.putIfAbsent(element, () => <HInstruction, HInstruction>{});
    map[receiver] = value;
  }

  /**
   * Returns the value stored in `receiver.element`. Returns `null` if we don't
   * know.
   */
  HInstruction lookupFieldValue(MemberEntity element, HInstruction receiver) {
    assert(receiver == null || receiver == receiver.nonCheck());
    Map<HInstruction, HInstruction> map = fieldValues[element];
    return (map == null) ? null : map[receiver];
  }

  /**
   * Kill all places that may be affected by this [instruction]. Also update the
   * set of non-escaping objects in case [instruction] has non-escaping objects
   * in its inputs.
   */
  void killAffectedBy(HInstruction instruction) {
    // Even if [instruction] does not have side effects, it may use non-escaping
    // objects and store them in a new object, which make these objects
    // escaping.
    instruction.inputs.forEach((input) {
      nonEscapingReceivers.remove(input.nonCheck());
    });

    if (instruction.sideEffects.changesInstanceProperty() ||
        instruction.sideEffects.changesStaticProperty()) {
      List<MemberEntity> fieldsToRemove;
      List<HInstruction> receiversToRemove = <HInstruction>[];
      fieldValues.forEach((MemberEntity element, map) {
        if (isFinal(element)) return;
        map.forEach((receiver, value) {
          if (escapes(receiver)) {
            receiversToRemove.add(receiver);
          }
        });
        if (receiversToRemove.length == map.length) {
          // Remove them all by removing the entire map.
          (fieldsToRemove ??= <MemberEntity>[]).add(element);
        } else {
          receiversToRemove.forEach(map.remove);
        }
        receiversToRemove.clear();
      });
      fieldsToRemove?.forEach(fieldValues.remove);
    }

    if (instruction.sideEffects.changesIndex()) {
      keyedValues.forEach((receiver, map) {
        if (escapes(receiver)) {
          map.forEach((index, value) {
            map[index] = null;
          });
        }
      });
    }
  }

  /**
   * Returns the value stored in `receiver[index]`. Returns null if
   * we don't know.
   */
  HInstruction lookupKeyedValue(HInstruction receiver, HInstruction index) {
    Map<HInstruction, HInstruction> map = keyedValues[receiver];
    return (map == null) ? null : map[index];
  }

  /**
   * Registers that `receiver[index]` is now [value].
   */
  void registerKeyedValue(
      HInstruction receiver, HInstruction index, HInstruction value) {
    Map<HInstruction, HInstruction> map =
        keyedValues.putIfAbsent(receiver, () => <HInstruction, HInstruction>{});
    map[index] = value;
  }

  /**
   * Sets `receiver[index]` to contain [value]. Kills all potential
   * places that may be affected by this update.
   */
  void registerKeyedValueUpdate(
      HInstruction receiver, HInstruction index, HInstruction value) {
    nonEscapingReceivers.remove(value.nonCheck());
    keyedValues.forEach((key, values) {
      if (mayAlias(receiver, key)) {
        // Typed arrays that are views of the same buffer may have different
        // offsets or element sizes, unless they are the same typed array.
        bool weakIndex = couldBeTypedArray(key) && !mustAlias(receiver, key);
        values.forEach((otherIndex, otherValue) {
          if (weakIndex || mayAlias(index, otherIndex)) {
            values[otherIndex] = null;
          }
        });
      }
    });

    // Typed arrays may narrow incoming values.
    if (couldBeTypedArray(receiver)) return;

    Map<HInstruction, HInstruction> map =
        keyedValues.putIfAbsent(receiver, () => <HInstruction, HInstruction>{});
    map[index] = value;
  }

  /**
   * Returns null if either [first] or [second] is null. Otherwise
   * returns [first] if [first] and [second] are equal. Otherwise
   * creates or re-uses a phi in [block] that holds [first] and [second].
   */
  HInstruction findCommonInstruction(HInstruction first, HInstruction second,
      HBasicBlock block, int predecessorIndex) {
    if (first == null || second == null) return null;
    if (first == second) return first;
    TypeMask phiType =
        second.instructionType.union(first.instructionType, closedWorld);
    if (first is HPhi && first.block == block) {
      HPhi phi = first;
      phi.addInput(second);
      phi.instructionType = phiType;
      return phi;
    } else {
      HPhi phi = new HPhi.noInputs(null, phiType);
      block.addPhi(phi);
      // Previous predecessors had the same input. A phi must have
      // the same number of inputs as its block has predecessors.
      for (int i = 0; i < predecessorIndex; i++) {
        phi.addInput(first);
      }
      phi.addInput(second);
      return phi;
    }
  }

  /**
   * Returns the intersection between [this] and [other].
   */
  MemorySet intersectionFor(
      MemorySet other, HBasicBlock block, int predecessorIndex) {
    MemorySet result = new MemorySet(closedWorld);
    if (other == null) {
      // This is the first visit to a loop header ([other] is `null` because we
      // have not visited the back edge). Copy the nonEscapingReceivers that are
      // guaranteed to survive the loop because they are not escaped before
      // method exit.
      // TODO(sra): We should do a proper dataflow to find the maximal
      // nonEscapingReceivers (a variant of Available-Expressions), which must
      // converge before we edit the program in [findCommonInstruction].
      for (HInstruction instruction in nonEscapingReceivers) {
        bool isNonEscapingUse(HInstruction use) {
          if (use is HReturn) return true; // Escapes, but so does control.
          if (use is HFieldGet) return true;
          if (use is HFieldSet &&
              use.receiver.nonCheck() == instruction &&
              use.value.nonCheck() != instruction) {
            return true;
          }
          if (use is HTypeInfoReadVariable) return true;
          return false;
        }

        if (instruction.usedBy.every(isNonEscapingUse)) {
          result.nonEscapingReceivers.add(instruction);
        }
      }
      return result;
    }

    fieldValues.forEach((element, values) {
      var otherValues = other.fieldValues[element];
      if (otherValues == null) return;
      values.forEach((receiver, value) {
        HInstruction instruction = findCommonInstruction(
            value, otherValues[receiver], block, predecessorIndex);
        if (instruction != null) {
          result.registerFieldValue(element, receiver, instruction);
        }
      });
    });

    keyedValues.forEach((receiver, values) {
      var otherValues = other.keyedValues[receiver];
      if (otherValues == null) return;
      values.forEach((index, value) {
        HInstruction instruction = findCommonInstruction(
            value, otherValues[index], block, predecessorIndex);
        if (instruction != null) {
          result.registerKeyedValue(receiver, index, instruction);
        }
      });
    });

    nonEscapingReceivers.forEach((receiver) {
      if (other.nonEscapingReceivers.contains(receiver)) {
        result.nonEscapingReceivers.add(receiver);
      }
    });
    return result;
  }

  /**
   * Returns a copy of [this].
   */
  MemorySet clone() {
    MemorySet result = new MemorySet(closedWorld);

    fieldValues.forEach((element, values) {
      result.fieldValues[element] =
          new Map<HInstruction, HInstruction>.from(values);
    });

    keyedValues.forEach((receiver, values) {
      result.keyedValues[receiver] =
          new Map<HInstruction, HInstruction>.from(values);
    });

    result.nonEscapingReceivers.addAll(nonEscapingReceivers);
    return result;
  }
}
