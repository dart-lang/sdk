// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Constant system following the semantics for Dart code that has been
/// compiled to JavaScript.
library dart2js.constant_system;

import '../common_elements.dart' show CommonElements;
import '../elements/entities.dart';
import '../elements/operators.dart';
import '../elements/types.dart';
import 'values.dart';

final _BITS32 = new BigInt.from(0xFFFFFFFF);

const add = const AddOperation();
const bitAnd = const BitAndOperation();
const bitNot = const BitNotOperation();
const bitOr = const BitOrOperation();
const bitXor = const BitXorOperation();
const booleanAnd = const BooleanAndOperation();
const booleanOr = const BooleanOrOperation();
const divide = const DivideOperation();
const equal = const EqualsOperation();
const greaterEqual = const GreaterEqualOperation();
const greater = const GreaterOperation();
const identity = const IdentityOperation();
const ifNull = const IfNullOperation();
const lessEqual = const LessEqualOperation();
const less = const LessOperation();
const modulo = const ModuloOperation();
const multiply = const MultiplyOperation();
const negate = const NegateOperation();
const not = const NotOperation();
const remainder = const RemainderOperation();
const shiftLeft = const ShiftLeftOperation();
const shiftRight = const ShiftRightOperation();
const subtract = const SubtractOperation();
const truncatingDivide = const TruncatingDivideOperation();
const codeUnitAt = const CodeUnitAtOperation();
const round = const RoundOperation();
const toInt = const ToIntOperation();
const abs = const UnfoldedUnaryOperation('abs');

/// Returns true if [value] will turn into NaN or infinity
/// at runtime.
bool _integerBecomesNanOrInfinity(BigInt value) {
  double doubleValue = value.toDouble();
  return doubleValue.isNaN || doubleValue.isInfinite;
}

NumConstantValue _convertToJavaScriptConstant(NumConstantValue constant) {
  if (constant.isInt) {
    IntConstantValue intConstant = constant;
    BigInt intValue = intConstant.intValue;
    if (_integerBecomesNanOrInfinity(intValue)) {
      return new DoubleConstantValue(intValue.toDouble());
    }
    // If the integer loses precision with JavaScript numbers, use
    // the floored version JavaScript will use.
    BigInt floorValue = new BigInt.from(intValue.toDouble());
    if (floorValue != intValue) {
      return new IntConstantValue(floorValue);
    }
  } else if (constant.isDouble) {
    DoubleConstantValue doubleResult = constant;
    double doubleValue = doubleResult.doubleValue;
    if (!doubleValue.isInfinite &&
        !doubleValue.isNaN &&
        !constant.isMinusZero) {
      double truncated = doubleValue.truncateToDouble();
      if (truncated == doubleValue) {
        return new IntConstantValue(new BigInt.from(truncated));
      }
    }
  }
  return constant;
}

NumConstantValue createInt(BigInt i) =>
    _convertToJavaScriptConstant(new IntConstantValue(i));
NumConstantValue createIntFromInt(int i) => createInt(new BigInt.from(i));
NumConstantValue _createInt32(BigInt i) => new IntConstantValue(i & _BITS32);
NumConstantValue createDouble(double d) =>
    _convertToJavaScriptConstant(new DoubleConstantValue(d));
StringConstantValue createString(String string) =>
    new StringConstantValue(string);
BoolConstantValue createBool(bool value) => new BoolConstantValue(value);
NullConstantValue createNull() => new NullConstantValue();

ListConstantValue createList(CommonElements commonElements,
    InterfaceType sourceType, List<ConstantValue> values) {
  InterfaceType type = commonElements.getConstantListTypeFor(sourceType);
  return ListConstantValue(type, values);
}

ConstantValue createType(CommonElements commonElements, DartType type) {
  InterfaceType instanceType = commonElements.typeLiteralType;
  return new TypeConstantValue(type, instanceType);
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
    constant.isInt ||
    constant.isMinusZero ||
    constant.isPositiveInfinity ||
    constant.isNegativeInfinity;

/// Returns true if the [constant] is a double at runtime.
bool isDouble(ConstantValue constant) =>
    constant.isDouble && !constant.isMinusZero;

/// Returns true if the [constant] is a string at runtime.
bool isString(ConstantValue constant) => constant.isString;

/// Returns true if the [constant] is a boolean at runtime.
bool isBool(ConstantValue constant) => constant.isBool;

/// Returns true if the [constant] is null at runtime.
bool isNull(ConstantValue constant) => constant.isNull;

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
  List<NullConstantValue> nulls = new List<NullConstantValue>.filled(
      values.length, const NullConstantValue());
  MapConstantValue entries = createMap(commonElements, mapType, values, nulls);
  return new JavaScriptSetConstant(type, entries);
}

