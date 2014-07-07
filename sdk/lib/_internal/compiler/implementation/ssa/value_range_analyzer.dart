// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;


class ValueRangeInfo {
  final ConstantSystem constantSystem;

  IntValue intZero;
  IntValue intOne;

  ValueRangeInfo(this.constantSystem) {
    intZero = newIntValue(0);
    intOne = newIntValue(1);
  }

  Value newIntValue(int value) {
    return new IntValue(value, this);
  }

  Value newInstructionValue(HInstruction instruction) {
    return new InstructionValue(instruction, this);
  }

  Value newPositiveValue(HInstruction instruction) {
    return new PositiveValue(instruction, this);
  }

  Value newAddValue(Value left, Value right) {
    return new AddValue(left, right, this);
  }

  Value newSubtractValue(Value left, Value right) {
    return new SubtractValue(left, right, this);
  }

  Value newNegateValue(Value value) {
    return new NegateValue(value, this);
  }

  Range newUnboundRange() {
    return new Range.unbound(this);
  }

  Range newNormalizedRange(Value low, Value up) {
    return new Range.normalize(low, up, this);
  }

  Range newMarkerRange() {
    return new Range(new MarkerValue(false, this),
                     new MarkerValue(true, this),
                     this);
  }
}

/**
 * A [Value] represents both symbolic values like the value of a
 * parameter, or the length of an array, and concrete values, like
 * constants.
 */
abstract class Value {
  final ValueRangeInfo info;
  const Value(this.info);

  Value operator +(Value other) => const UnknownValue();
  Value operator -(Value other) => const UnknownValue();
  Value operator -()  => const UnknownValue();
  Value operator &(Value other) => const UnknownValue();

  Value min(Value other) {
    if (this == other) return this;
    if (other == const MinIntValue()) return other;
    if (other == const MaxIntValue()) return this;
    Value value = this - other;
    if (value.isPositive) return other;
    if (value.isNegative) return this;
    return const UnknownValue();
  }

  Value max(Value other) {
    if (this == other) return this;
    if (other == const MinIntValue()) return this;
    if (other == const MaxIntValue()) return other;
    Value value = this - other;
    if (value.isPositive) return this;
    if (value.isNegative) return other;
    return const UnknownValue();
  }

  bool get isNegative => false;
  bool get isPositive => false;
  bool get isZero => false;
}

/**
 * The [MarkerValue] class is used to recognize ranges of loop
 * updates.
 */
class MarkerValue extends Value {
  /// If [positive] is true (respectively false), the marker goes
  /// to [MaxIntValue] (respectively [MinIntValue]) when being added
  /// to a positive (respectively negative) value.
  final bool positive;

  const MarkerValue(this.positive, info) : super(info);

  Value operator +(Value other) {
    if (other.isPositive && positive) return const MaxIntValue();
    if (other.isNegative && !positive) return const MinIntValue();
    if (other is IntValue) return this;
    return const UnknownValue();
  }

  Value operator -(Value other) {
    if (other.isPositive && !positive) return const MinIntValue();
    if (other.isNegative && positive) return const MaxIntValue();
    if (other is IntValue) return this;
    return const UnknownValue();
  }
}

/**
 * An [IntValue] contains a constant integer value.
 */
class IntValue extends Value {
  final int value;

  const IntValue(this.value, info) : super(info);

  Value operator +(other) {
    if (other.isZero) return this;
    if (other is !IntValue) return other + this;
    ConstantSystem constantSystem = info.constantSystem;
    var constant = constantSystem.add.fold(
        constantSystem.createInt(value), constantSystem.createInt(other.value));
    if (!constant.isInt) return const UnknownValue();
    return info.newIntValue(constant.value);
  }

  Value operator -(other) {
    if (other.isZero) return this;
    if (other is !IntValue) return -other + this;
    ConstantSystem constantSystem = info.constantSystem;
    var constant = constantSystem.subtract.fold(
        constantSystem.createInt(value), constantSystem.createInt(other.value));
    if (!constant.isInt) return const UnknownValue();
    return info.newIntValue(constant.value);
  }

