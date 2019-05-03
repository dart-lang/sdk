// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../world.dart' show JClosedWorld;
import 'nodes.dart';
import 'optimize.dart';

class ValueRangeInfo {
  IntValue intZero;
  IntValue intOne;

  ValueRangeInfo() {
    intZero = newIntValue(BigInt.zero);
    intOne = newIntValue(BigInt.one);
  }

  Value newIntValue(BigInt value) {
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
    return new Range(
        new MarkerValue(false, this), new MarkerValue(true, this), this);
  }
}

/// A [Value] represents both symbolic values like the value of a
/// parameter, or the length of an array, and concrete values, like
/// constants.
abstract class Value {
  final ValueRangeInfo info;
  const Value(this.info);

  Value operator +(Value other) => const UnknownValue();
  Value operator -(Value other) => const UnknownValue();
  Value operator -() => const UnknownValue();
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

/// The [MarkerValue] class is used to recognize ranges of loop
/// updates.
class MarkerValue extends Value {
  /// If [positive] is true (respectively false), the marker goes
  /// to [MaxIntValue] (respectively [MinIntValue]) when being added
  /// to a positive (respectively negative) value.
  final bool positive;

  const MarkerValue(this.positive, info) : super(info);

  @override
  Value operator +(Value other) {
    if (other.isPositive && positive) return const MaxIntValue();
    if (other.isNegative && !positive) return const MinIntValue();
    if (other is IntValue) return this;
    return const UnknownValue();
  }

  @override
  Value operator -(Value other) {
    if (other.isPositive && !positive) return const MinIntValue();
    if (other.isNegative && positive) return const MaxIntValue();
    if (other is IntValue) return this;
    return const UnknownValue();
  }
}

/// An [IntValue] contains a constant integer value.
class IntValue extends Value {
  final BigInt value;

  const IntValue(this.value, info) : super(info);

  @override
  Value operator +(dynamic other) {
    if (other.isZero) return this;
    if (other is! IntValue) return other + this;
    dynamic constant = constant_system.add.fold(
        constant_system.createInt(value),
        constant_system.createInt(other.value));
    if (!constant.isInt) return const UnknownValue();
    return info.newIntValue(constant.intValue);
  }

  @override
  Value operator -(dynamic other) {
    if (other.isZero) return this;
    if (other is! IntValue) return -other + this;
    dynamic constant = constant_system.subtract.fold(
        constant_system.createInt(value),
        constant_system.createInt(other.value));
    if (!constant.isInt) return const UnknownValue();
    return info.newIntValue(constant.intValue);
  }

  @override
  Value operator -() {
    if (isZero) return this;
    dynamic constant =
        constant_system.negate.fold(constant_system.createInt(value));
    if (!constant.isInt) return const UnknownValue();
    return info.newIntValue(constant.intValue);
  }

  @override
  Value operator &(dynamic other) {
    if (other is! IntValue) return const UnknownValue();
    dynamic constant = constant_system.bitAnd.fold(
        constant_system.createInt(value),
        constant_system.createInt(other.value));
    return info.newIntValue(constant.intValue);
  }

  @override
  Value min(dynamic other) {
    if (other is! IntValue) return other.min(this);
    return this.value < other.value ? this : other;
  }

  @override
  Value max(dynamic other) {
    if (other is! IntValue) return other.max(this);
    return this.value < other.value ? other : this;
  }

  @override
  bool operator ==(other) {
    if (other is! IntValue) return false;
    return this.value == other.value;
  }

  @override
  int get hashCode => throw new UnsupportedError('IntValue.hashCode');

