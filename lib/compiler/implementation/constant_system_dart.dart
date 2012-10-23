// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const DART_CONSTANT_SYSTEM = const DartConstantSystem();

class BitNotOperation implements UnaryOperation {
  final SourceString name = const SourceString('~');
  bool isUserDefinable() => true;
  const BitNotOperation();
  Constant fold(Constant constant) {
    if (constant.isInt()) {
      IntConstant intConstant = constant;
      return DART_CONSTANT_SYSTEM.createInt(~intConstant.value);
    }
    return null;
  }
  apply(value) => ~value;
}

class NegateOperation implements UnaryOperation {
  final SourceString name = const SourceString('negate');
  bool isUserDefinable() => true;
  const NegateOperation();
  Constant fold(Constant constant) {
    if (constant.isInt()) {
      IntConstant intConstant = constant;
      return DART_CONSTANT_SYSTEM.createInt(-intConstant.value);
    }
    if (constant.isDouble()) {
      DoubleConstant doubleConstant = constant;
      return DART_CONSTANT_SYSTEM.createDouble(-doubleConstant.value);
    }
    return null;
  }
  apply(value) => -value;
}

class NotOperation implements UnaryOperation {
  final SourceString name = const SourceString('!');
  bool isUserDefinable() => true;
  const NotOperation();
  Constant fold(Constant constant) {
    if (constant.isBool()) {
      BoolConstant boolConstant = constant;
      return DART_CONSTANT_SYSTEM.createBool(!boolConstant.value);
    }
    return null;
  }
  apply(value) => !value;
}

/**
 * Operations that only work if both arguments are integers.
 */
abstract class BinaryBitOperation implements BinaryOperation {
  bool isUserDefinable() => true;
  const BinaryBitOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isInt() && right.isInt()) {
      IntConstant leftInt = left;
      IntConstant rightInt = right;
      int resultValue = foldInts(leftInt.value, rightInt.value);
      if (resultValue == null) return null;
      return DART_CONSTANT_SYSTEM.createInt(resultValue);
    }
    return null;
  }

  abstract int foldInts(int left, int right);
}

class BitOrOperation extends BinaryBitOperation {
  final SourceString name = const SourceString('|');
  const BitOrOperation();
  int foldInts(int left, int right)  => left | right;
  apply(left, right) => left | right;
}

class BitAndOperation extends BinaryBitOperation {
  final SourceString name = const SourceString('&');
  const BitAndOperation();
  int foldInts(int left, int right) => left & right;
  apply(left, right) => left & right;
}

class BitXorOperation extends BinaryBitOperation {
  final SourceString name = const SourceString('^');
  const BitXorOperation();
  int foldInts(int left, int right) => left ^ right;
  apply(left, right) => left ^ right;
}

class ShiftLeftOperation extends BinaryBitOperation {
  final SourceString name = const SourceString('<<');
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
  final SourceString name = const SourceString('>>');
  const ShiftRightOperation();
  int foldInts(int left, int right) {
    if (right < 0) return null;
    return left >> right;
  }
  apply(left, right) => left >> right;
}

abstract class BinaryBoolOperation implements BinaryOperation {
  bool isUserDefinable() => false;
  const BinaryBoolOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isBool() && right.isBool()) {
      BoolConstant leftBool = left;
      BoolConstant rightBool = right;
      bool resultValue = foldBools(leftBool.value, rightBool.value);
      return DART_CONSTANT_SYSTEM.createBool(resultValue);
    }
    return null;
  }

  abstract bool foldBools(bool left, bool right);
}

class BooleanAndOperation extends BinaryBoolOperation {
  final SourceString name = const SourceString('&&');
  const BooleanAndOperation();
  bool foldBools(bool left, bool right) => left && right;
  apply(left, right) => left && right;
}

class BooleanOrOperation extends BinaryBoolOperation {
  final SourceString name = const SourceString('||');
  const BooleanOrOperation();
  bool foldBools(bool left, bool right) => left || right;
  apply(left, right) => left || right;
}

abstract class ArithmeticNumOperation implements BinaryOperation {
  bool isUserDefinable() => true;
  const ArithmeticNumOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isNum() && right.isNum()) {
      NumConstant leftNum = left;
      NumConstant rightNum = right;
      num foldedValue;
      if (left.isInt() && right.isInt()) {
        foldedValue = foldInts(leftNum.value, rightNum.value);
      } else {
        foldedValue = foldNums(leftNum.value, rightNum.value);
      }
      // A division by 0 means that we might not have a folded value.
      if (foldedValue == null) return null;
      if (left.isInt() && right.isInt() && !isDivide()) {
        assert(foldedValue is int);
        return DART_CONSTANT_SYSTEM.createInt(foldedValue);
      } else {
        return DART_CONSTANT_SYSTEM.createDouble(foldedValue);
      }
    }
    return null;
  }

  bool isDivide() => false;
  num foldInts(int left, int right) => foldNums(left, right);
  abstract num foldNums(num left, num right);
}

class SubtractOperation extends ArithmeticNumOperation {
  final SourceString name = const SourceString('-');
  const SubtractOperation();
  num foldNums(num left, num right) => left - right;
  apply(left, right) => left - right;
}