  Value operator -() {
    if (isZero) return this;
    ConstantSystem constantSystem = info.constantSystem;
    var constant = constantSystem.negate.fold(
        constantSystem.createInt(value));
    if (!constant.isInt) return const UnknownValue();
    return info.newIntValue(constant.value);
  }

  Value operator &(other) {
    if (other is !IntValue) return const UnknownValue();
    ConstantSystem constantSystem = info.constantSystem;
    var constant = constantSystem.bitAnd.fold(
        constantSystem.createInt(value), constantSystem.createInt(other.value));
    return info.newIntValue(constant.value);
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

  int get hashCode => throw new UnsupportedError('IntValue.hashCode');

  String toString() => 'IntValue $value';
  bool get isNegative => value < 0;
  bool get isPositive => value >= 0;
  bool get isZero => value == 0;
}

/**
 * The [MaxIntValue] represents the maximum value an integer can have,
 * which is currently +infinity.
 */
class MaxIntValue extends Value {
  const MaxIntValue() : super(null);
  Value operator +(Value other) => this;
  Value operator -(Value other) => this;
  Value operator -() => const MinIntValue();
  Value min(Value other) => other;
  Value max(Value other) => this;
  String toString() => 'Max';
  bool get isNegative => false;
  bool get isPositive => true;
}

/**
 * The [MinIntValue] represents the minimum value an integer can have,
 * which is currently -infinity.
 */
class MinIntValue extends Value {
  const MinIntValue() : super(null);
  Value operator +(Value other) => this;
  Value operator -(Value other) => this;
  Value operator -() => const MaxIntValue();
  Value min(Value other) => this;
  Value max(Value other) => other;
  String toString() => 'Min';
  bool get isNegative => true;
  bool get isPositive => false;
}

/**
 * The [UnknownValue] is the sentinel in our analysis to mark an
 * operation that could not be done because of too much complexity.
 */
class UnknownValue extends Value {
  const UnknownValue() : super(null);
  Value operator +(Value other) => const UnknownValue();
  Value operator -(Value other) => const UnknownValue();
  Value operator -() => const UnknownValue();
  Value min(Value other) => const UnknownValue();
  Value max(Value other) => const UnknownValue();
  bool get isNegative => false;
  bool get isPositive => false;
  String toString() => 'Unknown';
}

/**
 * A symbolic value representing an [HInstruction].
 */
class InstructionValue extends Value {
  final HInstruction instruction;
  InstructionValue(this.instruction, info) : super(info);

  bool operator ==(other) {
    if (other is !InstructionValue) return false;
    return this.instruction == other.instruction;
  }

  int get hashCode => throw new UnsupportedError('InstructionValue.hashCode');

  Value operator +(Value other) {
    if (other.isZero) return this;
    if (other is IntValue) {
      if (other.isNegative) {
        return info.newSubtractValue(this, -other);
      }
      return info.newAddValue(this, other);
    }
    if (other is InstructionValue) {
      return info.newAddValue(this, other);
    }
    return other + this;
  }

  Value operator -(Value other) {
    if (other.isZero) return this;
    if (this == other) return info.intZero;
    if (other is IntValue) {
      if (other.isNegative) {
        return info.newAddValue(this, -other);
      }
      return info.newSubtractValue(this, other);
    }
    if (other is InstructionValue) {
      return info.newSubtractValue(this, other);
    }
    return -other + this;
  }

  Value operator -() {
    return info.newNegateValue(this);
  }

  bool get isNegative => false;
  bool get isPositive => false;

  String toString() => 'Instruction: $instruction';
}

/**
 * Special value for instructions whose type is a positive integer.
 */
class PositiveValue extends InstructionValue {
  PositiveValue(HInstruction instruction, info) : super(instruction, info);
  bool get isPositive => true;
}

/**
 * Represents a binary operation on two [Value], where the operation
 * did not yield a canonical value.
 */
class BinaryOperationValue extends Value {
  final Value left;
  final Value right;
  BinaryOperationValue(this.left, this.right, info) : super(info);
}

class AddValue extends BinaryOperationValue {
  AddValue(left, right, info) : super(left, right, info);