  @override
  String toString() => 'IntValue $value';
  @override
  bool get isNegative => value < BigInt.zero;
  @override
  bool get isPositive => value >= BigInt.zero;
  @override
  bool get isZero => value == BigInt.zero;
}

/// The [MaxIntValue] represents the maximum value an integer can have,
/// which is currently +infinity.
class MaxIntValue extends Value {
  const MaxIntValue() : super(null);
  @override
  Value operator +(Value other) => this;
  @override
  Value operator -(Value other) => this;
  @override
  Value operator -() => const MinIntValue();
  @override
  Value min(Value other) => other;
  @override
  Value max(Value other) => this;
  @override
  String toString() => 'Max';
  @override
  bool get isNegative => false;
  @override
  bool get isPositive => true;
}

/// The [MinIntValue] represents the minimum value an integer can have,
/// which is currently -infinity.
class MinIntValue extends Value {
  const MinIntValue() : super(null);
  @override
  Value operator +(Value other) => this;
  @override
  Value operator -(Value other) => this;
  @override
  Value operator -() => const MaxIntValue();
  @override
  Value min(Value other) => this;
  @override
  Value max(Value other) => other;
  @override
  String toString() => 'Min';
  @override
  bool get isNegative => true;
  @override
  bool get isPositive => false;
}

/// The [UnknownValue] is the sentinel in our analysis to mark an
/// operation that could not be done because of too much complexity.
class UnknownValue extends Value {
  const UnknownValue() : super(null);
  @override
  Value operator +(Value other) => const UnknownValue();
  @override
  Value operator -(Value other) => const UnknownValue();
  @override
  Value operator -() => const UnknownValue();
  @override
  Value min(Value other) => const UnknownValue();
  @override
  Value max(Value other) => const UnknownValue();
  @override
  bool get isNegative => false;
  @override
  bool get isPositive => false;
  @override
  String toString() => 'Unknown';
}

/// A symbolic value representing an [HInstruction].
class InstructionValue extends Value {
  final HInstruction instruction;
  InstructionValue(this.instruction, info) : super(info);

  @override
  bool operator ==(other) {
    if (other is! InstructionValue) return false;
    return this.instruction == other.instruction;
  }

  @override
  int get hashCode => throw new UnsupportedError('InstructionValue.hashCode');

  @override
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

  @override
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

  @override
  Value operator -() {
    return info.newNegateValue(this);
  }

  @override
  bool get isNegative => false;
  @override
  bool get isPositive => false;

  @override
  String toString() => 'Instruction: $instruction';
}

/// Special value for instructions whose type is a positive integer.
class PositiveValue extends InstructionValue {
  PositiveValue(HInstruction instruction, info) : super(instruction, info);
  @override
  bool get isPositive => true;
}

/// Represents a binary operation on two [Value], where the operation
/// did not yield a canonical value.
class BinaryOperationValue extends Value {
  final Value left;
  final Value right;
  BinaryOperationValue(this.left, this.right, info) : super(info);
}

class AddValue extends BinaryOperationValue {
  AddValue(left, right, info) : super(left, right, info);

  @override
  bool operator ==(other) {
    if (other is! AddValue) return false;
    return (left == other.left && right == other.right) ||
        (left == other.right && right == other.left);
  }

  @override
  int get hashCode => throw new UnsupportedError('AddValue.hashCode');

  @override
  Value operator -() => -left - right;

  @override
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

  @override
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

  @override
  bool get isNegative => left.isNegative && right.isNegative;
  @override
  bool get isPositive => left.isPositive && right.isPositive;
  @override
  String toString() => '$left + $right';
}

class SubtractValue extends BinaryOperationValue {
  SubtractValue(left, right, info) : super(left, right, info);

  @override
  bool operator ==(other) {
    if (other is! SubtractValue) return false;
    return left == other.left && right == other.right;
  }

  @override
  int get hashCode => throw new UnsupportedError('SubtractValue.hashCode');

  @override
  Value operator -() => right - left;

  @override
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

  @override
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

  @override
  bool get isNegative => left.isNegative && right.isPositive;
  @override
  bool get isPositive => left.isPositive && right.isNegative;
  @override
  String toString() => '$left - $right';
}

class NegateValue extends Value {
  final Value value;
  NegateValue(this.value, info) : super(info);

  @override
  bool operator ==(other) {
    if (other is! NegateValue) return false;
    return value == other.value;
  }

  @override
  int get hashCode => throw new UnsupportedError('Negate.hashCode');

  @override
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

  @override
  Value operator &(Value other) => const UnknownValue();

  @override
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

  @override
  Value operator -() => value;

  @override
  bool get isNegative => value.isPositive;
  @override
  bool get isPositive => value.isNegative;
  @override
  String toString() => '-$value';
}

/// A [Range] represents the possible integer values an instruction
/// can have, from its [lower] bound to its [upper] bound, both
/// included.
class Range {
  final Value lower;
  final Value upper;
  final ValueRangeInfo info;
  Range(this.lower, this.upper, this.info) {
    assert(lower != const UnknownValue());
    assert(upper != const UnknownValue());
  }

  Range.unbound(info) : this(const MinIntValue(), const MaxIntValue(), info);

