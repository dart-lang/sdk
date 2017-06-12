// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constant_system.dart;

import 'constants/constant_system.dart';
import 'constants/values.dart';
import 'common_elements.dart' show CommonElements;
import 'elements/types.dart';

const DART_CONSTANT_SYSTEM = const DartConstantSystem();

class BitNotOperation implements UnaryOperation {
  final String name = '~';
  const BitNotOperation();
  ConstantValue fold(ConstantValue constant) {
    if (constant.isInt) {
      IntConstantValue intConstant = constant;
      return DART_CONSTANT_SYSTEM.createInt(~intConstant.primitiveValue);
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
      return DART_CONSTANT_SYSTEM.createInt(-intConstant.primitiveValue);
    }
    if (constant.isDouble) {
      DoubleConstantValue doubleConstant = constant;
      return DART_CONSTANT_SYSTEM.createDouble(-doubleConstant.primitiveValue);
    }
    return null;
  }
}

class NotOperation implements UnaryOperation {
  final String name = '!';
  const NotOperation();
  ConstantValue fold(ConstantValue constant) {
    if (constant.isBool) {
      BoolConstantValue boolConstant = constant;
      return DART_CONSTANT_SYSTEM.createBool(!boolConstant.primitiveValue);
    }
    return null;
  }
}

/**
 * Operations that only work if both arguments are integers.
 */
abstract class BinaryBitOperation implements BinaryOperation {
  const BinaryBitOperation();
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    if (left.isInt && right.isInt) {
      IntConstantValue leftInt = left;
      IntConstantValue rightInt = right;
      int resultValue =
          foldInts(leftInt.primitiveValue, rightInt.primitiveValue);
      if (resultValue == null) return null;
      return DART_CONSTANT_SYSTEM.createInt(resultValue);
    }
    return null;
  }

  int foldInts(int left, int right);
}

class BitOrOperation extends BinaryBitOperation {
  final String name = '|';
  const BitOrOperation();
  int foldInts(int left, int right) => left | right;
  apply(left, right) => left | right;
}

class BitAndOperation extends BinaryBitOperation {
  final String name = '&';
  const BitAndOperation();
  int foldInts(int left, int right) => left & right;
  apply(left, right) => left & right;
}

class BitXorOperation extends BinaryBitOperation {
  final String name = '^';
  const BitXorOperation();
  int foldInts(int left, int right) => left ^ right;
  apply(left, right) => left ^ right;
}

class ShiftLeftOperation extends BinaryBitOperation {
  final String name = '<<';
  const ShiftLeftOperation();
  int foldInts(int left, int right) {
    // TODO(floitsch): find a better way to guard against excessive shifts to
    // the left.
    if (right > 100 || right < 0) return null;
    return left << right;
  }

  apply(left, right) => left << right;
}

class ShiftRightOperation extends BinaryBitOperation {
  final String name = '>>';
  const ShiftRightOperation();
  int foldInts(int left, int right) {
    if (right < 0) return null;
    return left >> right;
  }

  apply(left, right) => left >> right;
}

abstract class BinaryBoolOperation implements BinaryOperation {
  const BinaryBoolOperation();
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    if (left.isBool && right.isBool) {
      BoolConstantValue leftBool = left;
      BoolConstantValue rightBool = right;
      bool resultValue =
          foldBools(leftBool.primitiveValue, rightBool.primitiveValue);
      return DART_CONSTANT_SYSTEM.createBool(resultValue);
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
      num foldedValue;
      if (left.isInt && right.isInt) {
        foldedValue = foldInts(leftNum.primitiveValue, rightNum.primitiveValue);
      } else {
        foldedValue = foldNums(leftNum.primitiveValue, rightNum.primitiveValue);
      }
      // A division by 0 means that we might not have a folded value.
      if (foldedValue == null) return null;
      if (left.isInt && right.isInt && !isDivide() || isTruncatingDivide()) {
        assert(foldedValue is int);
        return DART_CONSTANT_SYSTEM.createInt(foldedValue);
      } else {
        return DART_CONSTANT_SYSTEM.createDouble(foldedValue);
      }
    }
    return null;
  }

  bool isDivide() => false;
  bool isTruncatingDivide() => false;
  num foldInts(int left, int right) => foldNums(left, right);
  num foldNums(num left, num right);
}

