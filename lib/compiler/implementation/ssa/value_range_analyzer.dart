// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A [Value] represents both symbolic values like the value of a
 * parameter, or the length of an array, and concrete values, like
 * constants.
 */
abstract class Value {
  const Value();

  Value operator +(Value other);
  Value operator -(Value other);
  Value operator &(Value other);

  Value min(Value other) {
    if (this == other) return this;
    if (other == const MinIntValue()) return other;
    if (other == const MaxIntValue()) return this;
    Value value = this - other;
    if (value.isPositive()) return other;
    if (value.isNegative()) return this;
    return const UnknownValue();
  }

  Value max(Value other) {
    if (this == other) return this;
    if (other == const MinIntValue()) return this;
    if (other == const MaxIntValue()) return other;
    Value value = this - other;
    if (value.isPositive()) return this;
    if (value.isNegative()) return other;
    return const UnknownValue();
  }

  bool isNegative() => false;
  bool isPositive() => false;
  bool isZero() => false;
}

/**
 * An [IntValue] contains a constant integer value.
 */
class IntValue extends Value {
  final int value;
  const IntValue(this.value);

  Value operator +(other) {
    if (other is !IntValue) return other + this;
    return new IntValue(value + other.value);
  }

  Value operator -(other) {
    if (other is !IntValue) return other - this;
    return new IntValue(value - other.value);
  }

  Value operator &(other) {
    if (other is !IntValue) return this;
    return new IntValue(value & other.value);
  }

  Value min(other) {
    if (other is !IntValue) return other.min(this);
    return this.value < other.value ? this : other;
  }

  Value max(other) {
    if (other is !IntValue) return other.max(this);
    return this.value < other.value ? other : this;
  }

  bool operator ==(other) {
    if (other is !IntValue) return false;
    return this.value == other.value;
  }

  String toString() => 'IntValue $value';
  bool isNegative() => value < 0;
  bool isPositive() => value >= 0;
  bool isZero() => value == 0;
}

/**
 * The [MaxIntValue] represents the maximum value an integer can have,
 * which is currently +infinity.
 */
class MaxIntValue extends Value {
  const MaxIntValue();
  Value operator +(Value other) => this;
  Value operator -(Value other) => this;
  Value operator &(Value other) {
    if (other.isPositive()) return other;
    if (other.isNegative()) return const IntValue(0);
    return this;
  }
  Value min(Value other) => other;
  Value max(Value other) => this;
  String toString() => 'Max';
  bool isNegative() => false;
  bool isPositive() => true;
}

/**
 * The [MinIntValue] represents the minimum value an integer can have,
 * which is currently -infinity.
 */
class MinIntValue extends Value {
  const MinIntValue();
  Value operator +(Value other) => this;
  Value operator -(Value other) => this;
  Value operator &(Value other) {
    if (other.isPositive()) return const IntValue(0);
    return this;
  }
  Value min(Value other) => this;
  Value max(Value other) => other;
  String toString() => 'Min';
  bool isNegative() => true;
  bool isPositive() => false;
}

/**
 * The [UnknownValue] is the sentinel in our analysis to mark an
 * operation that could not be done because of too much complexity.
 */
class UnknownValue extends Value {
  const UnknownValue();
  Value operator +(Value other) => const UnknownValue();
  Value operator -(Value other) => const UnknownValue();
  Value operator &(Value other) => const UnknownValue();
  Value min(Value other) => const UnknownValue();
  Value max(Value other) => const UnknownValue();
  bool isNegative() => false;
  bool isPositive() => false;
  String toString() => 'Unknown';
}

/**
 * A symbolic value representing an [HInstruction].
 */
class InstructionValue extends Value {
  final HInstruction instruction;
  InstructionValue(this.instruction);

  bool operator ==(other) {
    if (other is !InstructionValue) return false;
    return this.instruction == other.instruction;
  }

  Value operator +(Value other) {
    if (other.isZero()) return this;
    return new OperationValue(this, other, const AddOperation());
  }

  Value operator -(Value other) {
    if (other.isZero()) return this;
    if (this == other) return const IntValue(0);
    return new OperationValue(this, other, const SubtractOperation());
  }

  Value operator &(Value other) {
    if (other is IntValue) return other & this;
    return this;
  }

  bool isNegative() => false;
  bool isPositive() => false;