  bool operator ==(other) {
    if (other is !AddValue) return false;
    return (left == other.left && right == other.right)
      || (left == other.right && right == other.left);
  }

  int get hashCode => throw new UnsupportedError('AddValue.hashCode');

  Value operator -() => -left - right;

  Value operator +(Value other) {
    if (other.isZero) return this;
    Value value = left + other;
    if (value != const UnknownValue() && value is! BinaryOperationValue) {
      return value + right;
    }
    // If the result is not simple enough, we try the same approach
    // with [right].
    value = right + other;
    if (value != const UnknownValue() && value is! BinaryOperationValue) {
      return left + value;
    }
    return const UnknownValue();
  }

  Value operator -(Value other) {
    if (other.isZero) return this;
    Value value = left - other;
    if (value != const UnknownValue() && value is! BinaryOperationValue) {
      return value + right;
    }
    // If the result is not simple enough, we try the same approach
    // with [right].
    value = right - other;
    if (value != const UnknownValue() && value is! BinaryOperationValue) {
      return left + value;
    }
    return const UnknownValue();
  }

  bool get isNegative => left.isNegative && right.isNegative;
  bool get isPositive => left.isPositive && right.isPositive;
  String toString() => '$left + $right';
}

class SubtractValue extends BinaryOperationValue {
  SubtractValue(left, right, info) : super(left, right, info);

  bool operator ==(other) {
    if (other is !SubtractValue) return false;
    return left == other.left && right == other.right;
  }

  int get hashCode => throw new UnsupportedError('SubtractValue.hashCode');

  Value operator -() => right - left;

  Value operator +(Value other) {
    if (other.isZero) return this;
    Value value = left + other;
    if (value != const UnknownValue() && value is! BinaryOperationValue) {
      return value - right;
    }
    // If the result is not simple enough, we try the same approach
    // with [right].
    value = other - right;
    if (value != const UnknownValue() && value is! BinaryOperationValue) {
      return left + value;
    }
    return const UnknownValue();
  }

  Value operator -(Value other) {
    if (other.isZero) return this;
    Value value = left - other;
    if (value != const UnknownValue() && value is! BinaryOperationValue) {
      return value - right;
    }
    // If the result is not simple enough, we try the same approach
    // with [right].
    value = right + other;
    if (value != const UnknownValue() && value is! BinaryOperationValue) {
      return left - value;
    }
    return const UnknownValue();
  }

  bool get isNegative => left.isNegative && right.isPositive;
  bool get isPositive => left.isPositive && right.isNegative;
  String toString() => '$left - $right';
}

class NegateValue extends Value {
  final Value value;
  NegateValue(this.value, info) : super(info);

  bool operator ==(other) {
    if (other is !NegateValue) return false;
    return value == other.value;
  }

  int get hashCode => throw new UnsupportedError('Negate.hashCode');

  Value operator +(other) {
    if (other.isZero) return this;
    if (other == value) return info.intZero;
    if (other is NegateValue) return this - other.value;
    if (other is IntValue) {
      if (other.isNegative) {
        return info.newSubtractValue(this, -other);
      }
      return info.newSubtractValue(other, value);
    }
    if (other is InstructionValue) {
      return info.newSubtractValue(other, value);
    }
    return other - value;
  }

  Value operator &(Value other) => const UnknownValue();

  Value operator -(other) {
    if (other.isZero) return this;
    if (other is IntValue) {
      if (other.isNegative) {
        return info.newSubtractValue(-other, value);
      }
      return info.newSubtractValue(this, other);
    }
    if (other is InstructionValue) {
      return info.newSubtractValue(this, other);
    }
    if (other is NegateValue) return this + other.value;
    return -other - value;
  }

  Value operator -() => value;

