// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Operation {
  final SourceString name;
  bool isUserDefinable();
}

interface UnaryOperation extends Operation {
  /** Returns [:null:] if it was unable to fold the operation. */
  Constant fold(Constant constant);
}

class BitNotOperation implements UnaryOperation {
  final SourceString name = const SourceString('~');
  bool isUserDefinable() => true;
  const BitNotOperation();
  Constant fold(Constant constant) {
    if (constant.isInt()) {
      IntConstant intConstant = constant;
      return new IntConstant(~intConstant.value);
    }
    return null;
  }
}

class NegateOperation implements UnaryOperation {
  final SourceString name = const SourceString('negate');
  bool isUserDefinable() => true;
  const NegateOperation();
  Constant fold(Constant constant) {
    if (constant.isInt()) {
      IntConstant intConstant = constant;
      return new IntConstant(-intConstant.value);
    }
    if (constant.isDouble()) {
      DoubleConstant doubleConstant = constant;
      return new DoubleConstant(-doubleConstant.value);
    }
    return null;
  }
}

class NotOperation implements UnaryOperation {
  final SourceString name = const SourceString('!');
  bool isUserDefinable() => true;
  const NotOperation();
  Constant fold(Constant constant) {
    if (constant.isBool()) {
      BoolConstant boolConstant = constant;
      return boolConstant.negate();
    }
    return null;
  }
}

interface BinaryOperation extends Operation {
  /** Returns [:null:] if it was unable to fold the operation. */
  Constant fold(Constant left, Constant right);
}

/**
 * Operations that only work if both arguments are integers.
 */
class BinaryIntOperation implements BinaryOperation {
  bool isUserDefinable() => true;
  const BinaryIntOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isInt() && right.isInt()) {
      IntConstant leftInt = left;
      IntConstant rightInt = right;
      int resultValue = foldInts(leftInt.value, rightInt.value);
      if (resultValue === null) return null;
      return new IntConstant(resultValue);
    }
    return null;
  }

  abstract int foldInts(int left, int right);
}

class BitOrOperation extends BinaryIntOperation {
  final SourceString name = const SourceString('|');
  const BitOrOperation();
  int foldInts(int left, int right)  => left | right;
}

class BitAndOperation extends BinaryIntOperation {
  final SourceString name = const SourceString('&');
  const BitAndOperation();
  int foldInts(int left, int right) => left & right;
}

class BitXorOperation extends BinaryIntOperation {
  final SourceString name = const SourceString('^');
  const BitXorOperation();
  int foldInts(int left, int right) => left ^ right;
}

class ShiftLeftOperation extends BinaryIntOperation {
  final SourceString name = const SourceString('<<');
  const ShiftLeftOperation();
  int foldInts(int left, int right) {
    // TODO(floitsch): find a better way to guard against excessive shifts to
    // the left.
    if (right > 100 || right < 0) return null;
    return left << right;
  }
}

class ShiftRightOperation extends BinaryIntOperation {
  final SourceString name = const SourceString('>>');
  const ShiftRightOperation();
  int foldInts(int left, int right) {
    if (right < 0) return null;
    return left >> right;
  }
}

class BinaryBoolOperation implements BinaryOperation {
  bool isUserDefinable() => false;
  const BinaryBoolOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isBool() && right.isBool()) {
      BoolConstant leftBool = left;
      BoolConstant rightBool = right;
      bool resultValue = foldBools(leftBool.value, rightBool.value);
      return new BoolConstant(resultValue);
    }
    return null;
  }

  abstract bool foldBools(bool left, bool right);
}

class BooleanAnd extends BinaryBoolOperation {
  final SourceString name = const SourceString('&&');
  const BooleanAnd();
  bool foldBools(bool left, bool right) => left && right;
}

class BooleanOr extends BinaryBoolOperation {
  final SourceString name = const SourceString('||');
  const BooleanOr();
  bool foldBools(bool left, bool right) => left || right;
}

