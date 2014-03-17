// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

const DART_CONSTANT_SYSTEM = const DartConstantSystem();

class BitNotOperation implements UnaryOperation {
  final String name = '~';
  const BitNotOperation();
  Constant fold(Constant constant) {
    if (constant.isInt) {
      IntConstant intConstant = constant;
      return DART_CONSTANT_SYSTEM.createInt(~intConstant.value);
    }
    return null;
  }
}

class NegateOperation implements UnaryOperation {
  final String name = 'negate';
  const NegateOperation();
  Constant fold(Constant constant) {
    if (constant.isInt) {
      IntConstant intConstant = constant;
      return DART_CONSTANT_SYSTEM.createInt(-intConstant.value);
    }
    if (constant.isDouble) {
      DoubleConstant doubleConstant = constant;
      return DART_CONSTANT_SYSTEM.createDouble(-doubleConstant.value);
    }
    return null;
  }
}

class NotOperation implements UnaryOperation {
  final String name = '!';
  const NotOperation();
  Constant fold(Constant constant) {
    if (constant.isBool) {
      BoolConstant boolConstant = constant;
      return DART_CONSTANT_SYSTEM.createBool(!boolConstant.value);
    }
    return null;
  }
}

/**
 * Operations that only work if both arguments are integers.
 */
abstract class BinaryBitOperation implements BinaryOperation {
  const BinaryBitOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isInt && right.isInt) {
      IntConstant leftInt = left;
      IntConstant rightInt = right;
      int resultValue = foldInts(leftInt.value, rightInt.value);
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
  int foldInts(int left, int right)  => left | right;
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
  Constant fold(Constant left, Constant right) {
    if (left.isBool && right.isBool) {
      BoolConstant leftBool = left;
      BoolConstant rightBool = right;
      bool resultValue = foldBools(leftBool.value, rightBool.value);
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
  Constant fold(Constant left, Constant right) {
    if (left.isNum && right.isNum) {
      NumConstant leftNum = left;
      NumConstant rightNum = right;
      num foldedValue;
      if (left.isInt && right.isInt) {
        foldedValue = foldInts(leftNum.value, rightNum.value);
      } else {
        foldedValue = foldNums(leftNum.value, rightNum.value);
      }
      // A division by 0 means that we might not have a folded value.
      if (foldedValue == null) return null;
      if (left.isInt && right.isInt && !isDivide() ||
          isTruncatingDivide()) {
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
  Constant fold(Constant left, Constant right) {
    if (left.isInt && right.isInt) {
      IntConstant leftInt = left;
      IntConstant rightInt = right;
      int result = leftInt.value + rightInt.value;
      return DART_CONSTANT_SYSTEM.createInt(result);
    } else if (left.isNum && right.isNum) {
      NumConstant leftNum = left;
      NumConstant rightNum = right;
      double result = leftNum.value + rightNum.value;
      return DART_CONSTANT_SYSTEM.createDouble(result);
    } else {
      return null;
    }
  }
  apply(left, right) => left + right;
}

abstract class RelationalNumOperation implements BinaryOperation {
  const RelationalNumOperation();
  Constant fold(Constant left, Constant right) {
    if (!left.isNum || !right.isNum) return null;
    NumConstant leftNum = left;
    NumConstant rightNum = right;
    bool foldedValue = foldNums(leftNum.value, rightNum.value);
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
  Constant fold(Constant left, Constant right) {
    if (left.isNum && right.isNum) {
      // Numbers need to be treated specially because: NaN != NaN, -0.0 == 0.0,
      // and 1 == 1.0.
      NumConstant leftNum = left;
      NumConstant rightNum = right;
      bool result = leftNum.value == rightNum.value;
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
  BoolConstant fold(Constant left, Constant right) {
    // In order to preserve runtime semantics which says that NaN !== NaN don't
    // constant fold NaN === NaN. Otherwise the output depends on inlined
    // variables and other optimizations.
    if (left.isNaN && right.isNaN) return null;
    return DART_CONSTANT_SYSTEM.createBool(left == right);
  }
  apply(left, right) => identical(left, right);
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
  final lessEqual = const LessEqualOperation();
  final less = const LessOperation();
  final modulo = const ModuloOperation();
  final multiply = const MultiplyOperation();
  final negate = const NegateOperation();
  final not = const NotOperation();
  final shiftLeft = const ShiftLeftOperation();
  final shiftRight = const ShiftRightOperation();
  final subtract = const SubtractOperation();
  final truncatingDivide = const TruncatingDivideOperation();

  const DartConstantSystem();

  IntConstant createInt(int i) => new IntConstant(i);
  DoubleConstant createDouble(double d) => new DoubleConstant(d);
  StringConstant createString(DartString string) => new StringConstant(string);
  BoolConstant createBool(bool value) => new BoolConstant(value);
  NullConstant createNull() => new NullConstant();

  bool isInt(Constant constant) => constant.isInt;
  bool isDouble(Constant constant) => constant.isDouble;
  bool isString(Constant constant) => constant.isString;
  bool isBool(Constant constant) => constant.isBool;
  bool isNull(Constant constant) => constant.isNull;

  bool isSubtype(Compiler compiler, DartType s, DartType t) {
    return compiler.types.isSubtype(s, t);
  }
}
