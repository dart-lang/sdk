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

const add = const JavaScriptAddOperation();
const bitAnd = const JavaScriptBinaryBitOperation(const BitAndOperation());
const bitNot = const BitNotOperation();
const bitOr = const JavaScriptBinaryBitOperation(const BitOrOperation());
const bitXor = const JavaScriptBinaryBitOperation(const BitXorOperation());
const booleanAnd = const BooleanAndOperation();
const booleanOr = const BooleanOrOperation();
const divide =
    const JavaScriptBinaryArithmeticOperation(const DivideOperation());
const equal = const EqualsOperation();
const greaterEqual = const GreaterEqualOperation();
const greater = const GreaterOperation();
const identity = const JavaScriptIdentityOperation();
const ifNull = const IfNullOperation();
const lessEqual = const LessEqualOperation();
const less = const LessOperation();
const modulo =
    const JavaScriptBinaryArithmeticOperation(const ModuloOperation());
const multiply =
    const JavaScriptBinaryArithmeticOperation(const MultiplyOperation());
const negate = const JavaScriptNegateOperation();
const not = const NotOperation();
const remainder = const JavaScriptRemainderOperation();
const shiftLeft =
    const JavaScriptBinaryBitOperation(const ShiftLeftOperation());
const shiftRight = const JavaScriptShiftRightOperation();
const subtract =
    const JavaScriptBinaryArithmeticOperation(const SubtractOperation());
const truncatingDivide = const JavaScriptBinaryArithmeticOperation(
    const TruncatingDivideOperation());
const codeUnitAt = const CodeUnitAtRuntimeOperation();
const round = const JavaScriptRoundOperation();
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
ListConstantValue createList(InterfaceType type, List<ConstantValue> values) =>
    new ListConstantValue(type, values);

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
  return new JavaScriptSetConstant(commonElements, type, values);
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
  if (sourceType.treatAsRaw) {
    keysType = commonElements.listType();
  } else {
    keysType = commonElements.listType(sourceType.typeArguments.first);
  }
  ListConstantValue keysList = new ListConstantValue(keysType, keys);
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
  final String name = '~';
  const BitNotOperation();

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
  final String name = 'negate';
  const NegateOperation();
  ConstantValue fold(ConstantValue constant) {
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
}

class JavaScriptNegateOperation implements UnaryOperation {
  final NegateOperation dartNegateOperation = const NegateOperation();

  const JavaScriptNegateOperation();

  String get name => dartNegateOperation.name;

  ConstantValue fold(ConstantValue constant) {
    if (constant.isInt) {
      IntConstantValue intConstant = constant;
      if (intConstant.intValue == BigInt.zero) {
        return createDouble(-0.0);
      }
    }
    return dartNegateOperation.fold(constant);
  }
}

class NotOperation implements UnaryOperation {
  final String name = '!';
  const NotOperation();
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
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    if (left.isInt && right.isInt) {
      IntConstantValue leftInt = left;
      IntConstantValue rightInt = right;
      BigInt resultValue = foldInts(leftInt.intValue, rightInt.intValue);
      if (resultValue == null) return null;
      return createInt(resultValue);
    }
    return null;
  }

  BigInt foldInts(BigInt left, BigInt right);
}

/// In JavaScript we truncate the result to an unsigned 32 bit integer. Also, -0
/// is treated as if it was the integer 0.
class JavaScriptBinaryBitOperation implements BinaryOperation {
  final BinaryBitOperation dartBitOperation;

  const JavaScriptBinaryBitOperation(this.dartBitOperation);

  String get name => dartBitOperation.name;

  ConstantValue fold(ConstantValue left, ConstantValue right) {
    // In JavaScript we don't check for -0 and treat it as if it was zero.
    if (left.isMinusZero) {
      left = createInt(BigInt.zero);
    }
    if (right.isMinusZero) {
      right = createInt(BigInt.zero);
    }
    IntConstantValue result = dartBitOperation.fold(left, right);
    if (result != null) {
      // We convert the result of bit-operations to 32 bit unsigned integers.
      return _createInt32(result.intValue);
    }
    return result;
  }

  apply(left, right) => dartBitOperation.apply(left, right);
}

class BitAndOperation extends BinaryBitOperation {
  final String name = '&';
  const BitAndOperation();
  BigInt foldInts(BigInt left, BigInt right) => left & right;
  apply(left, right) => left & right;
}

