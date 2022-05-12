// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Constant system following the semantics for Dart code that has been
/// compiled to JavaScript.
library dart2js.constant_system;

//import '../common/elements.dart' show CommonElements;
import 'common_elements_for_constants.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import 'values.dart';

const add = AddOperation();
const bitAnd = BitAndOperation();
const bitNot = BitNotOperation();
const bitOr = BitOrOperation();
const bitXor = BitXorOperation();
const booleanAnd = BooleanAndOperation();
const booleanOr = BooleanOrOperation();
const divide = DivideOperation();
const equal = EqualsOperation();
const greaterEqual = GreaterEqualOperation();
const greater = GreaterOperation();
const identity = IdentityOperation();
const ifNull = IfNullOperation();
const index = _IndexOperation();
const lessEqual = LessEqualOperation();
const less = LessOperation();
const modulo = ModuloOperation();
const multiply = MultiplyOperation();
const negate = NegateOperation();
const not = NotOperation();
const remainder = RemainderOperation();
const shiftLeft = ShiftLeftOperation();
const shiftRight = ShiftRightOperation();
const shiftRightUnsigned = ShiftRightUnsignedOperation();
const subtract = SubtractOperation();
const truncatingDivide = TruncatingDivideOperation();
const codeUnitAt = CodeUnitAtOperation();
const round = RoundOperation();
const toInt = ToIntOperation();
const abs = UnfoldedUnaryOperation('abs');

/// Returns true if [value] will turn into NaN or infinity
/// at runtime.
bool _integerBecomesNanOrInfinity(BigInt value) {
  double doubleValue = value.toDouble();
  return doubleValue.isNaN || doubleValue.isInfinite;
}

NumConstantValue _convertToJavaScriptConstant(NumConstantValue constant) {
  if (constant is IntConstantValue) {
    BigInt intValue = constant.intValue;
    if (_integerBecomesNanOrInfinity(intValue)) {
      return DoubleConstantValue(intValue.toDouble());
    }
    // If the integer loses precision with JavaScript numbers, use
    // the floored value JavaScript will use.
    BigInt floorValue = BigInt.from(intValue.toDouble());
    if (floorValue != intValue) {
      return IntConstantValue(floorValue);
    }
  } else if (constant is DoubleConstantValue) {
    double doubleValue = constant.doubleValue;
    if (!doubleValue.isInfinite &&
        !doubleValue.isNaN &&
        !constant.isMinusZero) {
      double truncated = doubleValue.truncateToDouble();
      if (truncated == doubleValue) {
        return IntConstantValue(BigInt.from(truncated));
      }
    }
  }
  return constant;
}

NumConstantValue createInt(BigInt i) =>
    _convertToJavaScriptConstant(IntConstantValue(i));

NumConstantValue createIntFromInt(int i) => createInt(BigInt.from(i));

IntConstantValue _createInt32(BigInt i) => IntConstantValue(i.toUnsigned(32));

NumConstantValue createDouble(double d) =>
    _convertToJavaScriptConstant(DoubleConstantValue(d));

StringConstantValue createString(String string) => StringConstantValue(string);

BoolConstantValue createBool(bool value) => BoolConstantValue(value);

NullConstantValue createNull() => NullConstantValue();

ListConstantValue createList(CommonElements commonElements,
    InterfaceType sourceType, List<ConstantValue> values) {
  InterfaceType type = commonElements.getConstantListTypeFor(sourceType);
  return ListConstantValue(type, values);
}

TypeConstantValue createType(CommonElements commonElements, DartType type) {
  InterfaceType instanceType = commonElements.typeLiteralType;
  return TypeConstantValue(type, instanceType);
}

/// Returns true if the [constant] is an integer at runtime.
///
/// Integer checks report true for -0.0, INFINITY, and -INFINITY.  At
/// runtime an 'X is int' check is implemented as:
///
/// typeof(X) === "number" && Math.floor(X) === X
///
/// We consistently match that runtime semantics at compile time as well.
bool isInt(ConstantValue constant) =>
    constant is IntConstantValue ||
    constant.isMinusZero ||
    constant.isPositiveInfinity ||
    constant.isNegativeInfinity;