  String toString() => 'Instruction: $instruction';
}

/**
 * Special value for instructions that represent the length of an
 * array. The difference with an [InstructionValue] is that we know
 * the value is positive.
 */
class LengthValue extends InstructionValue {
  LengthValue(HInstruction instruction) : super(instruction);
  bool isPositive() => true;
  String toString() => 'Length: $instruction';
}

/**
 * Represents a binary operation on two [Value], where the operation
 * did not yield a canonical value.
 */
class OperationValue extends Value {
  final Value left;
  final Value right;
  final Operation operation;
  OperationValue(this.left, this.right, this.operation);

  bool operator ==(other) {
    if (other is !OperationValue) return false;
    return left == other.left
        && right == other.right
        && operation == other.operation;
  }

  Value operator +(Value other) => const UnknownValue();
  Value operator &(Value other) => const UnknownValue();

  Value operator -(Value other) {
    if (operation is! SubtractOperation && operation is! AddOperation) {
      return const UnknownValue();
    }
    // We try to create a simple [Value] out of this operation. So we
    // first try to substract [other] to [left]. If the result is simple
    // enough (not unknown and not an operation), we return the result
    // of doing the operation of this [OperationValue] on the previous
    // result and [right].
    //
    // For example:
    // OperationValue(LengthValue(i1), IntValue(42), '-') - LengthValue(i1)
    //
    // Will return IntValue(-42)
    Value value = left - other;
    if (value != const UnknownValue() && value is! OperationValue) {
      return operation.apply(value, right);
    }
    // If the result is not simple enough, we try the same approach
    // with [right].
    if (operation is SubtractOperation) {
      value = right + other;
    } else {
      assert(operation is AddOperation);
      value = right - other;
    }
    if (value != const UnknownValue() && value is! OperationValue) {
      return operation.apply(left, value);
    }
    return const UnknownValue();
  }

  bool isNegative() => false;
  bool isPositive() => false;
  String toString() => '$left ${operation.name} $right';
}

/**
 * A [Range] represents the possible integer values an instruction
 * can have, from its [lower] bound to its [upper] bound, both
 * included.
 */
class Range {
  final Value lower;
  final Value upper;
  const Range(this.lower, this.upper);
  const Range.unbound()
      : lower = const MinIntValue(),
        upper = const MaxIntValue();
  /**
   * Checks if the given values are unknown, and creates a
   * range that does not have any unknown values.
   */
  Range.normalize(Value low, Value up)
      : lower = low == const UnknownValue() ? const MinIntValue() : low,
        upper = up == const UnknownValue() ? const MaxIntValue() : up;

  Range union(Range other) {
    return new Range.normalize(lower.min(other.lower), upper.max(other.upper));
  }

  intersection(Range other) {
    Value low = lower.max(other.lower);
    Value up = upper.min(other.upper);
    // If we could not compute max or min, pick a value in the two
    // ranges, with priority to [IntValue]s because they are simpler.
    if (low == const UnknownValue()) {
      if (lower is IntValue) low = lower;
      else if (other.lower is IntValue) low = other.lower;
      else low = lower;
    }
    if (up == const UnknownValue()) {
      if (upper is IntValue) up = upper;
      else if (other.upper is IntValue) up = other.upper;
      else up = upper;
    }
    return new Range(low, up);
  }

  Range operator +(Range other) {
    return new Range.normalize(lower + other.lower, upper + other.upper);
  }

  Range operator -(Range other) {
    return new Range.normalize(lower - other.lower, upper - other.upper);
  }

  Range operator &(Range other) {
    return new Range.normalize(lower & other.lower, upper & other.upper);
  }

  bool operator ==(other) {
    if (other is! Range) return false;
    return other.lower == lower && other.upper == upper;
  }

  bool isLessThan(Range other) {
    return upper != other.lower && upper.min(other.lower) == upper;
  }

  bool isNegative() => upper.isNegative();
  bool isPositive() => lower.isPositive();

  String toString() => '[$lower, $upper]';
}

/**
 * Visits the graph in dominator order, and computes value ranges for
 * integer instructions. While visiting the graph, this phase also
 * removes unnecessary bounds checks, and comparisons that are proven
 * to be true or false.
 */
class SsaValueRangeAnalyzer extends HBaseVisitor implements OptimizationPhase {
  String get name => 'SSA value range builder';