MapConstantValue createMap(
    CommonElements commonElements,
    InterfaceType sourceType,
    List<ConstantValue> keys,
    List<ConstantValue> values) {
  bool onlyStringKeys = true;
  ConstantValue protoValue = null;
  for (int i = 0; i < keys.length; i++) {
    dynamic key = keys[i];
    if (key.isString) {
      if (key.stringValue == JavaScriptMapConstant.PROTO_PROPERTY) {
        protoValue = values[i];
      }
    } else {
      onlyStringKeys = false;
      // Don't handle __proto__ values specially in the general map case.
      protoValue = null;
      break;
    }
  }

  bool hasProtoKey = (protoValue != null);
  InterfaceType keysType;
  if (commonElements.dartTypes.treatAsRawType(sourceType)) {
    keysType = commonElements.listType();
  } else {
    keysType = commonElements.listType(sourceType.typeArguments.first);
  }
  ListConstantValue keysList = createList(commonElements, keysType, keys);
  InterfaceType type = commonElements.getConstantMapTypeFor(sourceType,
      hasProtoKey: hasProtoKey, onlyStringKeys: onlyStringKeys);
  return new JavaScriptMapConstant(
      type, keysList, values, protoValue, onlyStringKeys);
}

ConstantValue createSymbol(CommonElements commonElements, String text) {
  InterfaceType type = commonElements.symbolImplementationType;
  FieldEntity field = commonElements.symbolField;
  ConstantValue argument = createString(text);
  // TODO(johnniwinther): Use type arguments when all uses no longer expect
  // a [FieldElement].
  var fields = <FieldEntity, ConstantValue>{field: argument};
  return new ConstructedConstantValue(type, fields);
}

UnaryOperation lookupUnary(UnaryOperator operator) {
  switch (operator.kind) {
    case UnaryOperatorKind.COMPLEMENT:
      return bitNot;
    case UnaryOperatorKind.NEGATE:
      return negate;
    case UnaryOperatorKind.NOT:
      return not;
    default:
      return null;
  }
}

BinaryOperation lookupBinary(BinaryOperator operator) {
  switch (operator.kind) {
    case BinaryOperatorKind.ADD:
      return add;
    case BinaryOperatorKind.SUB:
      return subtract;
    case BinaryOperatorKind.MUL:
      return multiply;
    case BinaryOperatorKind.DIV:
      return divide;
    case BinaryOperatorKind.MOD:
      return modulo;
    case BinaryOperatorKind.IDIV:
      return truncatingDivide;
    case BinaryOperatorKind.OR:
      return bitOr;
    case BinaryOperatorKind.AND:
      return bitAnd;
    case BinaryOperatorKind.XOR:
      return bitXor;
    case BinaryOperatorKind.LOGICAL_OR:
      return booleanOr;
    case BinaryOperatorKind.LOGICAL_AND:
      return booleanAnd;
    case BinaryOperatorKind.SHL:
      return shiftLeft;
    case BinaryOperatorKind.SHR:
      return shiftRight;
    case BinaryOperatorKind.LT:
      return less;
    case BinaryOperatorKind.LTEQ:
      return lessEqual;
    case BinaryOperatorKind.GT:
      return greater;
    case BinaryOperatorKind.GTEQ:
      return greaterEqual;
    case BinaryOperatorKind.EQ:
      return equal;
    case BinaryOperatorKind.IF_NULL:
      return ifNull;
    default:
      return null;
  }
}

abstract class Operation {
  String get name;
}

abstract class UnaryOperation extends Operation {
  /// Returns [:null:] if it was unable to fold the operation.
  ConstantValue fold(ConstantValue constant);
}

abstract class BinaryOperation extends Operation {
  /// Returns [:null:] if it was unable to fold the operation.
  ConstantValue fold(ConstantValue left, ConstantValue right);
  apply(left, right);
}

class BitNotOperation implements UnaryOperation {
  @override
  final String name = '~';

  const BitNotOperation();

  @override
  ConstantValue fold(ConstantValue constant) {
    if (isInt(constant)) {
      // In JavaScript we don't check for -0 and treat it as if it was zero.
      if (constant.isMinusZero) {
        constant = createInt(BigInt.zero);
      }
      IntConstantValue intConstant = constant;
      // We convert the result of bit-operations to 32 bit unsigned integers.
      return _createInt32(~intConstant.intValue);
    }
    return null;
  }
}

class NegateOperation implements UnaryOperation {
  @override
  final String name = 'negate';

  const NegateOperation();