  /// Checks if the given values are unknown, and creates a
  /// range that does not have any unknown values.
  Range.normalize(Value low, Value up, info)
      : this(low == const UnknownValue() ? const MinIntValue() : low,
            up == const UnknownValue() ? const MaxIntValue() : up, info);

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
      if (lower is IntValue)
        low = lower;
      else if (other.lower is IntValue)
        low = other.lower;
      else
        low = lower;
    }
    if (up == const UnknownValue()) {
      if (upper is IntValue)
        up = upper;
      else if (other.upper is IntValue)
        up = other.upper;
      else
        up = upper;
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
    if (isSingleValue &&
        other.isSingleValue &&
        lower is IntValue &&
        other.lower is IntValue) {
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

  @override
  bool operator ==(other) {
    if (other is! Range) return false;
    return other.lower == lower && other.upper == upper;
  }

  @override
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

  @override
  String toString() => '[$lower, $upper]';
}

/// Visits the graph in dominator order, and computes value ranges for
/// integer instructions. While visiting the graph, this phase also
/// removes unnecessary bounds checks, and comparisons that are proven
/// to be true or false.
class SsaValueRangeAnalyzer extends HBaseVisitor implements OptimizationPhase {
  @override
  String get name => 'SSA value range builder';

  /// List of [HRangeConversion] instructions created by the phase. We
  /// save them here in order to remove them once the phase is done.
  final List<HRangeConversion> conversions = <HRangeConversion>[];

  /// Value ranges for integer instructions. This map gets populated by
  /// the dominator tree visit.
  final Map<HInstruction, Range> ranges = new Map<HInstruction, Range>();

  final JClosedWorld closedWorld;
  final ValueRangeInfo info;
  final SsaOptimizerTask optimizer;

  HGraph graph;

  SsaValueRangeAnalyzer(JClosedWorld closedWorld, this.optimizer)
      : info = new ValueRangeInfo(),
        this.closedWorld = closedWorld;

  @override
  void visitGraph(HGraph graph) {
    this.graph = graph;
    visitDominatorTree(graph);
    // We remove the range conversions after visiting the graph so
    // that the graph does not get polluted with these instructions
    // only necessary for this phase.
    removeRangeConversion();
    // TODO(herhut): Find a cleaner way to pass around ranges.
    optimizer.ranges = ranges;
  }

  void removeRangeConversion() {
    conversions.forEach((HRangeConversion instruction) {
      instruction.block.rewrite(instruction, instruction.inputs[0]);
      instruction.block.remove(instruction);
    });
  }

  @override
  void visitBasicBlock(HBasicBlock block) {
    void visit(HInstruction instruction) {
      Range range = instruction.accept(this);
      if (instruction
          .isInteger(closedWorld.abstractValueDomain)
          .isDefinitelyTrue) {
        assert(range != null);
        ranges[instruction] = range;
      }
    }

    block.forEachPhi(visit);
    block.forEachInstruction(visit);
  }

  @override
  Range visitInstruction(HInstruction instruction) {
    if (instruction
        .isPositiveInteger(closedWorld.abstractValueDomain)
        .isDefinitelyTrue) {
      return info.newNormalizedRange(
          info.intZero, info.newPositiveValue(instruction));
    } else if (instruction
        .isInteger(closedWorld.abstractValueDomain)
        .isDefinitelyTrue) {
      InstructionValue value = info.newInstructionValue(instruction);
      return info.newNormalizedRange(value, value);
    } else {
      return info.newUnboundRange();
    }
  }

  @override
  Range visitPhi(HPhi phi) {
    if (phi.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse)
      return info.newUnboundRange();
    // Some phases may replace instructions that change the inputs of
    // this phi. Only the [SsaTypesPropagation] phase will update the
    // phi type. Play it safe by assuming the [SsaTypesPropagation]
    // phase is not necessarily run before the [ValueRangeAnalyzer].
    if (phi.inputs.any((i) =>
        i.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse)) {
      return info.newUnboundRange();
    }
    if (phi.block.isLoopHeader()) {
      Range range =
          new LoopUpdateRecognizer(closedWorld, ranges, info).run(phi);
      if (range == null) return info.newUnboundRange();
      return range;
    }

    Range range = ranges[phi.inputs[0]];
    for (int i = 1; i < phi.inputs.length; i++) {
      range = range.union(ranges[phi.inputs[i]]);
    }
    return range;
  }

  @override
  Range visitConstant(HConstant hConstant) {
    if (hConstant
        .isInteger(closedWorld.abstractValueDomain)
        .isPotentiallyFalse) {
      return info.newUnboundRange();
    }
    ConstantValue constant = hConstant.constant;
    NumConstantValue constantNum;
    if (constant is DeferredGlobalConstantValue) {
      constantNum = constant.referenced;
    } else {
      constantNum = constant;
    }
    if (constantNum.isPositiveInfinity || constantNum.isNegativeInfinity) {
      return info.newUnboundRange();
    }
    if (constantNum.isMinusZero) {
      constantNum = new IntConstantValue(BigInt.zero);
    }

    BigInt intValue = constantNum is IntConstantValue
        ? constantNum.intValue
        : new BigInt.from(constantNum.doubleValue.toInt());
    Value value = info.newIntValue(intValue);
    return info.newNormalizedRange(value, value);
  }

  @override
  Range visitFieldGet(HFieldGet fieldGet) {
    return visitInstruction(fieldGet);
  }

  @override
  Range visitGetLength(HGetLength node) {
    PositiveValue value = info.newPositiveValue(node);
    // We know this range is above zero. To simplify the analysis, we
    // put the zero value as the lower bound of this range. This
    // allows to easily remove the second bound check in the following
    // expression: a[1] + a[0].
    return info.newNormalizedRange(info.intZero, value);
  }

  @override
  Range visitBoundsCheck(HBoundsCheck check) {
    // Save the next instruction, in case the check gets removed.
    HInstruction next = check.next;
    Range indexRange = ranges[check.index];
    Range lengthRange = ranges[check.length];
    if (indexRange == null) {
      indexRange = info.newUnboundRange();
      assert(check.index
          .isInteger(closedWorld.abstractValueDomain)
          .isPotentiallyFalse);
    }
    if (lengthRange == null) {
      // We might have lost the length range due to a type conversion that
      // asserts a non-integer type. In such a case, the program will never
      // get to this point anyway, so no need to try and refine ranges.
      return indexRange;
    }
    assert(check.length
        .isInteger(closedWorld.abstractValueDomain)
        .isDefinitelyTrue);

    // Check if the index is strictly below the upper bound of the length
    // range.
    Value maxIndex = lengthRange.upper - info.intOne;
    bool belowLength = maxIndex != const MaxIntValue() &&
        indexRange.upper.min(maxIndex) == indexRange.upper;

    // Check if the index is strictly below the lower bound of the length
    // range.
    belowLength = belowLength ||
        (indexRange.upper != lengthRange.lower &&
            indexRange.upper.min(lengthRange.lower) == indexRange.upper);
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
        HInstruction instruction = createRangeConversion(next, check.length);
        ranges[instruction] = info.newNormalizedRange(low, lengthRange.upper);
      }
    }

    // Update the range of the index if using the maximum index
    // narrows it. Use that new range for this instruction as well.
    Range newIndexRange = indexRange
        .intersection(info.newNormalizedRange(info.intZero, maxIndex));
    if (indexRange == newIndexRange) return indexRange;
    // Explicitly attach the range information to the index instruction,
    // which may be used by other instructions.  Returning the new range will
    // attach it to this instruction.
    HInstruction instruction = createRangeConversion(next, check.index);
    ranges[instruction] = newIndexRange;
    return newIndexRange;
  }