/// Returns true if the [constant] is a double at runtime.
bool isDouble(ConstantValue constant) =>
    constant is DoubleConstantValue && !constant.isMinusZero;

/// Returns true if the [constant] is a string at runtime.
bool isString(ConstantValue constant) => constant is StringConstantValue;

/// Returns true if the [constant] is a boolean at runtime.
bool isBool(ConstantValue constant) => constant is BoolConstantValue;

/// Returns true if the [constant] is null at runtime.
bool isNull(ConstantValue constant) => constant is NullConstantValue;

bool isSubtype(DartTypes types, DartType s, DartType t) {
  // At runtime, an integer is both an integer and a double: the
  // integer type check is Math.floor, which will return true only
  // for real integers, and our double type check is 'typeof number'
  // which will return true for both integers and doubles.
  if (s == types.commonElements.intType &&
      t == types.commonElements.doubleType) {
    return true;
  }
  return types.isSubtype(s, t);
}

SetConstantValue createSet(CommonElements commonElements,
    InterfaceType sourceType, List<ConstantValue> values) {
  InterfaceType type = commonElements.getConstantSetTypeFor(sourceType);
  DartType elementType = type.typeArguments.first;
  InterfaceType mapType =
      commonElements.mapType(elementType, commonElements.nullType);
  List<NullConstantValue> nulls =
      List<NullConstantValue>.filled(values.length, const NullConstantValue());
  MapConstantValue entries = createMap(commonElements, mapType, values, nulls);
  return JavaScriptSetConstant(type, entries);
}

MapConstantValue createMap(
    CommonElements commonElements,
    InterfaceType sourceType,
    List<ConstantValue> keys,
    List<ConstantValue> values) {
  bool onlyStringKeys = keys.every((key) =>
      key is StringConstantValue &&
      key.stringValue != JavaScriptMapConstant.PROTO_PROPERTY);

  InterfaceType keysType;
  if (commonElements.dartTypes.treatAsRawType(sourceType)) {
    keysType = commonElements.listType();
  } else {
    keysType = commonElements.listType(sourceType.typeArguments.first);
  }
  ListConstantValue keysList = createList(commonElements, keysType, keys);
  InterfaceType type = commonElements.getConstantMapTypeFor(sourceType,
      onlyStringKeys: onlyStringKeys);
  return JavaScriptMapConstant(type, keysList, values, onlyStringKeys);
}

ConstructedConstantValue createSymbol(
    CommonElements commonElements, String text) {
  InterfaceType type = commonElements.symbolImplementationType;
  FieldEntity field = commonElements.symbolField;
  ConstantValue argument = createString(text);
  // TODO(johnniwinther): Use type arguments when all uses no longer expect
  // a [FieldElement].
  var fields = <FieldEntity, ConstantValue>{field: argument};
  return ConstructedConstantValue(type, fields);
}

abstract class Operation {
  String get name;
}

abstract class UnaryOperation extends Operation {
  /// Returns [:null:] if it was unable to fold the operation.
  ConstantValue? fold(ConstantValue constant);
}

abstract class BinaryOperation extends Operation {
  /// Returns [:null:] if it was unable to fold the operation.
  ConstantValue? fold(ConstantValue left, ConstantValue right);
  apply(left, right);
}

class BitNotOperation implements UnaryOperation {
  @override
  final String name = '~';

  const BitNotOperation();

  @override
  IntConstantValue? fold(ConstantValue constant) {
    if (isInt(constant)) {
      // In JavaScript we don't check for -0 and treat it as if it was zero.
      if (constant.isMinusZero) {
        constant = createInt(BigInt.zero);
      }
      if (constant is IntConstantValue) {
        // Bit-operations yield 32-bit unsigned integers.
        return _createInt32(~constant.intValue);
      }
    }
    return null;
  }
}

