// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Constant system following the semantics for Dart code that has been
/// compiled to JavaScript.
library dart2js.constant_system;

import '../common/elements.dart' show CommonElements;
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
  JavaScriptObjectConstantValue? indexObject = _makeStringIndex(values);
  InterfaceType type = commonElements.getConstantSetTypeFor(sourceType,
      onlyStringKeys: indexObject != null);
  return JavaScriptSetConstant(type, values, indexObject);
}

MapConstantValue createMap(
    CommonElements commonElements,
    InterfaceType sourceType,
    List<ConstantValue> keys,
    List<ConstantValue> values) {
  final JavaScriptObjectConstantValue? indexObject = _makeStringIndex(keys);
  final onlyStringKeys = indexObject != null;
  InterfaceType keysType =
      commonElements.listType(sourceType.typeArguments.first);
  InterfaceType valuesType =
      commonElements.listType(sourceType.typeArguments.last);
  ListConstantValue keysList = createList(commonElements, keysType, keys);
  ListConstantValue valuesList = createList(commonElements, valuesType, values);

  InterfaceType type = commonElements.getConstantMapTypeFor(sourceType,
      onlyStringKeys: onlyStringKeys);

  return JavaScriptMapConstant(
      type, keysList, valuesList, onlyStringKeys, indexObject);
}

JavaScriptObjectConstantValue? _makeStringIndex(List<ConstantValue> keys) {
  for (final key in keys) {
    if (key is! StringConstantValue) return null;
    if (key.stringValue == JavaScriptMapConstant.PROTO_PROPERTY) return null;
  }

  // If we generate a JavaScript Object initializer with the keys in order, are
  // the properties of the Object in the same order? If so, we can generate the
  // keys of the map using `Object.keys`, otherwise we need to provide the key
  // ordering explicitly, or sort by position at runtime, or have a Map/Set
  // subclass for the case where sorting is necessary.  For now we use the
  // general constant Map/Set for the occasional case where the order is wrong.
  if (!_valuesInObjectPropertyOrder(keys)) return null;

  return JavaScriptObjectConstantValue(
      keys, List.generate(keys.length, createIntFromInt));
}

final _numberRegExp = RegExp(r'^0$|^[1-9][0-9]*$');

/// If the values are the keys of a JavaScript Object initializer, is the result
/// of `Object.keys` in the same order as [keys]? This method may conservatively
/// return `false`.
///
/// Object keys are split into 'indexes' and 'names', with all the 'indexes'
/// before the 'names'. 'indexes' are strings that have the value of
/// `i.toString()` for some `i` from 0 up to some limit. The indexes are ordered
/// by their integer value. 'names' are in insertion order. The literal
/// `{"a":1,"10":2,"2":3,"b":4}` has `Object.keys` of `["2","10","a","b"]`
/// because `10` and `2` come before `a` and `b`.
bool _valuesInObjectPropertyOrder(List<ConstantValue> keys) {
  int lastNumber = -1;
  bool seenNonNumber = false;
  for (final key in keys) {
    if (key is! StringConstantValue) return false;
    final string = key.stringValue;
    if (_numberRegExp.hasMatch(string)) {
      // This index would move before the non-number.
      if (seenNonNumber) return false;
      // Sufficiently large digit strings are not considered to be indexes. It
      // is not clear where the cutoff is or whether it is consistent between
      // JavaScript implementations.
      if (string.length > 8) return false;
      final value = int.parse(string);
      // Adjacent indexes must be in increasing numerical order.
      if (value <= lastNumber) return false;
      lastNumber = value;
    } else {
      seenNonNumber = true;
    }
  }
  return true;
}

ConstructedConstantValue createSymbol(
    CommonElements commonElements, String text) {
  InterfaceType type = commonElements.symbolImplementationType;
  FieldEntity field = commonElements.symbolField;
  ConstantValue argument = createString(text);
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
}

class BitOrOperation extends BinaryBitOperation {
  @override
  final String name = '|';

  const BitOrOperation();

  @override
  BigInt foldInts(BigInt left, BigInt right) => left | right;
}

class BitXorOperation extends BinaryBitOperation {
  @override
  final String name = '^';