class MultiplyOperation extends ArithmeticNumOperation {
  final SourceString name = const SourceString('*');
  const MultiplyOperation();
  num foldNums(num left, num right) => left * right;
  apply(left, right) => left * right;
}

class ModuloOperation extends ArithmeticNumOperation {
  final SourceString name = const SourceString('%');
  const ModuloOperation();
  int foldInts(int left, int right) {
    if (right == 0) return null;
    return left % right;
  }
  num foldNums(num left, num right) => left % right;
  apply(left, right) => left % right;
}

class TruncatingDivideOperation extends ArithmeticNumOperation {
  final SourceString name = const SourceString('~/');
  const TruncatingDivideOperation();
  int foldInts(int left, int right) {
    if (right == 0) return null;
    return left ~/ right;
  }
  num foldNums(num left, num right) => left ~/ right;
  apply(left, right) => left ~/ right;
}

class DivideOperation extends ArithmeticNumOperation {
  final SourceString name = const SourceString('/');
  const DivideOperation();
  num foldNums(num left, num right) => left / right;
  bool isDivide() => true;
  apply(left, right) => left / right;
}

class AddOperation implements BinaryOperation {
  final SourceString name = const SourceString('+');
  bool isUserDefinable() => true;
  const AddOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isInt() && right.isInt()) {
      IntConstant leftInt = left;
      IntConstant rightInt = right;
      int result = leftInt.value + rightInt.value;
      return DART_CONSTANT_SYSTEM.createInt(result);
    } else if (left.isNum() && right.isNum()) {
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
  bool isUserDefinable() => true;
  const RelationalNumOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isNum() && right.isNum()) {
      NumConstant leftNum = left;
      NumConstant rightNum = right;
      bool foldedValue = foldNums(leftNum.value, rightNum.value);
      assert(foldedValue != null);
      return DART_CONSTANT_SYSTEM.createBool(foldedValue);
    }
  }

  abstract bool foldNums(num left, num right);
}

class LessOperation extends RelationalNumOperation {
  final SourceString name = const SourceString('<');
  const LessOperation();
  bool foldNums(num left, num right) => left < right;
  apply(left, right) => left < right;
}

class LessEqualOperation extends RelationalNumOperation {
  final SourceString name = const SourceString('<=');
  const LessEqualOperation();
  bool foldNums(num left, num right) => left <= right;
  apply(left, right) => left <= right;
}

class GreaterOperation extends RelationalNumOperation {
  final SourceString name = const SourceString('>');
  const GreaterOperation();
  bool foldNums(num left, num right) => left > right;
  apply(left, right) => left > right;
}

class GreaterEqualOperation extends RelationalNumOperation {
  final SourceString name = const SourceString('>=');
  const GreaterEqualOperation();
  bool foldNums(num left, num right) => left >= right;
  apply(left, right) => left >= right;
}

class EqualsOperation implements BinaryOperation {
  final SourceString name = const SourceString('==');
  bool isUserDefinable() => true;
  const EqualsOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isNum() && right.isNum()) {
      // Numbers need to be treated specially because: NaN != NaN, -0.0 == 0.0,
      // and 1 == 1.0.
      NumConstant leftNum = left;
      NumConstant rightNum = right;
      bool result = leftNum.value == rightNum.value;
      return DART_CONSTANT_SYSTEM.createBool(result);
    }
    if (left.isConstructedObject()) {
      // Unless we know that the user-defined object does not implement the
      // equality operator we cannot fold here.
      return null;
    }
    return DART_CONSTANT_SYSTEM.createBool(left == right);
  }
  apply(left, right) => left == right;
}

class IdentityOperation implements BinaryOperation {
  final SourceString name = const SourceString('===');
  bool isUserDefinable() => false;
  const IdentityOperation();
  BoolConstant fold(Constant left, Constant right) {
    // In order to preserve runtime semantics which says that NaN !== NaN don't
    // constant fold NaN === NaN. Otherwise the output depends on inlined
    // variables and other optimizations.
    if (left.isNaN() && right.isNaN()) return null;
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
class DartConstantSystem implements ConstantSystem {
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
  const lessEqual = const LessEqualOperation();
  const less = const LessOperation();
  const modulo = const ModuloOperation();
  const multiply = const MultiplyOperation();
  const negate = const NegateOperation();
  const not = const NotOperation();
  const shiftLeft = const ShiftLeftOperation();
  const shiftRight = const ShiftRightOperation();
  const subtract = const SubtractOperation();
  const truncatingDivide = const TruncatingDivideOperation();

  const DartConstantSystem();

  IntConstant createInt(int i) => new IntConstant(i);
  DoubleConstant createDouble(double d) => new DoubleConstant(d);
  StringConstant createString(DartString string, Node diagnosticNode)
      => new StringConstant(string, diagnosticNode);
  BoolConstant createBool(bool value) => new BoolConstant(value);
  NullConstant createNull() => new NullConstant();

  bool isInt(Constant constant) => constant.isInt();
  bool isDouble(Constant constant) => constant.isDouble();
  bool isString(Constant constant) => constant.isString();
  bool isBool(Constant constant) => constant.isBool();
  bool isNull(Constant constant) => constant.isNull();

  bool isSubtype(Compiler compiler, DartType s, DartType t) {
    return compiler.types.isSubtype(s, t);
  }
}