class NegateOperation implements UnaryOperation {
  @override
  final String name = 'negate';

  const NegateOperation();

  @override
  NumConstantValue? fold(ConstantValue constant) {
    NumConstantValue? _fold(ConstantValue constant) {
      if (constant is IntConstantValue) {
        return createInt(-constant.intValue);
      }
      if (constant is DoubleConstantValue) {
        return createDouble(-constant.doubleValue);
      }
      return null;
    }

    if (constant is IntConstantValue) {
      if (constant.intValue == BigInt.zero) {
        return createDouble(-0.0);
      }
    }
    return _fold(constant);
  }
}

class NotOperation implements UnaryOperation {
  @override
  final String name = '!';

  const NotOperation();

  @override
  BoolConstantValue? fold(ConstantValue constant) {
    if (constant is BoolConstantValue) {
      return createBool(!constant.boolValue);
    }
    return null;
  }
}

/// Operations that only work if both arguments are integers.
abstract class BinaryBitOperation implements BinaryOperation {
  const BinaryBitOperation();

  @override
  IntConstantValue? fold(ConstantValue left, ConstantValue right) {
    IntConstantValue? _fold(ConstantValue left, ConstantValue right) {
      if (left is IntConstantValue && right is IntConstantValue) {
        BigInt? resultValue = foldInts(left.intValue, right.intValue);
        if (resultValue == null) return null;
        return createInt(resultValue) as IntConstantValue;
      }
      return null;
    }

    // In JavaScript we don't check for -0 and treat it as if it was zero.
    if (left.isMinusZero) {
      left = createInt(BigInt.zero);
    }
    if (right.isMinusZero) {
      right = createInt(BigInt.zero);
    }
    IntConstantValue? result = _fold(left, right);
    if (result != null) {
      // We convert the result of bit-operations to 32 bit unsigned integers.
      return _createInt32(result.intValue);
    }
    return result;
  }

  BigInt? foldInts(BigInt left, BigInt right);
}

class BitAndOperation extends BinaryBitOperation {
  @override
  final String name = '&';

  const BitAndOperation();

  @override
  BigInt foldInts(BigInt left, BigInt right) => left & right;

  @override
  apply(left, right) => left & right;
}

class BitOrOperation extends BinaryBitOperation {
  @override
  final String name = '|';

  const BitOrOperation();

  @override
  BigInt foldInts(BigInt left, BigInt right) => left | right;

  @override
  apply(left, right) => left | right;
}

class BitXorOperation extends BinaryBitOperation {
  @override
  final String name = '^';

  const BitXorOperation();

  @override
  BigInt foldInts(BigInt left, BigInt right) => left ^ right;

  @override
  apply(left, right) => left ^ right;
}

class ShiftLeftOperation extends BinaryBitOperation {
  @override
  final String name = '<<';

  const ShiftLeftOperation();

  @override
  BigInt? foldInts(BigInt left, BigInt right) {
    // TODO(floitsch): find a better way to guard against excessive shifts to
    // the left.
    if (right > BigInt.from(100) || right < BigInt.zero) return null;
    return left << right.toInt();
  }

  @override
  apply(left, right) => left << right;
}

class ShiftRightOperation extends BinaryBitOperation {
  @override
  final String name = '>>';

  const ShiftRightOperation();

  @override
  IntConstantValue? fold(ConstantValue left, ConstantValue right) {
    // Truncate the input value to 32 bits. The web implementation of '>>' is a
    // signed shift for negative values, and an unsigned for shift for
    // non-negative values.
    ConstantValue adjustedLeft = left;
    if (left is IntConstantValue) {
      BigInt value = left.intValue;
      BigInt truncated =
          value.isNegative ? value.toSigned(32) : value.toUnsigned(32);
      if (value != truncated) {
        adjustedLeft = createInt(truncated);
      }
    }
    return super.fold(adjustedLeft, right);
  }