  @override
  Range visitRelational(HRelational relational) {
    HInstruction right = relational.right;
    HInstruction left = relational.left;
    if (left.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse) {
      return info.newUnboundRange();
    }
    if (right.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse) {
      return info.newUnboundRange();
    }
    constant_system.BinaryOperation operation = relational.operation();
    Range rightRange = ranges[relational.right];
    Range leftRange = ranges[relational.left];

    if (relational is HIdentity) {
      handleEqualityCheck(relational);
    } else if (operation.apply(leftRange, rightRange)) {
      relational.block
          .rewrite(relational, graph.addConstantBool(true, closedWorld));
      relational.block.remove(relational);
    } else if (negateOperation(operation).apply(leftRange, rightRange)) {
      relational.block
          .rewrite(relational, graph.addConstantBool(false, closedWorld));
      relational.block.remove(relational);
    }
    return info.newUnboundRange();
  }

  void handleEqualityCheck(HRelational node) {
    Range right = ranges[node.right];
    Range left = ranges[node.left];
    if (left.isSingleValue && right.isSingleValue && left == right) {
      node.block.rewrite(node, graph.addConstantBool(true, closedWorld));
      node.block.remove(node);
    }
  }

  Range handleInvokeModulo(HInvokeDynamicMethod invoke) {
    HInstruction left = invoke.inputs[1];
    HInstruction right = invoke.inputs[2];
    Range divisor = ranges[right];
    if (divisor != null) {
      // For Integer values we can be precise in the upper bound, so special
      // case those.
      if (left.isInteger(closedWorld.abstractValueDomain).isDefinitelyTrue &&
          right.isInteger(closedWorld.abstractValueDomain).isDefinitelyTrue) {
        if (divisor.isPositive) {
          return info.newNormalizedRange(
              info.intZero, divisor.upper - info.intOne);
        } else if (divisor.isNegative) {
          return info.newNormalizedRange(
              info.intZero, info.newNegateValue(divisor.lower) - info.intOne);
        }
      } else if (left
              .isNumber(closedWorld.abstractValueDomain)
              .isDefinitelyTrue &&
          right.isNumber(closedWorld.abstractValueDomain).isDefinitelyTrue) {
        if (divisor.isPositive) {
          return info.newNormalizedRange(info.intZero, divisor.upper);
        } else if (divisor.isNegative) {
          return info.newNormalizedRange(
              info.intZero, info.newNegateValue(divisor.lower));
        }
      }
    }
    return info.newUnboundRange();
  }