class SubtractOperation extends ArithmeticNumOperation {
  final String name = '-';
  const SubtractOperation();
  num foldNums(num left, num right) => left - right;
  apply(left, right) => left - right;
}

class MultiplyOperation extends ArithmeticNumOperation {
  final String name = '*';
  const MultiplyOperation();
  num foldNums(num left, num right) => left * right;
  apply(left, right) => left * right;
}

class ModuloOperation extends ArithmeticNumOperation {
  final String name = '%';
  const ModuloOperation();
  int foldInts(int left, int right) {
    if (right == 0) return null;
    return left % right;
  }

  num foldNums(num left, num right) => left % right;
  apply(left, right) => left % right;
}

class RemainderOperation extends ArithmeticNumOperation {
  final String name = 'remainder';
  const RemainderOperation();
  // Not a defined constant operation.
  num foldNums(num left, num right) => null;
  apply(left, right) => left.remainder(right);
}

class TruncatingDivideOperation extends ArithmeticNumOperation {
  final String name = '~/';
  const TruncatingDivideOperation();
  int foldInts(int left, int right) {
    if (right == 0) return null;
    return left ~/ right;
  }

  num foldNums(num left, num right) {
    num ratio = left / right;
    if (ratio.isNaN || ratio.isInfinite) return null;
    return ratio.truncate().toInt();
  }

  apply(left, right) => left ~/ right;
  bool isTruncatingDivide() => true;
}

class DivideOperation extends ArithmeticNumOperation {
  final String name = '/';
  const DivideOperation();
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
      int result = leftInt.primitiveValue + rightInt.primitiveValue;
      return DART_CONSTANT_SYSTEM.createInt(result);
    } else if (left.isNum && right.isNum) {
      NumConstantValue leftNum = left;
      NumConstantValue rightNum = right;
      double result = leftNum.primitiveValue + rightNum.primitiveValue;
      return DART_CONSTANT_SYSTEM.createDouble(result);
    } else if (left.isString && right.isString) {
      StringConstantValue leftString = left;
      StringConstantValue rightString = right;
      String result = leftString.primitiveValue + rightString.primitiveValue;
      return DART_CONSTANT_SYSTEM.createString(result);
    } else {
      return null;
    }
  }

  apply(left, right) => left + right;
}

abstract class RelationalNumOperation implements BinaryOperation {
  const RelationalNumOperation();
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    if (!left.isNum || !right.isNum) return null;
    NumConstantValue leftNum = left;
    NumConstantValue rightNum = right;
    bool foldedValue =
        foldNums(leftNum.primitiveValue, rightNum.primitiveValue);
    assert(foldedValue != null);
    return DART_CONSTANT_SYSTEM.createBool(foldedValue);
  }

  bool foldNums(num left, num right);
}

class LessOperation extends RelationalNumOperation {
  final String name = '<';
  const LessOperation();
  bool foldNums(num left, num right) => left < right;
  apply(left, right) => left < right;
}

class LessEqualOperation extends RelationalNumOperation {
  final String name = '<=';
  const LessEqualOperation();
  bool foldNums(num left, num right) => left <= right;
  apply(left, right) => left <= right;
}

class GreaterOperation extends RelationalNumOperation {
  final String name = '>';
  const GreaterOperation();
  bool foldNums(num left, num right) => left > right;
  apply(left, right) => left > right;
}

class GreaterEqualOperation extends RelationalNumOperation {
  final String name = '>=';
  const GreaterEqualOperation();
  bool foldNums(num left, num right) => left >= right;
  apply(left, right) => left >= right;
}