  const BitXorOperation();

  @override
  BigInt foldInts(BigInt left, BigInt right) => left ^ right;
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
}

class BooleanOrOperation extends BinaryBoolOperation {
  @override
  final String name = '||';

  const BooleanOrOperation();

  @override
  bool foldBools(bool left, bool right) => left || right;
}

abstract class ArithmeticNumOperation implements BinaryOperation {
  const ArithmeticNumOperation();

  @override
  NumConstantValue? fold(ConstantValue left, ConstantValue right) {
    NumConstantValue? _fold(ConstantValue left, ConstantValue right) {
      if (left is NumConstantValue && right is NumConstantValue) {
        Object? foldedValue;
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
          return createInt(foldedValue as BigInt);
        } else {
          return createDouble(foldedValue as double);
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
  Object? foldInts(BigInt left, BigInt right);
  Object? foldNums(num left, num right);
}

class SubtractOperation extends ArithmeticNumOperation {
  @override
  final String name = '-';

  const SubtractOperation();

  @override
  BigInt foldInts(BigInt left, BigInt right) => left - right;

  @override
  num foldNums(num left, num right) => left - right;
}

class MultiplyOperation extends ArithmeticNumOperation {
  @override
  final String name = '*';

  const MultiplyOperation();

  @override
  BigInt foldInts(BigInt left, BigInt right) => left * right;

  @override
  num foldNums(num left, num right) => left * right;
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
}

class LessEqualOperation extends RelationalNumOperation {
  @override
  final String name = '<=';

  const LessEqualOperation();

  @override
  bool foldInts(BigInt left, BigInt right) => left <= right;

  @override
  bool foldNums(num left, num right) => left <= right;
}

class GreaterOperation extends RelationalNumOperation {
  @override
  final String name = '>';

  const GreaterOperation();

  @override
  bool foldInts(BigInt left, BigInt right) => left > right;

  @override
  bool foldNums(num left, num right) => left > right;
}

class GreaterEqualOperation extends RelationalNumOperation {
  @override
  final String name = '>=';

  const GreaterEqualOperation();

  @override
  bool foldInts(BigInt left, BigInt right) => left >= right;

  @override
  bool foldNums(num left, num right) => left >= right;
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
  static const String DART_STRING_CLASS = "ConstantStringSet";
  static const String DART_GENERAL_CLASS = "GeneralConstantSet";

  /// Index for all-string Sets.
  final JavaScriptObjectConstantValue? indexObject;

  JavaScriptSetConstant(super.type, super.elements, this.indexObject);

  @override
  List<ConstantValue> getDependencies() {
    if (indexObject == null) {
      // For a general constant Set the values are emitted as a literal array.
      return [...values];
    } else {
      // For a ConstantStringSet, the index contains the elements.
      return [indexObject!];
    }
  }
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

  static const String JS_INDEX_NAME = '_jsIndex';
  static const String VALUES_NAME = '_values';

  final ListConstantValue keyList;
  final ListConstantValue valueList;
  final bool onlyStringKeys;
  final JavaScriptObjectConstantValue? indexObject;

  JavaScriptMapConstant(InterfaceType type, this.keyList, this.valueList,
      this.onlyStringKeys, this.indexObject)
      : super(type, keyList.entries, valueList.entries);

  @override
  List<ConstantValue> getDependencies() {
    if (onlyStringKeys) {
      // TODO(25230): If we use `valueList` instead of `...values`, that creates
      // a constant list that has a name in the constant pool and the list has
      // Dart type attached. The Map constant has a reference to the list. If we
      // knew that the `valueList` was the only reference to the list, we could
      // generate the array in-place and omit the type. See [here][1] for more
      // on the idea of building constants with unnamed subexpressions.
      //
      // [1]: https://github.com/dart-lang/sdk/issues/25230
      //
      // For now the values are generated in a fresh Array, so add the values.
      return [indexObject!, ...values];
    } else {
      // The general representation uses a list of key/value pairs, so add the
      // keys and values individually to avoid generating an unused list
      // constant for the keys and values.
      return [...keys, ...values];
    }
  }
}