  /**
   * List of [HRangeConversion] instructions created by the phase. We
   * save them here in order to remove them once the phase is done.
   */
  final List<HRangeConversion> conversions = <HRangeConversion>[];

  /**
   * Value ranges for integer instructions. This map gets populated by
   * the dominator tree visit.
   */
  final Map<HInstruction, Range> ranges = new Map<HInstruction, Range>();

  final ConstantSystem constantSystem;
  final HTypeMap types;
  WorkItem work;
  HGraph graph;

  SsaValueRangeAnalyzer(this.constantSystem, this.types, WorkItem this.work);

  void visitGraph(HGraph graph) {
    this.graph = graph;
    visitDominatorTree(graph);
    // We remove the range conversions after visiting the graph so
    // that the graph does not get polluted with these instructions
    // only necessary for this phase.
    removeRangeConversion();
  }

  void removeRangeConversion() {
    conversions.forEach((HRangeConversion instruction) {
      instruction.block.rewrite(instruction, instruction.inputs[0]);;
      instruction.block.remove(instruction);
    });
  }

  void visitBasicBlock(HBasicBlock block) {

    void visit(HInstruction instruction) {
      Range range = instruction.accept(this);
      if (instruction.isInteger(types)) {
        assert(range != null);
        ranges[instruction] = range;
      }
    }

    block.forEachPhi(visit);
    block.forEachInstruction(visit);
  }

  Range visitInstruction(HInstruction instruction) {
    return const Range.unbound();
  }

  Range visitParameterValue(HParameterValue parameter) {
    if (!parameter.isInteger(types)) return const Range.unbound();
    Value value = new InstructionValue(parameter);
    return new Range(value, value);
  }

  Range visitPhi(HPhi phi) {
    if (!phi.isInteger(types)) return const Range.unbound();
    if (phi.block.isLoopHeader()) {
      Range range = tryInferLoopPhiRange(phi);
      if (range == null) return const Range.unbound();
      return range;
    }

    Range range = ranges[phi.inputs[0]];
    for (int i = 1; i < phi.inputs.length; i++) {
      range = range.union(ranges[phi.inputs[i]]);
    }
    return range;
  }

  Range tryInferLoopPhiRange(HPhi phi) {
    HInstruction update = phi.inputs[1];
    return update.accept(new LoopUpdateRecognizer(phi, ranges, types));
  }

  Range visitConstant(HConstant constant) {
    if (!constant.isInteger(types)) return const Range.unbound();
    Value value = new IntValue(constant.constant.value);
    return new Range(value, value);
  }

  Range visitInvokeInterceptor(HInvokeInterceptor interceptor) {
    if (!interceptor.isInteger(types)) return const Range.unbound();
    if (!interceptor.isLengthGetterOnStringOrArray(types)) {
      return visitInstruction(interceptor);
    }
    LengthValue value = new LengthValue(interceptor);
    // We know this range is above zero. To simplify the analysis, we
    // put the zero value as the lower bound of this range. This
    // allows to easily remove the second bound check in the following
    // expression: a[1] + a[0].
    return new Range(const IntValue(0), value);
  }

  Range visitBoundsCheck(HBoundsCheck check) {
    // Save the next instruction, in case the check gets removed.
    HInstruction next = check.next;
    Range indexRange = ranges[check.index];
    Range lengthRange = ranges[check.length];

    // Check if the index is strictly below the upper bound of the length
    // range.
    Value maxIndex = lengthRange.upper - const IntValue(1);
    bool belowLength = maxIndex != const MaxIntValue()
        && indexRange.upper.min(maxIndex) == indexRange.upper;

    // Check if the index is strictly below the lower bound of the length
    // range.
    belowLength = belowLength
        || (indexRange.upper != lengthRange.lower
            && indexRange.upper.min(lengthRange.lower) == indexRange.upper);
    if (indexRange.isPositive() && belowLength) {
      check.block.rewrite(check, check.index);
      check.block.remove(check);
    } else if (indexRange.isNegative() || lengthRange.isLessThan(indexRange)) {
      check.staticChecks = HBoundsCheck.ALWAYS_FALSE;
      // The check is always false, and whatever instruction it
      // dominates is dead code.
      return indexRange;
    } else if (indexRange.isPositive()) {
      check.staticChecks = HBoundsCheck.ALWAYS_ABOVE_ZERO;
    } else if (belowLength) {
      check.staticChecks = HBoundsCheck.ALWAYS_BELOW_LENGTH;
    }

    if (indexRange.isPositive()) {
      // If the test passes, we know the lower bound of the length is
      // greater or equal than the lower bound of the index.
      Value low = lengthRange.lower.max(indexRange.lower);
      if (low != const UnknownValue()) {
        HInstruction instruction =
            createRangeConversion(next, check.length);
        ranges[instruction] = new Range(low, lengthRange.upper);
      }
    }

    if (!belowLength) {
      // Update the range of the index if using the length bounds
      // narrows it.
      Range newIndexRange = indexRange.intersection(
          new Range(lengthRange.lower, maxIndex));
      if (indexRange == newIndexRange) return indexRange;
      HInstruction instruction = createRangeConversion(next, check.index);
      ranges[instruction] = newIndexRange;
      return newIndexRange;
    }

    return indexRange;
  }