  bool get isNegative => value.isPositive;
  bool get isPositive => value.isNegative;
  String toString() => '-$value';
}

/**
 * A [Range] represents the possible integer values an instruction
 * can have, from its [lower] bound to its [upper] bound, both
 * included.
 */
class Range {
  final Value lower;
  final Value upper;
  final ValueRangeInfo info;
  Range(this.lower, this.upper, this.info) {
    assert(lower != const UnknownValue());
    assert(upper != const UnknownValue());
  }

  Range.unbound(info) : this(const MinIntValue(), const MaxIntValue(), info);

  /**
   * Checks if the given values are unknown, and creates a
   * range that does not have any unknown values.
   */
  Range.normalize(Value low, Value up, info) : this(
      low == const UnknownValue() ? const MinIntValue() : low,
      up == const UnknownValue() ? const MaxIntValue() : up,
      info);

  Range union(Range other) {
    return info.newNormalizedRange(
        lower.min(other.lower), upper.max(other.upper));
  }

  Range intersection(Range other) {
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
    return info.newNormalizedRange(low, up);
  }

  Range operator +(Range other) {
    return info.newNormalizedRange(lower + other.lower, upper + other.upper);
  }

  Range operator -(Range other) {
    return info.newNormalizedRange(lower - other.upper, upper - other.lower);
  }

  Range operator -() {
    return info.newNormalizedRange(-upper, -lower);
  }

  Range operator &(Range other) {
    if (isSingleValue
        && other.isSingleValue
        && lower is IntValue
        && other.lower is IntValue) {
      return info.newNormalizedRange(lower & other.lower, upper & other.upper);
    }
    if (isPositive && other.isPositive) {
      Value up = upper.min(other.upper);
      if (up == const UnknownValue()) {
        // If we could not find a trivial bound, just try to use the
        // one that is an int.
        up = upper is IntValue ? upper : other.upper;
        // Make sure we get the same upper bound, whether it's a & b
        // or b & a.
        if (up is! IntValue && upper != other.upper) up = const MaxIntValue();
      }
      return info.newNormalizedRange(info.intZero, up);
    } else if (isPositive) {
      return info.newNormalizedRange(info.intZero, upper);
    } else if (other.isPositive) {
      return info.newNormalizedRange(info.intZero, other.upper);
    } else {
      return info.newUnboundRange();
    }
  }

  bool operator ==(other) {
    if (other is! Range) return false;
    return other.lower == lower && other.upper == upper;
  }

  int get hashCode => throw new UnsupportedError('Range.hashCode');

  bool operator <(Range other) {
    return upper != other.lower && upper.min(other.lower) == upper;
  }

  bool operator >(Range other) {
    return lower != other.upper && lower.max(other.upper) == lower;
  }

  bool operator <=(Range other) {
    return upper.min(other.lower) == upper;
  }

  bool operator >=(Range other) {
    return lower.max(other.upper) == lower;
  }

  bool get isNegative => upper.isNegative;
  bool get isPositive => lower.isPositive;
  bool get isSingleValue => lower == upper;

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

  final Compiler compiler;
  final ConstantSystem constantSystem;
  final ValueRangeInfo info;

  CodegenWorkItem work;
  HGraph graph;

  SsaValueRangeAnalyzer(this.compiler, constantSystem, this.work)
      : info = new ValueRangeInfo(constantSystem),
        this.constantSystem = constantSystem;

  void visitGraph(HGraph graph) {
    this.graph = graph;
    visitDominatorTree(graph);
    // We remove the range conversions after visiting the graph so
    // that the graph does not get polluted with these instructions
    // only necessary for this phase.
    removeRangeConversion();
    JavaScriptBackend backend = compiler.backend;
    // TODO(herhut): Find a cleaner way to pass around ranges.
    backend.optimizer.ranges = ranges;
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
      if (instruction.isInteger(compiler)) {
        assert(range != null);
        ranges[instruction] = range;
      }
    }