class ArithmeticNumOperation implements BinaryOperation {
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
      if (foldedValue === null) return null;
      if (left.isInt() && right.isInt() && !isDivide()) {
        assert(foldedValue is int);
        return new IntConstant(foldedValue);
      } else {
        return new DoubleConstant(foldedValue);
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
}

class MultiplyOperation extends ArithmeticNumOperation {
  final SourceString name = const SourceString('*');
  const MultiplyOperation();
  num foldNums(num left, num right) => left * right;
}

class ModuloOperation extends ArithmeticNumOperation {
  final SourceString name = const SourceString('%');
  const ModuloOperation();
  int foldInts(int left, int right) {
    if (right == 0) return null;
    return left % right;
  }
  num foldNums(num left, num right) => left % right;
}

class TruncatingDivideOperation extends ArithmeticNumOperation {
  final SourceString name = const SourceString('~/');
  const TruncatingDivideOperation();
  int foldInts(int left, int right) {
    if (right == 0) return null;
    return left ~/ right;
  }
  num foldNums(num left, num right) => left ~/ right;
}

class DivideOperation extends ArithmeticNumOperation {
  final SourceString name = const SourceString('/');
  const DivideOperation();
  num foldNums(num left, num right) => left / right;
  bool isDivide() => true;
}

class AddOperation implements BinaryOperation {
  final SourceString name = const SourceString('+');
  bool isUserDefinable() => true;
  const AddOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isInt() && right.isInt()) {
      IntConstant leftInt = left;
      IntConstant rightInt = right;
      return new IntConstant(leftInt.value + rightInt.value);
    } else if (left.isNum() && right.isNum()) {
      NumConstant leftNum = left;
      NumConstant rightNum = right;
      return new DoubleConstant(leftNum.value + rightNum.value);
    } else if (left.isString() && !right.isObject()) {
      PrimitiveConstant primitiveRight = right;
      DartString rightDartString = primitiveRight.toDartString();
      StringConstant leftString = left;
      if (rightDartString.isEmpty()) {
        return left;
      } else if (leftString.value.isEmpty()) {
        return new StringConstant(rightDartString);
      } else {
        DartString concatenated =
            new ConsDartString(leftString.value, rightDartString);
        return new StringConstant(concatenated);
      }
    } else {
      return null;
    }
  }
}

class RelationalNumOperation implements BinaryOperation {
  bool isUserDefinable() => true;
  const RelationalNumOperation();
  Constant fold(Constant left, Constant right) {
    if (left.isNum() && right.isNum()) {
      NumConstant leftNum = left;
      NumConstant rightNum = right;
      bool foldedValue = foldNums(leftNum.value, rightNum.value);
      assert(foldedValue != null);
      return new BoolConstant(foldedValue);
    }
  }

  abstract bool foldNums(num left, num right);
}

class LessOperation extends RelationalNumOperation {
  final SourceString name = const SourceString('<');
  const LessOperation();
  bool foldNums(num left, num right) => left < right;
}

class LessEqualOperation extends RelationalNumOperation {
  final SourceString name = const SourceString('<=');
  const LessEqualOperation();
  bool foldNums(num left, num right) => left <= right;
}

class GreaterOperation extends RelationalNumOperation {
  final SourceString name = const SourceString('>');
  const GreaterOperation();
  bool foldNums(num left, num right) => left > right;
}

class GreaterEqualOperation extends RelationalNumOperation {
  final SourceString name = const SourceString('>=');
  const GreaterEqualOperation();
  bool foldNums(num left, num right) => left >= right;
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
      return new BoolConstant(leftNum.value == rightNum.value);
    }
    if (left.isConstructedObject()) {
      // Unless we know that the user-defined object does not implement the
      // equality operator we cannot fold here.
      return null;
    }
    return new BoolConstant(left == right);
  }
}

class IdentityOperation implements BinaryOperation {
  final SourceString name = const SourceString('===');
  bool isUserDefinable() => false;
  const IdentityOperation();
  Constant fold(Constant left, Constant right) {
    // In order to preserve runtime semantics which says that NaN !== NaN don't
    // constant fold NaN === NaN. Otherwise the output depends on inlined
    // variables and other optimizations.
    if (left.isNaN() && right.isNaN()) return null;
    return new BoolConstant(left == right);
  }
}
