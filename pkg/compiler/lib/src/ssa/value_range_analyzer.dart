// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show UnmodifiableMapView;

import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../js_model/js_world.dart' show JClosedWorld;
import 'nodes.dart';
import 'optimize.dart' show OptimizationPhase, SsaOptimizerTask;

bool _DEBUG = false;

class ValueRangeInfo {
  late final IntValue intZero;
  late final IntValue intOne;

  late final Value maxIntValue;
  late final Value minIntValue;
  late final Value unknownValue;

  ValueRangeInfo() {
    intZero = newIntValue(BigInt.zero);
    intOne = newIntValue(BigInt.one);

    maxIntValue = MaxIntValue(this);
    minIntValue = MinIntValue(this);
    unknownValue = UnknownValue(this);
  }

  IntValue newIntValue(BigInt value) {
    return IntValue(value, this);
  }

  InstructionValue newInstructionValue(HInstruction instruction) {
    return InstructionValue(instruction, this);
  }

  PositiveValue newPositiveValue(HInstruction instruction) {
    return PositiveValue(instruction, this);
  }

  Value newAddValue(Value left, Value right) {
    return AddValue(left, right, this);
  }

  Value newSubtractValue(Value left, Value right) {
    return SubtractValue(left, right, this);
  }

  Value newNegateValue(Value value) {
    return NegateValue(value, this);
  }

  Range newUnboundRange() {
    return Range.unbound(this);
  }

  Range newNormalizedRange(Value low, Value up) {
    return Range.normalize(low, up, this);
  }

  Value newMarkerValue({required bool isLower, required bool isPositive}) {
    return MarkerValue(isLower, isPositive, this);
  }
}

/// A [Value] represents both symbolic values like the value of a
/// parameter, or the length of an array, and concrete values, like
/// constants.
abstract class Value {
  final ValueRangeInfo info;
  const Value(this.info);

  Value operator +(Value other) => info.unknownValue;
  Value operator -(Value other) => info.unknownValue;
  Value operator -() => info.unknownValue;
  Value operator &(Value other) => info.unknownValue;

  Value min(Value other) {
    if (this == other) return this;
    if (other == info.minIntValue) return other;
    if (other == info.maxIntValue) return this;
    Value value = this - other;
    if (value.isPositive) return other;
    if (value.isNegative) return this;
    return info.unknownValue;
  }

  Value max(Value other) {
    if (this == other) return this;
    if (other == info.minIntValue) return this;
    if (other == info.maxIntValue) return other;
    Value value = this - other;
    if (value.isPositive) return this;
    if (value.isNegative) return other;
    return info.unknownValue;
  }

  Value replaceMarkers(Value lowerBound, Value upperBound) {
    return this;
  }

  bool get isNegative => false;
  bool get isPositive => false;
  bool get isZero => false;
}

/// An [IntValue] contains a constant integer value.
class IntValue extends Value {
  final BigInt value;

  const IntValue(this.value, info) : super(info);

  @override
  Value operator +(Value other) {
    if (other.isZero) return this;
    if (other is IntValue) {
      final constant = constant_system.add.fold(
          constant_system.createInt(value),
          constant_system.createInt(other.value));
      if (constant is IntConstantValue) {
        return info.newIntValue(constant.intValue);
      }
      return info.unknownValue;
    }
    return other + this;
  }

  @override
  Value operator -(Value other) {
    if (other.isZero) return this;
    if (other is IntValue) {
      final constant = constant_system.subtract.fold(
          constant_system.createInt(value),
          constant_system.createInt(other.value));
      if (constant is IntConstantValue) {
        return info.newIntValue(constant.intValue);
      }
      return info.unknownValue;
    }
    return -other + this;
  }

  @override
  Value operator -() {
    if (isZero) return this;
    final constant =
        constant_system.negate.fold(constant_system.createInt(value));
    if (constant is IntConstantValue) {
      return info.newIntValue(constant.intValue);
    }
    return info.unknownValue;
  }

  @override
  Value operator &(Value other) {
    if (other is IntValue) {
      final constant = constant_system.bitAnd.fold(
          constant_system.createInt(value),
          constant_system.createInt(other.value)) as IntConstantValue;
      return info.newIntValue(constant.intValue);
    }
    return info.unknownValue;
  }