  @override
  BigInt? foldInts(BigInt left, BigInt right) {
    if (right < BigInt.zero) return null;
    return left >> right.toInt();
  }

  @override
  apply(left, right) => left >> right;
}

class ShiftRightUnsignedOperation extends BinaryBitOperation {
  @override
  final String name = '>>>';

  const ShiftRightUnsignedOperation();

  @override
  BigInt? foldInts(BigInt left, BigInt right) {
    if (right < BigInt.zero) return null;
    return left.toUnsigned(32) >> right.toInt();
  }

  @override
  apply(left, right) {
    throw UnimplementedError('ShiftRightUnsignedOperation.apply');
  }
}

abstract class BinaryBoolOperation implements BinaryOperation {
  const BinaryBoolOperation();

  @override
  BoolConstantValue? fold(ConstantValue left, ConstantValue right) {
    if (left is BoolConstantValue && right is BoolConstantValue) {
      bool resultValue = foldBools(left.boolValue, right.boolValue);
      return createBool(resultValue);
    }
    return null;
  }

  bool foldBools(bool left, bool right);
}

class BooleanAndOperation extends BinaryBoolOperation {
  @override
  final String name = '&&';

  const BooleanAndOperation();

  @override
  bool foldBools(bool left, bool right) => left && right;

  @override
  apply(left, right) => left && right;
}

class BooleanOrOperation extends BinaryBoolOperation {
  @override
  final String name = '||';

  const BooleanOrOperation();

  @override
  bool foldBools(bool left, bool right) => left || right;

  @override
  apply(left, right) => left || right;
}

abstract class ArithmeticNumOperation implements BinaryOperation {
  const ArithmeticNumOperation();

  @override
  NumConstantValue? fold(ConstantValue left, ConstantValue right) {
    NumConstantValue? _fold(ConstantValue left, ConstantValue right) {
      if (left is NumConstantValue && right is NumConstantValue) {
        var foldedValue;
        if (left is IntConstantValue && right is IntConstantValue) {
          foldedValue = foldInts(left.intValue, right.intValue);
        } else {
          foldedValue = foldNums(left.doubleValue, right.doubleValue);
        }
        // A division by 0 means that we might not have a folded value.
        if (foldedValue == null) return null;
        if (left is IntConstantValue &&
                right is IntConstantValue &&
                !isDivide() ||
            isTruncatingDivide()) {
          assert(foldedValue is BigInt);
          return createInt(foldedValue);
        } else {
          return createDouble(foldedValue);
        }
      }
      return null;
    }

    NumConstantValue? result = _fold(left, right);
    if (result == null) return result;
    return _convertToJavaScriptConstant(result);
  }

  bool isDivide() => false;
  bool isTruncatingDivide() => false;
  foldInts(BigInt left, BigInt right);
  foldNums(num left, num right);
}

class SubtractOperation extends ArithmeticNumOperation {
  @override
  final String name = '-';

  const SubtractOperation();

  @override
  BigInt foldInts(BigInt left, BigInt right) => left - right;

  @override
  num foldNums(num left, num right) => left - right;

  @override
  apply(left, right) => left - right;
}

class MultiplyOperation extends ArithmeticNumOperation {
  @override
  final String name = '*';

  const MultiplyOperation();

  @override
  BigInt foldInts(BigInt left, BigInt right) => left * right;

  @override
  num foldNums(num left, num right) => left * right;

  @override
  apply(left, right) => left * right;
}

class ModuloOperation extends ArithmeticNumOperation {
  @override
  final String name = '%';

  const ModuloOperation();

  @override
  BigInt? foldInts(BigInt left, BigInt right) {
    if (right == BigInt.zero) return null;
    return left % right;
  }

  @override
  num foldNums(num left, num right) => left % right;

  @override
  apply(left, right) => left % right;
}

class RemainderOperation extends ArithmeticNumOperation {
  @override
  final String name = 'remainder';