    block.forEachPhi(visit);
    block.forEachInstruction(visit);
  }

  Range visitInstruction(HInstruction instruction) {
    if (instruction.isPositiveInteger(compiler)) {
      return info.newNormalizedRange(
          info.intZero, info.newPositiveValue(instruction));
    } else if (instruction.isInteger(compiler)) {
      InstructionValue value = info.newInstructionValue(instruction);
      return info.newNormalizedRange(value, value);
    } else {
      return info.newUnboundRange();
    }
  }

  Range visitPhi(HPhi phi) {
    if (!phi.isInteger(compiler)) return info.newUnboundRange();
    // Some phases may replace instructions that change the inputs of
    // this phi. Only the [SsaTypesPropagation] phase will update the
    // phi type. Play it safe by assuming the [SsaTypesPropagation]
    // phase is not necessarily run before the [ValueRangeAnalyzer].
    if (phi.inputs.any((i) => !i.isInteger(compiler))) {
      return info.newUnboundRange();
    }
    if (phi.block.isLoopHeader()) {
      Range range = new LoopUpdateRecognizer(compiler, ranges, info).run(phi);
      if (range == null) return info.newUnboundRange();
      return range;
    }

    Range range = ranges[phi.inputs[0]];
    for (int i = 1; i < phi.inputs.length; i++) {
      range = range.union(ranges[phi.inputs[i]]);
    }
    return range;
  }

  Range visitConstant(HConstant hConstant) {
    if (!hConstant.isInteger(compiler)) return info.newUnboundRange();
    Constant constant = hConstant.constant;
    NumConstant constantNum;
    if (constant is DeferredConstant) {
      constantNum = constant.referenced;
    } else {
      constantNum = constant;
    }
    if (constantNum.isMinusZero) constantNum = new IntConstant(0);
    Value value = info.newIntValue(constantNum.value);
    return info.newNormalizedRange(value, value);
  }

  Range visitFieldGet(HFieldGet fieldGet) {
    if (!fieldGet.isInteger(compiler)) return info.newUnboundRange();
    if (!fieldGet.receiver.isIndexablePrimitive(compiler)) {
      return visitInstruction(fieldGet);
    }
    JavaScriptBackend backend = compiler.backend;
    assert(fieldGet.element == backend.jsIndexableLength);
    PositiveValue value = info.newPositiveValue(fieldGet);
    // We know this range is above zero. To simplify the analysis, we
    // put the zero value as the lower bound of this range. This
    // allows to easily remove the second bound check in the following
    // expression: a[1] + a[0].
    return info.newNormalizedRange(info.intZero, value);
  }

  Range visitBoundsCheck(HBoundsCheck check) {
    // Save the next instruction, in case the check gets removed.
    HInstruction next = check.next;
    Range indexRange = ranges[check.index];
    Range lengthRange = ranges[check.length];
    if (indexRange == null) {
      indexRange = info.newUnboundRange();
      assert(!check.index.isInteger(compiler));
    }
    assert(check.length.isInteger(compiler));

    // Check if the index is strictly below the upper bound of the length
    // range.
    Value maxIndex = lengthRange.upper - info.intOne;
    bool belowLength = maxIndex != const MaxIntValue()
        && indexRange.upper.min(maxIndex) == indexRange.upper;

    // Check if the index is strictly below the lower bound of the length
    // range.
    belowLength = belowLength
        || (indexRange.upper != lengthRange.lower
            && indexRange.upper.min(lengthRange.lower) == indexRange.upper);
    if (indexRange.isPositive && belowLength) {
      check.block.rewrite(check, check.index);
      check.block.remove(check);
    } else if (indexRange.isNegative || lengthRange < indexRange) {
      check.staticChecks = HBoundsCheck.ALWAYS_FALSE;
      // The check is always false, and whatever instruction it
      // dominates is dead code.
      return indexRange;
    } else if (indexRange.isPositive) {
      check.staticChecks = HBoundsCheck.ALWAYS_ABOVE_ZERO;
    } else if (belowLength) {
      check.staticChecks = HBoundsCheck.ALWAYS_BELOW_LENGTH;
    }

    if (indexRange.isPositive) {
      // If the test passes, we know the lower bound of the length is
      // greater or equal than the lower bound of the index.
      Value low = lengthRange.lower.max(indexRange.lower);
      if (low != const UnknownValue()) {
        HInstruction instruction =
            createRangeConversion(next, check.length);
        ranges[instruction] = info.newNormalizedRange(low, lengthRange.upper);
      }
    }

    // Update the range of the index if using the maximum index
    // narrows it. Use that new range for this instruction as well.
    Range newIndexRange = indexRange.intersection(
        info.newNormalizedRange(info.intZero, maxIndex));
    if (indexRange == newIndexRange) return indexRange;
    // Explicitly attach the range information to the index instruction,
    // which may be used by other instructions.  Returning the new range will
    // attach it to this instruction.
    HInstruction instruction = createRangeConversion(next, check.index);
    ranges[instruction] = newIndexRange;
    return newIndexRange;
  }