  @override
  Value min(Value other) {
    if (other is IntValue) {
      return this.value < other.value ? this : other;
    }
    return other.min(this);
  }

  @override
  Value max(Value other) {
    if (other is IntValue) {
      return this.value < other.value ? other : this;
    }
    return other.max(this);
  }

  @override
  bool operator ==(other) {
    if (other is! IntValue) return false;
    return this.value == other.value;
  }

  @override
  int get hashCode => throw UnsupportedError('IntValue.hashCode');

  @override
  String toString() => 'Int($value)';
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
  MaxIntValue(super.info);
  @override
  Value operator +(Value other) => this;
  @override
  Value operator -(Value other) => this;
  @override
  Value operator -() => info.minIntValue;
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
  MinIntValue(super.info);
  @override
  Value operator +(Value other) => this;
  @override
  Value operator -(Value other) => this;
  @override
  Value operator -() => info.maxIntValue;
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
  UnknownValue(super.info);
  @override
  Value operator +(Value other) => info.unknownValue;
  @override
  Value operator -(Value other) => info.unknownValue;
  @override
  Value operator -() => info.unknownValue;
  @override
  Value min(Value other) => info.unknownValue;
  @override
  Value max(Value other) => info.unknownValue;
  @override
  bool get isNegative => false;
  @override
  bool get isPositive => false;
  @override
  String toString() => 'Unknown';
}

abstract class VariableValue extends Value {
  VariableValue(super.info);

  @override
  bool operator ==(other) => throw UnsupportedError('VariableValue.==');

  @override
  int get hashCode => throw UnsupportedError('VariableValue.hashCode');