  const RemainderOperation();

  @override
  BigInt? foldInts(BigInt left, BigInt right) {
    if (right == BigInt.zero) return null;
    return left.remainder(right);
  }

  @override
  num foldNums(num left, num right) => left.remainder(right);

  @override
  apply(left, right) => left.remainder(right);
}

class TruncatingDivideOperation extends ArithmeticNumOperation {
  @override
  final String name = '~/';

  const TruncatingDivideOperation();

  @override
  BigInt? foldInts(BigInt left, BigInt right) {
    if (right == BigInt.zero) return null;
    return left ~/ right;
  }

  @override
  BigInt? foldNums(num left, num right) {
    num ratio = left / right;
    if (ratio.isNaN || ratio.isInfinite) return null;
    return BigInt.from(ratio.truncateToDouble());
  }

  @override
  apply(left, right) => left ~/ right;

  @override
  bool isTruncatingDivide() => true;
}

class DivideOperation extends ArithmeticNumOperation {
  @override
  final String name = '/';

  const DivideOperation();

  @override
  double foldInts(BigInt left, BigInt right) => left / right;

  @override
  num foldNums(num left, num right) => left / right;

  @override
  bool isDivide() => true;

  @override
  apply(left, right) => left / right;
}

class AddOperation implements BinaryOperation {
  @override
  final String name = '+';

  const AddOperation();

  @override
  ConstantValue? fold(ConstantValue left, ConstantValue right) {
    ConstantValue? _fold(ConstantValue left, ConstantValue right) {
      if (left is IntConstantValue && right is IntConstantValue) {
        BigInt result = left.intValue + right.intValue;
        return createInt(result);
      } else if (left is NumConstantValue && right is NumConstantValue) {
        double result = left.doubleValue + right.doubleValue;
        return createDouble(result);
      } else if (left is StringConstantValue && right is StringConstantValue) {
        String result = left.stringValue + right.stringValue;
        return createString(result);
      } else {
        return null;
      }
    }

    ConstantValue? result = _fold(left, right);
    if (result is NumConstantValue) {
      return _convertToJavaScriptConstant(result);
    }
    return result;
  }

  @override
  apply(left, right) => left + right;
}

abstract class RelationalNumOperation implements BinaryOperation {
  const RelationalNumOperation();

  @override
  BoolConstantValue? fold(ConstantValue left, ConstantValue right) {
    if (left is NumConstantValue && right is NumConstantValue) {
      bool foldedValue;
      if (left is IntConstantValue && right is IntConstantValue) {
        foldedValue = foldInts(left.intValue, right.intValue);
      } else {
        foldedValue = foldNums(left.doubleValue, right.doubleValue);
      }
      assert((foldedValue as dynamic) != null);
      return createBool(foldedValue);
    }
    return null;
  }

  bool foldInts(BigInt left, BigInt right);
  bool foldNums(num left, num right);
}

class LessOperation extends RelationalNumOperation {
  @override
  final String name = '<';

  const LessOperation();

  @override
  bool foldInts(BigInt left, BigInt right) => left < right;

  @override
  bool foldNums(num left, num right) => left < right;

  @override
  apply(left, right) => left < right;
}

class LessEqualOperation extends RelationalNumOperation {
  @override
  final String name = '<=';

  const LessEqualOperation();

  @override
  bool foldInts(BigInt left, BigInt right) => left <= right;

  @override
  bool foldNums(num left, num right) => left <= right;

  @override
  apply(left, right) => left <= right;
}

class GreaterOperation extends RelationalNumOperation {
  @override
  final String name = '>';

  const GreaterOperation();

  @override
  bool foldInts(BigInt left, BigInt right) => left > right;

  @override
  bool foldNums(num left, num right) => left > right;

  @override
  apply(left, right) => left > right;
}

class GreaterEqualOperation extends RelationalNumOperation {
  @override
  final String name = '>=';

  const GreaterEqualOperation();