  Range visitRelational(HRelational relational) {
    HInstruction right = relational.right;
    HInstruction left = relational.left;
    if (!left.isInteger(compiler)) return info.newUnboundRange();
    if (!right.isInteger(compiler)) return info.newUnboundRange();
    BinaryOperation operation = relational.operation(constantSystem);
    Range rightRange = ranges[relational.right];
    Range leftRange = ranges[relational.left];

    if (relational is HIdentity) {
      handleEqualityCheck(relational);
    } else if (operation.apply(leftRange, rightRange)) {
      relational.block.rewrite(
          relational, graph.addConstantBool(true, compiler));
      relational.block.remove(relational);
    } else if (negateOperation(operation).apply(leftRange, rightRange)) {
      relational.block.rewrite(
          relational, graph.addConstantBool(false, compiler));
      relational.block.remove(relational);
    }
    return info.newUnboundRange();
  }

  void handleEqualityCheck(HRelational node) {
    Range right = ranges[node.right];
    Range left = ranges[node.left];
    if (left.isSingleValue && right.isSingleValue && left == right) {
      node.block.rewrite(
          node, graph.addConstantBool(true, compiler));
      node.block.remove(node);
    }
  }

  Range handleInvokeModulo(HInvokeDynamicMethod invoke) {
    HInstruction left = invoke.inputs[1];
    HInstruction right = invoke.inputs[2];
    Range divisor = ranges[right];
    if (divisor != null) {
      // For Integer values we can be precise in the upper bound,
      // so special case those.
      if (left.isInteger(compiler) && right.isInteger(compiler)) {
        if (divisor.isPositive) {
          return info.newNormalizedRange(info.intZero, divisor.upper -
              info.intOne);
        } else if (divisor.isNegative) {
          return info.newNormalizedRange(info.intZero, info.newNegateValue(
              divisor.lower) - info.intOne);
        }
      } else if (left.isNumber(compiler) && right.isNumber(compiler)) {
        if (divisor.isPositive) {
          return info.newNormalizedRange(info.intZero, divisor.upper);
        } else if (divisor.isNegative) {
          return info.newNormalizedRange(info.intZero, info.newNegateValue(
              divisor.lower));
        }
      }
    }
    return info.newUnboundRange();
  }

  Range visitInvokeDynamicMethod(HInvokeDynamicMethod invoke) {
    if ((invoke.inputs.length == 3) && (invoke.selector.name == "%"))
      return handleInvokeModulo(invoke);
    return super.visitInvokeDynamicMethod(invoke);
  }

