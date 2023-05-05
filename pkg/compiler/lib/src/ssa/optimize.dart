// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry;
import '../common/elements.dart' show JCommonElements;
import '../common/names.dart' show Selectors;
import '../common/tasks.dart' show CompilerTask;
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../ir/util.dart';
import '../js_backend/field_analysis.dart'
    show FieldAnalysisData, JFieldAnalysis;
import '../js_backend/codegen_inputs.dart' show CodegenInputs;
import '../js_backend/native_data.dart' show NativeData;
import '../js_model/js_world.dart' show JClosedWorld;
import '../js_model/type_recipe.dart'
    show TypeExpressionRecipe, TypeRecipeDomain, TypeRecipeDomainImpl;
import '../js_backend/specialized_checks.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../universe/selector.dart' show Selector;
import '../universe/side_effects.dart' show SideEffects;
import '../universe/use.dart' show StaticUse;
import '../util/util.dart';
import 'interceptor_simplifier.dart';
import 'interceptor_finalizer.dart';
import 'late_field_optimizer.dart';
import 'logging.dart';
import 'nodes.dart';
import 'metrics.dart';
import 'types.dart';
import 'types_propagation.dart';
import 'validate.dart' show NoUnusedPhiValidator;
import 'value_range_analyzer.dart';
import 'value_set.dart';

abstract class OptimizationPhase {
  String get name;
  void visitGraph(HGraph graph);
  bool validPostcondition(HGraph graph);
}

class SsaOptimizerTask extends CompilerTask {
  final CompilerOptions _options;

  Map<HInstruction, Range> ranges = {};

  final Map<MemberEntity, OptimizationTestLog> loggersForTesting = {};

  SsaOptimizerTask(super.measurer, this._options);

  @override
  String get name => 'SSA optimizer';

  void optimize(
      MemberEntity member,
      HGraph graph,
      CodegenInputs codegen,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenRegistry registry,
      SsaMetrics metrics) {
    void runPhase(OptimizationPhase phase) {
      measureSubtask(phase.name, () => phase.visitGraph(graph));
      codegen.tracer.traceGraph(phase.name, graph);
      assert(graph.isValid(), 'Graph not valid after ${phase.name}');
      assert(phase.validPostcondition(graph),
          'Graph does not satisfy phase postcondition after ${phase.name}');
    }

    SsaCodeMotion codeMotion;
    SsaLoadElimination loadElimination;

    TypeRecipeDomain typeRecipeDomain =
        TypeRecipeDomainImpl(closedWorld.dartTypes);

    OptimizationTestLog? log;
    if (retainDataForTesting) {
      log = loggersForTesting[member] =
          OptimizationTestLog(closedWorld.dartTypes);
    }

    measure(() {
      List<OptimizationPhase> phases = [
        // Run trivial instruction simplification first to optimize
        // some patterns useful for type conversion.
        SsaInstructionSimplifier(globalInferenceResults, _options, closedWorld,
            typeRecipeDomain, registry, log, metrics),
        SsaTypeConversionInserter(closedWorld),
        SsaRedundantPhiEliminator(),
        SsaDeadPhiEliminator(),
        SsaTypePropagator(globalInferenceResults, closedWorld.commonElements,
            closedWorld, log),
        // After type propagation, more instructions can be
        // simplified.
        SsaInstructionSimplifier(globalInferenceResults, _options, closedWorld,
            typeRecipeDomain, registry, log, metrics),
        SsaInstructionSimplifier(globalInferenceResults, _options, closedWorld,
            typeRecipeDomain, registry, log, metrics),
        SsaTypePropagator(globalInferenceResults, closedWorld.commonElements,
            closedWorld, log),
        // Run a dead code eliminator before LICM because dead
        // interceptors are often in the way of LICM'able instructions.
        SsaDeadCodeEliminator(closedWorld, this),
        SsaGlobalValueNumberer(closedWorld.abstractValueDomain),
        // After GVN, some instructions might need their type to be
        // updated because they now have different inputs.
        SsaTypePropagator(globalInferenceResults, closedWorld.commonElements,
            closedWorld, log),
        codeMotion = SsaCodeMotion(closedWorld.abstractValueDomain),
        loadElimination = SsaLoadElimination(closedWorld),
        SsaRedundantPhiEliminator(),
        SsaDeadPhiEliminator(),
        SsaLateFieldOptimizer(closedWorld, log),
        // After GVN and load elimination the same value may be used in code
        // controlled by a test on the value, so redo 'conversion insertion' to
        // learn from the refined type.
        SsaTypeConversionInserter(closedWorld),
        SsaTypePropagator(globalInferenceResults, closedWorld.commonElements,
            closedWorld, log),
        SsaValueRangeAnalyzer(closedWorld, this),
        // Previous optimizations may have generated new
        // opportunities for instruction simplification.
        SsaInstructionSimplifier(globalInferenceResults, _options, closedWorld,
            typeRecipeDomain, registry, log, metrics),
      ];
      phases.forEach(runPhase);

      // Simplifying interceptors is just an optimization, it is required for
      // implementation correctness because the code generator assumes it is
      // always performed to compute the intercepted classes sets.
      runPhase(SsaSimplifyInterceptors(closedWorld, member.enclosingClass));

      SsaDeadCodeEliminator dce = SsaDeadCodeEliminator(closedWorld, this);
      runPhase(dce);
      if (codeMotion.movedCode ||
          dce.eliminatedSideEffects ||
          dce.newGvnCandidates ||
          loadElimination.newGvnCandidates) {
        phases = [
          SsaTypePropagator(globalInferenceResults, closedWorld.commonElements,
              closedWorld, log),
          SsaGlobalValueNumberer(closedWorld.abstractValueDomain),
          SsaCodeMotion(closedWorld.abstractValueDomain),
          SsaValueRangeAnalyzer(closedWorld, this),
          SsaInstructionSimplifier(globalInferenceResults, _options,
              closedWorld, typeRecipeDomain, registry, log, metrics),
          SsaSimplifyInterceptors(closedWorld, member.enclosingClass),
          SsaDeadCodeEliminator(closedWorld, this),
        ];
      } else {
        phases = [
          SsaTypePropagator(globalInferenceResults, closedWorld.commonElements,
              closedWorld, log),
          // Run the simplifier to remove unneeded type checks inserted by
          // type propagation.
          SsaInstructionSimplifier(globalInferenceResults, _options,
              closedWorld, typeRecipeDomain, registry, log, metrics),
        ];
      }
      phases.forEach(runPhase);
    });

    // SsaFinalizeInterceptors must always be run to ensure consistent calling
    // conventions between SSA-generated code and other code fragments generated
    // by the emitter.
    // TODO(sra): Generate these other fragments via SSA, then this phase
    // becomes an opt-in optimization.
    runPhase(SsaFinalizeInterceptors(closedWorld));
  }
}

/// Returns `true` if [mask] represents only types that have a length that
/// cannot change.  The current implementation is conservative for the purpose
/// of identifying gvn-able lengths and mis-identifies some unions of fixed
/// length indexables (see TODO) as not fixed length.
bool isFixedLength(AbstractValue mask, JClosedWorld closedWorld) {
  AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
  if (abstractValueDomain.isContainer(mask) &&
      abstractValueDomain.getContainerLength(mask) != null) {
    // A container on which we have inferred the length.
    return true;
  }
  // TODO(sra): Recognize any combination of fixed length indexables.
  if (abstractValueDomain.isFixedArray(mask).isDefinitelyTrue ||
      abstractValueDomain.isStringOrNull(mask).isDefinitelyTrue ||
      abstractValueDomain.isTypedArray(mask).isDefinitelyTrue) {
    return true;
  }
  return false;
}

/// Returns `true` if the end of [block] is unreachable, e.g. due to a `throw`
/// expression.
bool hasUnreachableExit(HBasicBlock block) {
  if (!block.isLive) return false;
  final last = block.last;
  if (last is HGoto) {
    final previous = last.previous;
    if (previous is HThrowExpression) return true;
    // TODO(sra): Match other signs of unreachability, e.g. a call to a method
    // that returns `[empty]`.
  }
  return false;
}

