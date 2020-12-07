// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show JClosedWorld;
import 'logging.dart';
import 'nodes.dart';
import 'optimize.dart';

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
class SsaTypePropagator extends HBaseVisitor implements OptimizationPhase {
  final Map<int, HInstruction> workmap = new Map<int, HInstruction>();
  final List<int> worklist = <int>[];
  final Map<HInstruction, Function> pendingOptimizations =
      new Map<HInstruction, Function>();

  final GlobalTypeInferenceResults results;
  final CommonElements commonElements;
  final JClosedWorld closedWorld;
  final OptimizationTestLog _log;
  @override
  String get name => 'SsaTypePropagator';

  SsaTypePropagator(
      this.results, this.commonElements, this.closedWorld, this._log);

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
    assert(newType != null);
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
  visitBasicBlock(HBasicBlock block) {
    if (block.isLoopHeader()) {
      block.forEachPhi((HPhi phi) {
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
      block.forEachPhi((HPhi phi) {
        if (updateType(phi)) {
          addDependentInstructionsToWorkList(phi);
        }
      });
    }

    HInstruction instruction = block.first;
    while (instruction != null) {
      if (updateType(instruction)) {
        addDependentInstructionsToWorkList(instruction);
      }
      instruction = instruction.next;
    }
  }

  void processWorklist() {
    do {
      while (!worklist.isEmpty) {
        int id = worklist.removeLast();
        HInstruction instruction = workmap[id];
        assert(instruction != null);
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
    } while (!worklist.isEmpty);
  }

  void addToWorkList(HInstruction instruction) {
    final int id = instruction.id;

    if (!workmap.containsKey(id)) {
      worklist.add(id);
      workmap[id] = instruction;
    }
  }

  @override
  AbstractValue visitBinaryArithmetic(HBinaryArithmetic instruction) {
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    if (left.isInteger(abstractValueDomain).isDefinitelyTrue &&
        right.isInteger(abstractValueDomain).isDefinitelyTrue) {
      return abstractValueDomain.intType;
    }
    if (left.isDouble(abstractValueDomain).isDefinitelyTrue) {
      return abstractValueDomain.doubleType;
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
  AbstractValue visitMultiply(HMultiply instruction) {
    return checkPositiveInteger(instruction);
  }

  @override
  AbstractValue visitAdd(HAdd instruction) {
    return checkPositiveInteger(instruction);
  }

  @override
  AbstractValue visitDivide(HDivide instruction) {
    // Always double, as initialized.
    return instruction.instructionType;
  }

  @override
  AbstractValue visitTruncatingDivide(HTruncatingDivide instruction) {
    // Always as initialized.
    return instruction.instructionType;
  }

  @override
  AbstractValue visitRemainder(HRemainder instruction) {
    // Always as initialized.
    return instruction.instructionType;
  }

  @override
  AbstractValue visitNegate(HNegate instruction) {
    HInstruction operand = instruction.operand;
    // We have integer subclasses that represent ranges, so widen any int
    // subclass to full integer.
    if (operand.isInteger(abstractValueDomain).isDefinitelyTrue) {
      return abstractValueDomain.intType;
    }
    return instruction.operand.instructionType;
  }

  @override
  AbstractValue visitAbs(HAbs instruction) {
    // TODO(sra): Can narrow to non-negative type for integers.
    return instruction.operand.instructionType;
  }

  @override
  AbstractValue visitInstruction(HInstruction instruction) {
    assert(instruction.instructionType != null);
    return instruction.instructionType;
  }

  @override
  AbstractValue visitPhi(HPhi phi) {
    AbstractValue candidateType = abstractValueDomain.emptyType;
    for (int i = 0, length = phi.inputs.length; i < length; i++) {
      AbstractValue inputType = phi.inputs[i].instructionType;
      candidateType = abstractValueDomain.union(candidateType, inputType);
    }
    return candidateType;
  }

  @override
  AbstractValue visitPrimitiveCheck(HPrimitiveCheck instruction) {
    HInstruction input = instruction.checkedInput;
    AbstractValue inputType = input.instructionType;
    AbstractValue checkedType = instruction.checkedType;

    AbstractValue outputType =
        abstractValueDomain.intersection(checkedType, inputType);
    if (inputType != outputType) {
      // Replace dominated uses of input with uses of this HPrimitiveCheck so
      // the uses benefit from the stronger type.
      assert(!(input is HParameterValue && input.usedAsVariable()));
      input.replaceAllUsersDominatedBy(instruction.next, instruction);
    }
    return outputType;
  }

  @override
  AbstractValue visitTypeKnown(HTypeKnown instruction) {
    HInstruction input = instruction.checkedInput;
    AbstractValue inputType = input.instructionType;
    AbstractValue outputType =
        abstractValueDomain.intersection(instruction.knownType, inputType);
    if (inputType != outputType) {
      input.replaceAllUsersDominatedBy(instruction.next, instruction);
    }
    return outputType;
  }

  void convertInput(HInvokeDynamic instruction, HInstruction input,
      AbstractValue type, int kind, DartType typeExpression) {
    assert(kind == HPrimitiveCheck.RECEIVER_TYPE_CHECK ||
        kind == HPrimitiveCheck.ARGUMENT_TYPE_CHECK);
    Selector selector = (kind == HPrimitiveCheck.RECEIVER_TYPE_CHECK)
        ? instruction.selector
        : null;
    HPrimitiveCheck converted = new HPrimitiveCheck(
        typeExpression, kind, type, input, instruction.sourceInformation,
        receiverTypeCheckSelector: selector);
    instruction.block.addBefore(instruction, converted);
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
          HPrimitiveCheck.RECEIVER_TYPE_CHECK,
          commonElements.numType);
      return true;
    } else if (instruction.element == null) {
      if (closedWorld.includesClosureCall(
          instruction.selector, instruction.receiverType)) {
        return false;
      }
      Iterable<MemberEntity> targets = closedWorld.locateMembers(
          instruction.selector, instruction.receiverType);
      if (targets.length == 1) {
        MemberEntity target = targets.first;
        ClassEntity cls = target.enclosingClass;
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
        convertInput(instruction, receiver, type,
            HPrimitiveCheck.RECEIVER_TYPE_CHECK, typeExpression);
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
      convertInput(instruction, right, type,
          HPrimitiveCheck.ARGUMENT_TYPE_CHECK, commonElements.numType);
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
    instruction.usedBy.forEach((HInstruction user) {
      if (user != invoke) addToWorkList(user);
    });
  }

  @override
  AbstractValue visitInvokeDynamic(HInvokeDynamic instruction) {
    if (instruction.isInterceptedCall) {
      // We cannot do the following optimization now, because we have to wait
      // for the type propagation to be stable. The receiver of [instruction]
      // might move from number to dynamic.
      void checkInputs() {
        Selector selector = instruction.selector;
        if (selector.isOperator && selector.name != '==') {
          if (checkReceiver(instruction)) {
            addAllUsersBut(instruction, instruction.inputs[1]);
          }
          if (!selector.isUnaryOperator && checkArgument(instruction)) {
            addAllUsersBut(instruction, instruction.inputs[2]);
          }
        } else if (selector.isCall) {
          if (selector.name == 'abs' && selector.argumentCount == 0) {
            if (checkReceiver(instruction)) {
              addAllUsersBut(instruction, instruction.inputs[1]);
            }
          }
        }
      }

      pendingOptimizations.putIfAbsent(instruction, () => checkInputs);
    }

    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    AbstractValue receiverType = receiver.instructionType;
    instruction.updateReceiverType(abstractValueDomain, receiverType);

    // Try to refine that the receiver is not null after this call by inserting
    // a refinement node (HTypeKnown).
    var selector = instruction.selector;
    if (!selector.isClosureCall && !selector.appliesToNullWithoutThrow()) {
      var next = instruction.next;
      if (next is HTypeKnown && next.checkedInput == receiver) {
        // On a previous pass or iteration we already refined [receiver] by
        // inserting a [HTypeKnown] instruction. That replaced several dominated
        // uses with the refinement. We update the type of the [HTypeKnown]
        // instruction because it may have been refined with a correct type at
        // the time, but incorrect now.
        AbstractValue newType = abstractValueDomain.excludeNull(receiverType);
        if (next.instructionType != newType) {
          next.knownType = next.instructionType = newType;
          addDependentInstructionsToWorkList(next);
        }
      } else if (abstractValueDomain.isNull(receiverType).isPotentiallyTrue) {
        DominatedUses uses =
            DominatedUses.of(receiver, instruction, excludeDominator: true);
        if (uses.isNotEmpty) {
          // Insert a refinement node after the call and update all users
          // dominated by the call to use that node instead of [receiver].
          AbstractValue newType = abstractValueDomain.excludeNull(receiverType);
          HTypeKnown converted =
              new HTypeKnown.witnessed(newType, receiver, instruction);
          instruction.block.addBefore(instruction.next, converted);
          uses.replaceWith(converted);
          addDependentInstructionsToWorkList(converted);
        }
      }
    }

    return instruction.specializer
        .computeTypeFromInputTypes(instruction, results, closedWorld);
  }

  @override
  AbstractValue visitNullCheck(HNullCheck instruction) {
    HInstruction input = instruction.checkedInput;
    AbstractValue inputType = input.instructionType;
    AbstractValue outputType = abstractValueDomain.excludeNull(inputType);
    if (inputType != outputType) {
      // Replace dominated uses of input with uses of this check so the uses
      // benefit from the stronger type.
      assert(!(input is HParameterValue && input.usedAsVariable()));
      input.replaceAllUsersDominatedBy(instruction.next, instruction);
    }
    return outputType;
  }

  @override
  AbstractValue visitAsCheck(HAsCheck instruction) {
    return _narrowAsCheck(instruction, instruction.checkedInput,
        instruction.checkedType.abstractValue);
  }

  @override
  AbstractValue visitAsCheckSimple(HAsCheckSimple instruction) {
    return _narrowAsCheck(instruction, instruction.checkedInput,
        instruction.checkedType.abstractValue);
  }

  AbstractValue _narrowAsCheck(
      HInstruction instruction, HInstruction input, AbstractValue checkedType) {
    AbstractValue inputType = input.instructionType;
    AbstractValue outputType =
        abstractValueDomain.intersection(checkedType, inputType);
    if (inputType != outputType) {
      // Replace dominated uses of input with uses of this check so the uses
      // benefit from the stronger type.
      assert(!(input is HParameterValue && input.usedAsVariable()));
      input.replaceAllUsersDominatedBy(instruction.next, instruction);
    }
    return outputType;
  }

  @override
  AbstractValue visitBoolConversion(HBoolConversion instruction) {
    return abstractValueDomain.intersection(
        abstractValueDomain.boolType, instruction.checkedInput.instructionType);
  }
}