  Range handleBinaryOperation(HBinaryArithmetic instruction) {
    if (!instruction.isInteger(compiler)) return info.newUnboundRange();
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
    if (!node.isInteger(compiler)) return info.newUnboundRange();
    HInstruction right = node.right;
    HInstruction left = node.left;
    if (left.isInteger(compiler) && right.isInteger(compiler)) {
      return ranges[left] & ranges[right];
    }

    Range tryComputeRange(HInstruction instruction) {
      Range range = ranges[instruction];
      if (range.isPositive) {
        return info.newNormalizedRange(info.intZero, range.upper);
      } else if (range.isNegative) {
        return info.newNormalizedRange(range.lower, info.intZero);
      }
      return info.newUnboundRange();
    }

    if (left.isInteger(compiler)) {
      return tryComputeRange(left);
    } else if (right.isInteger(compiler)) {
      return tryComputeRange(right);
    }
    return info.newUnboundRange();
  }

  Range visitCheck(HCheck instruction) {
    if (ranges[instruction.checkedInput] == null) {
      return visitInstruction(instruction);
    }
    return ranges[instruction.checkedInput];
  }

  HInstruction createRangeConversion(HInstruction cursor,
                                     HInstruction instruction) {
    JavaScriptBackend backend = compiler.backend;
    HRangeConversion newInstruction =
        new HRangeConversion(instruction, backend.intType);
    conversions.add(newInstruction);
    cursor.block.addBefore(cursor, newInstruction);
    // Update the users of the instruction dominated by [cursor] to
    // use the new instruction, that has an narrower range.
    instruction.replaceAllUsersDominatedBy(cursor, newInstruction);
    return newInstruction;
  }

  static BinaryOperation negateOperation(BinaryOperation operation) {
    if (operation == const LessOperation()) {
      return const GreaterEqualOperation();
    } else if (operation == const LessEqualOperation()) {
      return const GreaterOperation();
    } else if (operation == const GreaterOperation()) {
      return const LessEqualOperation();
    } else if (operation == const GreaterEqualOperation()) {
      return const LessOperation();
    } else {
      return null;
    }
  }

  static BinaryOperation flipOperation(BinaryOperation operation) {
    if (operation == const LessOperation()) {
      return const GreaterOperation();
    } else if (operation == const LessEqualOperation()) {
      return const GreaterEqualOperation();
    } else if (operation == const GreaterOperation()) {
      return const LessOperation();
    } else if (operation == const GreaterEqualOperation()) {
      return const LessEqualOperation();
    } else {
      return null;
    }
  }

  Range computeConstrainedRange(BinaryOperation operation,
                                Range leftRange,
                                Range rightRange) {
    Range range;
    if (operation == const LessOperation()) {
      range = info.newNormalizedRange(
          const MinIntValue(), rightRange.upper - info.intOne);
    } else if (operation == const LessEqualOperation()) {
      range = info.newNormalizedRange(const MinIntValue(), rightRange.upper);
    } else if (operation == const GreaterOperation()) {
      range = info.newNormalizedRange(
          rightRange.lower + info.intOne, const MaxIntValue());
    } else if (operation == const GreaterEqualOperation()) {
      range = info.newNormalizedRange(rightRange.lower, const MaxIntValue());
    } else {
      range = info.newUnboundRange();
    }
    return range.intersection(leftRange);
  }