/// If both inputs to known operations are available execute the operation at
/// compile-time.
class SsaInstructionSimplifier extends HBaseVisitor<HInstruction>
    implements OptimizationPhase {
  // We don't produce constant-folded strings longer than this unless they have
  // a single use.  This protects against exponentially large constant folded
  // strings.
  static const MAX_SHARED_CONSTANT_FOLDED_STRING_LENGTH = 512;

  @override
  final String name = "SsaInstructionSimplifier";
  final GlobalTypeInferenceResults _globalInferenceResults;
  final CompilerOptions _options;
  final JClosedWorld _closedWorld;
  final TypeRecipeDomain _typeRecipeDomain;
  final CodegenRegistry _registry;
  final OptimizationTestLog? _log;
  final SsaMetrics _metrics;
  late final HGraph _graph;

  SsaInstructionSimplifier(
      this._globalInferenceResults,
      this._options,
      this._closedWorld,
      this._typeRecipeDomain,
      this._registry,
      this._log,
      this._metrics);

  JCommonElements get commonElements => _closedWorld.commonElements;

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

  NativeData get _nativeData => _closedWorld.nativeData;

  @override
  void visitGraph(HGraph visitee) {
    _graph = visitee;
    visitDominatorTree(visitee);
  }

  @override
  bool validPostcondition(HGraph graph) => true;

  @override
  void visitBasicBlock(HBasicBlock block) {
    simplifyPhis(block);
    HInstruction? instruction = block.first;
    while (instruction != null) {
      HInstruction? next = instruction.next;
      HInstruction replacement = instruction.accept(this);
      if (replacement != instruction) {
        block.rewrite(instruction, replacement);

        // The intersection of double and int return conflicting, and
        // because of our number implementation for JavaScript, it
        // might be that an operation thought to return double, can be
        // simplified to an int. For example:
        // `2.5 * 10`.
        if (!(replacement
                .isNumberOrNull(_abstractValueDomain)
                .isDefinitelyTrue &&
            instruction
                .isNumberOrNull(_abstractValueDomain)
                .isDefinitelyTrue)) {
          // If we can replace [instruction] with [replacement], then
          // [replacement]'s type can be narrowed.
          AbstractValue newType = _abstractValueDomain.intersection(
              replacement.instructionType, instruction.instructionType);
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
        _removeInstructionAndPureDeadInputs(instruction);
      }
      instruction = next;
    }
  }

  /// Removes [instruction] and the DAG of pure instructions that are transitive
  /// inputs to [instruction].
  ///
  /// It is worth doing the cleanup of removing the instructions in the
  /// simplifier as it reduces the `usedBy` count, which enables rewrites that
  /// are sensitive to the use count. Such rewrites can occur much earlier with
  /// 'online' usedBy counting.  The cost of visiting all inputs of a rewritten
  /// instruction is regained by avoiding visiting the dead instructions in
  /// subsequent passes.
  void _removeInstructionAndPureDeadInputs(HInstruction instruction) {
    List<HInstruction> worklist = instruction.inputs.toList();
    instruction.block!.remove(instruction);
    for (int i = 0; i < worklist.length; i++) {
      HInstruction next = worklist[i];
      final block = next.block;
      if (block == null) continue; // Already removed.
      if (next.usedBy.isEmpty && next.isPure(_abstractValueDomain)) {
        // Special cases that are removed properly by other phases.
        if (next is HParameterValue) continue;
        if (next is HLocalValue) continue;
        if (next is HConstant) continue;
        if (next is HPhi) continue;
        worklist.addAll(next.inputs);
        block.remove(next);
      }
    }
  }

  // Simplify some CFG diamonds to equivalent expressions.
  simplifyPhis(HBasicBlock block) {
    // Is [block] the join point for a simple diamond that generates a single
    // phi node?
    if (block.phis.isEmpty) return;
    HPhi phi = block.phis.first as HPhi;
    if (phi.next != null) return;
    if (block.predecessors.length != 2) return;
    assert(phi.inputs.length == 2);
    HBasicBlock b1 = block.predecessors[0];
    HBasicBlock b2 = block.predecessors[1];
    HBasicBlock dominator = block.dominator!;
    if (!(b1.dominator == dominator && b2.dominator == dominator)) return;

    // Extract the controlling condition.
    final controlFlow = dominator.last;
    if (controlFlow is! HIf) return;
    HInstruction test = controlFlow.inputs.single;
    if (test.usedBy.length > 1) return;

    bool negated = false;
    while (test is HNot) {
      test = test.inputs.single;
      if (test.usedBy.length > 1) return;
      negated = !negated;
    }

    if (test is! HIdentity) return;
    HInstruction tested;
    if (test.inputs[0].isNull(_abstractValueDomain).isDefinitelyTrue) {
      tested = test.inputs[1];
    } else if (test.inputs[1].isNull(_abstractValueDomain).isDefinitelyTrue) {
      tested = test.inputs[0];
    } else {
      return;
    }

    HInstruction whenNullValue = phi.inputs[negated ? 1 : 0];
    HInstruction whenNotNullValue = phi.inputs[negated ? 0 : 1];
    HBasicBlock whenNullBlock = block.predecessors[negated ? 1 : 0];
    HBasicBlock whenNotNullBlock = block.predecessors[negated ? 0 : 1];

    // If 'x' is nullable boolean,
    //
    //     x == null ? false : x  --->  x == true
    //
    // This ofen comes from the dart code `x ?? false`.
    if (_sameOrRefinementOf(tested, whenNotNullValue) &&
        _isBoolConstant(whenNullValue, false) &&
        whenNotNullValue
            .isBooleanOrNull(_abstractValueDomain)
            .isDefinitelyTrue &&
        _mostlyEmpty(whenNullBlock) &&
        _mostlyEmpty(whenNotNullBlock)) {
      HInstruction trueConstant = _graph.addConstantBool(true, _closedWorld);
      HInstruction replacement =
          HIdentity(tested, trueConstant, _abstractValueDomain.boolType)
            ..sourceElement = phi.sourceElement
            ..sourceInformation = phi.sourceInformation;
      block.rewrite(phi, replacement);
      block.addAtEntry(replacement);
      block.removePhi(phi);
      return;
    }
    // If 'x'is nullable boolean,
    //
    //     x == null ? true : x  --->  !(x == false)
    //
    // This ofen comes from the dart code `x ?? true`.
    if (_sameOrRefinementOf(tested, whenNotNullValue) &&
        _isBoolConstant(whenNullValue, true) &&
        whenNotNullValue
            .isBooleanOrNull(_abstractValueDomain)
            .isDefinitelyTrue &&
        _mostlyEmpty(whenNullBlock) &&
        _mostlyEmpty(whenNotNullBlock)) {
      HInstruction falseConstant = _graph.addConstantBool(false, _closedWorld);
      HInstruction compare =
          HIdentity(tested, falseConstant, _abstractValueDomain.boolType);
      block.addAtEntry(compare);
      HInstruction replacement = HNot(compare, _abstractValueDomain.boolType)
        ..sourceElement = phi.sourceElement
        ..sourceInformation = phi.sourceInformation;
      block.rewrite(phi, replacement);
      block.addAfter(compare, replacement);
      block.removePhi(phi);
      return;
    }

    // TODO(sra): Consider other simple diamonds, e.g. with the addition of a
    // special instruction,
    //
    //     s == null ? "" : s  --->  s || "".
    return;
  }

  bool _isBoolConstant(HInstruction node, bool value) {
    if (node is HConstant) {
      ConstantValue c = node.constant;
      if (c is BoolConstantValue) {
        return c.boolValue == value;
      }
    }
    return false;
  }

  bool _sameOrRefinementOf(HInstruction base, HInstruction insn) {
    if (base == insn) return true;
    if (insn is HTypeKnown) return _sameOrRefinementOf(base, insn.checkedInput);
    return false;
  }

  bool _mostlyEmpty(HBasicBlock block) {
    for (HInstruction? insn = block.first; insn != null; insn = insn.next) {
      if (insn is HTypeKnown) continue;
      if (insn is HGoto) return true;
      return false;
    }
    return true;
  }

  @override
  HInstruction visitInstruction(HInstruction node) {
    return node;
  }

  ConstantValue? getConstantFromType(HInstruction node) {
    if (node.isValue(_abstractValueDomain) &&
        node.isNull(_abstractValueDomain).isDefinitelyFalse &&
        node.isLateSentinel(_abstractValueDomain).isDefinitelyFalse) {
      final value =
          _abstractValueDomain.getPrimitiveValue(node.instructionType);
      if (value is BoolConstantValue) {
        return value;
      }
      // TODO(het): consider supporting other values (short strings?)
    }
    return null;
  }

  void propagateConstantValueToUses(HInstruction node) {
    if (node.usedBy.isEmpty) return;
    final value = getConstantFromType(node);
    if (value != null) {
      HConstant constant = _graph.addConstant(value, _closedWorld);
      for (HInstruction user in node.usedBy.toList()) {
        user.changeUse(node, constant);
      }
    }
  }

  @override
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
      // Trivial SSA-conversion. Replace all HLocalGet instructions with the
      // parameter.
      //
      // If there is a single assignment, it could dominate all the reads, or
      // dominate all the reads except one read, which was used to 'check' the
      // value at entry, like this:
      //
      //     t1 = HLocalGet(param);
      //     t2 = check(t1);           // replace t1 with param
      //     HLocalSet(param, t2);
      //     ....
      //     t3 = HLocalGet(param);
      //     ... t3 ...                // replace t3 with t2
      //
      HLocalSet? assignment;
      for (HInstruction user in node.usedBy) {
        if (user is HLocalSet) {
          assert(user.local == node);
          if (assignment != null) return node; // Two or more assignments.
          assignment = user;
          continue;
        }
        if (user is HLocalGet) continue;
        // There should not really be anything else but there are Phis which
        // have not been cleaned up.
        return node;
      }
      HLocalGet? checkedLoad;
      HInstruction value = node;
      if (assignment != null) {
        value = assignment.value;
        HInstruction source = value.nonCheck();
        if (source is HLocalGet && source.local == node) {
          if (source.usedBy.length != 1) return node;
          checkedLoad = source;
        }
      }
      // If there is a single assignment it will dominate all other uses.
      List<HLocalGet> loads = [];
      for (HInstruction user in node.usedBy) {
        if (user == assignment) continue;
        if (user == checkedLoad) continue;
        assert(user is HLocalGet && user.local == node);
        if (assignment != null && !assignment.dominates(user)) return node;
        loads.add(user as HLocalGet);
      }

      for (HLocalGet user in loads) {
        final block = user.block!;
        block.rewrite(user, value);
        block.remove(user);
      }
      if (checkedLoad != null) {
        final block = checkedLoad.block!;
        block.rewrite(checkedLoad, node);
        block.remove(checkedLoad);
      }
      if (assignment != null) {
        assignment.block!.remove(assignment);
      }
    }

    propagateConstantValueToUses(node);
    return node;
  }

  @override
  HInstruction visitNot(HNot node) {
    List<HInstruction> inputs = node.inputs;
    assert(inputs.length == 1);
    HInstruction input = inputs[0];
    if (input is HConstant) {
      return _graph.addConstantBool(
          input.constant is! TrueConstantValue, _closedWorld);
    } else if (input is HNot) {
      return input.inputs[0];
    }
    return node;
  }

  @override
  HInstruction visitInvokeUnary(HInvokeUnary node) {
    final folded = foldUnary(node.operation(), node.operand);
    return folded ?? node;
  }

  HInstruction? foldUnary(
      constant_system.UnaryOperation operation, HInstruction operand) {
    if (operand is HConstant) {
      HConstant receiver = operand;
      final folded = operation.fold(receiver.constant);
      if (folded != null) return _graph.addConstant(folded, _closedWorld);
    }
    return null;
  }

  HInstruction? tryOptimizeLengthInterceptedGetter(HInvokeDynamic node) {
    HInstruction actualReceiver = node.inputs[1];

    if (actualReceiver is HConstant) {
      ConstantValue constant = actualReceiver.constant;
      if (constant is StringConstantValue) {
        return _graph.addConstantInt(constant.length, _closedWorld);
      }
      if (constant is ListConstantValue) {
        return _graph.addConstantInt(constant.length, _closedWorld);
      }
      if (constant is MapConstantValue) {
        return _graph.addConstantInt(constant.length, _closedWorld);
      }
    }

    if (actualReceiver
        .isIndexablePrimitive(_abstractValueDomain)
        .isDefinitelyTrue) {
      bool isFixed =
          isFixedLength(actualReceiver.instructionType, _closedWorld);
      AbstractValue actualType = node.instructionType;
      AbstractValue resultType = _abstractValueDomain.positiveIntType;
      // If we already have computed a more specific type, keep that type.
      if (_abstractValueDomain
          .isInstanceOfOrNull(actualType, commonElements.jsUInt31Class)
          .isDefinitelyTrue) {
        resultType = _abstractValueDomain.uint31Type;
      } else if (_abstractValueDomain
          .isInstanceOfOrNull(actualType, commonElements.jsUInt32Class)
          .isDefinitelyTrue) {
        resultType = _abstractValueDomain.uint32Type;
      }
      HInstruction checkedReceiver = actualReceiver;
      if (actualReceiver.isNull(_abstractValueDomain).isPotentiallyTrue) {
        // The receiver is potentially `null` so we insert a null receiver
        // check. This will be folded into the length access later.
        HNullCheck check = HNullCheck(actualReceiver,
            _abstractValueDomain.excludeNull(actualReceiver.instructionType))
          ..selector = node.selector
          ..sourceInformation = node.sourceInformation;
        _log?.registerNullCheck(node, check);
        node.block!.addBefore(node, check);
        checkedReceiver = check;
      }
      HGetLength result =
          HGetLength(checkedReceiver, resultType, isAssignable: !isFixed);
      return result;
    }
    return null;
  }

  HInstruction handleInterceptedCall(HInvokeDynamic node) {
    // Try constant folding the instruction.
    final operation = node.specializer.operation();
    if (operation != null) {
      HInstruction? folded;
      if (operation is constant_system.UnaryOperation) {
        assert(node.inputs.length == 2);
        folded = foldUnary(operation, node.inputs[1]);
      } else if (operation is constant_system.BinaryOperation) {
        assert(node.inputs.length == 3);
        folded = foldBinary(operation, node.inputs[1], node.inputs[2]);
      }
      if (folded != null) {
        _metrics.countOperationFolded.add();
        return folded;
      }
    }

    // Try converting the instruction to a builtin instruction.
    final instruction = node.specializer.tryConvertToBuiltin(node, _graph,
        _globalInferenceResults, commonElements, _closedWorld, _log);
    if (instruction != null) {
      _metrics.countSpecializations.add();
      return instruction;
    }

    Selector selector = node.selector;
    AbstractValue mask = node.receiverType;
    HInstruction input = node.inputs[1];

    bool applies(MemberEntity element) {
      return selector.applies(element) &&
          _abstractValueDomain
              .isTargetingMember(mask, element, selector.memberName)
              .isPotentiallyTrue;
    }

    if (selector.isCall || selector.isOperator) {
      FunctionEntity? target;
      if (input.isExtendableArray(_abstractValueDomain).isDefinitelyTrue) {
        if (applies(commonElements.jsArrayAdd)) {
          // Codegen special cases array calls to `Array.push`, but does not
          // inline argument type checks. We lower if the check always passes
          // (due to invariance or being a top-type), or if the check is not
          // emitted.
          if (node.isInvariant ||
              input is HLiteralList ||
              !_closedWorld.annotationsData
                  .getParameterCheckPolicy(commonElements.jsArrayAdd)
                  .isEmitted) {
            target = commonElements.jsArrayAdd;
          }
        }
      } else if (input.isStringOrNull(_abstractValueDomain).isDefinitelyTrue) {
        if (commonElements.appliesToJsStringSplit(
            selector, mask, _abstractValueDomain)) {
          return handleStringSplit(node);
        } else if (applies(commonElements.jsStringOperatorAdd)) {
          // `operator+` is turned into a JavaScript '+' so we need to
          // make sure the receiver and the argument are not null.
          // TODO(sra): Do this via [node.specializer].
          HInstruction argument = node.inputs[2];
          if (argument.isString(_abstractValueDomain).isDefinitelyTrue &&
              input.isNull(_abstractValueDomain).isDefinitelyFalse) {
            return HStringConcat(input, argument, node.instructionType);
          }
        } else if (applies(commonElements.jsStringToString) &&
            input.isNull(_abstractValueDomain).isDefinitelyFalse) {
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
        // TODO(sra): Fix comment - SsaCheckInserter is deleted.
        HInvokeDynamicMethod result = HInvokeDynamicMethod(
            node.selector,
            node.receiverType,
            node.inputs.sublist(1), // Drop interceptor.
            node.instructionType,
            node.typeArguments,
            node.sourceInformation,
            isIntercepted: false);
        result.element = target;
        return result;
      }
    } else if (selector.isGetter) {
      if (commonElements.appliesToJsIndexableLength(selector)) {
        final optimized = tryOptimizeLengthInterceptedGetter(node);
        if (optimized != null) {
          _metrics.countLengthOptimized.add();
          return optimized;
        }
      }
    }

    return node;
  }

  HInstruction handleStringSplit(HInvokeDynamic node) {
    HInstruction argument = node.inputs[2];
    if (!argument.isString(_abstractValueDomain).isDefinitelyTrue) {
      return node;
    }

    // Replace `s.split$1(pattern)` with
    //
    //     t1 = s.split(pattern);
    //     t2 = String;
    //     t3 = JSArray<t2>;
    //     t4 = setArrayType(t1, t3);
    //

    AbstractValue resultMask = _abstractValueDomain.growableListType;

    HInvokeDynamicMethod splitInstruction = HInvokeDynamicMethod(
        node.selector,
        node.receiverType,
        node.inputs.sublist(1), // Drop interceptor.
        resultMask,
        const <DartType>[],
        node.sourceInformation,
        isIntercepted: false)
      ..element = commonElements.jsStringSplit
      ..setAllocation(true);

    if (!_closedWorld.rtiNeed
        .classNeedsTypeArguments(commonElements.jsArrayClass)) {
      return splitInstruction;
    }

    node.block!.addBefore(node, splitInstruction);

    HInstruction typeInfo = HLoadType.type(
        _closedWorld.elementEnvironment.createInterfaceType(
            commonElements.jsArrayClass, [commonElements.stringType]),
        _abstractValueDomain.dynamicType);
    node.block!.addBefore(node, typeInfo);

    HInvokeStatic tagInstruction = HInvokeStatic(commonElements.setArrayType,
        [splitInstruction, typeInfo], resultMask, const <DartType>[]);
    // 'Linear typing' trick: [tagInstruction] is the only use of the
    // [splitInstruction], so it becomes the sole alias.
    // TODO(sra): Build this knowledge into alias analysis.
    tagInstruction.setAllocation(true);

    return tagInstruction;
  }

  @override
  HInstruction visitInvokeDynamicMethod(HInvokeDynamicMethod node) {
    propagateConstantValueToUses(node);
    if (node.isInterceptedCall) {
      HInstruction folded = handleInterceptedCall(node);
      if (folded != node) return folded;
    }

    HInstruction receiver = node.getDartReceiver(_closedWorld);
    AbstractValue receiverType = receiver.instructionType;
    final element =
        _closedWorld.locateSingleMember(node.selector, receiverType);
    if (element == null) return node;

    // TODO(ngeoffray): Also fold if it's a getter or variable.
    if (element.isFunction &&
        // If we found out that the only target is an implicitly called
        // `noSuchMethod` we just ignore it.
        node.selector.applies(element)) {
      // `.isFunction` implies FunctionEntity, but not vice-versa.
      FunctionEntity method = element as FunctionEntity;

      if (_nativeData.isNativeMember(method)) {
        return tryInlineNativeMethod(node, method) ?? node;
      }

      // TODO(ngeoffray): If the method has optional parameters, we should pass
      // the default values.
      ParameterStructure parameters = method.parameterStructure;
      if (parameters.totalParameters == node.selector.argumentCount &&
          parameters.typeParameters ==
              node.selector.callStructure.typeArgumentCount) {
        node.element = method;
      }
      return node;
    }

    // Replace method calls through fields with a closure call on the value of
    // the field. This usually removes the demand for the call-through stub and
    // makes the field load available to further optimization, e.g. LICM.

    if (element is FieldEntity && element.name == node.selector.name) {
      FieldEntity field = element;
      if (!_nativeData.isNativeMember(field) &&
          !node.isCallOnInterceptor(_closedWorld)) {
        // Insertion point for the closure call.
        HInstruction insertionPoint = node;
        HInstruction load;
        FieldAnalysisData fieldData =
            _closedWorld.fieldAnalysis.getFieldData(field);
        if (fieldData.isEffectivelyConstant) {
          // The field is elided and replace it with its constant value.
          if (_abstractValueDomain.isNull(receiverType).isPotentiallyTrue) {
            // The receiver is potentially `null` so we insert a null receiver
            // check to trigger a null pointer exception.  Insert check
            // conditionally to avoid the work of removing it later.
            HNullCheck check = HNullCheck(
                receiver, _abstractValueDomain.excludeNull(receiverType))
              ..selector = node.selector
              ..sourceInformation = node.sourceInformation;
            _log?.registerNullCheck(node, check);
            node.block!.addBefore(node, check);
            insertionPoint = check;
          }
          HConstant constant = _graph.addConstant(
              fieldData.constantValue!, _closedWorld,
              sourceInformation: node.sourceInformation);
          _log?.registerConstantFieldCall(node, field, constant);
          load = constant;
        } else {
          AbstractValue type = AbstractValueFactory.inferredTypeForMember(
              field, _globalInferenceResults);
          HFieldGet fieldGet = HFieldGet(
              field, receiver, type, node.sourceInformation,
              isAssignable: field.isAssignable);
          _log?.registerFieldCall(node, fieldGet);
          node.block!.addBefore(node, fieldGet);
          insertionPoint = fieldGet;
          load = fieldGet;
        }
        Selector callSelector = Selector.callClosureFrom(node.selector);
        List<HInstruction> inputs = [
          load,
          ...node.inputs.skip(node.isInterceptedCall ? 2 : 1)
        ];
        DartType fieldType =
            _closedWorld.elementEnvironment.getFieldType(field);
        HInstruction closureCall = HInvokeClosure(
            callSelector,
            _abstractValueDomain
                .createFromStaticType(fieldType, nullable: true)
                .abstractValue,
            inputs,
            node.instructionType,
            node.typeArguments)
          ..sourceInformation = node.sourceInformation;
        node.block!.addAfter(insertionPoint, closureCall);
        return closureCall;
      }
    }

    return node;
  }

  bool _avoidInliningNativeMethod(HInvokeDynamic node, FunctionEntity method) {
    assert(_nativeData.isNativeMember(method));
    if (_options.disableInlining) return true;
    if (_closedWorld.annotationsData.hasNoInline(method)) {
      return true;
    }
    return false;
  }

  // Try to 'inline' an instance getter call to a known native or js-interop
  // getter. This replaces the call to the getter on the Dart interceptor with a
  // direct call to the external method.
  HInstruction? tryInlineNativeGetter(
      HInvokeDynamicGetter node, FunctionEntity method) {
    if (_avoidInliningNativeMethod(node, method)) return null;

    // Strengthen instruction type from annotations to help optimize dependent
    // instructions.
    NativeBehavior nativeBehavior = _nativeData.getNativeMethodBehavior(method);
    AbstractValue returnType =
        AbstractValueFactory.fromNativeBehavior(nativeBehavior, _closedWorld);
    HInstruction receiver = node.inputs.last; // Drop interceptor.
    receiver = maybeGuardWithNullCheck(receiver, node, null);
    HInstruction result = HInvokeExternal(
        method, [receiver], returnType, nativeBehavior,
        sourceInformation: node.sourceInformation);
    _registry.registerStaticUse(StaticUse.methodInlining(method, null));
    // Assume Native getters effect-free as an approximation to being
    // idempotent.
    // TODO(sra): [native.BehaviorBuilder.buildMethodBehavior] should do this
    // for us.
    result.sideEffects.setDependsOnSomething();
    result.sideEffects.clearAllSideEffects();
    result.setUseGvn();

    return maybeAddNativeReturnNullCheck(node, result, method);
  }

  HInstruction maybeAddNativeReturnNullCheck(
      HInstruction node, HInstruction replacement, FunctionEntity method) {
    if (_options.nativeNullAssertions) {
      if (method.library.isNonNullableByDefault) {
        FunctionType type =
            _closedWorld.elementEnvironment.getFunctionType(method);
        if (_closedWorld.dartTypes.isNonNullableIfSound(type.returnType) &&
            memberEntityIsInWebLibrary(method)) {
          node.block!.addBefore(node, replacement);
          replacement = HNullCheck(replacement,
              _abstractValueDomain.excludeNull(replacement.instructionType),
              sticky: true);
        }
      }
    }
    return replacement;
  }

  // Try to 'inline' an instance setter call to a known native or js-interop
  // getter. This replaces the call to the setter on the Dart interceptor with a
  // direct call to the external method.
  HInstruction? tryInlineNativeSetter(
      HInvokeDynamicSetter node, FunctionEntity method) {
    if (_avoidInliningNativeMethod(node, method)) return null;

    assert(node.inputs.length == 3);
    HInstruction receiver = node.inputs[1];
    HInstruction value = node.inputs[2];
    FunctionType type = _closedWorld.elementEnvironment.getFunctionType(method);
    assert(type.optionalParameterTypes.isEmpty);
    assert(type.namedParameterTypes.isEmpty);
    DartType parameterType = type.parameterTypes.single;
    if (_nativeArgumentNeedsCheckOrConversion(method, parameterType, value)) {
      return null;
    }

    NativeBehavior nativeBehavior = _nativeData.getNativeMethodBehavior(method);
    receiver = maybeGuardWithNullCheck(receiver, node, null);
    HInvokeExternal result = HInvokeExternal(
        method, [receiver, value], value.instructionType, nativeBehavior,
        sourceInformation: node.sourceInformation);
    _registry.registerStaticUse(StaticUse.methodInlining(method, null));
    return result;
  }

  // TODO(sra): Refactor this code so that we can decide to inline the method
  // with a few checks or conversions. We would want to do this if there was a
  // single call site to [method], or most arguments do not require a check.
  bool _nativeArgumentNeedsCheckOrConversion(
      FunctionEntity method, DartType parameterType, HInstruction argument) {
    // TODO(sra): JS-interop *instance* methods don't check their arguments
    // since the forwarding stub is shared by all JS-interop methods with the
    // same name, regardless of parameter types. We could 'inline' js-interop
    // calls even when the types of the arguments are incorrect.

    if (!_nativeData.isJsInteropMember(method)) {
      // @Native methods have conversion code for function arguments. Rather
      // than insert that code at the inlined call site, call the target on the
      // interceptor.
      if (parameterType.withoutNullability is FunctionType) return true;
    }

    if (!_closedWorld.annotationsData
        .getParameterCheckPolicy(method)
        .isEmitted) {
      // If the target has no checks we can inline.
      return false;
    }

    final parameterAbstractValue = _abstractValueDomain
        .getAbstractValueForNativeMethodParameterType(parameterType);

    if (parameterAbstractValue == null ||
        _abstractValueDomain
            .isIn(argument.instructionType, parameterAbstractValue)
            .isPotentiallyFalse) {
      return true;
    }
    return false;
  }

  // Try to 'inline' an instance method call to a known native or js-interop
  // method. This replaces the call to the method on the Dart interceptor with a
  // direct call to the external method.
  HInstruction? tryInlineNativeMethod(
      HInvokeDynamicMethod node, FunctionEntity method) {
    if (_avoidInliningNativeMethod(node, method)) return null;
    // We can replace the call to the native class interceptor method (target)
    // if the target does no conversions or useful type checks.

    FunctionType type = _closedWorld.elementEnvironment.getFunctionType(method);
    if (type.namedParameters.isNotEmpty) return null;

    // The call site might omit optional arguments. The inlined code must
    // preserve the number of arguments, so check only the actual arguments.
    bool canInline = true;
    List<HInstruction> inputs = node.inputs;
    int inputPosition = 2; // Skip interceptor and receiver.

    void checkParameterType(DartType parameterType) {
      if (!canInline) return;
      if (inputPosition >= inputs.length) return;
      HInstruction input = inputs[inputPosition++];
      if (_nativeArgumentNeedsCheckOrConversion(method, parameterType, input)) {
        canInline = false;
      }
    }

    type.parameterTypes.forEach(checkParameterType);
    type.optionalParameterTypes.forEach(checkParameterType);
    assert(type.namedParameterTypes.isEmpty);

    if (!canInline) return null;

    // Strengthen instruction type from annotations to help optimize
    // dependent instructions.
    NativeBehavior nativeBehavior = _nativeData.getNativeMethodBehavior(method);
    AbstractValue returnType =
        AbstractValueFactory.fromNativeBehavior(nativeBehavior, _closedWorld);
    HInstruction receiver = inputs[1];
    receiver = maybeGuardWithNullCheck(receiver, node, null);
    HInstruction result = HInvokeExternal(
        method,
        [receiver, ...inputs.skip(2)], // '2': Drop interceptor and receiver.
        returnType,
        nativeBehavior,
        sourceInformation: node.sourceInformation);
    _registry.registerStaticUse(StaticUse.methodInlining(method, null));

    return maybeAddNativeReturnNullCheck(node, result, method);
  }

  @override
  HInstruction visitBoundsCheck(HBoundsCheck node) {
    // TODO(sra): Remove all this code. It marks a bounds check where the index
    // is a non-integer as always failing. We can still get a non-integer index
    // with non-sound null safety (1) with legacy code where the index is `null`
    // (2) when we lower `[]` from a dynamic call and omit the argument type
    // check (e.g. under -O3).
    HInstruction index = node.index;
    if (index.isInteger(_abstractValueDomain).isDefinitelyTrue) {
      return node;
    }
    if (index is HConstant) {
      assert(index.constant is! IntConstantValue);
      if (!constant_system.isInt(index.constant)) {
        // -0.0 is a double but will pass the runtime integer check.
        node.staticChecks = HBoundsCheck.ALWAYS_FALSE;
      }
    }
    return node;
  }

  HConstant? foldBinary(constant_system.BinaryOperation operation,
      HInstruction left, HInstruction right) {
    if (left is HConstant && right is HConstant) {
      ConstantValue? folded = operation.fold(left.constant, right.constant);
      if (folded != null) return _graph.addConstant(folded, _closedWorld);
    }
    return null;
  }

  @override
  HInstruction visitAdd(HAdd node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    // We can only perform this rewriting on Integer, as it is not
    // valid for -0.0.
    if (left.isInteger(_abstractValueDomain).isDefinitelyTrue &&
        right.isInteger(_abstractValueDomain).isDefinitelyTrue) {
      if (left is HConstant && left.constant.isZero) return right;
      if (right is HConstant && right.constant.isZero) return left;
    }
    return super.visitAdd(node);
  }

  @override
  HInstruction visitMultiply(HMultiply node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    if (left.isNumber(_abstractValueDomain).isDefinitelyTrue &&
        right.isNumber(_abstractValueDomain).isDefinitelyTrue) {
      if (left is HConstant && left.constant.isOne) return right;
      if (right is HConstant && right.constant.isOne) return left;
    }
    return super.visitMultiply(node);
  }

  @override
  HInstruction visitInvokeBinary(HInvokeBinary node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    constant_system.BinaryOperation operation = node.operation();
    final folded = foldBinary(operation, left, right);
    if (folded != null) return folded;
    return node;
  }

  @override
  HInstruction visitRelational(HRelational node) {
    return super.visitRelational(node);
  }

  HInstruction? handleIdentityCheck(HRelational node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    AbstractValue leftType = left.instructionType;
    AbstractValue rightType = right.instructionType;

    HInstruction makeTrue() => _graph.addConstantBool(true, _closedWorld);
    HInstruction makeFalse() => _graph.addConstantBool(false, _closedWorld);

    // Intersection of int and double return conflicting, so
    // we don't optimize on numbers to preserve the runtime semantics.
    // TODO(sra): The above is probably no longer true.
    if (!(left.isNumberOrNull(_abstractValueDomain).isDefinitelyTrue &&
        right.isNumberOrNull(_abstractValueDomain).isDefinitelyTrue)) {
      if (_abstractValueDomain
          .areDisjoint(leftType, rightType)
          .isDefinitelyTrue) {
        return makeFalse();
      }
    }

    if (left.isNull(_abstractValueDomain).isDefinitelyTrue &&
        right.isNull(_abstractValueDomain).isDefinitelyTrue) {
      return makeTrue();
    }

    // `x == true` --> `x`
    // `x == false` --> `!x`
    HInstruction? tryCompareConstant(
        HConstant constantInput, HInstruction otherInput) {
      final constant = constantInput.constant;
      if (constant is BoolConstantValue &&
          otherInput.isBoolean(_abstractValueDomain).isDefinitelyTrue) {
        return constant.boolValue
            ? otherInput
            : HNot(otherInput, _abstractValueDomain.boolType);
      }
      return null;
    }

    HInstruction? replacement;
    if (left is HConstant) {
      replacement = tryCompareConstant(left, right);
    } else if (right is HConstant) {
      replacement = tryCompareConstant(right, left);
    }
    if (replacement != null) return replacement;

    if (identical(left.nonCheck(), right.nonCheck())) {
      // Avoid constant-folding `identical(x, x)` when `x` might be double.  The
      // dart2js runtime has not always been consistent with the Dart
      // specification (section 16.0.1), which makes distinctions on NaNs and
      // -0.0 that are hard to implement efficiently.
      if (left.isIntegerOrNull(_abstractValueDomain).isDefinitelyTrue) {
        return makeTrue();
      }
      if (left.isPrimitiveNumber(_abstractValueDomain).isDefinitelyFalse) {
        return makeTrue();
      }
    }

    return null;
  }

  FieldEntity _indexFieldOfEnumClass(ClassEntity enumClass) {
    // We expect the enum class to extend `_Enum`, which has an `index` field,
    // but that might be shadowed by an abstract getter from the class or a
    // mixin.
    ClassEntity? cls = enumClass;
    MemberEntity? foundMember;
    while (cls != null) {
      final member = _closedWorld.elementEnvironment
          .lookupClassMember(cls, const PublicName('index'));
      if (member == null) break; // should never happen.
      foundMember = member;
      if (member is FieldEntity) return member;
      if (!member.isAbstract) break;
      cls = _closedWorld.elementEnvironment.getSuperClass(cls);
    }
    throw StateError('$enumClass should have index field, found $foundMember');
  }

  IntConstantValue _indexValueOfEnumConstant(
      ConstantValue constant, ClassEntity enumClass, FieldEntity field) {
    if (constant is ConstructedConstantValue) {
      if (constant.type.element == enumClass) {
        final value = constant.fields[field];
        if (value is IntConstantValue) return value;
      }
    }
    throw StateError(
        'Enum constant ${constant.toStructuredText(_closedWorld.dartTypes)}'
        ' should have $field');
  }

  // The `enum` class of the [node], or `null` if [node] does not have an
  // non-nullable enum type.
  ClassEntity? _enumClass(HInstruction node) {
    final cls = _abstractValueDomain.getExactClass(node.instructionType);
    if (cls == null) return null;
    if (_closedWorld.elementEnvironment.isEnumClass(cls)) return cls;
    return null;
  }

  // Try to replace enum labels in a switch with the index values. This is
  // usually smaller, faster, and might allow the JavaScript engine to compile
  // the switch to a jump-table.
  void _tryReduceEnumsInSwitch(HSwitch node) {
    final enumClass = _enumClass(node.expression);
    if (enumClass == null) return;

    FieldEntity indexField = _indexFieldOfEnumClass(enumClass);
    // In some cases the `index` field is elided. We can't load an elided field.
    //
    // TODO(sra): The ConstantValue has the index value, so we can still reduce
    // the enum to the index value. We could handle an elided `index` field in
    // some cases by doing this optimization more like scalar replacement or
    // unboxing, replacing all enums in the method at once, possibly reducing
    // phis of enums to phis of indexes.
    if (_closedWorld.fieldAnalysis.getFieldData(indexField).isElided) return;

    // All the label expressions should be of the same enum class as the switch
    // expression.
    for (final label in node.inputs.skip(1)) {
      if (label is! HConstant) return;
      if (_enumClass(label) != enumClass) return;
    }

    final loadIndex = _directFieldGet(node.expression, indexField, node);
    node.block!.addBefore(node, loadIndex);
    node.replaceInput(0, loadIndex);

    for (int i = 1; i < node.inputs.length; i++) {
      ConstantValue labelConstant = (node.inputs[i] as HConstant).constant;
      node.replaceInput(
          i,
          _graph.addConstant(
              _indexValueOfEnumConstant(labelConstant, enumClass, indexField),
              _closedWorld));
    }
  }

  @override
  HInstruction visitSwitch(HSwitch node) {
    _tryReduceEnumsInSwitch(node);
    return node;
  }

  @override
  HInstruction visitIdentity(HIdentity node) {
    final newInstruction = handleIdentityCheck(node);
    return newInstruction ?? super.visitIdentity(node);
  }

  @override
  HInstruction visitIsLateSentinel(HIsLateSentinel node) {
    HInstruction value = node.inputs[0];
    AbstractBool isLateSentinel = value.isLateSentinel(_abstractValueDomain);
    if (isLateSentinel.isDefinitelyTrue) {
      _metrics.countLateSentinelCheckDecided.add();
      return _graph.addConstantBool(true, _closedWorld);
    } else if (isLateSentinel.isDefinitelyFalse) {
      _metrics.countLateSentinelCheckDecided.add();
      return _graph.addConstantBool(false, _closedWorld);
    }

    return super.visitIsLateSentinel(node);
  }

  void simplifyCondition(
      HBasicBlock? block, HInstruction condition, bool value, String tag) {
    if (block == null) return;

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
    // which is further simplified to:
    //
    //    if (x) { init(); }
    //    ...
    //    x = false;
    //
    // This is mostly harmless (if a little confusing) but does cause a lot of
    // `x = false;` copies to be inserted when a loop body has many continue
    // statements or ends with a switch.
    DominatedUses uses =
        DominatedUses.of(condition, block.first!, excludePhiOutEdges: true);
    if (uses.isEmpty) return;
    uses.replaceWith(_graph.addConstantBool(value, _closedWorld));
    _log?.registerConditionValue(condition, value, tag, uses.length);
  }

  @override
  HInstruction visitIf(HIf node) {
    HInstruction condition = node.condition;
    if (condition is HConstant) return node;

    AbstractBool isTruthy =
        _abstractValueDomain.isTruthy(condition.instructionType);
    if (isTruthy.isDefinitelyTrue) {
      _metrics.countConditionDecided.add();
      return _replaceHIfCondition(
          node, _graph.addConstantBool(true, _closedWorld));
    } else if (isTruthy.isDefinitelyFalse) {
      _metrics.countConditionDecided.add();
      return _replaceHIfCondition(
          node, _graph.addConstantBool(false, _closedWorld));
    }

    HBasicBlock thenBlock = node.thenBlock;
    HBasicBlock elseBlock = node.elseBlock;

    // For diamond control flow, if the end of the then- or else-block is not
    // reachable, the other block dynamically dominates the join, so the join
    // acts as a continuation of the else- or then- branch.
    HBasicBlock? thenContinuation;
    HBasicBlock? elseContinuation;
    if (node.joinBlock != null) {
      final joinPredecessors = node.joinBlock!.predecessors;
      if (joinPredecessors.length == 2) {
        if (hasUnreachableExit(joinPredecessors[0])) {
          elseContinuation = node.joinBlock;
        } else if (hasUnreachableExit(joinPredecessors[1])) {
          thenContinuation = node.joinBlock;
        }
      }
    }

    simplifyCondition(thenBlock, condition, true, 'then');
    simplifyCondition(thenContinuation, condition, true, 'then-join');
    simplifyCondition(elseBlock, condition, false, 'else');
    simplifyCondition(elseContinuation, condition, false, 'else-join');

    if (condition is HNot) {
      //  if (!t1) ... t1 ...
      HInstruction negated = condition.inputs[0];
      simplifyCondition(thenBlock, negated, false, 'then');
      simplifyCondition(thenContinuation, negated, false, 'then-join');
      simplifyCondition(elseBlock, negated, true, 'else');
      simplifyCondition(elseContinuation, negated, true, 'else-join');
    } else {
      // It is possible for LICM to move a negated version of the condition out
      // of the loop where it used. We still want to simplify the nested use of
      // the condition in that case, so we look for all dominating negated
      // conditions and replace nested uses of them with true or false.
      //
      //     t1 = ...
      //     t2 = !t1
      //     loop
      //       if (t1)
      //         t2     // replace with `false`
      //
      Iterable<HInstruction> dominating = condition.usedBy
          .where((user) => user is HNot && user.dominates(node));
      dominating.forEach((hoisted) {
        simplifyCondition(thenBlock, hoisted, false, 'hoisted-then');
        simplifyCondition(
            thenContinuation, hoisted, false, 'hoisted-then-join');
        simplifyCondition(elseBlock, hoisted, true, 'hoisted-else');
        simplifyCondition(elseContinuation, hoisted, true, 'hoisted-else-join');
      });
    }

    return node;
  }

  /// Returns [node] after replacing condition.
  HInstruction _replaceHIfCondition(HIf node, HInstruction newCondition) {
    node.replaceInput(0, newCondition);
    return node;
  }

  @override
  HInstruction visitPrimitiveCheck(HPrimitiveCheck node) {
    if (node.isRedundant(_closedWorld)) return node.checkedInput;
    return node;
  }

  @override
  HInstruction visitBoolConversion(HBoolConversion node) {
    if (node.isRedundant(_closedWorld)) return node.checkedInput;
    return node;
  }

  @override
  HInstruction visitNullCheck(HNullCheck node) {
    if (node.isRedundant(_closedWorld)) return node.checkedInput;
    return node;
  }

  @override
  HInstruction visitLateReadCheck(HLateReadCheck node) {
    if (node.isRedundant(_closedWorld)) return node.checkedInput;
    return node;
  }

  @override
  HInstruction visitLateWriteOnceCheck(HLateWriteOnceCheck node) {
    if (node.isRedundant(_closedWorld)) return node.checkedInput;
    return node;
  }

  @override
  HInstruction visitLateInitializeOnceCheck(HLateInitializeOnceCheck node) {
    if (node.isRedundant(_closedWorld)) return node.checkedInput;
    return node;
  }

  @override
  HInstruction visitTypeKnown(HTypeKnown node) {
    if (node.isRedundant(_closedWorld)) return node.checkedInput;
    return node;
  }

  @override
  HInstruction visitFieldGet(HFieldGet node) {
    var receiver = node.receiver;

    // HFieldGet of a constructed constant can be replaced with the constant's
    // field.
    if (receiver is HConstant) {
      ConstantValue constant = receiver.constant;
      if (constant is ConstructedConstantValue) {
        final value = constant.fields[node.element];
        if (value != null) {
          _metrics.countFieldGetFolded.add();
          return _graph.addConstant(value, _closedWorld);
        }
      }
    }

    return node;
  }

  @override
  HInstruction visitGetLength(HGetLength node) {
    HInstruction receiver = node.receiver;

    if (receiver is HConstant) {
      ConstantValue constant = receiver.constant;
      if (constant is ListConstantValue) {
        _metrics.countGetLengthFolded.add();
        return _graph.addConstantInt(constant.length, _closedWorld);
      }
      if (constant is StringConstantValue) {
        _metrics.countGetLengthFolded.add();
        return _graph.addConstantInt(constant.length, _closedWorld);
      }
    }

    AbstractValue receiverType = receiver.instructionType;
    if (_abstractValueDomain.isContainer(receiverType)) {
      int? length = _abstractValueDomain.getContainerLength(receiverType);
      if (length != null) {
        HInstruction constant = _graph.addConstantInt(length, _closedWorld);
        _metrics.countGetLengthFolded.add();
        if (_abstractValueDomain.isNull(receiverType).isPotentiallyTrue) {
          // If the container can be null, we update all uses of the length
          // access to use the constant instead, but keep the length access in
          // the graph, to ensure we still have a null check.
          node.block!.rewrite(node, constant);
          return node;
        }
        return constant;
      }
    }

    // Can we find the length as an input to an allocation?
    HInstruction potentialAllocation = receiver;
    if (receiver is HInvokeStatic &&
        receiver.element == commonElements.setArrayType) {
      // Look through `setArrayType(new Array(), ...)`
      potentialAllocation = receiver.inputs.first;
    }
    if (_graph.allocatedFixedLists.contains(potentialAllocation)) {
      // TODO(sra): How do we keep this working if we lower/inline the receiver
      // in an optimization?

      HInstruction lengthInput = potentialAllocation.inputs.first;

      // We don't expect a non-integer first input to the fixed-size allocation,
      // but checking the input is an integer ensures we do not replace a
      // HGetlength with a reference to something with a type that will confuse
      // bounds check elimination.
      if (lengthInput.isInteger(_abstractValueDomain).isDefinitelyTrue) {
        // TODO(sra). HGetLength may have a better type than [lengthInput] as
        // the allocation may throw on an out-of-range input. Typically the
        // input is an unconstrained `int` and the length is non-negative. We
        // may have done some optimizations with the better type that we won't
        // be able to do with the broader type of [lengthInput].  We should
        // insert a HTypeKnown witnessed by the allocation to narrow the
        // lengthInput.
        _metrics.countGetLengthFolded.add();
        return lengthInput;
      }
    }

    if (node.isAssignable &&
        isFixedLength(receiver.instructionType, _closedWorld)) {
      // The input type has changed to fixed-length so change to an unassignable
      // HGetLength to allow more GVN optimizations.
      _metrics.countGetLengthFolded.add();
      return HGetLength(receiver, node.instructionType, isAssignable: false);
    }
    return node;
  }

  @override
  HInstruction visitIndex(HIndex node) {
    HInstruction receiver = node.receiver;
    if (receiver is HConstant) {
      HInstruction index = node.index;
      if (index is HConstant) {
        final foldedValue =
            constant_system.index.fold(receiver.constant, index.constant);
        if (foldedValue != null) {
          _metrics.countIndexFolded.add();
          return _graph.addConstant(foldedValue, _closedWorld);
        }
      }
    }
    return node;
  }

  @override
  HInstruction visitCharCodeAt(HCharCodeAt node) {
    final folded =
        foldBinary(constant_system.codeUnitAt, node.receiver, node.index);
    if (folded != null) return folded;
    return node;
  }

  /// Returns the guarded receiver.
  HInstruction maybeGuardWithNullCheck(
      HInstruction receiver, HInvokeDynamic node, FieldEntity? field) {
    AbstractValue receiverType = receiver.instructionType;
    if (_abstractValueDomain.isNull(receiverType).isPotentiallyTrue) {
      HNullCheck check =
          HNullCheck(receiver, _abstractValueDomain.excludeNull(receiverType))
            ..selector = node.selector
            ..field = field
            ..sourceInformation = node.sourceInformation;
      _log?.registerNullCheck(node, check);
      node.block!.addBefore(node, check);
      return check;
    }
    return receiver;
  }

  @override
  HInstruction visitInvokeDynamicGetter(HInvokeDynamicGetter node) {
    propagateConstantValueToUses(node);
    if (node.isInterceptedCall) {
      HInstruction folded = handleInterceptedCall(node);
      if (folded != node) return folded;
    }
    HInstruction receiver = node.getDartReceiver(_closedWorld);
    AbstractValue receiverType = receiver.instructionType;

    Selector selector = node.selector;
    final member =
        node.element ?? _closedWorld.locateSingleMember(selector, receiverType);
    if (member == null) return node;

    if (member is FieldEntity) {
      FieldEntity field = member;
      FieldAnalysisData fieldData =
          _closedWorld.fieldAnalysis.getFieldData(field);
      if (fieldData.isEffectivelyConstant) {
        // The field is elided and replace it with its constant value.
        maybeGuardWithNullCheck(receiver, node, null);
        ConstantValue constant = fieldData.constantValue!;
        HConstant result = _graph.addConstant(constant, _closedWorld,
            sourceInformation: node.sourceInformation);
        _metrics.countGettersElided.add();
        _log?.registerConstantFieldGet(node, field, result);
        return result;
      } else {
        receiver = maybeGuardWithNullCheck(receiver, node, field);
        HFieldGet result = _directFieldGet(receiver, field, node);
        _metrics.countGettersInlined.add();
        _log?.registerFieldGet(node, result);
        return result;
      }
    }

    if (member is FunctionEntity) {
      // If the member is not a getter, this could be a property extraction
      // getter or legacy `noSuchMethod`.
      if (member.isGetter && member.name == selector.name) {
        node.element = member;
        if (_nativeData.isNativeMember(member)) {
          return tryInlineNativeGetter(node, member) ?? node;
        }
      }
    }

    if (member.isFunction && member.name == selector.name) {
      // A property extraction getter, aka a tear-off.
      node.element = member;
      node.sideEffects.clearAllDependencies();
      node.sideEffects.clearAllSideEffects();
      node.setUseGvn(); // We don't care about identity of tear-offs.
    }
    return node;
  }

  HFieldGet _directFieldGet(
      HInstruction receiver, FieldEntity field, HInstruction node) {
    bool isAssignable = !_closedWorld.fieldNeverChanges(field);

    AbstractValue type;
    if (_nativeData.isNativeClass(field.enclosingClass!)) {
      type = AbstractValueFactory.fromNativeBehavior(
          _nativeData.getNativeFieldLoadBehavior(field), _closedWorld);
    } else {
      // TODO(johnniwinther): Use the potentially more precise type of the
      // node + find a test that shows its usefulness.
      // type = _abstractValueDomain.intersection(
      //     node.instructionType,
      //     AbstractValueFactory.inferredTypeForMember(
      //         field, _globalInferenceResults));
      type = AbstractValueFactory.inferredTypeForMember(
          field, _globalInferenceResults);
    }

    return HFieldGet(field, receiver, type, node.sourceInformation,
        isAssignable: isAssignable);
  }

  @override
  HInstruction visitInvokeDynamicSetter(HInvokeDynamicSetter node) {
    if (node.isInterceptedCall) {
      HInstruction folded = handleInterceptedCall(node);
      if (folded != node) return folded;
    }

    HInstruction receiver = node.getDartReceiver(_closedWorld);
    AbstractValue receiverType = receiver.instructionType;
    final member = node.element ??=
        _closedWorld.locateSingleMember(node.selector, receiverType);
    if (member == null) return node;

    if (member is FieldEntity) {
      if (!member.isAssignable) return node;
      // Use `node.inputs.last` in case the call follows the interceptor calling
      // convention, but is not a call on an interceptor.
      HInstruction value = node.inputs.last;

      HInstruction assignField() {
        if (_closedWorld.fieldAnalysis.getFieldData(member).isElided) {
          _log?.registerFieldSet(node);
          _metrics.countSettersElided.add();
          return value;
        } else {
          HFieldSet result =
              HFieldSet(_abstractValueDomain, member, receiver, value)
                ..sourceInformation = node.sourceInformation;
          _log?.registerFieldSet(node, result);
          _metrics.countSettersInlined.add();
          return result;
        }
      }

      if (!_closedWorld.annotationsData
          .getParameterCheckPolicy(member)
          .isEmitted) {
        return assignField();
      }

      DartType fieldType = _closedWorld.elementEnvironment.getFieldType(member);

      AbstractValueWithPrecision checkedType =
          _abstractValueDomain.createFromStaticType(fieldType, nullable: true);
      if (checkedType.isPrecise &&
          _abstractValueDomain
              .isIn(value.instructionType, checkedType.abstractValue)
              .isDefinitelyTrue) {
        return assignField();
      }
      // TODO(sra): Implement inlining of setters with checks for new rti. The
      // check and field assignment for the setter should be inlined if this is
      // the only call to the setter, or the current function already computes
      // the type of the field.
      node.needsCheck = true;
      return node;
    }

    if (member is FunctionEntity) {
      // If the member is not a setter is could be legacy `noSuchMethod`.
      if (member.isSetter && member.name == node.selector.name) {
        if (_nativeData.isNativeMember(member)) {
          return tryInlineNativeSetter(node, member) ?? node;
        }
      }
    }

    return node;
  }

  @override
  HInstruction visitInvokeClosure(HInvokeClosure node) {
    HInstruction closure = node.getDartReceiver(_closedWorld);

    // Replace indirect call to static method tear-off closure with direct call
    // to static method.
    if (closure is HConstant) {
      ConstantValue constant = closure.constant;
      if (constant is FunctionConstantValue) {
        FunctionEntity target = constant.element;
        ParameterStructure parameterStructure = target.parameterStructure;
        if (parameterStructure.callStructure == node.selector.callStructure) {
          // TODO(sra): Handle adding optional arguments default values.
          assert(!node.isInterceptedCall);
          return HInvokeStatic(target, node.inputs.skip(1).toList(),
              node.instructionType, node.typeArguments)
            ..sourceInformation = node.sourceInformation;
        }
      }
    }
    return node;
  }

  @override
  HInstruction visitInvokeStatic(HInvokeStatic node) {
    propagateConstantValueToUses(node);
    MemberEntity element = node.element;

    if (element == commonElements.identicalFunction) {
      if (node.inputs.length == 2) {
        return HIdentity(
            node.inputs[0], node.inputs[1], _abstractValueDomain.boolType)
          ..sourceInformation = node.sourceInformation;
      }
    } else if (element == commonElements.setArrayType) {
      if (node.inputs.length == 2) {
        return handleArrayTypeInfo(node);
      }
    } else if (commonElements.isCheckConcurrentModificationError(element)) {
      if (node.inputs.length == 2) {
        HInstruction firstArgument = node.inputs[0];
        if (firstArgument is HConstant) {
          HConstant constant = firstArgument;
          if (constant.constant is TrueConstantValue) return constant;
        }
      }
    } else if (commonElements.isCheckInt(element)) {
      if (node.inputs.length == 1) {
        HInstruction argument = node.inputs[0];
        if (argument.isInteger(_abstractValueDomain).isDefinitelyTrue) {
          return argument;
        }
      }
    } else if (commonElements.isCheckNum(element)) {
      if (node.inputs.length == 1) {
        HInstruction argument = node.inputs[0];
        if (argument.isNumber(_abstractValueDomain).isDefinitelyTrue) {
          return argument;
        }
      }
    } else if (commonElements.isCheckString(element)) {
      if (node.inputs.length == 1) {
        HInstruction argument = node.inputs[0];
        if (argument.isString(_abstractValueDomain).isDefinitelyTrue) {
          return argument;
        }
      }
    } else if (element == commonElements.assertHelper ||
        element == commonElements.assertTest) {
      if (node.inputs.length == 1) {
        HInstruction argument = node.inputs[0];
        if (argument is HConstant) {
          ConstantValue constant = argument.constant;
          if (constant is BoolConstantValue) {
            bool value = constant is TrueConstantValue;
            if (element == commonElements.assertTest) {
              // `assertTest(argument)` effectively negates the argument.
              return _graph.addConstantBool(!value, _closedWorld);
            }
            // `assertHelper(true)` is a no-op, other values throw.
            if (value) return argument;
          }
        }
      }
    }

    // TODO(sra): [element] could be a native or js-interop method, in which
    // case we could 'inline' the call to the Dart-convention wrapper code,
    // replacing it with a HInvokeExternal instruction. Many of these static
    // methods are already 'inlined' by the CFG builder.

    return node;
  }

  HInstruction handleArrayTypeInfo(HInvokeStatic node) {
    // If type information is not needed, use the raw Array.
    HInstruction source = node.inputs[0];
    if (source.usedBy.length != 1) return node;
    if (source.isArray(_abstractValueDomain).isPotentiallyFalse) {
      return node;
    }
    for (HInstruction user in node.usedBy) {
      if (user is HGetLength) continue;
      if (user is HIndex) continue;
      // Bounds check escapes the array, but we don't care.
      if (user is HBoundsCheck) continue;
      // Interceptor only escapes the Array if array passed to an intercepted
      // method.
      if (user is HInterceptor) continue;
      if (user is HInvokeStatic) {
        MemberEntity element = user.element;
        if (commonElements.isCheckConcurrentModificationError(element)) {
          // CME check escapes the array, but we don't care.
          continue;
        }
      }
      if (user is HInvokeDynamicGetter) {
        String name = user.selector.name;
        // These getters don't use the Array type.
        if (name == 'last') continue;
        if (name == 'first') continue;
      }
      // TODO(sra): Implement a more general algorithm - many methods don't use
      // the element type.
      return node;
    }
    return source;
  }

  @override
  HInstruction visitStringConcat(HStringConcat node) {
    // Simplify string concat:
    //
    //     "" + R                ->  R
    //     L + ""                ->  L
    //     "L" + "R"             ->  "LR"
    //     (prefix + "L") + "R"  ->  prefix + "LR"
    //
    StringConstantValue? getString(HInstruction instruction) {
      if (instruction is HConstant) {
        final constant = instruction.constant;
        if (constant is StringConstantValue) return constant;
      }
      return null;
    }

    final left = node.left;
    final right = node.right;
    StringConstantValue? leftString = getString(left);
    if (leftString != null && leftString.stringValue.length == 0) {
      return right;
    }

    final rightString = getString(right);
    if (rightString == null) return node;
    if (rightString.stringValue.length == 0) return left;

    HInstruction? prefix;
    if (leftString == null) {
      if (left is! HStringConcat) return node;
      HStringConcat leftConcat = left;
      // Don't undo CSE.
      if (leftConcat.usedBy.length != 1) return node;
      prefix = leftConcat.left;
      leftString = getString(leftConcat.right);
      if (leftString == null) return node;
    }

    if (leftString.stringValue.length + rightString.stringValue.length >
        MAX_SHARED_CONSTANT_FOLDED_STRING_LENGTH) {
      if (node.usedBy.length > 1) return node;
    }

    HInstruction folded = _graph.addConstant(
        constant_system
            .createString(leftString.stringValue + rightString.stringValue),
        _closedWorld);
    if (prefix == null) return folded;
    return HStringConcat(prefix, folded, _abstractValueDomain.stringType);
  }

  @override
  HInstruction visitStringify(HStringify node) {
    HInstruction input = node.inputs[0];
    if (input.isString(_abstractValueDomain).isDefinitelyTrue) {
      return input;
    }

    HInstruction asString(String string) =>
        _graph.addConstant(constant_system.createString(string), _closedWorld);

    HInstruction? tryConstant() {
      if (input is HConstant) {
        ConstantValue value = input.constant;
        if (value is IntConstantValue) {
          // Only constant-fold int.toString() when Dart and JS results the
          // same.
          // TODO(18103): We should be able to remove this workaround when
          // issue 18103 is resolved by providing the correct string.
          if (!value.isUInt32()) return null;
          return asString('${value.intValue}');
        }
        if (value is BoolConstantValue) {
          return asString(value.boolValue ? 'true' : 'false');
        }
        if (value is NullConstantValue) {
          return asString('null');
        }
        if (value is DoubleConstantValue) {
          // TODO(sra): It seems unlikely that all dart2js host implementations
          // produce exactly the same characters as all JavaScript targets.
          return asString('${value.doubleValue}');
        }
      }
      return null;
    }

    HInstruction? tryToString() {
      // If the `toString` method is guaranteed to return a string we can call
      // it directly. Keep the stringifier for primitives (since they have fast
      // path code in the stringifier) and for classes requiring interceptors
      // (since SsaInstructionSimplifier runs after SsaSimplifyInterceptors).
      if (input.isPrimitive(_abstractValueDomain).isPotentiallyTrue) {
        return null;
      }
      if (input.isNull(_abstractValueDomain).isPotentiallyTrue) {
        return null;
      }
      Selector selector = Selectors.toString_;
      AbstractValue toStringType =
          AbstractValueFactory.inferredResultTypeForSelector(
              selector, input.instructionType, _globalInferenceResults);
      if (_abstractValueDomain
          .containsOnlyType(
              toStringType, _closedWorld.commonElements.jsStringClass)
          .isPotentiallyFalse) {
        return null;
      }
      // All intercepted classes extend `Interceptor`, so if the receiver can't
      // be a class extending `Interceptor` then it can be called directly.
      if (_abstractValueDomain
          .isInterceptor(input.instructionType)
          .isDefinitelyFalse) {
        List<HInstruction> inputs = [input, input]; // [interceptor, receiver].
        HInstruction result = HInvokeDynamicMethod(
            selector,
            input.instructionType, // receiver type.
            inputs,
            toStringType,
            const <DartType>[],
            node.sourceInformation,
            isIntercepted: true);
        return result;
      }
      return null;
    }

    // For primitives we know the stringifier is effect-free and never throws.
    if (input.isNumberOrNull(_abstractValueDomain).isDefinitelyTrue ||
        input.isStringOrNull(_abstractValueDomain).isDefinitelyTrue ||
        input.isBooleanOrNull(_abstractValueDomain).isDefinitelyTrue) {
      node.setPure();
    }

    return tryConstant() ?? tryToString() ?? node;
  }

  @override
  HInstruction visitOneShotInterceptor(HOneShotInterceptor node) {
    throw StateError('Should not see HOneShotInterceptor in simplifier: $node');
  }

  @override
  HInstruction visitTypeEval(HTypeEval node) {
    HInstruction environment = node.inputs.single;
    if (_typeRecipeDomain.isIdentity(node.typeExpression, node.envStructure)) {
      return environment;
    }

    if (environment is HLoadType) {
      final result = _typeRecipeDomain.foldLoadEval(
          environment.typeExpression, node.envStructure, node.typeExpression);
      if (result != null) return HLoadType(result, node.instructionType);
      return node;
    }

    if (environment is HTypeBind) {
      HInstruction bindings = environment.inputs.last;
      if (bindings is HLoadType) {
        //  env.bind(LoadType(T)).eval(...1...)  -->  env.eval(...T...)
        final result = _typeRecipeDomain.foldBindLoadEval(
            bindings.typeExpression, node.envStructure, node.typeExpression);
        if (result != null) {
          HInstruction previousEnvironment = environment.inputs.first;
          return HTypeEval(previousEnvironment, result.environmentStructure,
              result.recipe, node.instructionType);
        }
      }
      // TODO(sra):  LoadType(T).bind(E).eval(...1...) --> E.eval(...0...)
      return node;
    }

    if (environment is HTypeEval) {
      final result = _typeRecipeDomain.foldEvalEval(environment.envStructure,
          environment.typeExpression, node.envStructure, node.typeExpression);
      if (result != null) {
        HInstruction previousEnvironment = environment.inputs.first;
        return HTypeEval(previousEnvironment, result.environmentStructure,
            result.recipe, node.instructionType);
      }
      return node;
    }

    if (environment is HInstanceEnvironment) {
      HInstruction instance = environment.inputs.single;
      AbstractValue instanceAbstractValue = instance.instructionType;
      ClassEntity? instanceClass;

      // All the subclasses of JSArray are JSArray at runtime.
      ClassEntity jsArrayClass = _closedWorld.commonElements.jsArrayClass;
      if (_abstractValueDomain
          .isInstanceOf(instanceAbstractValue, jsArrayClass)
          .isDefinitelyTrue) {
        instanceClass = jsArrayClass;
      } else {
        instanceClass =
            _abstractValueDomain.getExactClass(instanceAbstractValue);
      }
      if (instanceClass != null) {
        if (_typeRecipeDomain.isReconstruction(
            instanceClass, node.envStructure, node.typeExpression)) {
          return environment;
        }
      }
    }

    return node;
  }

  @override
  HInstruction visitTypeBind(HTypeBind node) {
    // TODO(sra):  env1.eval(X).bind(env1.eval(Y)) --> env1.eval(...X...Y...)
    return node;
  }

  @override
  HInstruction visitAsCheck(HAsCheck node) {
    // TODO(fishythefish): Correctly constant fold `null as T` (also in
    // [visitAsCheckSimple]) when running with sound null safety. We might get
    // this for free if nullability is precisely propagated to the typemasks.

    HInstruction typeInput = node.typeInput;
    if (typeInput is HLoadType) {
      // Always a TypeExpressionRecipe, otherwise 'as' is malformed.
      TypeExpressionRecipe recipe =
          typeInput.typeExpression as TypeExpressionRecipe;
      node.checkedTypeExpression = recipe.type;
    }

    if (node.isRedundant(_closedWorld, _options)) {
      return node.checkedInput;
    }

    // See if this check can be lowered to a simple one.
    final specializedCheck = SpecializedChecks.findAsCheck(
        node.checkedTypeExpression,
        _closedWorld.commonElements,
        _options.useLegacySubtyping);
    if (specializedCheck != null) {
      AbstractValueWithPrecision checkedType = _abstractValueDomain
          .createFromStaticType(node.checkedTypeExpression, nullable: true);
      return HAsCheckSimple(
          node.checkedInput,
          node.checkedTypeExpression,
          checkedType,
          node.isTypeError,
          specializedCheck,
          node.instructionType);
    }
    return node;
  }

  @override
  HInstruction visitAsCheckSimple(HAsCheckSimple node) {
    if (node.isRedundant(_closedWorld, _options)) {
      return node.checkedInput;
    }
    return node;
  }

  @override
  HInstruction visitIsTest(HIsTest node) {
    HInstruction typeInput = node.typeInput;
    if (typeInput is HLoadType) {
      // Always a TypeExpressionRecipe, otherwise 'is' is malformed.
      TypeExpressionRecipe recipe =
          typeInput.typeExpression as TypeExpressionRecipe;
      node.dartType = recipe.type;
    }

    AbstractBool result = node.evaluate(_closedWorld, _options);
    if (result.isDefinitelyFalse) {
      _metrics.countIsTestDecided.add();
      return _graph.addConstantBool(false, _closedWorld);
    }
    if (result.isDefinitelyTrue) {
      _metrics.countIsTestDecided.add();
      return _graph.addConstantBool(true, _closedWorld);
    }

    final specialization = SpecializedChecks.findIsTestSpecialization(
        node.dartType, _graph.element, _closedWorld);

    if (specialization == IsTestSpecialization.isNull ||
        specialization == IsTestSpecialization.isNotNull) {
      HInstruction nullTest = HIdentity(node.checkedInput,
          _graph.addConstantNull(_closedWorld), _abstractValueDomain.boolType);
      if (specialization == IsTestSpecialization.isNull) return nullTest;
      nullTest.sourceInformation = node.sourceInformation;
      node.block!.addBefore(node, nullTest);
      return HNot(nullTest, _abstractValueDomain.boolType);
    }

    if (specialization != null) {
      AbstractValueWithPrecision checkedType = _abstractValueDomain
          .createFromStaticType(node.dartType, nullable: false);
      _metrics.countIsTestSimplified.add();
      return HIsTestSimple(node.dartType, checkedType, specialization,
          node.checkedInput, _abstractValueDomain.boolType);
    }

    // TODO(fishythefish): Prune now-unneeded is-tests from the metadata.

    return node;
  }

  @override
  HInstruction visitIsTestSimple(HIsTestSimple node) {
    AbstractBool result = node.evaluate(_closedWorld, _options);
    if (result.isDefinitelyFalse) {
      _metrics.countIsTestDecided.add();
      return _graph.addConstantBool(false, _closedWorld);
    }
    if (result.isDefinitelyTrue) {
      _metrics.countIsTestDecided.add();
      return _graph.addConstantBool(true, _closedWorld);
    }
    return node;
  }

  @override
  HInstruction visitInstanceEnvironment(HInstanceEnvironment node) {
    HInstruction instance = node.inputs.single;

    // Store-forward instance types of created instances and constant instances.
    //
    // Forwarding the type might cause the instance (HCreate, constant etc) to
    // become dead. This might cause us to lose track of that fact that there
    // are type expressions from within the instance's class scope, so breaking
    // the algorithm for generating the per-type runtime type information. The
    // fix is to register the classes as created here in case the instance
    // becomes dead.
    //
    // TODO(sra): It would be cleaner to track on HLoadType, HTypeEval, etc
    // which class scope(s) they originated from. If the type expressions become
    // dead, the references to the scope type variables become dead.

    if (instance is HCreate) {
      if (instance.hasRtiInput) {
        instance.instantiatedTypes?.forEach(_registry.registerInstantiation);
        return instance.rtiInput;
      }
      InterfaceType instanceType =
          _closedWorld.elementEnvironment.getThisType(instance.element);
      if (instanceType.typeArguments.length == 0) {
        instance.instantiatedTypes?.forEach(_registry.registerInstantiation);
        return HLoadType.type(instanceType, instance.instructionType);
      }
      return node;
    }

    if (instance is HConstant) {
      ConstantValue constantValue = instance.constant;
      if (constantValue is ConstructedConstantValue) {
        _registry.registerInstantiation(constantValue.type);
        return HLoadType.type(constantValue.type, instance.instructionType);
      }
      if (constantValue is ListConstantValue) {
        InterfaceType type = constantValue.type;
        _registry.registerInstantiation(type);
        return HLoadType.type(type, instance.instructionType);
      }
      return node;
    }

    if (instance is HInvokeStatic &&
        instance.element == commonElements.setArrayType) {
      // TODO(sra): What is the 'instantiated type' we should be registering as
      // discussed above? Perhaps it should be carried on HLiteralList.
      return instance.inputs.last;
    }

    return node;
  }

  @override
  HInstruction visitBitAnd(HBitAnd node) {
    HInstruction left = node.left;
    HInstruction right = node.right;

    if (left is HConstant) {
      if (right is HConstant) {
        return foldBinary(node.operation(), left, right) ?? node;
      }
      //  c1 & a  -->  a & c1
      return HBitAnd(right, left, node.instructionType);
    }

    if (right is HConstant) {
      ConstantValue constant = right.constant;
      if (constant.isZero) return right; // a & 0  -->  0
      if (_isFull32BitMask(constant)) {
        if (left.isUInt32(_abstractValueDomain).isDefinitelyTrue) {
          // Mask of all '1's has no effect.
          return left;
          // TODO(sra): A more advanced version of this would be to see if the
          // input might have any bits that would be cleared by the mask.  Thus
          // `a >> 24 & 255` is a no-op since `a >> 24` can have only the low 8
          // bits non-zero. If a bit is must-zero, we can remove it from
          // mask. e.g. if a is Uint31, then `a >> 24 & 0xF0` becomes `a >> 24 &
          // 0x70`.
        }

        // Ensure that the result is still canonicalized to an unsigned 32-bit
        // integer using `left >>> 0`. This shift is often removed or combined
        // in subsequent optimization.
        HConstant zero = _graph.addConstantInt(0, _closedWorld);
        return HShiftRight(left, zero, node.instructionType);
      }

      if (left is HBitAnd && left.usedBy.length == 1) {
        HInstruction operand1 = left.left;
        HInstruction operand2 = left.right;
        if (operand2 is HConstant) {
          //  (a & c1) & c2  -->  a & (c1 & c2)
          final folded = foldBinary(constant_system.bitAnd, operand2, right);
          if (folded == null) return node;
          return HBitAnd(operand1, folded, node.instructionType);
        }
        // TODO(sra): We don't rewrite (a & c1) & b --> (a & b) & c1. I suspect
        // that the JavaScript VM might benefit from reducing the value early
        // (e.g. to a 'Smi'). We could do that, but we should also consider a
        // variation of the above rule where:
        //
        //     a & c1 & ... & b & c2  -->  a & (c1 & c2) & ... & b
        //
        // This would probably be best deferred until after GVN in case (a & c1)
        // is reused.
      }
    }

    return node;
  }

  bool _isFull32BitMask(ConstantValue constant) {
    return constant is IntConstantValue && constant.intValue == _mask32;
  }

  static final _mask32 = BigInt.parse('FFFFFFFF', radix: 16);

  @override
  HInstruction visitBitOr(HBitOr node) {
    HInstruction left = node.left;
    HInstruction right = node.right;

    if (left is HConstant) {
      if (right is HConstant) {
        return foldBinary(node.operation(), left, right) ?? node;
      }
      //  c1 | a  -->  a | c1
      return HBitOr(right, left, node.instructionType);
    }

    //  (a | b) | c
    if (left is HBitOr && left.usedBy.length == 1) {
      HInstruction operand1 = left.left;
      HInstruction operand2 = left.right;
      if (operand2 is HConstant) {
        if (right is HConstant) {
          //  (a | c1) | c2  -->  a | (c1 | c2)
          final folded = foldBinary(constant_system.bitOr, operand2, right);
          if (folded == null) return node;
          return HBitOr(operand1, folded, node.instructionType);
        } else {
          //  (a | c1) | b  -->  (a | b) | c1
          HInstruction or1 = _makeBitOr(operand1, right)
            ..sourceInformation = left.sourceInformation;
          node.block!.addBefore(node, or1);
          // TODO(sra): Restart simplification at 'or1'.
          return _makeBitOr(or1, operand2);
        }
      }
    }

    //  (a & c1) | (a & c2)  -->  a & (c1 | c2)
    if (left is HBitAnd &&
        left.usedBy.length == 1 &&
        right is HBitAnd &&
        right.usedBy.length == 1) {
      HInstruction a1 = left.left;
      HInstruction a2 = right.left;
      if (a1 == a2) {
        HInstruction c1 = left.right;
        HInstruction c2 = right.right;
        if (c1 is HConstant && c2 is HConstant) {
          final folded = foldBinary(constant_system.bitOr, c1, c2);
          if (folded != null) {
            return HBitAnd(a1, folded, node.instructionType);
          }
        }
      }
    }

    // TODO(sra):
    //
    //  (e | (a & c1)) | (a & c2)  -->  e | (a & (c1 | c2))

    return node;
  }

  HBitOr _makeBitOr(HInstruction operand1, HInstruction operand2) {
    AbstractValue instructionType = _abstractValueDomainBitOr(
        operand1.instructionType, operand2.instructionType);
    return HBitOr(operand1, operand2, instructionType);
  }

  // TODO(sra): Use a common definition of primitive operations in the
  // AbstractValueDomain.
  AbstractValue _abstractValueDomainBitOr(AbstractValue a, AbstractValue b) {
    return (_abstractValueDomain.isUInt31(a).isDefinitelyTrue &&
            _abstractValueDomain.isUInt31(b).isDefinitelyTrue)
        ? _abstractValueDomain.uint31Type
        : _abstractValueDomain.uint32Type;
  }

  @override
  HInstruction visitShiftRight(HShiftRight node) {
    HInstruction left = node.left;
    HInstruction count = node.right;
    if (count is HConstant) {
      if (left is HConstant) {
        return foldBinary(node.operation(), left, count) ?? node;
      }
      ConstantValue countValue = count.constant;
      // Shift by zero can convert to 32 bit unsigned, so remove only if no-op.
      //  a >> 0  -->  a
      if (countValue.isZero &&
          left.isUInt32(_abstractValueDomain).isDefinitelyTrue) {
        return left;
      }
      if (left is HBitAnd && left.usedBy.length == 1) {
        // TODO(sra): Should this be postponed to after GVN?
        HInstruction operand = left.left;
        HInstruction mask = left.right;
        if (mask is HConstant) {
          // Reduce mask constant size.
          //  (a & mask) >> count  -->  (a >> count) & (mask >> count)
          ConstantValue maskValue = mask.constant;

          final shiftedMask =
              constant_system.shiftRight.fold(maskValue, countValue);
          if (shiftedMask is IntConstantValue && shiftedMask.isUInt32()) {
            // TODO(sra): The shift type should be available from the abstract
            // value domain.
            AbstractValue shiftType = shiftedMask.isZero
                ? _abstractValueDomain.uint32Type
                : _abstractValueDomain.uint31Type;
            var shift = HShiftRight(operand, count, shiftType)
              ..sourceInformation = node.sourceInformation;

            node.block!.addBefore(node, shift);
            HConstant shiftedMaskInstruction =
                _graph.addConstant(shiftedMask, _closedWorld);
            return HBitAnd(shift, shiftedMaskInstruction, node.instructionType);
          }
        }
        return node;
      }
    }
    return node;
  }

  @override
  HInstruction visitShiftLeft(HShiftLeft node) {
    HInstruction left = node.left;
    HInstruction count = node.right;
    if (count is HConstant) {
      if (left is HConstant) {
        return foldBinary(node.operation(), left, count) ?? node;
      }
      // Shift by zero can convert to 32 bit unsigned, so remove only if no-op.
      //  a << 0  -->  a
      if (count.constant.isZero &&
          left.isUInt32(_abstractValueDomain).isDefinitelyTrue) {
        return left;
      }
      // Shift-mask-unshift reduction.
      //   ((a >> c1) & c2) << c1  -->  a & (c2 << c1);
      if (left is HBitAnd && left.usedBy.length == 1) {
        HInstruction operand1 = left.left;
        HInstruction operand2 = left.right;
        if (operand2 is HConstant) {
          if (operand1 is HShiftRight && operand1.usedBy.length == 1) {
            HInstruction a = operand1.left;
            HInstruction count2 = operand1.right;
            if (count2 == count) {
              final folded =
                  foldBinary(constant_system.shiftLeft, operand2, count);
              if (folded != null) {
                return HBitAnd(a, folded, node.instructionType);
              }
            }
          }
        }
      }
    }
    return node;
  }
}

