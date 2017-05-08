// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements;
import '../elements/entities.dart';
import '../options.dart';
import '../types/types.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show ClosedWorld;
import 'nodes.dart';
import 'optimize.dart';

class SsaTypePropagator extends HBaseVisitor implements OptimizationPhase {
  final Map<int, HInstruction> workmap = new Map<int, HInstruction>();
  final List<int> worklist = new List<int>();
  final Map<HInstruction, Function> pendingOptimizations =
      new Map<HInstruction, Function>();

  final GlobalTypeInferenceResults results;
  final CompilerOptions options;
  final CommonElements commonElements;
  final ClosedWorld closedWorld;
  String get name => 'type propagator';

  SsaTypePropagator(
      this.results, this.options, this.commonElements, this.closedWorld);

  TypeMask computeType(HInstruction instruction) {
    return instruction.accept(this);
  }

  // Re-compute and update the type of the instruction. Returns
  // whether or not the type was changed.
  bool updateType(HInstruction instruction) {
    // Compute old and new types.
    TypeMask oldType = instruction.instructionType;
    TypeMask newType = computeType(instruction);
    assert(newType != null);
    // We unconditionally replace the propagated type with the new type. The
    // computeType must make sure that we eventually reach a stable state.
    instruction.instructionType = newType;
    return oldType != newType;
  }

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
    processWorklist();
  }

  visitBasicBlock(HBasicBlock block) {
    if (block.isLoopHeader()) {
      block.forEachPhi((HPhi phi) {
        // Set the initial type for the phi. We're not using the type
        // the phi thinks it has because new optimizations may imply
        // changing it.
        // In theory we would need to mark
        // the type of all other incoming edges as "unitialized" and take this
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

  TypeMask visitBinaryArithmetic(HBinaryArithmetic instruction) {
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    if (left.isInteger(closedWorld) && right.isInteger(closedWorld)) {
      return closedWorld.commonMasks.intType;
    }
    if (left.isDouble(closedWorld)) {
      return closedWorld.commonMasks.doubleType;
    }
    return closedWorld.commonMasks.numType;
  }

  TypeMask checkPositiveInteger(HBinaryArithmetic instruction) {
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    if (left.isPositiveInteger(closedWorld) &&
        right.isPositiveInteger(closedWorld)) {
      return closedWorld.commonMasks.positiveIntType;
    }
    return visitBinaryArithmetic(instruction);
  }

  TypeMask visitMultiply(HMultiply instruction) {
    return checkPositiveInteger(instruction);
  }

  TypeMask visitAdd(HAdd instruction) {
    return checkPositiveInteger(instruction);
  }

  TypeMask visitDivide(HDivide instruction) {
    // Always double, as initialized.
    return instruction.instructionType;
  }

  TypeMask visitTruncatingDivide(HTruncatingDivide instruction) {
    // Always as initialized.
    return instruction.instructionType;
  }

  TypeMask visitRemainder(HRemainder instruction) {
    // Always as initialized.
    return instruction.instructionType;
  }

  TypeMask visitNegate(HNegate instruction) {
    HInstruction operand = instruction.operand;
    // We have integer subclasses that represent ranges, so widen any int
    // subclass to full integer.
    if (operand.isInteger(closedWorld)) {
      return closedWorld.commonMasks.intType;
    }
    return instruction.operand.instructionType;
  }

  TypeMask visitInstruction(HInstruction instruction) {
    assert(instruction.instructionType != null);
    return instruction.instructionType;
  }

  TypeMask visitPhi(HPhi phi) {
    TypeMask candidateType = closedWorld.commonMasks.emptyType;
    for (int i = 0, length = phi.inputs.length; i < length; i++) {
      TypeMask inputType = phi.inputs[i].instructionType;
      candidateType = candidateType.union(inputType, closedWorld);
    }
    return candidateType;
  }

  TypeMask visitTypeConversion(HTypeConversion instruction) {
    HInstruction input = instruction.checkedInput;
    TypeMask inputType = input.instructionType;
    TypeMask checkedType = instruction.checkedType;
    if (instruction.isArgumentTypeCheck || instruction.isReceiverTypeCheck) {
      // We must make sure a type conversion for receiver or argument check
      // does not try to do an int check, because an int check is not enough.
      // We only do an int check if the input is integer or null.
      if (checkedType.containsOnlyNum(closedWorld) &&
          !checkedType.containsOnlyDouble(closedWorld) &&
          input.isIntegerOrNull(closedWorld)) {
        instruction.checkedType = closedWorld.commonMasks.intType;
      } else if (checkedType.containsOnlyInt(closedWorld) &&
          !input.isIntegerOrNull(closedWorld)) {
        instruction.checkedType = closedWorld.commonMasks.numType;
      }
    }

    TypeMask outputType = checkedType.intersection(inputType, closedWorld);
    if (outputType.isEmpty) {
      // Intersection of double and integer conflicts (is empty), but JS numbers
      // can be both int and double at the same time.  For example, the input
      // can be a literal double '8.0' that is marked as an integer (because 'is
      // int' will return 'true').  What we really need to do is make the
      // overlap between int and double values explicit in the TypeMask system.
      if (inputType.containsOnlyInt(closedWorld) &&
          checkedType.containsOnlyDouble(closedWorld)) {
        if (inputType.isNullable && checkedType.isNullable) {
          outputType = closedWorld.commonMasks.doubleType.nullable();
        } else {
          outputType = closedWorld.commonMasks.doubleType;
        }
      }
    }
    if (inputType != outputType) {
      // Replace dominated uses of input with uses of this HTypeConversion so
      // the uses benefit from the stronger type.
      //
      // The dependency on the checked value also improves the generated
      // JavaScript. Many checks are compiled to a function call expression that
      // returns the checked result, so the check can be generated as a
      // subexpression rather than a separate statement.
      //
      // Do not replace local accesses, since the local must be a HLocalValue,
      // not a HTypeConversion.
      if (!(input is HParameterValue && input.usedAsVariable())) {
        input.replaceAllUsersDominatedBy(instruction.next, instruction);
      }
    }
    return outputType;
  }

  TypeMask visitTypeKnown(HTypeKnown instruction) {
    HInstruction input = instruction.checkedInput;
    TypeMask inputType = input.instructionType;
    TypeMask outputType =
        instruction.knownType.intersection(inputType, closedWorld);
    if (inputType != outputType) {
      input.replaceAllUsersDominatedBy(instruction.next, instruction);
    }
    return outputType;
  }

  void convertInput(
      HInvokeDynamic instruction, HInstruction input, TypeMask type, int kind) {
    Selector selector = (kind == HTypeConversion.RECEIVER_TYPE_CHECK)
        ? instruction.selector
        : null;
    HTypeConversion converted = new HTypeConversion(null, kind, type, input,
        receiverTypeCheckSelector: selector)
      ..sourceInformation = instruction.sourceInformation;
    instruction.block.addBefore(instruction, converted);
    input.replaceAllUsersDominatedBy(instruction, converted);
  }

  bool isCheckEnoughForNsmOrAe(HInstruction instruction, TypeMask type) {
    // In some cases, we want the receiver to be an integer,
    // but that does not mean we will get a NoSuchMethodError
    // if it's not: the receiver could be a double.
    if (type.containsOnlyInt(closedWorld)) {
      // If the instruction's type is integer or null, the codegen
      // will emit a null check, which is enough to know if it will
      // hit a noSuchMethod.
      return instruction.isIntegerOrNull(closedWorld);
    }
    return true;
  }

  // Add a receiver type check when the call can only hit
  // [noSuchMethod] if the receiver is not of a specific type.
  // Return true if the receiver type check was added.
  bool checkReceiver(HInvokeDynamic instruction) {
    assert(instruction.isInterceptedCall);
    HInstruction receiver = instruction.inputs[1];
    if (receiver.isNumber(closedWorld)) return false;
    if (receiver.isNumberOrNull(closedWorld)) {
      convertInput(
          instruction,
          receiver,
          receiver.instructionType.nonNullable(),
          HTypeConversion.RECEIVER_TYPE_CHECK);
      return true;
    } else if (instruction.element == null) {
      Iterable<MemberEntity> targets =
          closedWorld.locateMembers(instruction.selector, instruction.mask);
      if (targets.length == 1) {
        MemberEntity target = targets.first;
        ClassEntity cls = target.enclosingClass;
        TypeMask type = new TypeMask.nonNullSubclass(cls, closedWorld);
        // TODO(ngeoffray): We currently only optimize on primitive
        // types.
        if (!type.satisfies(commonElements.jsIndexableClass, closedWorld) &&
            !type.containsOnlyNum(closedWorld) &&
            !type.containsOnlyBool(closedWorld)) {
          return false;
        }
        if (!isCheckEnoughForNsmOrAe(receiver, type)) return false;
        instruction.element = target;
        convertInput(
            instruction, receiver, type, HTypeConversion.RECEIVER_TYPE_CHECK);
        return true;
      }
    }
    return false;
  }

  // Add an argument type check if the argument is not of a type
  // expected by the call.
  // Return true if the argument type check was added.
  bool checkArgument(HInvokeDynamic instruction) {
    // We want the right error in checked mode.
    if (options.enableTypeAssertions) return false;
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];

    Selector selector = instruction.selector;
    if (selector.isOperator && left.isNumber(closedWorld)) {
      if (right.isNumber(closedWorld)) return false;
      TypeMask type = right.isIntegerOrNull(closedWorld)
          ? right.instructionType.nonNullable()
          : closedWorld.commonMasks.numType;
      // TODO(ngeoffray): Some number operations don't have a builtin
      // variant and will do the check in their method anyway. We
      // still add a check because it allows to GVN these operations,
      // but we should find a better way.
      convertInput(
          instruction, right, type, HTypeConversion.ARGUMENT_TYPE_CHECK);
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

  TypeMask visitInvokeDynamic(HInvokeDynamic instruction) {
    if (instruction.isInterceptedCall) {
      // We cannot do the following optimization now, because we have
      // to wait for the type propagation to be stable. The receiver
      // of [instruction] might move from number to dynamic.
      pendingOptimizations.putIfAbsent(
          instruction,
          () => () {
                Selector selector = instruction.selector;
                if (selector.isOperator && selector.name != '==') {
                  if (checkReceiver(instruction)) {
                    addAllUsersBut(instruction, instruction.inputs[1]);
                  }
                  if (!selector.isUnaryOperator && checkArgument(instruction)) {
                    addAllUsersBut(instruction, instruction.inputs[2]);
                  }
                }
              });
    }

    HInstruction receiver = instruction.getDartReceiver(closedWorld);
    TypeMask receiverType = receiver.instructionType;
    instruction.mask = receiverType;

    // Try to specialize the receiver after this call by instering a refinement
    // node (HTypeKnown). There are two potentially expensive tests - are there
    // any uses of the receiver dominated by and following this call?, and what
    // is the refined type? The first is expensive if the receiver has many
    // uses, the second is expensive if many classes implement the selector. So
    // we try to do the least expensive test first.
    const int _MAX_QUICK_USERS = 50;
    if (!instruction.selector.isClosureCall) {
      TypeMask newType;
      TypeMask computeNewType() {
        newType = closedWorld.computeReceiverType(
            instruction.selector, instruction.mask);
        newType = newType.intersection(receiverType, closedWorld);
        return newType;
      }

      var next = instruction.next;
      if (next is HTypeKnown && next.checkedInput == receiver) {
        // On a previous pass or iteration we already refined [receiver] by
        // inserting a [HTypeKnown] instruction. That replaced several dominated
        // uses with the refinement. We update the type of the [HTypeKnown]
        // instruction because it may have been refined with a correct type at
        // the time, but incorrect now.
        if (next.instructionType != computeNewType()) {
          next.knownType = next.instructionType = newType;
          addDependentInstructionsToWorkList(next);
        }
      } else {
        DominatedUses uses;
        bool hasCandidates() {
          uses =
              DominatedUses.of(receiver, instruction, excludeDominator: true);
          return uses.isNotEmpty;
        }

        if ((receiver.usedBy.length <= _MAX_QUICK_USERS)
            ? (hasCandidates() && computeNewType() != receiverType)
            : (computeNewType() != receiverType && hasCandidates())) {
          // Insert a refinement node after the call and update all users
          // dominated by the call to use that node instead of [receiver].
          HTypeKnown converted =
              new HTypeKnown.witnessed(newType, receiver, instruction);
          instruction.block.addBefore(instruction.next, converted);
          uses.replaceWith(converted);
          addDependentInstructionsToWorkList(converted);
        }
      }
    }

    return instruction.specializer
        .computeTypeFromInputTypes(instruction, results, options, closedWorld);
  }
}