  @override
  Value operator +(Value other) {
    if (other.isZero) return this;
    if (other is IntValue) {
      if (other.isNegative) {
        return info.newSubtractValue(this, -other);
      }
      return info.newAddValue(this, other);
    }
    if (other is VariableValue) {
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
    if (other is VariableValue) {
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
  String toString() => throw UnsupportedError('VariableValue.toString');
}

/// The [MarkerValue] class is a symbolc variable used to recognize ranges of
/// loop updates.
class MarkerValue extends VariableValue {
  /// There are two marker values in the marker range - a lower value and an
  /// upper value. [isLower] is true for the lower marker value.
  final bool isLower;
  @override
  final bool isPositive;

  MarkerValue(this.isLower, this.isPositive, super.info);

  @override
  bool operator ==(other) {
    return other is MarkerValue && isLower == other.isLower;
  }

  @override
  Value replaceMarkers(Value lowerBound, Value upperBound) {
    return isLower ? lowerBound : upperBound;
  }

  @override
  String toString() =>
      'Marker(${isLower ? "lower" : "upper"}${isPositive ? ",>=0" : ""})';
}

/// A symbolic value representing an [HInstruction].
class InstructionValue extends VariableValue {
  final HInstruction instruction;
  InstructionValue(this.instruction, super.info);

  @override
  bool operator ==(other) {
    if (other is! InstructionValue) return false;
    return this.instruction == other.instruction;
  }

  @override
  int get hashCode => throw UnsupportedError('InstructionValue.hashCode');

  @override
  String toString() => 'Instruction($instruction)';
}

/// Special value for instructions whose type is a positive integer.
class PositiveValue extends InstructionValue {
  PositiveValue(super.instruction, super.info);
  @override
  bool get isPositive => true;
}

/// Represents a binary operation on two [Value]s, where the operation did not
/// yield a canonical value.
abstract class BinaryOperationValue extends Value {
  final Value left;
  final Value right;
  BinaryOperationValue(this.left, this.right, info) : super(info);
}

class AddValue extends BinaryOperationValue {
  AddValue(super.left, super.right, super.info);

  @override
  bool operator ==(other) {
    if (other is! AddValue) return false;
    return (left == other.left && right == other.right) ||
        (left == other.right && right == other.left);
  }

  @override
  int get hashCode => throw UnsupportedError('AddValue.hashCode');

  @override
  Value operator -() => -left - right;

  @override
  Value operator +(Value other) {
    if (other.isZero) return this;
    Value value = left + other;
    if (value != info.unknownValue && value is! BinaryOperationValue) {
      return value + right;
    }
    // If the result is not simple enough, we try the same approach
    // with [right].
    value = right + other;
    if (value != info.unknownValue && value is! BinaryOperationValue) {
      return left + value;
    }
    return info.unknownValue;
  }

  @override
  Value operator -(Value other) {
    if (other.isZero) return this;
    Value value = left - other;
    if (value != info.unknownValue && value is! BinaryOperationValue) {
      return value + right;
    }
    // If the result is not simple enough, we try the same approach
    // with [right].
    value = right - other;
    if (value != info.unknownValue && value is! BinaryOperationValue) {
      return left + value;
    }
    return info.unknownValue;
  }

  @override
  Value replaceMarkers(Value lowerBound, Value upperBound) {
    final newLeft = left.replaceMarkers(lowerBound, upperBound);
    final newRight = right.replaceMarkers(lowerBound, upperBound);
    if (left == newLeft && right == newRight) return this;
    return newLeft + newRight;
  }

  @override
  bool get isNegative => left.isNegative && right.isNegative;
  @override
  bool get isPositive => left.isPositive && right.isPositive;
  @override
  String toString() => '$left + $right';
}

class SubtractValue extends BinaryOperationValue {
  SubtractValue(super.left, super.right, super.info);

  @override
  bool operator ==(other) {
    if (other is! SubtractValue) return false;
    return left == other.left && right == other.right;
  }

  @override
  int get hashCode => throw UnsupportedError('SubtractValue.hashCode');

  @override
  Value operator -() => right - left;

  @override
  Value operator +(Value other) {
    if (other.isZero) return this;
    Value value = left + other;
    if (value != info.unknownValue && value is! BinaryOperationValue) {
      return value - right;
    }
    // If the result is not simple enough, we try the same approach
    // with [right].
    value = other - right;
    if (value != info.unknownValue && value is! BinaryOperationValue) {
      return left + value;
    }
    return info.unknownValue;
  }

  @override
  Value operator -(Value other) {
    if (other.isZero) return this;
    Value value = left - other;
    if (value != info.unknownValue && value is! BinaryOperationValue) {
      return value - right;
    }
    // If the result is not simple enough, we try the same approach
    // with [right].
    value = right + other;
    if (value != info.unknownValue && value is! BinaryOperationValue) {
      return left - value;
    }
    return info.unknownValue;
  }

  @override
  Value replaceMarkers(Value lowerBound, Value upperBound) {
    final newLeft = left.replaceMarkers(lowerBound, upperBound);
    final newRight = right.replaceMarkers(lowerBound, upperBound);
    if (left == newLeft && right == newRight) return this;
    return newLeft - newRight;
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
  int get hashCode => throw UnsupportedError('Negate.hashCode');

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
  Value operator &(Value other) => info.unknownValue;

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
  Value replaceMarkers(Value lowerBound, Value upperBound) {
    final newValue = value.replaceMarkers(lowerBound, upperBound);
    if (value == newValue) return this;
    return -newValue;
  }

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
    assert(lower != info.unknownValue);
    assert(upper != info.unknownValue);
  }

  Range.unbound(ValueRangeInfo info)
      : this(info.minIntValue, info.maxIntValue, info);

  /// Checks if the given values are unknown, and creates a
  /// range that does not have any unknown values.
  Range.normalize(Value low, Value up, ValueRangeInfo info)
      : this(low == info.unknownValue ? info.minIntValue : low,
            up == info.unknownValue ? info.maxIntValue : up, info);

  Range union(Range other) {
    return info.newNormalizedRange(
        lower.min(other.lower), upper.max(other.upper));
  }

  Range intersection(Range other) {
    Value low = lower.max(other.lower);
    Value up = upper.min(other.upper);
    // If we could not compute max or min, pick a value in the two
    // ranges, with priority to [IntValue]s because they are simpler.
    if (low == info.unknownValue) {
      if (lower is IntValue)
        low = lower;
      else if (other.lower is IntValue)
        low = other.lower;
      else
        low = lower;
    }
    if (up == info.unknownValue) {
      if (upper is IntValue)
        up = upper;
      else if (other.upper is IntValue)
        up = other.upper;
      else
        up = upper;
    }
    return info.newNormalizedRange(low, up);
  }

  static Range add(Range a, Range b) => a + b;
  static Range subtract(Range a, Range b) => a - b;

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
      if (up == info.unknownValue) {
        // If we could not find a trivial bound, just try to use the
        // one that is an int.
        up = upper is IntValue ? upper : other.upper;
        // Make sure we get the same upper bound, whether it's a & b
        // or b & a.
        if (up is! IntValue && upper != other.upper) up = info.maxIntValue;
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

  Range replaceMarkers(Value lowerBound, Value upperBound) {
    final newLower = lower.replaceMarkers(lowerBound, upperBound);
    final newUpper = upper.replaceMarkers(lowerBound, upperBound);
    if (lower == newLower && upper == newUpper) return this;
    return info.newNormalizedRange(newLower, newUpper);
  }

  @override
  bool operator ==(other) {
    if (other is! Range) return false;
    return other.lower == lower && other.upper == upper;
  }

  @override
  int get hashCode => throw UnsupportedError('Range.hashCode');

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

typedef BinaryRangeOperation = Range Function(Range, Range);

/// Visits the graph in dominator order, and computes value ranges for
/// integer instructions. While visiting the graph, this phase also
/// removes unnecessary bounds checks, and comparisons that are proven
/// to be true or false.
class SsaValueRangeAnalyzer extends HBaseVisitor<Range>
    implements OptimizationPhase {
  @override
  String get name => 'SsaValueRangeAnalyzer';

  /// List of [HRangeConversion] instructions created by the phase. We
  /// save them here in order to remove them once the phase is done.
  final List<HRangeConversion> conversions = [];

  /// Value ranges for integer instructions. This map gets populated by
  /// the dominator tree visit.
  final Map<HInstruction, Range> ranges = {};

  final JClosedWorld closedWorld;
  final ValueRangeInfo info = ValueRangeInfo();
  final SsaOptimizerTask optimizer;

  late HGraph graph;

  SsaValueRangeAnalyzer(this.closedWorld, this.optimizer);

  @override
  void visitGraph(HGraph graph) {
    // Example debugging code:
    //
    //    _DEBUG = graph.element.toString().contains('(main)');

    this.graph = graph;
    visitDominatorTree(graph);
    // We remove the range conversions after visiting the graph so
    // that the graph does not get polluted with these instructions
    // only necessary for this phase.
    removeRangeConversion();
    // TODO(herhut): Find a cleaner way to pass around ranges.
    optimizer.ranges = ranges;
  }

  @override
  bool validPostcondition(HGraph graph) => true;

  void removeRangeConversion() {
    conversions.forEach((HRangeConversion instruction) {
      final block = instruction.block!;
      block.rewrite(instruction, instruction.inputs[0]);
      block.remove(instruction);
    });
  }

  @override
  void visitBasicBlock(HBasicBlock block) {
    void visit(HInstruction instruction) {
      Range range = instruction.accept(this);
      if (instruction is! HControlFlow &&
          instruction
              .isInteger(closedWorld.abstractValueDomain)
              .isDefinitelyTrue) {
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
  Range visitControlFlow(HControlFlow instruction) {
    return info.newUnboundRange();
  }

  @override
  Range visitPhi(HPhi phi) {
    if (phi.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse) {
      return info.newUnboundRange();
    }
    // Some phases may replace instructions that change the inputs of
    // this phi. Only the [SsaTypesPropagation] phase will update the
    // phi type. Play it safe by assuming the [SsaTypesPropagation]
    // phase is not necessarily run before the [ValueRangeAnalyzer].
    if (phi.inputs.any((i) =>
        i.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse)) {
      return info.newUnboundRange();
    }
    if (phi.block!.isLoopHeader()) {
      final range =
          LoopUpdateRecognizer(closedWorld, UnmodifiableMapView(ranges), info)
              .run(phi);
      if (range == null) return info.newUnboundRange();
      return range;
    }

    Range range = ranges[phi.inputs[0]]!;
    for (int i = 1; i < phi.inputs.length; i++) {
      range = range.union(ranges[phi.inputs[i]]!);
    }
    return range;
  }

  @override
  Range visitConstant(HConstant node) {
    ConstantValue constant = node.constant;
    if (constant is DeferredGlobalConstantValue) {
      constant = constant.referenced;
    }
    if (constant is! IntConstantValue ||
        node.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse) {
      return info.newUnboundRange();
    }
    NumConstantValue constantNum = constant;
    if (constantNum.isPositiveInfinity || constantNum.isNegativeInfinity) {
      return info.newUnboundRange();
    }
    if (constantNum.isMinusZero) {
      constantNum = IntConstantValue(BigInt.zero);
    }

    BigInt intValue = constantNum is IntConstantValue
        ? constantNum.intValue
        : BigInt.from(constantNum.doubleValue.toInt());
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
    final next = check.next;
    Range? indexRange = ranges[check.index];
    final lengthRange = ranges[check.length];
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
    bool belowLength = maxIndex != info.maxIntValue &&
        indexRange.upper.min(maxIndex) == indexRange.upper;

    // Check if the index is strictly below the lower bound of the length
    // range.
    belowLength = belowLength ||
        (indexRange.upper != lengthRange.lower &&
            indexRange.upper.min(lengthRange.lower) == indexRange.upper);
    if (indexRange.isPositive && belowLength) {
      final checkBlock = check.block!;
      checkBlock.rewrite(check, check.index);
      checkBlock.remove(check);
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
      if (low != info.unknownValue) {
        HInstruction instruction = createRangeConversion(next!, check.length);
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
    HInstruction instruction = createRangeConversion(next!, check.index);
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
    Range rightRange = ranges[relational.right]!;
    Range leftRange = ranges[relational.left]!;

    if (relational is HIdentity) {
      handleEqualityCheck(relational);
    } else if (applyRelationalOperation(operation, leftRange, rightRange)) {
      final block = relational.block!;
      block.rewrite(relational, graph.addConstantBool(true, closedWorld));
      block.remove(relational);
    } else if (applyRelationalOperation(
        negateOperation(operation), leftRange, rightRange)) {
      final block = relational.block!;
      block.rewrite(relational, graph.addConstantBool(false, closedWorld));
      block.remove(relational);
    }
    return info.newUnboundRange();
  }

  bool applyRelationalOperation(
      constant_system.BinaryOperation operation, Range left, Range right) {
    if (operation == const constant_system.LessOperation()) {
      return left < right;
    }
    if (operation == const constant_system.LessEqualOperation()) {
      return left <= right;
    }
    if (operation == const constant_system.GreaterOperation()) {
      return left > right;
    }
    if (operation == const constant_system.GreaterEqualOperation()) {
      return left >= right;
    }

    throw StateError('Unknown relational operation: $operation, $left, $right');
  }

  void handleEqualityCheck(HRelational node) {
    Range right = ranges[node.right]!;
    Range left = ranges[node.left]!;
    if (left.isSingleValue && right.isSingleValue && left == right) {
      final block = node.block!;
      block.rewrite(node, graph.addConstantBool(true, closedWorld));
      block.remove(node);
    }
  }

  Range handleInvokeModulo(HInvokeDynamicMethod invoke) {
    HInstruction left = invoke.inputs[1];
    HInstruction right = invoke.inputs[2];
    final divisor = ranges[right];
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
    final dividend = ranges[left];
    // If both operands are >=0, the result is >= 0 and bounded by the divisor.
    if ((dividend != null && dividend.isPositive) ||
        left
            .isPositiveInteger(closedWorld.abstractValueDomain)
            .isDefinitelyTrue) {
      final divisor = ranges[right];
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

  Range handleBinaryOperation(
      HBinaryArithmetic instruction, BinaryRangeOperation operation) {
    if (instruction
        .isInteger(closedWorld.abstractValueDomain)
        .isPotentiallyFalse) {
      return info.newUnboundRange();
    }
    return operation(ranges[instruction.left]!, ranges[instruction.right]!);
  }

  @override
  Range visitAdd(HAdd add) {
    return handleBinaryOperation(add, Range.add);
  }

  @override
  Range visitSubtract(HSubtract sub) {
    return handleBinaryOperation(sub, Range.subtract);
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
      return ranges[left]! & ranges[right]!;
    }

    Range tryComputeRange(HInstruction instruction) {
      final range = ranges[instruction]!;
      if (range.isPositive) {
        return info.newNormalizedRange(info.intZero, range.upper);
      } else if (range.isNegative) {
        return info.newNormalizedRange(range.lower, info.intZero);
      }
      return info.newUnboundRange();
    }

    if (left.isInteger(closedWorld.abstractValueDomain).isDefinitelyTrue) {
      return tryComputeRange(left);
    }
    if (right.isInteger(closedWorld.abstractValueDomain).isDefinitelyTrue) {
      return tryComputeRange(right);
    }
    return info.newUnboundRange();
  }

  @override
  Range visitCheck(HCheck instruction) {
    final range = ranges[instruction.checkedInput];
    return range ?? visitInstruction(instruction);
  }

  HInstruction createRangeConversion(
      HInstruction cursor, HInstruction instruction) {
    HRangeConversion newInstruction =
        HRangeConversion(instruction, closedWorld.abstractValueDomain.intType);
    conversions.add(newInstruction);
    cursor.block!.addBefore(cursor, newInstruction);
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
    }
    throw ArgumentError('Cannot negate $operation');
  }

  static constant_system.BinaryOperation? flipOperation(
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
          info.minIntValue, rightRange.upper - info.intOne);
    } else if (operation == const constant_system.LessEqualOperation()) {
      range = info.newNormalizedRange(info.minIntValue, rightRange.upper);
    } else if (operation == const constant_system.GreaterOperation()) {
      range = info.newNormalizedRange(
          rightRange.lower + info.intOne, info.maxIntValue);
    } else if (operation == const constant_system.GreaterEqualOperation()) {
      range = info.newNormalizedRange(rightRange.lower, info.maxIntValue);
    } else {
      range = info.newUnboundRange();
    }
    return range.intersection(leftRange);
  }

  @override
  Range visitConditionalBranch(HConditionalBranch branch) {
    HInstruction condition = branch.condition;
    // TODO(ngeoffray): Handle complex conditions.
    if (condition is HRelational) {
      if (condition is HIdentity) return info.newUnboundRange();
      HInstruction right = condition.right;
      HInstruction left = condition.left;
      if (left.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse) {
        return info.newUnboundRange();
      }
      if (right.isInteger(closedWorld.abstractValueDomain).isPotentiallyFalse) {
        return info.newUnboundRange();
      }

      final rightRange = ranges[right]!;
      final leftRange = ranges[left]!;
      constant_system.BinaryOperation operation = condition.operation();
      constant_system.BinaryOperation mirrorOp = flipOperation(operation)!;
      // Only update the true branch if this block is the only
      // predecessor.
      if (branch.trueBranch.predecessors.length == 1) {
        assert(branch.trueBranch.predecessors[0] == branch.block);
        // Update the true branch to use narrower ranges for [left] and
        // [right].
        Range range = computeConstrainedRange(operation, leftRange, rightRange);
        if (leftRange != range) {
          HInstruction instruction =
              createRangeConversion(branch.trueBranch.first!, left);
          ranges[instruction] = range;
        }

        range = computeConstrainedRange(mirrorOp, rightRange, leftRange);
        if (rightRange != range) {
          HInstruction instruction =
              createRangeConversion(branch.trueBranch.first!, right);
          ranges[instruction] = range;
        }
      }

      // Only update the false branch if this block is the only
      // predecessor.
      if (branch.falseBranch.predecessors.length == 1) {
        assert(branch.falseBranch.predecessors[0] == branch.block);
        constant_system.BinaryOperation reverse = negateOperation(operation);
        constant_system.BinaryOperation reversedMirror =
            flipOperation(reverse)!;
        // Update the false branch to use narrower ranges for [left] and
        // [right].
        Range range = computeConstrainedRange(reverse, leftRange, rightRange);
        if (leftRange != range) {
          HInstruction instruction =
              createRangeConversion(branch.falseBranch.first!, left);
          ranges[instruction] = range;
        }

        range = computeConstrainedRange(reversedMirror, rightRange, leftRange);
        if (rightRange != range) {
          HInstruction instruction =
              createRangeConversion(branch.falseBranch.first!, right);
          ranges[instruction] = range;
        }
      }

      return info.newUnboundRange();
    }
    return info.newUnboundRange();
  }

  @override
  Range visitRangeConversion(HRangeConversion conversion) {
    return ranges[conversion]!;
  }
}

/// Tries to find a range for the update instruction of a loop phi.
class LoopUpdateRecognizer extends HBaseVisitor<Range?> {
  final JClosedWorld closedWorld;
  // Ranges from outside the loop, which never contain a marker value.
  final UnmodifiableMapView<HInstruction, Range> ranges;
  final ValueRangeInfo info;

  // Ranges inside the loop which may contain marker values specific to the loop
  // phi.
  final Map<HInstruction, Range?> temporaryRanges = {};

  LoopUpdateRecognizer(this.closedWorld, this.ranges, this.info);

  Range? run(HPhi loopPhi) {
    // Create a marker range for the loop phi. This is the symbolic initial
    // value of the loop variable for one iteration.
    bool isPositive = loopPhi
        .isPositiveInteger(closedWorld.abstractValueDomain)
        .isDefinitelyTrue;
    final lowerMarker =
        info.newMarkerValue(isLower: true, isPositive: isPositive);
    final upperMarker =
        info.newMarkerValue(isLower: false, isPositive: isPositive);
    final markerRange = info.newNormalizedRange(lowerMarker, upperMarker);

    // Compute the update range as a function of the initial marker range.
    temporaryRanges[loopPhi] = markerRange;
    final updateRange = visit(loopPhi.inputs[1]);
    if (updateRange == null) return null;

    // Use 'union' to compare the marker with the loop update to find out if the
    // lower or upper value did not change.
    final deltaRange = markerRange.union(updateRange);

    // If the lower (respectively upper) value is the marker, we know the loop
    // does not change it, so we can use the [startRange]'s lower (upper) value.
    // Otherwise the lower (upper) value changes and needs to be widened to the
    // minimum (maximum) value.
    final startRange = ranges[loopPhi.inputs[0]]!;

    Value lowerLimit = isPositive ? info.intZero : info.minIntValue;
    Value upperLimit = info.maxIntValue;
    Value lowerBound =
        deltaRange.lower == lowerMarker ? startRange.lower : lowerLimit;
    Value upperBound =
        deltaRange.upper == upperMarker ? startRange.upper : upperLimit;

    // Widen the update range and union with the start range.
    final widened = updateRange.replaceMarkers(lowerBound, upperBound);
    final result = startRange.union(widened);

    if (_DEBUG) {
      print('------- ${loopPhi.sourceElement}'
          '\n    marker  $markerRange'
          '\n    update  $updateRange'
          '\n    delta   $deltaRange'
          '\n    start   $startRange'
          '\n    widened $widened'
          '\n    result= $result');
    }

    return result;
  }

  Range? visit(HInstruction instruction) {
    if (instruction
        .isInteger(closedWorld.abstractValueDomain)
        .isPotentiallyFalse) {
      return null;
    }
    Range? result = ranges[instruction];
    if (result != null) return result;
    return temporaryRanges[instruction] ??= instruction.accept(this);
  }

  @override
  Range? visitPhi(HPhi phi) {
    // If the update of a loop phi involves another loop phi, we give up.
    if (phi.block!.isLoopHeader()) return null;
    Range? phiRange;
    for (HInstruction input in phi.inputs) {
      final inputRange = visit(input);
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
  Range? visitCheck(HCheck instruction) {
    return visit(instruction.checkedInput);
  }

  @override
  Range? visitAdd(HAdd operation) {
    return handleBinaryOperation(operation, Range.add);
  }

  @override
  Range? visitSubtract(HSubtract operation) {
    return handleBinaryOperation(operation, Range.subtract);
  }

  Range? handleBinaryOperation(
      HBinaryArithmetic instruction, BinaryRangeOperation operation) {
    final leftRange = visit(instruction.left);
    final rightRange = visit(instruction.right);
    if (leftRange == null || rightRange == null) return null;
    return operation(leftRange, rightRange);
  }
}