class SsaDeadCodeEliminator extends HGraphVisitor implements OptimizationPhase {
  @override
  final String name = "SsaDeadCodeEliminator";

  final JClosedWorld closedWorld;
  final SsaOptimizerTask optimizer;
  late final HGraph _graph;
  Map<HInstruction, bool> trivialDeadStoreReceivers = Maplet();
  bool eliminatedSideEffects = false;
  bool newGvnCandidates = false;

  SsaDeadCodeEliminator(this.closedWorld, this.optimizer);

  AbstractValueDomain get _abstractValueDomain =>
      closedWorld.abstractValueDomain;

  // A constant with no type does not pollute types at phi nodes.
  late final HInstruction zapInstruction =
      _graph.addConstantUnreachable(closedWorld);

  /// Determines whether we can delete [instruction] because the only thing it
  /// does is throw the same exception as the next instruction that throws or
  /// has an effect.
  bool canFoldIntoFollowingInstruction(HInstruction instruction) {
    assert(instruction.usedBy.isEmpty);
    assert(instruction.canThrow(_abstractValueDomain));

    if (!instruction.onlyThrowsNSM()) return false;

    final receiver = instruction.getDartReceiver(closedWorld);
    HInstruction? current = instruction.next;
    do {
      if ((current!.getDartReceiver(closedWorld) == receiver) &&
          current.canThrow(_abstractValueDomain)) {
        return true;
      }
      if (current is HForeignCode && current.isNullGuardFor(receiver)) {
        return true;
      }
      if (current.canThrow(_abstractValueDomain) ||
          current.sideEffects.hasSideEffects()) {
        return false;
      }

      HInstruction? next = current.next;
      if (next == null) {
        // We do not merge blocks in our SSA graph, so if this block just jumps
        // to a single successor, visit the successor, avoiding back-edges.
        HBasicBlock? successor;
        if (current is HGoto) {
          successor = current.block!.successors.single;
        } else if (current is HIf) {
          // We also leave HIf nodes in place when one branch is dead.
          HInstruction condition = current.inputs.first;
          if (condition is HConstant) {
            successor = condition.constant is TrueConstantValue
                ? current.thenBlock
                : current.elseBlock;
            assert(successor.isLive);
          }
        }
        if (successor != null && successor.id > current.block!.id) {
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

    return instruction.isAllocation(_abstractValueDomain) &&
        instruction.isPure(_abstractValueDomain) &&
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
    if (instruction.canThrow(_abstractValueDomain)) {
      if (canFoldIntoFollowingInstruction(instruction)) {
        // TODO(35996): If we remove [instruction], the source location of the
        // 'equivalent' instruction should be updated.
        return true;
      }
      return false;
    }
    if (instruction is HParameterValue) return false;
    if (instruction is HLocalSet) return false;
    return true;
  }

  @override
  void visitGraph(HGraph graph) {
    _graph = graph;
    _computeLiveness();
    visitPostDominatorTree(graph);
  }

  void _computeLiveness() {
    var analyzer = SsaLiveBlockAnalyzer(_graph, closedWorld, optimizer);
    analyzer.analyze();
    for (HBasicBlock block in _graph.blocks) {
      block.isLive = analyzer.isLiveBlock(block);
    }
  }

  @override
  bool validPostcondition(HGraph graph) {
    return NoUnusedPhiValidator.containsNoUnusedPhis(graph);
  }

  @override
  void visitBasicBlock(HBasicBlock block) {
    simplifyControlFlow(block);
    // Start from the last non-control flow instruction in the block.
    HInstruction? instruction = block.last!.previous;
    while (instruction != null) {
      var previous = instruction.previous;
      if (!block.isLive) {
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
    // Remove an unused HPhi so that the inputs can become potentially dead.
    if (!phi.block!.isLive) {
      removeUsers(phi);
    }

    if (phi.usedBy.isEmpty) {
      phi.block!.removePhi(phi);
      return;
    }

    // Run through the phis of the block and replace them with their input that
    // comes from the only live predecessor if that dominates the phi.
    //
    // TODO(sra): If the input is directly in the only live predecessor, it
    // might be possible to move it into [block] (e.g. all its inputs are
    // dominating.)
    // Find the index of the single live predecessor if it exists.
    List<HBasicBlock> predecessors = phi.block!.predecessors;
    int indexOfLive = -1;
    for (int i = 0; i < predecessors.length; i++) {
      if (predecessors[i].isLive) {
        if (indexOfLive >= 0) {
          indexOfLive = -1;
          break;
        }
        indexOfLive = i;
      }
    }

    if (indexOfLive >= 0) {
      HInstruction replacement = phi.inputs[indexOfLive];
      if (replacement.dominates(phi)) {
        final phiBlock = phi.block!;
        phiBlock.rewrite(phi, replacement);
        phiBlock.removePhi(phi);
        if (replacement.sourceElement == null &&
            phi.sourceElement != null &&
            replacement is! HThis) {
          replacement.sourceElement = phi.sourceElement;
        }
        return;
      }
    }

    // If the phi is of the form `phi(x, HTypeKnown(x))`, it does not strengthen
    // `x`.  We can replace the phi with `x` to potentially make the HTypeKnown
    // refinement node dead and potentially make a HIf control no HPhis.

    // TODO(sra): Implement version of this test that works for a subgraph of
    // HPhi nodes.
    HInstruction? base;
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
      final block = phi.block!;
      block.rewrite(phi, base!);
      block.removePhi(phi);
    }
  }

  void simplifyControlFlow(HBasicBlock block) {
    HInstruction? instruction = block.last;
    if (instruction is HIf) {
      HInstruction condition = instruction.condition;
      if (condition is HConstant) return;

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

      final thenSize = measureEmptyInterval(instruction.thenBlock, join);
      if (thenSize == null) return;
      final elseSize = measureEmptyInterval(instruction.elseBlock, join);
      if (elseSize == null) return;

      // Pick the 'live' branch to be the smallest subgraph.
      bool value = thenSize <= elseSize;
      HInstruction newCondition = _graph.addConstantBool(value, closedWorld);
      instruction.replaceInput(0, newCondition);
    }
  }

  /// Returns the number of blocks from [start] up to but not including [end].
  /// Returns `null` if any of the blocks is non-empty (other than control
  /// flow).  Returns `null` if there is an exit from the region other than
  /// [end] or via control flow other than HGoto and HIf.
  int? measureEmptyInterval(HBasicBlock start, HBasicBlock end) {
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
    HInstruction? branch = block.last;
    if (branch is HIf) {
      if (branch.thenBlock.isLive == branch.elseBlock.isLive) return;
      assert(branch.condition is HConstant);
      HBasicBlock liveSuccessor =
          branch.thenBlock.isLive ? branch.thenBlock : branch.elseBlock;
      HInstruction instruction = liveSuccessor.first!;
      // Move instructions up until the final control flow instruction or pinned
      // HTypeKnown.
      while (instruction.next != null) {
        if (instruction is HTypeKnown && instruction.isPinned) break;
        HInstruction next = instruction.next!;
        // It might be worth re-running GVN optimizations if we hoisted a
        // GVN-able instructions from [target] into [block].
        newGvnCandidates = newGvnCandidates || instruction.useGvn();
        instruction.block!.detach(instruction);
        block.moveAtExit(instruction);
        instruction = next;
      }
    }
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

class SsaLiveBlockAnalyzer extends HBaseVisitor<void> {
  final HGraph graph;
  final Set<HBasicBlock> live = {};
  final List<HBasicBlock> worklist = [];
  final SsaOptimizerTask optimizer;
  final JClosedWorld closedWorld;

  SsaLiveBlockAnalyzer(this.graph, this.closedWorld, this.optimizer);

  AbstractValueDomain get _abstractValueDomain =>
      closedWorld.abstractValueDomain;

  Map<HInstruction, Range> get ranges => optimizer.ranges;

  bool isLiveBlock(HBasicBlock block) => live.contains(block);

  void analyze() {
    markBlockLive(graph.entry);
    while (!worklist.isEmpty) {
      HBasicBlock live = worklist.removeLast();
      live.last!.accept(this);
    }
  }

  void markBlockLive(HBasicBlock block) {
    if (!live.contains(block)) {
      worklist.add(block);
      live.add(block);
    }
  }

  @override
  void visitControlFlow(HControlFlow instruction) {
    instruction.block!.successors.forEach(markBlockLive);
  }

  @override
  void visitIf(HIf instruction) {
    HInstruction condition = instruction.condition;
    if (condition is HConstant) {
      if (condition.isConstantTrue()) {
        markBlockLive(instruction.thenBlock);
      } else {
        markBlockLive(instruction.elseBlock);
      }
    } else {
      visitControlFlow(instruction);
    }
  }

  @override
  void visitSwitch(HSwitch node) {
    if (node.expression.isInteger(_abstractValueDomain).isDefinitelyTrue) {
      final switchRange = ranges[node.expression];
      if (switchRange != null) {
        final lowerValue = switchRange.lower;
        final upperValue = switchRange.upper;
        if (lowerValue is IntValue && upperValue is IntValue) {
          BigInt lower = lowerValue.value;
          BigInt upper = upperValue.value;
          Set<BigInt> liveLabels = {};
          for (int pos = 1; pos < node.inputs.length; pos++) {
            HConstant input = node.inputs[pos] as HConstant;
            final constant = input.constant;
            if (constant is! IntConstantValue) {
              // The switch expression is an integer but the constant is not, so
              // the target block is unreachable.
              continue;
            }
            BigInt label = constant.intValue;
            if (!liveLabels.contains(label) &&
                label <= upper &&
                label >= lower) {
              markBlockLive(node.block!.successors[pos - 1]);
              liveLabels.add(label);
            }
          }
          if (BigInt.from(liveLabels.length) != upper - lower + BigInt.one) {
            markBlockLive(node.defaultTarget);
          }
          return;
        }
      }
    }
    visitControlFlow(node);
  }
}

class SsaDeadPhiEliminator implements OptimizationPhase {
  @override
  final String name = "SsaDeadPhiEliminator";

  @override
  void visitGraph(HGraph graph) {
    final List<HPhi> worklist = [];
    // A set to keep track of the live phis that we found.
    final Set<HPhi> livePhis = {};

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

    // Collect dead phis.
    List<HPhi> deadPhis = [];
    for (final block in graph.blocks) {
      block.forEachPhi((phi) {
        if (!livePhis.contains(phi)) deadPhis.add(phi);
      });
    }

    // Two-phase removal, phase 1: unlink all the input nodes.
    for (final phi in deadPhis) {
      for (final input in phi.inputs) {
        input.removeUser(phi);
      }
      phi.inputs.clear();
    }

    // Two-phase removal, phase 2: remove the now-disconnected phis.
    for (final phi in deadPhis) {
      assert(phi.inputs.isEmpty);
      assert(phi.usedBy.isEmpty);
      phi.block!.removePhi(phi);
    }
  }

  @override
  bool validPostcondition(HGraph graph) {
    return NoUnusedPhiValidator.containsNoUnusedPhis(graph);
  }
}

class SsaRedundantPhiEliminator implements OptimizationPhase {
  @override
  final String name = "SsaRedundantPhiEliminator";

  @override
  void visitGraph(HGraph graph) {
    final List<HPhi> worklist = [];

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
      HInstruction? candidate = phi.inputs[0];
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
      final phiBlock = phi.block!;
      phiBlock.rewrite(phi, candidate);
      phiBlock.removePhi(phi);
      if (candidate.sourceElement == null &&
          phi.sourceElement != null &&
          candidate is! HThis) {
        candidate.sourceElement = phi.sourceElement;
      }
    }
  }

  @override
  bool validPostcondition(HGraph graph) => true;
}

class GvnWorkItem {
  final HBasicBlock block;
  final ValueSet valueSet;
  GvnWorkItem(this.block, this.valueSet);
}

class SsaGlobalValueNumberer implements OptimizationPhase {
  final AbstractValueDomain _abstractValueDomain;
  @override
  final String name = "SsaGlobalValueNumberer";
  final Set<int> visited = {};

  late final List<int> blockChangesFlags;
  late final List<int> loopChangesFlags;

  SsaGlobalValueNumberer(this._abstractValueDomain);

  @override
  void visitGraph(HGraph graph) {
    computeChangesFlags(graph);
    moveLoopInvariantCode(graph);
    List<GvnWorkItem> workQueue = [GvnWorkItem(graph.entry, ValueSet())];
    do {
      GvnWorkItem item = workQueue.removeLast();
      visitBasicBlock(item.block, item.valueSet, workQueue);
    } while (!workQueue.isEmpty);
  }

  @override
  bool validPostcondition(HGraph graph) => true;

  void moveLoopInvariantCode(HGraph graph) {
    for (int i = graph.blocks.length - 1; i >= 0; i--) {
      HBasicBlock block = graph.blocks[i];
      if (block.isLoopHeader()) {
        int changesFlags = loopChangesFlags[block.id];
        final info = block.loopInformation!;
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
    HInstruction? instruction = block.first;
    bool isLoopAlwaysTaken() {
      final instruction = loopHeader.last!;
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
      final next = instruction.next;
      if (instruction.useGvn() &&
          instruction.isMovable &&
          (!instruction.canThrow(_abstractValueDomain) ||
              firstInstructionInLoop) &&
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
    return input.block!.id > dominator.id;
  }

  void visitBasicBlock(
      HBasicBlock block, ValueSet values, List<GvnWorkItem> workQueue) {
    HInstruction? instruction = block.first;
    if (block.isLoopHeader()) {
      int flags = loopChangesFlags[block.id];
      values.kill(flags);
    }
    while (instruction != null) {
      final next = instruction.next;
      int flags = instruction.sideEffects.getChangesFlags();
      assert(flags == 0 || !instruction.useGvn());
      // TODO(sra): Is the above assertion too strong? We should be able to
      // reuse the values generated by idempotent operations that have
      // effects. Would it be correct to make the kill below be conditional on
      // not replacing the instruction?
      values.kill(flags);
      if (instruction.useGvn()) {
        final other = values.lookup(instruction);
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
      workQueue.add(GvnWorkItem(dominated, successorValues));
    }
  }

  void computeChangesFlags(HGraph graph) {
    // Create the changes flags lists. Make sure to initialize the
    // loop changes flags list to zero so we can use bitwise-or when
    // propagating loop changes upwards.
    final int length = graph.blocks.length;
    blockChangesFlags = List<int>.filled(length, -1);
    loopChangesFlags = List<int>.filled(length, 0);

    // Run through all the basic blocks in the graph and fill in the
    // changes flags lists.
    for (int i = length - 1; i >= 0; i--) {
      final HBasicBlock block = graph.blocks[i];
      final int id = block.id;

      // Compute block changes flags for the block.
      int changesFlags = 0;
      HInstruction? instruction = block.first;
      while (instruction != null) {
        changesFlags |= instruction.sideEffects.getChangesFlags();
        instruction = instruction.next;
      }
      assert(blockChangesFlags[id] == -1);
      blockChangesFlags[id] = changesFlags;

      // Loop headers are part of their loop, so update the loop
      // changes flags accordingly.
      if (block.isLoopHeader()) {
        loopChangesFlags[id] |= changesFlags;
      }

      // Propagate loop changes flags upwards.
      final parentLoopHeader = block.parentLoopHeader;
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
// A basic block looks at its successors and finds the intersection of
// these computed ValueSet. It moves all instructions of the
// intersection into its own list of instructions.
class SsaCodeMotion extends HBaseVisitor<void> implements OptimizationPhase {
  final AbstractValueDomain _abstractValueDomain;

  @override
  final String name = "SsaCodeMotion";

  bool movedCode = false;
  late final List<ValueSet> values;

  SsaCodeMotion(this._abstractValueDomain);

  @override
  void visitGraph(HGraph graph) {
    values = List.generate(graph.blocks.length, (_) => ValueSet());
    visitPostDominatorTree(graph);
  }

  @override
  bool validPostcondition(HGraph graph) => true;

  @override
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
        // Sort by instruction 'id' for more stable ordering under changes to
        // unrelated source code. 'id' is a function of the operations of
        // compiling the current method, whereas the ValueSet order is dependent
        // hashCodes that are a function of the whole program.
        list.sort((insn1, insn2) => insn1.id.compareTo(insn2.id));
        for (HInstruction instruction in list) {
          // Move the instruction to the current block.
          instruction.block!.detach(instruction);
          block.moveAtExit(instruction);
          // Go through all successors and rewrite their instruction
          // to the shared one.
          for (final successor in successors) {
            final toRewrite = values[successor.id].lookup(instruction);
            if (toRewrite != instruction) {
              successor.rewriteWithBetterUser(toRewrite, instruction);
              successor.remove(toRewrite!);
              movedCode = true;
            }
          }
        }
      }
      // TODO(sra): There are some non-gvn-able instructions that we could move,
      // e.g. allocations. We should probably not move instructions that can
      // directly or indirectly throw since the reported location might be in
      // the 'wrong' branch.
    }

    // Don't try to merge instructions to a dominator if we have
    // multiple predecessors.
    if (block.predecessors.length != 1) return;

    // Phase 2: Go through all instructions of this block and find
    // which instructions can be moved to a dominator block.
    ValueSet set_ = values[block.id];
    HInstruction? instruction = block.first;
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
      if (current.canThrow(_abstractValueDomain)) continue;
      if (current.sideEffects.dependsOn(dependsFlags)) continue;

      bool canBeMoved = true;
      for (final HInstruction input in current.inputs) {
        if (input.block == block) {
          canBeMoved = false;
          break;
          // TODO(sra): We could move trees of instructions provided we move the
          // roots before the leaves.
        }
      }
      if (!canBeMoved) continue;

      final existing = set_.lookup(current);
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

class SsaTypeConversionInserter extends HBaseVisitor<void>
    implements OptimizationPhase {
  @override
  final String name = "SsaTypeconversionInserter";
  final JClosedWorld closedWorld;

  SsaTypeConversionInserter(this.closedWorld);

  AbstractValueDomain get _abstractValueDomain =>
      closedWorld.abstractValueDomain;

  @override
  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  @override
  bool validPostcondition(HGraph graph) => true;

  // Update users of [input] that are dominated by [:dominator.first:]
  // to use [TypeKnown] of [input] instead. As the type information depends
  // on the control flow, we mark the inserted [HTypeKnown] nodes as
  // non-movable.
  void insertTypePropagationForDominatedUsers(
      HBasicBlock dominator, HInstruction input, AbstractValue convertedType) {
    DominatedUses dominatedUses = DominatedUses.of(input, dominator.first!);
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

    HTypeKnown newInput = HTypeKnown.pinned(convertedType, input);
    dominator.addBefore(dominator.first, newInput);
    dominatedUses.replaceWith(newInput);
  }

  @override
  void visitIsTest(HIsTest instruction) {
    List<HBasicBlock> trueTargets = [];
    List<HBasicBlock> falseTargets = [];

    collectTargets(instruction, trueTargets, falseTargets);

    if (trueTargets.isEmpty && falseTargets.isEmpty) return;

    AbstractValue convertedType =
        instruction.checkedAbstractValue.abstractValue;
    HInstruction input = instruction.checkedInput;

    for (HBasicBlock block in trueTargets) {
      insertTypePropagationForDominatedUsers(block, input, convertedType);
    }
    // TODO(sra): Also strengthen uses for when the condition is precise and
    // known false (e.g. int? x; ... if (x is! int) use(x)). Avoid strengthening
    // to `null`.
  }

  @override
  void visitIsTestSimple(HIsTestSimple instruction) {
    List<HBasicBlock> trueTargets = [];
    List<HBasicBlock> falseTargets = [];

    collectTargets(instruction, trueTargets, falseTargets);

    if (trueTargets.isEmpty && falseTargets.isEmpty) return;

    AbstractValue convertedType =
        instruction.checkedAbstractValue.abstractValue;
    HInstruction input = instruction.checkedInput;

    for (HBasicBlock block in trueTargets) {
      insertTypePropagationForDominatedUsers(block, input, convertedType);
    }
    // TODO(sra): Also strengthen uses for when the condition is precise and
    // known false (e.g. int? x; ... if (x is! int) use(x)). Avoid strengthening
    // to `null`.
  }

  @override
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

    if (_abstractValueDomain.isNull(input.instructionType).isDefinitelyFalse) {
      return;
    }

    List<HBasicBlock> trueTargets = [];
    List<HBasicBlock> falseTargets = [];

    collectTargets(instruction, trueTargets, falseTargets);

    if (trueTargets.isEmpty && falseTargets.isEmpty) return;

    AbstractValue nonNullType =
        _abstractValueDomain.excludeNull(input.instructionType);

    for (HBasicBlock block in falseTargets) {
      insertTypePropagationForDominatedUsers(block, input, nonNullType);
    }
    // We don't strengthen the known-true references. It doesn't happen often
    // and we don't want "if (x==null) return x;" to convert between JavaScript
    // 'null' and 'undefined'.
  }

  collectTargets(HInstruction instruction, List<HBasicBlock>? trueTargets,
      List<HBasicBlock>? falseTargets) {
    for (HInstruction user in instruction.usedBy) {
      if (user is HIf) {
        trueTargets?.add(user.thenBlock);
        falseTargets?.add(user.elseBlock);
      } else if (user is HLoopBranch) {
        trueTargets?.add(user.block!.successors.first);
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
      }
    }
  }
}

/// Optimization phase that tries to eliminate memory loads (for example
/// [HFieldGet]), when it knows the value stored in that memory location, and
/// stores that overwrite with the same value.
class SsaLoadElimination extends HBaseVisitor<void>
    implements OptimizationPhase {
  final JClosedWorld _closedWorld;
  final JFieldAnalysis _fieldAnalysis;
  @override
  final String name = "SsaLoadElimination";
  late MemorySet memorySet;
  late final List<MemorySet?> memories;
  bool newGvnCandidates = false;
  late final HGraph _graph;

  // Blocks that can be reached via control flow not expressed by the basic
  // block CFG. These are catch and finally blocks that are reached from some
  // mid-block instruction that throws in the CFG region corresponding to the
  // Dart language try-block. The value stored in the map is the HTry that owns
  // the catch or finally block. This map is filled in on-the-fly since the HTry
  // dominates the catch and finally so is visited first.
  Map<HBasicBlock, HTry>? _blocksWithImprecisePredecessors;

  SsaLoadElimination(this._closedWorld)
      : _fieldAnalysis = _closedWorld.fieldAnalysis;

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

  @override
  void visitGraph(HGraph graph) {
    _graph = graph;
    memories = List<MemorySet?>.filled(graph.blocks.length, null);
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

  @override
  bool validPostcondition(HGraph graph) => true;

  @override
  void visitBasicBlock(HBasicBlock block) {
    final predecessors = block.predecessors;
    final indegree = predecessors.length;
    if (indegree == 0) {
      // Entry block.
      memorySet = MemorySet(_closedWorld);
    } else if (indegree == 1 && predecessors[0].successors.length == 1) {
      // No need to clone, there is no other successor for
      // `block.predecessors[0]`, and this block has only one predecessor. Since
      // we are not going to visit `block.predecessors[0]` again, we can just
      // re-use its [memorySet].
      memorySet = memories[predecessors[0].id]!;
    } else if (indegree == 1) {
      // Clone the memorySet of the predecessor, because it is also used by
      // other successors of it.
      memorySet = memories[predecessors[0].id]!.clone();
    } else {
      // Compute the intersection of all predecessors.
      //
      // If a predecessor does not have a reachable exit, the kills on that path
      // can be ignored. Since the usual case is conditional diamond flow with
      // two predecessors, this is done by detecting a single non-dead
      // predecessor and cloning the memory-set, but removing expressions that
      // are not valid in the current block (invalid instructions would be in
      // one arm of the diamond).

      int firstLiveIndex = -1;
      int otherLiveIndex = -1;
      int firstDeadIndex = -1;
      bool pendingBackEdge = false;

      List<MemorySet?> inputs = List.filled(indegree, null);

      for (int i = 0; i < indegree; i++) {
        final predecessor = predecessors[i];
        final input = inputs[i] = memories[predecessor.id];
        if (input == null) pendingBackEdge = true;
        if (hasUnreachableExit(predecessor)) {
          if (firstDeadIndex == -1) firstDeadIndex = i;
        } else {
          if (firstLiveIndex == -1) {
            firstLiveIndex = i;
          } else if (otherLiveIndex == -1) {
            otherLiveIndex = i;
          }
        }
      }

      if (firstLiveIndex != -1 &&
          otherLiveIndex == -1 &&
          firstDeadIndex != -1 &&
          !pendingBackEdge) {
        // Single live input intersection.
        memorySet = memories[predecessors[firstLiveIndex].id]!
            .cloneIfDominatesBlock(block);
      } else {
        // Standard intersection over all predecessors.
        memorySet = inputs[0]!;
        for (int i = 1; i < inputs.length; i++) {
          memorySet = memorySet.intersectionFor(inputs[i], block, i);
        }
      }
    }

    // If the current block is a catch or finally block, it is reachable from
    // any instruction in the try region that can generate an exception.
    if (_blocksWithImprecisePredecessors != null) {
      final tryInstruction = _blocksWithImprecisePredecessors![block];
      if (tryInstruction != null) {
        memorySet.killLocationsForExceptionEdge();
      }
    }

    memories[block.id] = memorySet;
    HInstruction? instruction = block.first;
    while (instruction != null) {
      final next = instruction.next;
      instruction.accept(this);
      instruction = next;
    }
  }

  @override
  visitTry(HTry instruction) {
    final impreciseBlocks = _blocksWithImprecisePredecessors ??= {};
    if (instruction.catchBlock != null) {
      impreciseBlocks[instruction.catchBlock!] = instruction;
    }
    if (instruction.finallyBlock != null) {
      impreciseBlocks[instruction.finallyBlock!] = instruction;
    }
  }

  void checkNewGvnCandidates(HInstruction instruction, HInstruction existing) {
    if (newGvnCandidates) return;
    bool hasUseGvn(HInstruction insn) => insn.nonCheck().useGvn();
    if (instruction.usedBy.any(hasUseGvn) && existing.usedBy.any(hasUseGvn)) {
      newGvnCandidates = true;
    }
  }

  @override
  void visitFieldGet(HFieldGet instruction) {
    FieldEntity element = instruction.element;
    HInstruction receiver =
        instruction.getDartReceiver(_closedWorld).nonCheck();
    _visitFieldGet(element, receiver, instruction);
  }

  @override
  void visitGetLength(HGetLength instruction) {
    HInstruction receiver = instruction.receiver.nonCheck();
    final existing = memorySet.lookupFieldValue(MemoryFeature.length, receiver);
    if (existing != null) {
      checkNewGvnCandidates(instruction, existing);
      final block = instruction.block!;
      block.rewriteWithBetterUser(instruction, existing);
      block.remove(instruction);
    } else {
      memorySet.registerFieldValue(MemoryFeature.length, receiver, instruction);
    }
  }

  void _visitFieldGet(
      FieldEntity element, HInstruction receiver, HInstruction instruction) {
    final existing = memorySet.lookupFieldValue(element, receiver);
    if (existing != null) {
      checkNewGvnCandidates(instruction, existing);
      final block = instruction.block!;
      block.rewriteWithBetterUser(instruction, existing);
      block.remove(instruction);
    } else {
      memorySet.registerFieldValue(element, receiver, instruction);
    }
  }

  @override
  void visitFieldSet(HFieldSet instruction) {
    FieldEntity element = instruction.element;
    HInstruction receiver =
        instruction.getDartReceiver(_closedWorld).nonCheck();
    if (memorySet.registerFieldValueUpdate(
        element, receiver, instruction.value)) {
      instruction.block!.remove(instruction);
    }
  }

  @override
  void visitCreate(HCreate instruction) {
    memorySet.registerAllocation(instruction);
    if (shouldTrackInitialValues(instruction)) {
      int argumentIndex = 0;
      _closedWorld.elementEnvironment.forEachInstanceField(instruction.element,
          (_, FieldEntity member) {
        FieldAnalysisData fieldData = _fieldAnalysis.getFieldData(member);
        if (fieldData.isElided) return;
        if (fieldData.isInitializedInAllocator) {
          // TODO(sra): Can we avoid calling HGraph.addConstant?
          final value = fieldData.initialValue!;
          HConstant constant = _graph.addConstant(value, _closedWorld);
          memorySet.registerFieldValue(member, instruction, constant);
        } else {
          memorySet.registerFieldValue(
              member, instruction, instruction.inputs[argumentIndex++]);
        }
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
        // leak the inputs. For example `setArrayType` is used to mark
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

  @override
  void visitInstruction(HInstruction instruction) {
    if (instruction.isAllocation(_abstractValueDomain)) {
      memorySet.registerAllocation(instruction);
    }
    memorySet.killAffectedBy(instruction);
  }

  @override
  void visitLazyStatic(HLazyStatic instruction) {
    FieldEntity field = instruction.element;
    handleStaticLoad(field, instruction);
  }

  void handleStaticLoad(MemberEntity element, HInstruction instruction) {
    final existing = memorySet.lookupFieldValue(element, null);
    if (existing != null) {
      checkNewGvnCandidates(instruction, existing);
      final block = instruction.block!;
      block.rewriteWithBetterUser(instruction, existing);
      block.remove(instruction);
    } else {
      memorySet.registerFieldValue(element, null, instruction);
    }
  }

  @override
  void visitStatic(HStatic instruction) {
    handleStaticLoad(instruction.element, instruction);
  }

  @override
  void visitStaticStore(HStaticStore instruction) {
    if (memorySet.registerFieldValueUpdate(
        instruction.element, null, instruction.inputs.last)) {
      instruction.block!.remove(instruction);
    }
  }

  @override
  void visitLiteralList(HLiteralList instruction) {
    memorySet.registerAllocation(instruction);
    memorySet.killAffectedBy(instruction);
    // TODO(sra): Set initial keyed values.
    // TODO(sra): Set initial length.
  }

  @override
  void visitIndex(HIndex instruction) {
    HInstruction receiver = instruction.receiver.nonCheck();
    HInstruction index = instruction.index.nonCheck();
    final existing = memorySet.lookupKeyedValue(receiver, index);
    if (existing != null) {
      checkNewGvnCandidates(instruction, existing);
      final block = instruction.block!;
      block.rewriteWithBetterUser(instruction, existing);
      block.remove(instruction);
    } else {
      memorySet.registerKeyedValue(receiver, index, instruction);
    }
  }

  @override
  void visitIndexAssign(HIndexAssign instruction) {
    HInstruction receiver = instruction.receiver.nonCheck();
    memorySet.registerKeyedValueUpdate(
        receiver, instruction.index.nonCheck(), instruction.value);
  }

  // Pure operations that do not escape their inputs.
  @override
  void visitBinaryArithmetic(HBinaryArithmetic instruction) {}
  @override
  void visitBoundsCheck(HBoundsCheck instruction) {}
  @override
  void visitConstant(HConstant instruction) {}
  @override
  void visitIf(HIf instruction) {}
  @override
  void visitInterceptor(HInterceptor instruction) {}
  @override
  void visitNot(HNot instruction) {}
  @override
  void visitNullCheck(HNullCheck instruction) {}
  @override
  void visitLateReadCheck(HLateReadCheck instruction) {}
  @override
  void visitParameterValue(HParameterValue instruction) {}
  @override
  void visitRelational(HRelational instruction) {}
  @override
  void visitStringConcat(HStringConcat instruction) {}
  @override
  void visitTypeKnown(HTypeKnown instruction) {}
}

/// A non-field based feature of an object.
enum MemoryFeature {
  // Access to the `length` property of a `JSIndexable`.
  length,
}

/// Holds values of memory places.
///
/// Generally, values that name a place (a receiver) have type refinements and
/// other checks removed to ensure that checks and type refinements do not
/// confuse aliasing.  Values stored into a memory place keep the type
/// refinements to help further optimizations.
class MemorySet {
  final JClosedWorld closedWorld;

  /// Maps a field to a map of receivers to their current field values.
  ///
  /// The field is either a [FieldEntity], a [FunctionEntity] in case of
  /// instance methods, or a [MemoryFeature] for `length` access on
  /// `JSIndexable`.
  ///
  /// The receiver is `null` for static and top-level fields.
  ///
  /// Sometimes `null` is stored in the map instead of deleting an entry to
  /// avoid ConcurrentModificationError.
  // TODO(25544): Split length effects from other effects and model lengths
  // separately.
  final Map<Object /*MemberEntity|MemoryFeature*/,
      Map<HInstruction?, HInstruction?>> fieldValues = {};

  /// Maps a receiver to a map of keys to value.
  final Map<HInstruction, Map<HInstruction, HInstruction?>> keyedValues = {};

  /// Set of objects that we know don't escape (or have not yet escaped) the
  /// current function.
  final Setlet<HInstruction> nonEscapingReceivers = Setlet();

  MemorySet(this.closedWorld);

  AbstractValueDomain get _abstractValueDomain =>
      closedWorld.abstractValueDomain;

  /// Returns whether [first] and [second] always alias to the same object.
  bool mustAlias(HInstruction? first, HInstruction? second) {
    return first == second;
  }

  /// Returns whether [first] and [second] may alias to the same object.
  bool mayAlias(HInstruction? first, HInstruction? second) {
    if (mustAlias(first, second)) return true;
    if (isConcrete(first) && isConcrete(second)) return false;
    if (nonEscapingReceivers.contains(first)) return false;
    if (nonEscapingReceivers.contains(second)) return false;
    // Typed arrays of different types might have a shared buffer.
    if (couldBeTypedArray(first!) && couldBeTypedArray(second!)) return true;
    return _abstractValueDomain
        .areDisjoint(first.instructionType, second!.instructionType)
        .isPotentiallyFalse;
  }

  bool isFinal(Object element) {
    return element is MemberEntity && closedWorld.fieldNeverChanges(element);
  }

  bool isConcrete(HInstruction? instruction) {
    return instruction is HCreate ||
        instruction is HConstant ||
        instruction is HLiteralList;
  }

  bool couldBeTypedArray(HInstruction receiver) {
    return closedWorld.abstractValueDomain
        .couldBeTypedArray(receiver.instructionType)
        .isPotentiallyTrue;
  }

  /// Returns whether [receiver] escapes the current function.
  bool escapes(HInstruction? receiver) {
    assert(receiver == null || receiver == receiver.nonCheck());
    return !nonEscapingReceivers.contains(receiver);
  }

  /// Kills locations that are imprecise due to many possible edges from
  /// instructions in the try region that can throw.
  void killLocationsForExceptionEdge() {
    // Ideally we would treat each strong (must) update in the try region as a
    // weak (may) update at the catch block, but we don't track this. The
    // conservative approximation is to kill everything.
    //
    // Aliases can be retained because they are not updated - they are generated
    // by an allocation and are killed by escaping. There is an edge from any
    // exit from the try region to the catch block which accounts for the kills
    // via escapes. Similarly, array lengths don't have updates (set:length is
    // modeled as an escape which kills the length on some path), so lengths
    // don't need to be killed here.
    //
    // TODO(sra): A more precise accounting of the effects in the try region
    // might improve precision.
    fieldValues.forEach((key, map) {
      if (key != MemoryFeature.length) {
        map.clear();
      }
    });
    keyedValues.clear();
  }

  void registerAllocation(HInstruction instruction) {
    assert(instruction == instruction.nonCheck());
    nonEscapingReceivers.add(instruction);
  }

  /// Sets the [field] on [receiver] to contain [value]. Kills all potential
  /// places that may be affected by this update. Returns `true` if the update
  /// is redundant.
  bool registerFieldValueUpdate(
      Object field, HInstruction? receiver, HInstruction value) {
    assert(field is MemberEntity || field is MemoryFeature,
        "Unexpected member/feature: $field");
    assert(receiver == null || receiver == receiver.nonCheck());
    if (field is MemberEntity && closedWorld.nativeData.isNativeMember(field)) {
      return false; // TODO(14955): Remove this restriction?
    }
    // [value] is being set in some place in memory, we remove it from the
    // non-escaping set.
    nonEscapingReceivers.remove(value.nonCheck());
    final map = fieldValues.putIfAbsent(field, () => {});
    bool isRedundant = map[receiver] == value;
    map.forEach((key, value) {
      if (mayAlias(receiver, key)) map[key] = null;
    });
    map[receiver] = value;
    return isRedundant;
  }

  /// Registers that the [field] on [receiver] is now [value].
  void registerFieldValue(
      Object field, HInstruction? receiver, HInstruction value) {
    assert(field is MemberEntity || field is MemoryFeature,
        "Unexpected member/feature: $field");
    assert(receiver == null || receiver == receiver.nonCheck());
    if (field is MemberEntity && closedWorld.nativeData.isNativeMember(field)) {
      return; // TODO(14955): Remove this restriction?
    }
    final map = fieldValues.putIfAbsent(field, () => {});
    map[receiver] = value;
  }

  /// Returns the value stored for [field] on [receiver]. Returns `null` if we
  /// don't know.
  HInstruction? lookupFieldValue(Object field, HInstruction? receiver) {
    assert(field is MemberEntity || field is MemoryFeature,
        "Unexpected member/feature: $field");
    assert(receiver == null || receiver == receiver.nonCheck());
    final map = fieldValues[field];
    return (map == null) ? null : map[receiver];
  }

  /// Kill all places that may be affected by this [instruction]. Also update
  /// the set of non-escaping objects in case [instruction] has non-escaping
  /// objects in its inputs.
  void killAffectedBy(HInstruction instruction) {
    // Even if [instruction] does not have side effects, it may use non-escaping
    // objects and store them in a new object, which make these objects
    // escaping.
    instruction.inputs.forEach((input) {
      nonEscapingReceivers.remove(input.nonCheck());
    });

    if (instruction.sideEffects.changesInstanceProperty() ||
        instruction.sideEffects.changesStaticProperty()) {
      // TODO(sra): Be more precise about removing only instance or static
      // properties.
      List<HInstruction?> receiversToRemove = [];

      List<Object>? fieldsToRemove;
      fieldValues.forEach((Object element, map) {
        if (isFinal(element)) return;
        map.forEach((receiver, value) {
          if (escapes(receiver)) {
            receiversToRemove.add(receiver);
          }
        });
        if (receiversToRemove.length == map.length) {
          // Remove them all by removing the entire map.
          (fieldsToRemove ??= []).add(element);
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

  /// Returns the value stored in `receiver[index]`. Returns null if we don't
  /// know.
  HInstruction? lookupKeyedValue(HInstruction receiver, HInstruction index) {
    final map = keyedValues[receiver];
    return (map == null) ? null : map[index];
  }

  /// Registers that `receiver[index]` is now [value].
  void registerKeyedValue(
      HInstruction receiver, HInstruction index, HInstruction value) {
    final map = keyedValues.putIfAbsent(receiver, () => {});
    map[index] = value;
  }

  /// Sets `receiver[index]` to contain [value]. Kills all potential places that
  /// may be affected by this update.
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

    final map = keyedValues.putIfAbsent(receiver, () => {});
    map[index] = value;
  }

  /// Returns a common instruction for [first] and [second].
  ///
  /// Returns `null` if either [first] or [second] is null. Returns [first] if
  /// [first] and [second] are equal. Otherwise creates or re-uses a phi in
  /// [block] that holds [first] and [second].
  HInstruction? findCommonInstruction(HInstruction? first, HInstruction? second,
      HBasicBlock block, int predecessorIndex) {
    if (first == null || second == null) return null;
    if (first == second) return first;
    if (second is HGetLength) {
      // Don't always create phis for HGetLength. The phi confuses array bounds
      // check elimination and the resulting variable-heavy code probably is
      // confusing for JavaScript VMs. In practice, this mostly affects the
      // expansion of for-in loops on Arrays, so we match the expression
      //
      //     checkConcurrentModificationError(array.length == _end, array)
      //
      // starting with the HGetLength of the `array.length`, in the case where
      // `array.length` is not used elsewhere (i.e. not already optimized to use
      // a previous use, in the loop condition).
      //
      // TODO(sra): Figure out a better way ensure 'nice' loop code.
      // TODO(22407): The phi would not be so bad if it did not confuse bounds
      // check elimination.
      // TODO(25437): We could add a phi if we undid the harmful cases.
      if (second.usedBy.length == 1) {
        var user = second.usedBy.single;
        if (user is HIdentity && user.usedBy.length == 1) {
          HInstruction user2 = user.usedBy.single;
          if (user2 is HInvokeStatic &&
              closedWorld.commonElements
                  .isCheckConcurrentModificationError(user2.element)) {
            return null;
          }
        }
      }
    }
    AbstractValue phiType = _abstractValueDomain.union(
        second.instructionType, first.instructionType);
    if (first is HPhi && first.block == block) {
      HPhi phi = first;
      phi.addInput(second);
      phi.instructionType = phiType;
      return phi;
    } else {
      HPhi phi = HPhi.noInputs(null, phiType);
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

  /// Returns the intersection between [this] and the [other] memory set.
  MemorySet intersectionFor(
      MemorySet? other, HBasicBlock block, int predecessorIndex) {
    MemorySet result = MemorySet(closedWorld);
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
          if (use is HFieldSet) {
            return use.value.nonCheck() != instruction;
          }
          if (use is HGetLength) return true;
          if (use is HBoundsCheck) return true;
          if (use is HIndex) return true;
          if (use is HIndexAssign) {
            return use.value.nonCheck() != instruction;
          }
          if (use is HInterceptor) return true;
          if (use is HInvokeDynamicMethod) {
            final element = use.element;
            if (element != null) {
              if (element == closedWorld.commonElements.jsArrayAdd) {
                return use.inputs.last != instruction;
              }
            }
          }
          if (use is HInvokeStatic) {
            if (closedWorld.commonElements
                .isCheckConcurrentModificationError(use.element)) return true;
          }

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
        final instruction = findCommonInstruction(
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
        final instruction = findCommonInstruction(
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

  /// Returns a copy of [this] memory set.
  MemorySet clone() {
    MemorySet result = MemorySet(closedWorld);

    fieldValues.forEach((element, values) {
      result.fieldValues[element] = Map.of(values);
    });

    keyedValues.forEach((receiver, values) {
      result.keyedValues[receiver] = Map.of(values);
    });

    result.nonEscapingReceivers.addAll(nonEscapingReceivers);
    return result;
  }

  /// Returns a copy of [this] memory set, removing any expressions that are not
  /// valid in [block].
  MemorySet cloneIfDominatesBlock(HBasicBlock block) {
    bool instructionDominatesBlock(HInstruction? instruction) {
      return instruction != null && instruction.block!.dominates(block);
    }

    MemorySet result = MemorySet(closedWorld);

    fieldValues.forEach((element, values) {
      values.forEach((receiver, value) {
        if ((receiver == null || instructionDominatesBlock(receiver)) &&
            instructionDominatesBlock(value)) {
          result.registerFieldValue(element, receiver, value!);
        }
      });
    });

    keyedValues.forEach((receiver, values) {
      if (instructionDominatesBlock(receiver)) {
        values.forEach((index, value) {
          if (instructionDominatesBlock(index) &&
              instructionDominatesBlock(value)) {
            result.registerKeyedValue(receiver, index, value!);
          }
        });
      }
    });

    result.nonEscapingReceivers
        .addAll(nonEscapingReceivers.where(instructionDominatesBlock));
    return result;
  }
}