  Range visitLess(HLess less) {
    HInstruction right = less.right;
    HInstruction left = less.left;
    if (!left.isInteger(types)) return const Range.unbound();
    if (!right.isInteger(types)) return const Range.unbound();
    if (ranges[left].isLessThan(ranges[right])) {
      less.block.rewrite(less, graph.addConstantBool(true, constantSystem));
      less.block.remove(less);
      return const Range.unbound();
    }
    if (ranges[right].isLessThan(ranges[left])) {
      less.block.rewrite(less, graph.addConstantBool(false, constantSystem));
      less.block.remove(less);
      return const Range.unbound();
    }
    return const Range.unbound();
  }

  Range handleBinaryOperation(HBinaryArithmetic instruction) {
    if (!instruction.isInteger(types)) return const Range.unbound();
    return instruction.operation(constantSystem).apply(
        ranges[instruction.left], ranges[instruction.right]);
  }

  Range visitAdd(HAdd add) {
    return handleBinaryOperation(add);
  }

  Range visitSubtract(HSubtract sub) {
    return handleBinaryOperation(sub);
  }

  Range visitBitAnd(HBitAnd node) {
    if (!node.isInteger(types)) return const Range.unbound();
    HInstruction right = node.right;
    HInstruction left = node.left;
    if (left.isInteger(types) && right.isInteger(types)) {
      return ranges[left] & ranges[right];
    }

    Range tryComputeRange(HInstruction instruction) {
      Range range = ranges[instruction];
      if (range.isPositive()) {
        return new Range(const IntValue(0), range.upper);
      } else if (range.isNegative()) {
        return new Range(range.lower, const IntValue(0));
      }
      return const Range.unbound();
    }

    if (left.isInteger(types)) {
      return tryComputeRange(left);
    } else if (right.isInteger(types)) {
      return tryComputeRange(right);
    }
    return const Range.unbound();
  }

  Range visitCheck(HCheck instruction) {
    if (ranges[instruction.checkedInput] == null) {
      return const Range.unbound();
    }
    return ranges[instruction.checkedInput];
  }

  HInstruction createRangeConversion(HInstruction cursor,
                                     HInstruction instruction) {
    HRangeConversion newInstruction = new HRangeConversion(instruction);
    conversions.add(newInstruction);
    cursor.block.addBefore(cursor, newInstruction);
    // Update the users of the instruction dominated by [cursor] to
    // use the new instruction, that has an narrower range.
    Set<HInstruction> dominatedUsers = instruction.dominatedUsers(cursor);
    for (HInstruction user in dominatedUsers) {
      user.changeUse(instruction, newInstruction);
    }
    return newInstruction;
  }

  Range visitConditionalBranch(HConditionalBranch branch) {
    var condition = branch.condition;
    // TODO(ngeoffray): Handle more condition kinds.
    if (condition is !HLess) return const Range.unbound();
    HInstruction right = condition.right;
    HInstruction left = condition.left;
    if (!left.isInteger(types)) return const Range.unbound();
    if (!right.isInteger(types)) return const Range.unbound();

    // Update the true branch to use a narrower range for [left].
    // TODO(ngeoffray): Also do it for [right].
    HInstruction instruction =
        createRangeConversion(branch.trueBranch.first, left);
    Range range = new Range(
        const MinIntValue(), ranges[right].upper - const IntValue(1));
    range = range.intersection(ranges[left]);
    ranges[instruction] = range;

    // Update the false branch to use a narrower range for [left].
    // TODO(ngeoffray): Also do it for [right].
    instruction = createRangeConversion(branch.falseBranch.first, left);
    range = new Range(ranges[right].lower, const MaxIntValue());
    range = range.intersection(ranges[left]);
    ranges[instruction] = range;

    return const Range.unbound();
  }