  @override
  Range visitRemainder(HRemainder instruction) {
    HInstruction left = instruction.inputs[0];
    HInstruction right = instruction.inputs[1];
    Range dividend = ranges[left];
    // If both operands are >=0, the result is >= 0 and bounded by the divisor.
    if ((dividend != null && dividend.isPositive) ||
        left
            .isPositiveInteger(closedWorld.abstractValueDomain)
            .isDefinitelyTrue) {
      Range divisor = ranges[right];
      if (divisor != null) {
        if (divisor.isPositive) {
          // For Integer values we can be precise in the upper bound.
          if (left
                  .isInteger(closedWorld.abstractValueDomain)
                  .isDefinitelyTrue &&
              right
                  .isInteger(closedWorld.abstractValueDomain)
                  .isDefinitelyTrue) {
            return info.newNormalizedRange(
                info.intZero, divisor.upper - info.intOne);
          }
          if (left.isNumber(closedWorld.abstractValueDomain).isDefinitelyTrue &&
              right
                  .isNumber(closedWorld.abstractValueDomain)
                  .isDefinitelyTrue) {
            return info.newNormalizedRange(info.intZero, divisor.upper);
          }
        }
      }
    }
    return info.newUnboundRange();
  }

  @override
  Range visitInvokeDynamicMethod(HInvokeDynamicMethod invoke) {
    if ((invoke.inputs.length == 3) && (invoke.selector.name == "%"))
      return handleInvokeModulo(invoke);
    return super.visitInvokeDynamicMethod(invoke);
  }

  Range handleBinaryOperation(HBinaryArithmetic instruction) {
    if (instruction
        .isInteger(closedWorld.abstractValueDomain)
        .isPotentiallyFalse) {
      return info.newUnboundRange();
    }
    return instruction
        .operation()
        .apply(ranges[instruction.left], ranges[instruction.right]);
  }

  @override
  Range visitAdd(HAdd add) {
    return handleBinaryOperation(add);
  }

  @override
  Range visitSubtract(HSubtract sub) {
    return handleBinaryOperation(sub);
  }