  @override
  ConstantValue fold(ConstantValue constant) {
    ConstantValue _fold(ConstantValue constant) {
      if (constant.isInt) {
        IntConstantValue intConstant = constant;
        return createInt(-intConstant.intValue);
      }
      if (constant.isDouble) {
        DoubleConstantValue doubleConstant = constant;
        return createDouble(-doubleConstant.doubleValue);
      }
      return null;
    }

    if (constant.isInt) {
      IntConstantValue intConstant = constant;
      if (intConstant.intValue == BigInt.zero) {
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
  ConstantValue fold(ConstantValue constant) {
    if (constant.isBool) {
      BoolConstantValue boolConstant = constant;
      return createBool(!boolConstant.boolValue);
    }
    return null;
  }
}

/// Operations that only work if both arguments are integers.
abstract class BinaryBitOperation implements BinaryOperation {
  const BinaryBitOperation();

  @override
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    ConstantValue _fold(ConstantValue left, ConstantValue right) {
      if (left.isInt && right.isInt) {
        IntConstantValue leftInt = left;
        IntConstantValue rightInt = right;
        BigInt resultValue = foldInts(leftInt.intValue, rightInt.intValue);
        if (resultValue == null) return null;
        return createInt(resultValue);
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
    IntConstantValue result = _fold(left, right);
    if (result != null) {
      // We convert the result of bit-operations to 32 bit unsigned integers.
      return _createInt32(result.intValue);
    }
    return result;
  }

  BigInt foldInts(BigInt left, BigInt right);
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
  BigInt foldInts(BigInt left, BigInt right) {
    // TODO(floitsch): find a better way to guard against excessive shifts to
    // the left.
    if (right > new BigInt.from(100) || right < BigInt.zero) return null;
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
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    // Truncate the input value to 32 bits if necessary.
    if (left.isInt) {
      IntConstantValue intConstant = left;
      BigInt value = intConstant.intValue;
      BigInt truncatedValue = value & _BITS32;
      if (value < BigInt.zero) {
        // Sign-extend if the input was negative. The current semantics don't
        // make much sense, since we only look at bit 31.
        // TODO(floitsch): we should treat the input to right shifts as
        // unsigned.

        // A 32 bit complement-two value x can be computed by:
        //    x_u - 2^32 (where x_u is its unsigned representation).
        // Example: 0xFFFFFFFF - 0x100000000 => -1.
        // We simply and with the sign-bit and multiply by two. If the sign-bit
        // was set, then the result is 0. Otherwise it will become 2^32.
        final BigInt SIGN_BIT = new BigInt.from(0x80000000);
        truncatedValue -= BigInt.two * (truncatedValue & SIGN_BIT);
      }
      if (value != truncatedValue) {
        left = createInt(truncatedValue);
      }
    }
    return super.fold(left, right);
  }

  @override
  BigInt foldInts(BigInt left, BigInt right) {
    if (right < BigInt.zero) return null;
    return left >> right.toInt();
  }

  @override
  apply(left, right) => left >> right;
}

abstract class BinaryBoolOperation implements BinaryOperation {
  const BinaryBoolOperation();

  @override
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    if (left.isBool && right.isBool) {
      BoolConstantValue leftBool = left;
      BoolConstantValue rightBool = right;
      bool resultValue = foldBools(leftBool.boolValue, rightBool.boolValue);
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
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    ConstantValue _fold(ConstantValue left, ConstantValue right) {
      if (left.isNum && right.isNum) {
        NumConstantValue leftNum = left;
        NumConstantValue rightNum = right;
        var foldedValue;
        if (left.isInt && right.isInt) {
          IntConstantValue leftInt = leftNum;
          IntConstantValue rightInt = rightNum;
          foldedValue = foldInts(leftInt.intValue, rightInt.intValue);
        } else {
          foldedValue = foldNums(leftNum.doubleValue, rightNum.doubleValue);
        }
        // A division by 0 means that we might not have a folded value.
        if (foldedValue == null) return null;
        if (left.isInt && right.isInt && !isDivide() || isTruncatingDivide()) {
          assert(foldedValue is BigInt);
          return createInt(foldedValue);
        } else {
          return createDouble(foldedValue);
        }
      }
      return null;
    }

    ConstantValue result = _fold(left, right);
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
  BigInt foldInts(BigInt left, BigInt right) {
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
  BigInt foldInts(BigInt left, BigInt right) {
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
  BigInt foldInts(BigInt left, BigInt right) {
    if (right == BigInt.zero) return null;
    return left ~/ right;
  }

  @override
  BigInt foldNums(num left, num right) {
    num ratio = left / right;
    if (ratio.isNaN || ratio.isInfinite) return null;
    return new BigInt.from(ratio.truncateToDouble());
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
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    ConstantValue _fold(ConstantValue left, ConstantValue right) {
      if (left.isInt && right.isInt) {
        IntConstantValue leftInt = left;
        IntConstantValue rightInt = right;
        BigInt result = leftInt.intValue + rightInt.intValue;
        return createInt(result);
      } else if (left.isNum && right.isNum) {
        NumConstantValue leftNum = left;
        NumConstantValue rightNum = right;
        double result = leftNum.doubleValue + rightNum.doubleValue;
        return createDouble(result);
      } else if (left.isString && right.isString) {
        StringConstantValue leftString = left;
        StringConstantValue rightString = right;
        String result = leftString.stringValue + rightString.stringValue;
        return createString(result);
      } else {
        return null;
      }
    }

    ConstantValue result = _fold(left, right);
    if (result != null && result.isNum) {
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
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    if (!left.isNum || !right.isNum) return null;
    bool foldedValue;
    if (left.isInt && right.isInt) {
      IntConstantValue leftInt = left;
      IntConstantValue rightInt = right;
      foldedValue = foldInts(leftInt.intValue, rightInt.intValue);
    } else {
      NumConstantValue leftNum = left;
      NumConstantValue rightNum = right;
      foldedValue = foldNums(leftNum.doubleValue, rightNum.doubleValue);
    }
    assert(foldedValue != null);
    return createBool(foldedValue);
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
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    // Numbers need to be treated specially because: NaN != NaN, -0.0 == 0.0,
    // and 1 == 1.0.
    if (left.isInt && right.isInt) {
      IntConstantValue leftInt = left;
      IntConstantValue rightInt = right;
      bool result = leftInt.intValue == rightInt.intValue;
      return createBool(result);
    }

    if (left.isNum && right.isNum) {
      NumConstantValue leftNum = left;
      NumConstantValue rightNum = right;
      bool result = leftNum.doubleValue == rightNum.doubleValue;
      return createBool(result);
    }

    if (left.isConstructedObject) {
      if (right.isNull) {
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
    BoolConstantValue _fold(ConstantValue left, ConstantValue right) {
      // In order to preserve runtime semantics which says that NaN !== NaN
      // don't constant fold NaN === NaN. Otherwise the output depends on
      // inlined variables and other optimizations.
      if (left.isNaN && right.isNaN) return new FalseConstantValue();
      return createBool(left == right);
    }

    BoolConstantValue result = _fold(left, right);
    if (result == null || result.boolValue) return result;
    // In JavaScript -0.0 === 0 and all doubles are equal to their integer
    // values. Furthermore NaN !== NaN.
    if (left.isInt && right.isInt) {
      IntConstantValue leftInt = left;
      IntConstantValue rightInt = right;
      return new BoolConstantValue(leftInt.intValue == rightInt.intValue);
    }
    if (left.isNum && right.isNum) {
      NumConstantValue leftNum = left;
      NumConstantValue rightNum = right;
      double leftDouble = leftNum.doubleValue;
      double rightDouble = rightNum.doubleValue;
      return new BoolConstantValue(leftDouble == rightDouble);
    }
    return result;
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
    if (left.isNull) return right;
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
  IntConstantValue fold(ConstantValue left, ConstantValue right) {
    if (left.isString && right.isInt) {
      StringConstantValue stringConstant = left;
      IntConstantValue indexConstant = right;
      String string = stringConstant.stringValue;
      int index = indexConstant.intValue.toInt();
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
  ConstantValue fold(ConstantValue constant) {
    // Be careful to round() only values that do not throw on either the host or
    // target platform.
    ConstantValue tryToRound(double value) {
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
          new IntConstantValue(new BigInt.from(value.round())));
    }

    if (constant.isInt) {
      IntConstantValue intConstant = constant;
      double value = intConstant.intValue.toDouble();
      if (value >= -double.maxFinite && value <= double.maxFinite) {
        return tryToRound(value);
      }
    }
    if (constant.isDouble) {
      DoubleConstantValue doubleConstant = constant;
      double value = doubleConstant.doubleValue;
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
  ConstantValue fold(ConstantValue constant) {
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

class UnfoldedUnaryOperation implements UnaryOperation {
  @override
  final String name;

  const UnfoldedUnaryOperation(this.name);

  @override
  ConstantValue fold(ConstantValue constant) {
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
  static const String DART_PROTO_CLASS = "ConstantProtoMap";
  static const String DART_GENERAL_CLASS = "GeneralConstantMap";
  static const String LENGTH_NAME = "_length";
  static const String JS_OBJECT_NAME = "_jsObject";
  static const String KEYS_NAME = "_keys";
  static const String PROTO_VALUE = "_protoValue";
  static const String JS_DATA_NAME = "_jsData";

  final ListConstantValue keyList;
  final ConstantValue protoValue;
  final bool onlyStringKeys;

  JavaScriptMapConstant(InterfaceType type, ListConstantValue keyList,
      List<ConstantValue> values, this.protoValue, this.onlyStringKeys)
      : this.keyList = keyList,
        super(type, keyList.entries, values);
  @override
  bool get isMap => true;

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