class EqualsOperation implements BinaryOperation {
  final String name = '==';
  const EqualsOperation();
  ConstantValue fold(ConstantValue left, ConstantValue right) {
    if (left.isNum && right.isNum) {
      // Numbers need to be treated specially because: NaN != NaN, -0.0 == 0.0,
      // and 1 == 1.0.
      NumConstantValue leftNum = left;
      NumConstantValue rightNum = right;
      bool result = leftNum.primitiveValue == rightNum.primitiveValue;
      return DART_CONSTANT_SYSTEM.createBool(result);
    }
    if (left.isConstructedObject) {
      // Unless we know that the user-defined object does not implement the
      // equality operator we cannot fold here.
      return null;
    }
    return DART_CONSTANT_SYSTEM.createBool(left == right);
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
    return DART_CONSTANT_SYSTEM.createBool(left == right);
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
      String string = stringConstant.primitiveValue;
      int index = indexConstant.primitiveValue;
      if (index < 0 || index >= string.length) return null;
      int value = string.codeUnitAt(index);
      return DART_CONSTANT_SYSTEM.createInt(value);
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

/**
 * A constant system implementing the Dart semantics. This system relies on
 * the underlying runtime-system. That is, if dart2js is run in an environment
 * that doesn't correctly implement Dart's semantics this constant system will
 * not return the correct values.
 */
class DartConstantSystem extends ConstantSystem {
  final add = const AddOperation();
  final bitAnd = const BitAndOperation();
  final bitNot = const BitNotOperation();
  final bitOr = const BitOrOperation();
  final bitXor = const BitXorOperation();
  final booleanAnd = const BooleanAndOperation();
  final booleanOr = const BooleanOrOperation();
  final divide = const DivideOperation();
  final equal = const EqualsOperation();
  final greaterEqual = const GreaterEqualOperation();
  final greater = const GreaterOperation();
  final identity = const IdentityOperation();
  final ifNull = const IfNullOperation();
  final lessEqual = const LessEqualOperation();
  final less = const LessOperation();
  final modulo = const ModuloOperation();
  final multiply = const MultiplyOperation();
  final negate = const NegateOperation();
  final not = const NotOperation();
  final remainder = const RemainderOperation();
  final shiftLeft = const ShiftLeftOperation();
  final shiftRight = const ShiftRightOperation();
  final subtract = const SubtractOperation();
  final truncatingDivide = const TruncatingDivideOperation();
  final codeUnitAt = const CodeUnitAtOperation();
  final round = const UnfoldedUnaryOperation('round');

  const DartConstantSystem();

  @override
  IntConstantValue createInt(int i) => new IntConstantValue(i);

  @override
  DoubleConstantValue createDouble(double d) => new DoubleConstantValue(d);

  @override
  StringConstantValue createString(String string) {
    return new StringConstantValue(string);
  }

  @override
  BoolConstantValue createBool(bool value) => new BoolConstantValue(value);

  @override
  NullConstantValue createNull() => new NullConstantValue();

  @override
  ListConstantValue createList(InterfaceType type, List<ConstantValue> values) {
    return new ListConstantValue(type, values);
  }

  @override
  MapConstantValue createMap(CommonElements commonElements, InterfaceType type,
      List<ConstantValue> keys, List<ConstantValue> values) {
    return new MapConstantValue(type, keys, values);
  }

  @override
  ConstantValue createType(CommonElements commonElements, DartType type) {
    InterfaceType implementationType = commonElements.typeLiteralType;
    return new TypeConstantValue(type, implementationType);
  }

  @override
  ConstantValue createSymbol(CommonElements commonElements, String text) {
    throw new UnsupportedError('DartConstantSystem.createSymbol');
  }

  bool isInt(ConstantValue constant) => constant.isInt;
  bool isDouble(ConstantValue constant) => constant.isDouble;
  bool isString(ConstantValue constant) => constant.isString;
  bool isBool(ConstantValue constant) => constant.isBool;
  bool isNull(ConstantValue constant) => constant.isNull;

  bool isSubtype(DartTypes types, DartType s, DartType t) {
    return types.isSubtype(s, t);
  }
}