  Range visitRangeConversion(HRangeConversion conversion) {
    return ranges[conversion];
  }
}

/**
 * Recognizes a number of patterns in a loop update instruction and
 * tries to infer a range for the loop phi.
 */
class LoopUpdateRecognizer extends HBaseVisitor {
  final HPhi loopPhi;
  final Map<HInstruction, Range> ranges;
  final HTypeMap types;
  LoopUpdateRecognizer(this.loopPhi, this.ranges, this.types);

  Range visitAdd(HAdd operation) {
    Range range = getRangeForRecognizableOperation(operation);
    if (range == null) return const Range.unbound();
    Range initial = ranges[loopPhi.inputs[0]];
    if (range.isPositive()) {
      return new Range(initial.lower, const MaxIntValue());
    } else if (range.isNegative()) {
      return new Range(const MinIntValue(), initial.upper);
    }
    return const Range.unbound();
  }

  Range visitSubtract(HSubtract operation) {
    Range range = getRangeForRecognizableOperation(operation);
    if (range == null) return const Range.unbound();
    Range initial = ranges[loopPhi.inputs[0]];
    if (range.isPositive()) {
      return new Range(const MinIntValue(), initial.upper);
    } else if (range.isNegative()) {
      return new Range(initial.lower, const MaxIntValue());
    }
    return const Range.unbound();
  }

  Range visitPhi(HPhi phi) {
    Range phiRange;
    for (HInstruction input in phi.inputs) {
      HInstruction instruction = unwrap(input);
      // If one of the inputs is the loop phi, then we're only
      // interested in the other inputs: a loop phi feeding itself means
      // it is not being updated.
      if (instruction == loopPhi) continue;

      // If another loop phi is involved, it's too complex to analyze.
      if (instruction is HPhi && instruction.block.isLoopHeader()) return null;

      Range inputRange = instruction.accept(this);
      if (inputRange == null) return null;
      if (phiRange == null) {
        phiRange = inputRange;
      } else {
        phiRange = phiRange.union(inputRange);
      }
    }
    return phiRange;
  }

  /**
   * If [operation] is recognizable, returns the inferred range.
   * Otherwise returns [null].
   */
  Range getRangeForRecognizableOperation(HBinaryArithmetic operation) {
    if (!operation.left.isInteger(types)) return null;
    if (!operation.right.isInteger(types)) return null;
    HInstruction left = unwrap(operation.left);
    HInstruction right = unwrap(operation.right);
    // We only recognize operations that operate on the loop phi.
    bool isLeftLoopPhi = (left == loopPhi);
    bool isRightLoopPhi = (right == loopPhi);
    if (!isLeftLoopPhi && !isRightLoopPhi) return null;

    var other = isLeftLoopPhi ? right : left;
    // If the analysis already computed range for the update, use it.
    if (ranges[other] != null) return ranges[other];

    // We currently only handle constants in updates if the
    // update does not have a range.
    if (other.isConstant()) {
      Value value = new IntValue(other.constant.value);
      return new Range(value, value);
    }
    return null;
  }

  /**
   * [HCheck] instructions may check the loop phi. Since we only
   * recognize updates on the loop phi, we must [unwrap] the [HCheck]
   * instruction to check if it references the loop phi.
   */
  HInstruction unwrap(instruction) {
    if (instruction is HCheck) return unwrap(instruction.checkedInput);
    // [HPhi] might have two different [HCheck] instructions as
    // inputs, checking the same instruction.
    if (instruction is HPhi && !instruction.block.isLoopHeader()) {
      HInstruction result = unwrap(instruction.inputs[0]);
      for (int i = 1; i < instruction.inputs.length; i++) {
        if (result != unwrap(instruction.inputs[i])) return instruction;
      }
      return result;
    }
    return instruction;
  }
}