class BitOrOperation extends BinaryBitOperation {
  final String name = '|';
  const BitOrOperation();
  BigInt foldInts(BigInt left, BigInt right) => left | right;
  apply(left, right) => left | right;
}

class BitXorOperation extends BinaryBitOperation {
  final String name = '^';
  const BitXorOperation();
  BigInt foldInts(BigInt left, BigInt right) => left ^ right;
  apply(left, right) => left ^ right;
}

class ShiftLeftOperation extends BinaryBitOperation {
  final String name = '<<';
  const ShiftLeftOperation();
  BigInt foldInts(BigInt left, BigInt right) {
    // TODO(floitsch): find a better way to guard against excessive shifts to
    // the left.
    if (right > new BigInt.from(100) || right < BigInt.zero) return null;
    return left << right.toInt();
  }

  apply(left, right) => left << right;
}

class ShiftRightOperation extends BinaryBitOperation {
  final String name = '>>';
  const ShiftRightOperation();
  BigInt foldInts(BigInt left, BigInt right) {
    if (right < BigInt.zero) return null;
    return left >> right.toInt();
  }

  apply(left, right) => left >> right;
}

class JavaScriptShiftRightOperation extends JavaScriptBinaryBitOperation {
  const JavaScriptShiftRightOperation() : super(const ShiftRightOperation());

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
}

abstract class BinaryBoolOperation implements BinaryOperation {
  const BinaryBoolOperation();
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
  final String name = '&&';
  const BooleanAndOperation();
  bool foldBools(bool left, bool right) => left && right;
  apply(left, right) => left && right;
}

class BooleanOrOperation extends BinaryBoolOperation {
  final String name = '||';
  const BooleanOrOperation();
  bool foldBools(bool left, bool right) => left || right;
  apply(left, right) => left || right;
}

abstract class ArithmeticNumOperation implements BinaryOperation {
  const ArithmeticNumOperation();
  ConstantValue fold(ConstantValue left, ConstantValue right) {
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

  bool isDivide() => false;
  bool isTruncatingDivide() => false;
  foldInts(BigInt left, BigInt right);
  foldNums(num left, num right);
}

class JavaScriptBinaryArithmeticOperation implements BinaryOperation {
  final BinaryOperation dartArithmeticOperation;

  const JavaScriptBinaryArithmeticOperation(this.dartArithmeticOperation);

  String get name => dartArithmeticOperation.name;

  ConstantValue fold(ConstantValue left, ConstantValue right) {
    ConstantValue result = dartArithmeticOperation.fold(left, right);
    if (result == null) return result;
    return _convertToJavaScriptConstant(result);
  }

  apply(left, right) => dartArithmeticOperation.apply(left, right);
}

class SubtractOperation extends ArithmeticNumOperation {
  final String name = '-';
  const SubtractOperation();
  BigInt foldInts(BigInt left, BigInt right) => left - right;
  num foldNums(num left, num right) => left - right;
  apply(left, right) => left - right;
}

class MultiplyOperation extends ArithmeticNumOperation {
  final String name = '*';
  const MultiplyOperation();
  BigInt foldInts(BigInt left, BigInt right) => left * right;
  num foldNums(num left, num right) => left * right;
  apply(left, right) => left * right;
}

class ModuloOperation extends ArithmeticNumOperation {
  final String name = '%';
  const ModuloOperation();
  BigInt foldInts(BigInt left, BigInt right) {
    if (right == BigInt.zero) return null;
    return left % right;
  }

  num foldNums(num left, num right) => left % right;
  apply(left, right) => left % right;
}

class JavaScriptRemainderOperation extends ArithmeticNumOperation {
  String get name => 'remainder';

  const JavaScriptRemainderOperation();

  BigInt foldInts(BigInt left, BigInt right) {
    if (right == BigInt.zero) return null;
    return left.remainder(right);
  }

  num foldNums(num left, num right) => left.remainder(right);
  apply(left, right) => left.remainder(right);
}

class TruncatingDivideOperation extends ArithmeticNumOperation {
  final String name = '~/';
  const TruncatingDivideOperation();
  BigInt foldInts(BigInt left, BigInt right) {
    if (right == BigInt.zero) return null;
    return left ~/ right;
  }

  BigInt foldNums(num left, num right) {
    num ratio = left / right;
    if (ratio.isNaN || ratio.isInfinite) return null;
    return new BigInt.from(ratio.truncate().toInt());
  }