  @override
  Range visitBitAnd(HBitAnd node) {
    if (node.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse) {
      return info.newUnboundRange();
    }
    HInstruction right = node.right;
    HInstruction left = node.left;
    if (left.isInteger(closedWorld.abstractValueDomain).isDefinitelyTrue &&
        right.isInteger(closedWorld.abstractValueDomain).isDefinitelyTrue) {
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

    if (left.isInteger(closedWorld.abstractValueDomain).isDefinitelyTrue) {
      return tryComputeRange(left);
    } else if (right
        .isInteger(closedWorld.abstractValueDomain)
        .isDefinitelyTrue) {
      return tryComputeRange(right);
    }
    return info.newUnboundRange();
  }

  @override
  Range visitCheck(HCheck instruction) {
    if (ranges[instruction.checkedInput] == null) {
      return visitInstruction(instruction);
    }
    return ranges[instruction.checkedInput];
  }

  HInstruction createRangeConversion(
      HInstruction cursor, HInstruction instruction) {
    HRangeConversion newInstruction = new HRangeConversion(
        instruction, closedWorld.abstractValueDomain.intType);
    conversions.add(newInstruction);
    cursor.block.addBefore(cursor, newInstruction);
    // Update the users of the instruction dominated by [cursor] to
    // use the new instruction, that has an narrower range.
    instruction.replaceAllUsersDominatedBy(cursor, newInstruction);
    return newInstruction;
  }

  static constant_system.BinaryOperation negateOperation(
      constant_system.BinaryOperation operation) {
    if (operation == const constant_system.LessOperation()) {
      return const constant_system.GreaterEqualOperation();
    } else if (operation == const constant_system.LessEqualOperation()) {
      return const constant_system.GreaterOperation();
    } else if (operation == const constant_system.GreaterOperation()) {
      return const constant_system.LessEqualOperation();
    } else if (operation == const constant_system.GreaterEqualOperation()) {
      return const constant_system.LessOperation();
    } else {
      return null;
    }
  }

  static constant_system.BinaryOperation flipOperation(
      constant_system.BinaryOperation operation) {
    if (operation == const constant_system.LessOperation()) {
      return const constant_system.GreaterOperation();
    } else if (operation == const constant_system.LessEqualOperation()) {
      return const constant_system.GreaterEqualOperation();
    } else if (operation == const constant_system.GreaterOperation()) {
      return const constant_system.LessOperation();
    } else if (operation == const constant_system.GreaterEqualOperation()) {
      return const constant_system.LessEqualOperation();
    } else {
      return null;
    }
  }

  Range computeConstrainedRange(constant_system.BinaryOperation operation,
      Range leftRange, Range rightRange) {
    Range range;
    if (operation == const constant_system.LessOperation()) {
      range = info.newNormalizedRange(
          const MinIntValue(), rightRange.upper - info.intOne);
    } else if (operation == const constant_system.LessEqualOperation()) {
      range = info.newNormalizedRange(const MinIntValue(), rightRange.upper);
    } else if (operation == const constant_system.GreaterOperation()) {
      range = info.newNormalizedRange(
          rightRange.lower + info.intOne, const MaxIntValue());
    } else if (operation == const constant_system.GreaterEqualOperation()) {
      range = info.newNormalizedRange(rightRange.lower, const MaxIntValue());
    } else {
      range = info.newUnboundRange();
    }
    return range.intersection(leftRange);
  }

  @override
  Range visitConditionalBranch(HConditionalBranch branch) {
    dynamic condition = branch.condition;
    // TODO(ngeoffray): Handle complex conditions.
    if (condition is! HRelational) return info.newUnboundRange();
    if (condition is HIdentity) return info.newUnboundRange();
    HInstruction right = condition.right;
    HInstruction left = condition.left;
    if (left.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse) {
      return info.newUnboundRange();
    }
    if (right.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse) {
      return info.newUnboundRange();
    }

    Range rightRange = ranges[right];
    Range leftRange = ranges[left];
    constant_system.Operation operation = condition.operation();
    constant_system.Operation mirrorOp = flipOperation(operation);
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
      constant_system.Operation reverse = negateOperation(operation);
      constant_system.Operation reversedMirror = flipOperation(reverse);
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

  @override
  Range visitRangeConversion(HRangeConversion conversion) {
    return ranges[conversion];
  }
}

/// Tries to find a range for the update instruction of a loop phi.
class LoopUpdateRecognizer extends HBaseVisitor {
  final JClosedWorld closedWorld;
  final Map<HInstruction, Range> ranges;
  final ValueRangeInfo info;
  LoopUpdateRecognizer(this.closedWorld, this.ranges, this.info);

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
    if (instruction
        .isInteger(closedWorld.abstractValueDomain)
        .isPotentiallyFalse) {
      return null;
    }
    if (ranges[instruction] != null) return ranges[instruction];
    return instruction.accept(this);
  }

  @override
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

  @override
  Range visitCheck(HCheck instruction) {
    return visit(instruction.checkedInput);
  }

  @override
  Range visitAdd(HAdd operation) {
    return handleBinaryOperation(operation);
  }

  @override
  Range visitSubtract(HSubtract operation) {
    return handleBinaryOperation(operation);
  }

  Range handleBinaryOperation(HBinaryArithmetic instruction) {
    Range leftRange = visit(instruction.left);
    Range rightRange = visit(instruction.right);
    if (leftRange == null || rightRange == null) return null;
    constant_system.BinaryOperation operation = instruction.operation();
    return operation.apply(leftRange, rightRange);
  }
}