  @override
  bool foldInts(BigInt left, BigInt right) => left >= right;

  @override
  bool foldNums(num left, num right) => left >= right;

  @override
  apply(left, right) => left >= right;
}

class EqualsOperation implements BinaryOperation {
  @override
  final String name = '==';

  const EqualsOperation();

  @override
  BoolConstantValue? fold(ConstantValue left, ConstantValue right) {
    // Numbers need to be treated specially because: NaN != NaN, -0.0 == 0.0,
    // and 1 == 1.0.
    if (left is IntConstantValue && right is IntConstantValue) {
      bool result = left.intValue == right.intValue;
      return createBool(result);
    }

    if (left is NumConstantValue && right is NumConstantValue) {
      bool result = left.doubleValue == right.doubleValue;
      return createBool(result);
    }

    if (left is ConstructedConstantValue) {
      if (right is NullConstantValue) {
        return createBool(false);
      }
      // Unless we know that the user-defined object does not implement the
      // equality operator we cannot fold here.
      return null;
    }

    return createBool(left == right);
  }

  @override
  apply(left, right) => left == right;
}

class IdentityOperation implements BinaryOperation {
  @override
  final String name = '===';

  const IdentityOperation();

  @override
  BoolConstantValue fold(ConstantValue left, ConstantValue right) {
    // NaNs are not identical to anything. This is a web platform departure from
    // standard Dart. If we make `identical(double.nan, double.nan)` be `true`,
    // this constant folding will be incorrect. TODOs below for cross-reference.
    // TODO(11551): Keep constant-folding consistent with `identical`.
    // TODO(42224): Keep constant-folding consistent with `identical`.
    if (left.isNaN || right.isNaN) return FalseConstantValue();

    // In JavaScript -0.0 === 0 and all doubles are equal to their integer
    // values.
    if (left is IntConstantValue && right is IntConstantValue) {
      return createBool(left.intValue == right.intValue);
    }
    if (left is NumConstantValue && right is NumConstantValue) {
      return createBool(left.doubleValue == right.doubleValue);
    }
    // For the remaining constants, if they are the same constant, they are
    // identical, otherwise not.
    return createBool(left == right);
  }

  @override
  apply(left, right) => identical(left, right);
}

class IfNullOperation implements BinaryOperation {
  @override
  final String name = '??';

  const IfNullOperation();

  @override
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    if (left is NullConstantValue) return right;
    return left;
  }

  @override
  apply(left, right) => left ?? right;
}

class CodeUnitAtOperation implements BinaryOperation {
  @override
  final String name = 'charCodeAt';

  const CodeUnitAtOperation();

  @override
  NumConstantValue? fold(ConstantValue left, ConstantValue right) {
    if (left is StringConstantValue && right is IntConstantValue) {
      String string = left.stringValue;
      int index = right.intValue.toInt();
      if (index < 0 || index >= string.length) return null;
      int value = string.codeUnitAt(index);
      return createIntFromInt(value);
    }
    return null;
  }

  @override
  apply(left, right) => left.codeUnitAt(right);
}

class RoundOperation implements UnaryOperation {
  @override
  final String name = 'round';

  const RoundOperation();

  @override
  NumConstantValue? fold(ConstantValue constant) {
    // Be careful to round() only values that do not throw on either the host or
    // target platform.
    NumConstantValue? tryToRound(double value) {
      // Due to differences between browsers, only 'round' easy cases. Avoid
      // cases where nudging the value up or down changes the answer.
      // 13 digits is safely within the ~15 digit precision of doubles.
      const severalULP = 0.0000000000001;
      // Use 'roundToDouble()' to avoid exceptions on rounding the nudged value.
      double rounded = value.roundToDouble();
      double rounded1 = (value * (1.0 + severalULP)).roundToDouble();
      double rounded2 = (value * (1.0 - severalULP)).roundToDouble();
      if (rounded != rounded1 || rounded != rounded2) return null;
      return _convertToJavaScriptConstant(
          IntConstantValue(BigInt.from(value.round())));
    }

    if (constant is IntConstantValue) {
      double value = constant.intValue.toDouble();
      if (value >= -double.maxFinite && value <= double.maxFinite) {
        return tryToRound(value);
      }
    }
    if (constant is DoubleConstantValue) {
      double value = constant.doubleValue;
      // NaN and infinities will throw.
      if (value.isNaN) return null;
      if (value.isInfinite) return null;
      return tryToRound(value);
    }
    return null;
  }
}