  apply(left, right) => left ~/ right;
  bool isTruncatingDivide() => true;
}

class DivideOperation extends ArithmeticNumOperation {
  final String name = '/';
  const DivideOperation();
  double foldInts(BigInt left, BigInt right) => left / right;
  num foldNums(num left, num right) => left / right;
  bool isDivide() => true;
  apply(left, right) => left / right;
}

class AddOperation implements BinaryOperation {
  final String name = '+';
  const AddOperation();
  ConstantValue fold(ConstantValue left, ConstantValue right) {
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

  apply(left, right) => left + right;
}

class JavaScriptAddOperation implements BinaryOperation {
  final _addOperation = const AddOperation();
  String get name => _addOperation.name;

  const JavaScriptAddOperation();

  ConstantValue fold(ConstantValue left, ConstantValue right) {
    ConstantValue result = _addOperation.fold(left, right);
    if (result != null && result.isNum) {
      return _convertToJavaScriptConstant(result);
    }
    return result;
  }

  apply(left, right) => _addOperation.apply(left, right);
}

abstract class RelationalNumOperation implements BinaryOperation {
  const RelationalNumOperation();
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
  final String name = '<';
  const LessOperation();
  bool foldInts(BigInt left, BigInt right) => left < right;
  bool foldNums(num left, num right) => left < right;
  apply(left, right) => left < right;
}

class LessEqualOperation extends RelationalNumOperation {
  final String name = '<=';
  const LessEqualOperation();
  bool foldInts(BigInt left, BigInt right) => left <= right;
  bool foldNums(num left, num right) => left <= right;
  apply(left, right) => left <= right;
}

class GreaterOperation extends RelationalNumOperation {
  final String name = '>';
  const GreaterOperation();
  bool foldInts(BigInt left, BigInt right) => left > right;
  bool foldNums(num left, num right) => left > right;
  apply(left, right) => left > right;
}

class GreaterEqualOperation extends RelationalNumOperation {
  final String name = '>=';
  const GreaterEqualOperation();
  bool foldInts(BigInt left, BigInt right) => left >= right;
  bool foldNums(num left, num right) => left >= right;
  apply(left, right) => left >= right;
}

class EqualsOperation implements BinaryOperation {
  final String name = '==';
  const EqualsOperation();
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

  apply(left, right) => left == right;
}

class IdentityOperation implements BinaryOperation {
  final String name = '===';
  const IdentityOperation();
  BoolConstantValue fold(ConstantValue left, ConstantValue right) {
    // In order to preserve runtime semantics which says that NaN !== NaN don't
    // constant fold NaN === NaN. Otherwise the output depends on inlined
    // variables and other optimizations.
    if (left.isNaN && right.isNaN) return null;
    return createBool(left == right);
  }

  apply(left, right) => identical(left, right);
}

class JavaScriptIdentityOperation implements BinaryOperation {
  final IdentityOperation dartIdentityOperation = const IdentityOperation();

  const JavaScriptIdentityOperation();

  String get name => dartIdentityOperation.name;

  BoolConstantValue fold(ConstantValue left, ConstantValue right) {
    BoolConstantValue result = dartIdentityOperation.fold(left, right);
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

  apply(left, right) => identical(left, right);
}

class IfNullOperation implements BinaryOperation {
  final String name = '??';
  const IfNullOperation();
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    if (left.isNull) return right;
    return left;
  }

  apply(left, right) => left ?? right;
}

class CodeUnitAtOperation implements BinaryOperation {
  String get name => 'charCodeAt';
  const CodeUnitAtOperation();
  ConstantValue fold(ConstantValue left, ConstantValue right) => null;
  apply(left, right) => left.codeUnitAt(right);
}

class CodeUnitAtRuntimeOperation extends CodeUnitAtOperation {
  const CodeUnitAtRuntimeOperation();
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
}

class JavaScriptRoundOperation implements UnaryOperation {
  const JavaScriptRoundOperation();
  String get name => round.name;
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

class UnfoldedUnaryOperation implements UnaryOperation {
  final String name;
  const UnfoldedUnaryOperation(this.name);
  ConstantValue fold(ConstantValue constant) {
    return null;
  }
}

class JavaScriptSetConstant extends SetConstantValue {
  final MapConstantValue entries;

  JavaScriptSetConstant(CommonElements commonElements, InterfaceType type,
      List<ConstantValue> values)
      : entries = createMap(
            commonElements,
            commonElements.mapType(
                type.typeArguments.first, commonElements.nullType),
            values,
            new List<NullConstantValue>.filled(
                values.length, const NullConstantValue())),
        super(type, values);

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
  bool get isMap => true;

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
