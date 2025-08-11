// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/elements.dart' show CommonElements;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../js_model/js_world.dart' show JClosedWorld;
import '../universe/selector.dart' show Selector;
import 'logging.dart';
import 'nodes.dart';
import 'optimize.dart' show OptimizationPhase;

/// Type propagation and conditioning check insertion.
///
/// 1. Type propagation (dataflow) to determine the types of all nodes.
///
/// 2. HTypeKnown node insertion captures type strengthening.
///
/// 3. Conditioning check insertion inserts receiver and argument checks on
///    calls where that call is expected to be replaced with an instruction with
///    a narrower domain. For example `{Null,int} + {int}` would insert an
///    receiver check to strengthen the types to `{int} + {int}` to allow the
///    call of `operator+` to be replaced with a HAdd instruction.
///
/// Analysis and node insertion are done together, since insertion improves the
/// type propagation results.
// TODO(sra): The InvokeDynamicSpecializer should be consulted for better
// targeted conditioning checks.
class SsaTypePropagator extends HBaseVisitor<AbstractValue>
    implements OptimizationPhase {
  final Map<int, HInstruction> workmap = {};
  final List<int> worklist = [];
  final Map<HInstruction, void Function()> pendingOptimizations = {};

  final GlobalTypeInferenceResults results;
  final CommonElements commonElements;
  final JClosedWorld closedWorld;
  final OptimizationTestLog? _log;
  @override
  String get name => 'SsaTypePropagator';

  SsaTypePropagator(
    this.results,
    this.commonElements,
    this.closedWorld,
    this._log,
  );

  AbstractValueDomain get abstractValueDomain =>
      closedWorld.abstractValueDomain;

  AbstractValue computeType(HInstruction instruction) {
    return instruction.accept(this);
  }

  // Re-compute and update the type of the instruction. Returns
  // whether or not the type was changed.
  bool updateType(HInstruction instruction) {
    // Compute old and new types.
    AbstractValue oldType = instruction.instructionType;
    AbstractValue newType = computeType(instruction);
    // We unconditionally replace the propagated type with the new type. The
    // computeType must make sure that we eventually reach a stable state.
    instruction.instructionType = newType;
    return oldType != newType;
  }

  @override
  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
    processWorklist();
  }

  @override
  bool validPostcondition(HGraph graph) => true;

  @override
  void visitBasicBlock(HBasicBlock node) {
    if (node.isLoopHeader()) {
      node.forEachPhi((HPhi phi) {
        // Set the initial type for the phi. We're not using the type
        // the phi thinks it has because new optimizations may imply
        // changing it.
        // In theory we would need to mark
        // the type of all other incoming edges as "uninitialized" and take this
        // into account when doing the propagation inside the phis. Just
        // setting the propagated type is however easier.
        phi.instructionType = phi.inputs[0].instructionType;
        addToWorkList(phi);
      });
    } else {
      node.forEachPhi((HPhi phi) {
        if (updateType(phi)) {
          addDependentInstructionsToWorkList(phi);
        }
      });
    }

    HInstruction instruction = node.first!;
    while (instruction.next != null) {
      if (updateType(instruction)) {
        addDependentInstructionsToWorkList(instruction);
      }
      instruction = instruction.next!;
    }
    assert(instruction is HControlFlow);
  }

  void processWorklist() {
    do {
      while (worklist.isNotEmpty) {
        int id = worklist.removeLast();
        HInstruction instruction = workmap[id]!;
        workmap.remove(id);
        if (updateType(instruction)) {
          addDependentInstructionsToWorkList(instruction);
        }
      }
      // While processing the optimizable arithmetic instructions, we
      // may discover better type information for dominated users of
      // replaced operands, so we may need to take another stab at
      // emptying the worklist afterwards.
      processPendingOptimizations();
    } while (worklist.isNotEmpty);
  }

  void addToWorkList(HInstruction instruction) {
    if (instruction is HControlFlow) return;
    final int id = instruction.id;

    if (!workmap.containsKey(id)) {
      worklist.add(id);
      workmap[id] = instruction;
    }
  }

  @override
  AbstractValue visitBinaryArithmetic(HBinaryArithmetic node) {
    HInstruction left = node.left;
    HInstruction right = node.right;
    if (left.isInteger(abstractValueDomain).isDefinitelyTrue &&
        right.isInteger(abstractValueDomain).isDefinitelyTrue) {
      return abstractValueDomain.intType;
    }
    return abstractValueDomain.numType;
  }

  AbstractValue checkPositiveInteger(HBinaryArithmetic instruction) {
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    if (left.isPositiveInteger(abstractValueDomain).isDefinitelyTrue &&
        right.isPositiveInteger(abstractValueDomain).isDefinitelyTrue) {
      return abstractValueDomain.positiveIntType;
    }
    return visitBinaryArithmetic(instruction);
  }

  @override
  AbstractValue visitMultiply(HMultiply node) {
    return checkPositiveInteger(node);
  }

  @override
  AbstractValue visitAdd(HAdd node) {
    return checkPositiveInteger(node);
  }

  @override
  AbstractValue visitDivide(HDivide node) {
    // Always double, as initialized.
    return node.instructionType;
  }

  @override
  AbstractValue visitTruncatingDivide(HTruncatingDivide node) {
    // Always as initialized.
    return node.instructionType;
  }

  @override
  AbstractValue visitRemainder(HRemainder node) {
    // Always as initialized.
    return node.instructionType;
  }

  @override
  AbstractValue visitNegate(HNegate node) {
    HInstruction operand = node.operand;
    // We have integer subclasses that represent ranges, so widen any int
    // subclass to full integer.
    if (operand.isInteger(abstractValueDomain).isDefinitelyTrue) {
      return abstractValueDomain.intType;
    }
    return node.operand.instructionType;
  }

  @override
  AbstractValue visitAbs(HAbs node) {
    // TODO(sra): Can narrow to non-negative type for integers.
    return node.operand.instructionType;
  }

  @override
  AbstractValue visitInstruction(HInstruction instruction) {
    return instruction.instructionType;
  }

  @override
  AbstractValue visitFieldSet(HFieldSet node) {
    return node.value.instructionType;
  }

  @override
  AbstractValue visitIndexAssign(HIndexAssign node) {
    return node.value.instructionType;
  }

  @override
  AbstractValue visitStaticStore(HStaticStore node) {
    return node.value.instructionType;
  }

  @override
  AbstractValue visitPhi(HPhi node) {
    AbstractValue candidateType = abstractValueDomain.emptyType;
    for (int i = 0, length = node.inputs.length; i < length; i++) {
      AbstractValue inputType = node.inputs[i].instructionType;
      candidateType = abstractValueDomain.union(candidateType, inputType);
    }
    return candidateType;
  }

  @override
  AbstractValue visitPrimitiveCheck(HPrimitiveCheck node) {
    HInstruction input = node.checkedInput;
    AbstractValue inputType = input.instructionType;
    AbstractValue checkedType = node.checkedType;

    AbstractValue outputType = abstractValueDomain.intersection(
      checkedType,
      inputType,
    );
    if (inputType != outputType) {
      // Replace dominated uses of input with uses of this HPrimitiveCheck so
      // the uses benefit from the stronger type.
      assert(!(input is HParameterValue && input.usedAsVariable()));
      input.replaceAllUsersDominatedBy(node.next!, node);
    }
    return outputType;
  }

  @override
  AbstractValue visitTypeKnown(HTypeKnown node) {
    HInstruction input = node.checkedInput;
    AbstractValue inputType = input.instructionType;
    AbstractValue outputType = abstractValueDomain.intersection(
      node.knownType,
      inputType,
    );
    if (inputType != outputType) {
      input.replaceAllUsersDominatedBy(node.next!, node);
    }
    return outputType;
  }

  void convertInput(
    HInvokeDynamic instruction,
    HInstruction input,
    AbstractValue type,
    PrimitiveCheckKind kind,
    DartType typeExpression,
  ) {
    Selector? selector = (kind == PrimitiveCheckKind.receiverType)
        ? instruction.selector
        : null;
    HPrimitiveCheck converted = HPrimitiveCheck(
      typeExpression,
      kind,
      type,
      input,
      instruction.sourceInformation,
      receiverTypeCheckSelector: selector,
    );
    instruction.block!.addBefore(instruction, converted);
    input.replaceAllUsersDominatedBy(instruction, converted);
    _log?.registerPrimitiveCheck(instruction, converted);
  }

  bool isCheckEnoughForNsmOrAe(HInstruction instruction, AbstractValue type) {
    // In some cases, we want the receiver to be an integer,
    // but that does not mean we will get a NoSuchMethodError
    // if it's not: the receiver could be a double.
    if (abstractValueDomain.isIntegerOrNull(type).isDefinitelyTrue) {
      // If the instruction's type is integer or null, the codegen
      // will emit a null check, which is enough to know if it will
      // hit a noSuchMethod.
      return instruction.isIntegerOrNull(abstractValueDomain).isDefinitelyTrue;
    }
    return true;
  }

  // Add a receiver type check when the call can only hit
  // [noSuchMethod] if the receiver is not of a specific type.
  // Return true if the receiver type check was added.
  bool checkReceiver(HInvokeDynamic instruction) {
    assert(instruction.isInterceptedCall);
    HInstruction receiver = instruction.inputs[1];
    if (receiver.isNumber(abstractValueDomain).isDefinitelyTrue) {
      return false;
    }
    if (receiver.isNumberOrNull(abstractValueDomain).isDefinitelyTrue) {
      convertInput(
        instruction,
        receiver,
        abstractValueDomain.excludeNull(receiver.instructionType),
        PrimitiveCheckKind.receiverType,
        commonElements.numType,
      );
      return true;
    } else if (instruction.element == null) {
      if (closedWorld.includesClosureCall(
        instruction.selector,
        instruction.receiverType,
      )) {
        return false;
      }
      Iterable<MemberEntity> targets = closedWorld.locateMembers(
        instruction.selector,
        instruction.receiverType,
      );
      if (targets.length == 1) {
        MemberEntity target = targets.first;
        ClassEntity cls = target.enclosingClass!;
        AbstractValue type = abstractValueDomain.createNonNullSubclass(cls);
        // We currently only optimize on some primitive types.
        DartType typeExpression;
        if (abstractValueDomain.isNumberOrNull(type).isDefinitelyTrue) {
          typeExpression = commonElements.numType;
        } else if (abstractValueDomain.isBooleanOrNull(type).isDefinitelyTrue) {
          typeExpression = commonElements.boolType;
        } else {
          return false;
        }
        if (!isCheckEnoughForNsmOrAe(receiver, type)) return false;
        instruction.element = target;
        convertInput(
          instruction,
          receiver,
          type,
          PrimitiveCheckKind.receiverType,
          typeExpression,
        );
        return true;
      }
    }
    return false;
  }

  // Add an argument type check if the argument is not of a type
  // expected by the call.
  // Return true if the argument type check was added.
  bool checkArgument(HInvokeDynamic instruction) {
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];

    Selector selector = instruction.selector;
    if (selector.isOperator &&
        left.isNumber(abstractValueDomain).isDefinitelyTrue) {
      if (right.isNumber(abstractValueDomain).isDefinitelyTrue) {
        return false;
      }
      AbstractValue type =
          right.isIntegerOrNull(abstractValueDomain).isDefinitelyTrue
          ? abstractValueDomain.excludeNull(right.instructionType)
          : abstractValueDomain.numType;
      // TODO(ngeoffray): Some number operations don't have a builtin
      // variant and will do the check in their method anyway. We
      // still add a check because it allows to GVN these operations,
      // but we should find a better way.
      convertInput(
        instruction,
        right,
        type,
        PrimitiveCheckKind.argumentType,
        commonElements.numType,
      );
      return true;
    }
    return false;
  }

  void processPendingOptimizations() {
    pendingOptimizations.forEach((instruction, action) => action());
    pendingOptimizations.clear();
  }

  void addDependentInstructionsToWorkList(HInstruction instruction) {
    for (int i = 0, length = instruction.usedBy.length; i < length; i++) {
      // The type propagator only propagates types forward. We
      // thus only need to add the users of the [instruction] to the list.
      addToWorkList(instruction.usedBy[i]);
    }
  }

  void addAllUsersBut(HInvokeDynamic invoke, HInstruction instruction) {
    for (var user in instruction.usedBy) {
      if (user != invoke) addToWorkList(user);
    }
  }

  @override
  AbstractValue visitInvokeDynamic(HInvokeDynamic node) {
    if (node.isInterceptedCall) {
      // We cannot do the following optimization now, because we have to wait
      // for the type propagation to be stable. The receiver of [instruction]
      // might move from number to dynamic.
      void checkInputs() {
        Selector selector = node.selector;
        if (selector.isOperator && selector.name != '==') {
          if (checkReceiver(node)) {
            addAllUsersBut(node, node.inputs[1]);
          }
          if (!selector.isUnaryOperator && checkArgument(node)) {
            addAllUsersBut(node, node.inputs[2]);
          }
        } else if (selector.isCall) {
          if (selector.name == 'abs' && selector.argumentCount == 0) {
            if (checkReceiver(node)) {
              addAllUsersBut(node, node.inputs[1]);
            }
          }
        }
      }

      pendingOptimizations.putIfAbsent(node, () => checkInputs);
    }

    HInstruction receiver = node.getDartReceiver();
    AbstractValue receiverType = receiver.instructionType;
    node.updateReceiverType(abstractValueDomain, receiverType);

    var result = node.specializer.computeTypeFromInputTypes(
      node,
      results,
      closedWorld,
    );
    return node.computeInstructionType(result, abstractValueDomain);
  }

  @override
  AbstractValue visitNullCheck(HNullCheck node) {
    HInstruction input = node.checkedInput;
    AbstractValue inputType = input.instructionType;
    AbstractValue outputType = abstractValueDomain.excludeNull(inputType);
    if (inputType != outputType) {
      // Replace dominated uses of input with uses of this check so the uses
      // benefit from the stronger type.
      assert(!(input is HParameterValue && input.usedAsVariable()));
      input.replaceAllUsersDominatedBy(node.next!, node);
    }
    return outputType;
  }

  @override
  AbstractValue visitLateReadCheck(HLateReadCheck node) {
    HInstruction input = node.checkedInput;
    AbstractValue inputType = input.instructionType;
    AbstractValue outputType = abstractValueDomain.excludeLateSentinel(
      inputType,
    );
    if (inputType != outputType) {
      // Replace dominated uses of input with uses of this check so the uses
      // benefit from the stronger type.
      input.replaceAllUsersDominatedBy(node.next!, node);
    }
    return outputType;
  }

  @override
  AbstractValue visitAsCheck(HAsCheck node) {
    return _narrowAsCheck(
      node,
      node.checkedInput,
      node.checkedType.abstractValue,
    );
  }

  @override
  AbstractValue visitAsCheckSimple(HAsCheckSimple node) {
    return _narrowAsCheck(
      node,
      node.checkedInput,
      node.checkedType.abstractValue,
    );
  }

  AbstractValue _narrowAsCheck(
    HInstruction instruction,
    HInstruction input,
    AbstractValue checkedType,
  ) {
    AbstractValue inputType = input.instructionType;
    AbstractValue outputType = abstractValueDomain.intersection(
      checkedType,
      inputType,
    );
    if (inputType != outputType) {
      // Replace dominated uses of input with uses of this check so the uses
      // benefit from the stronger type.
      assert(!(input is HParameterValue && input.usedAsVariable()));
      input.replaceAllUsersDominatedBy(instruction.next!, instruction);
    }
    return outputType;
  }

  @override
  AbstractValue visitArrayFlagsCheck(HArrayFlagsCheck node) {
    node.array.replaceAllUsersDominatedBy(node.next!, node);
    AbstractValue inputType = node.array.instructionType;
    return node.computeInstructionType(inputType, abstractValueDomain);
  }
}