  Range visitConditionalBranch(HConditionalBranch branch) {
    var condition = branch.condition;
    // TODO(ngeoffray): Handle complex conditions.
    if (condition is !HRelational) return info.newUnboundRange();
    if (condition is HIdentity) return info.newUnboundRange();
    HInstruction right = condition.right;
    HInstruction left = condition.left;
    if (!left.isInteger(compiler)) return info.newUnboundRange();
    if (!right.isInteger(compiler)) return info.newUnboundRange();

    Range rightRange = ranges[right];
    Range leftRange = ranges[left];
    Operation operation = condition.operation(constantSystem);
    Operation mirrorOp = flipOperation(operation);
    // Only update the true branch if this block is the only
    // predecessor.
    if (branch.trueBranch.predecessors.length == 1) {
      assert(branch.trueBranch.predecessors[0] == branch.block);
      // Update the true branch to use narrower ranges for [left] and
      // [right].
      Range range = computeConstrainedRange(operation, leftRange, rightRange);
      if (leftRange != range) {
        HInstruction instruction =
            createRangeConversion(branch.trueBranch.first, left);
        ranges[instruction] = range;
      }

      range = computeConstrainedRange(mirrorOp, rightRange, leftRange);
      if (rightRange != range) {
        HInstruction instruction =
            createRangeConversion(branch.trueBranch.first, right);
        ranges[instruction] = range;
      }
    }

    // Only update the false branch if this block is the only
    // predecessor.
    if (branch.falseBranch.predecessors.length == 1) {
      assert(branch.falseBranch.predecessors[0] == branch.block);
      Operation reverse = negateOperation(operation);
      Operation reversedMirror = flipOperation(reverse);
      // Update the false branch to use narrower ranges for [left] and
      // [right].
      Range range = computeConstrainedRange(reverse, leftRange, rightRange);
      if (leftRange != range) {
        HInstruction instruction =
            createRangeConversion(branch.falseBranch.first, left);
        ranges[instruction] = range;
      }

      range = computeConstrainedRange(reversedMirror, rightRange, leftRange);
      if (rightRange != range) {
        HInstruction instruction =
            createRangeConversion(branch.falseBranch.first, right);
        ranges[instruction] = range;
      }
    }

    return info.newUnboundRange();
  }

  Range visitRangeConversion(HRangeConversion conversion) {
    return ranges[conversion];
  }
}

/**
 * Tries to find a range for the update instruction of a loop phi.
 */
class LoopUpdateRecognizer extends HBaseVisitor {
  final Compiler compiler;
  final Map<HInstruction, Range> ranges;
  final ValueRangeInfo info;
  LoopUpdateRecognizer(this.compiler, this.ranges, this.info);

  Range run(HPhi loopPhi) {
    // Create a marker range for the loop phi, so that if the update
    // uses the loop phi, it has a range to use.
    ranges[loopPhi] = info.newMarkerRange();
    Range updateRange = visit(loopPhi.inputs[1]);
    ranges[loopPhi] = null;
    if (updateRange == null) return null;
    Range startRange = ranges[loopPhi.inputs[0]];
    // If the lower (respectively upper) value is the marker, we know
    // the loop does not change it, so we can just use the
    // [startRange]'s lower (upper) value. Otherwise the lower (upper) value
    // is the minimum of the [startRange]'s lower (upper) and the
    // [updateRange]'s lower (upper).
    Value low = updateRange.lower is MarkerValue
        ? startRange.lower
        : updateRange.lower.min(startRange.lower);
    Value up = updateRange.upper is MarkerValue
        ? startRange.upper
        : updateRange.upper.max(startRange.upper);
    return info.newNormalizedRange(low, up);
  }

  Range visit(HInstruction instruction) {
    if (!instruction.isInteger(compiler)) return null;
    if (ranges[instruction] != null) return ranges[instruction];
    return instruction.accept(this);
  }

  Range visitPhi(HPhi phi) {
    // If the update of a loop phi involves another loop phi, we give
    // up.
    if (phi.block.isLoopHeader()) return null;
    Range phiRange;
    for (HInstruction input in phi.inputs) {
      Range inputRange = visit(input);
      if (inputRange == null) return null;
      if (phiRange == null) {
        phiRange = inputRange;
      } else {
        phiRange = phiRange.union(inputRange);
      }
    }
    return phiRange;
  }

  Range visitCheck(HCheck instruction) {
    return visit(instruction.checkedInput);
  }

  Range visitAdd(HAdd operation) {
    return handleBinaryOperation(operation);
  }

  Range visitSubtract(HSubtract operation) {
    return handleBinaryOperation(operation);
  }

  Range handleBinaryOperation(HBinaryArithmetic instruction) {
    Range leftRange = visit(instruction.left);
    Range rightRange = visit(instruction.right);
    if (leftRange == null || rightRange == null) return null;
    BinaryOperation operation = instruction.operation(info.constantSystem);
    return operation.apply(leftRange, rightRange);
  }
}