class ToIntOperation implements UnaryOperation {
  @override
  final String name = 'toInt';

  const ToIntOperation();

  @override
  NumConstantValue? fold(ConstantValue constant) {
    if (constant is IntConstantValue) {
      double value = constant.doubleValue;
      // The code below is written to work for any `double`, even though
      // IntConstantValue uses `BigInt`.
      // TODO(sra): IntConstantValue should wrap a `double` since we consider
      // infinities and negative zero to be `is int`.
      if (!value.isFinite) return null;
      // Ensure `(-0.0).toInt()` --> `0`.
      if (value == 0) return createIntFromInt(0);
      return constant;
    }
    // TODO(sra): Handle doubles. Note that integral-valued doubles are
    // canonicalized to IntConstantValue, so we are only missing `toInt()`
    // operations that truncate.
    return null;
  }
}

class _IndexOperation implements BinaryOperation {
  @override
  final String name = '[]';

  const _IndexOperation();

  @override
  ConstantValue? fold(ConstantValue left, ConstantValue right) {
    if (left is ListConstantValue) {
      if (right is IntConstantValue) {
        List<ConstantValue> entries = left.entries;
        if (right.isUInt32()) {
          int index = right.intValue.toInt();
          if (index >= 0 && index < entries.length) {
            return entries[index];
          }
        }
      }
    }
    if (left is MapConstantValue) {
      ConstantValue? value = left.lookup(right);
      if (value != null) return value;
      return const NullConstantValue();
    }

    return null;
  }

  @override
  apply(left, right) => throw UnsupportedError('punned indexing');
}

class UnfoldedUnaryOperation implements UnaryOperation {
  @override
  final String name;

  const UnfoldedUnaryOperation(this.name);

  @override
  ConstantValue? fold(ConstantValue constant) {
    return null;
  }
}

class JavaScriptSetConstant extends SetConstantValue {
  final MapConstantValue entries;

  JavaScriptSetConstant(InterfaceType type, this.entries)
      : super(type, entries.keys);

  @override
  List<ConstantValue> getDependencies() => [entries];
}

class JavaScriptMapConstant extends MapConstantValue {
  /// The [PROTO_PROPERTY] must not be used as normal property in any JavaScript
  /// object. It would change the prototype chain.
  static const String PROTO_PROPERTY = "__proto__";

  /// The dart class implementing constant map literals.
  static const String DART_CLASS = "ConstantMap";
  static const String DART_STRING_CLASS = "ConstantStringMap";
  static const String DART_GENERAL_CLASS = "GeneralConstantMap";
  static const String LENGTH_NAME = "_length";
  static const String JS_OBJECT_NAME = "_jsObject";
  static const String KEYS_NAME = "_keys";
  static const String JS_DATA_NAME = "_jsData";

  final ListConstantValue keyList;
  final bool onlyStringKeys;

  JavaScriptMapConstant(InterfaceType type, ListConstantValue keyList,
      List<ConstantValue> values, this.onlyStringKeys)
      : this.keyList = keyList,
        super(type, keyList.entries, values);

  @override
  List<ConstantValue> getDependencies() {
    List<ConstantValue> result = <ConstantValue>[];
    if (onlyStringKeys) {
      result.add(keyList);
    } else {
      // Add the keys individually to avoid generating an unused list constant
      // for the keys.
      result.addAll(keys);
    }
    result.addAll(values);
    return result;
  }
}
