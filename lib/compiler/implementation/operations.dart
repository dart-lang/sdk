// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Operation {
  
}

interface UnaryOperation extends Operation {
  /** Returns [:null:] if it was unable to fold the operation. */
  Constant fold(Constant constant);
}

class BitNotOperation implements UnaryOperation {
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
  const BitOrOperation();
  int foldInts(int left, int right)  => left | right;
}

class BitAndOperation extends BinaryIntOperation {
  const BitAndOperation();
  int foldInts(int left, int right) => left & right;
}

class BitXorOperation extends BinaryIntOperation {
  const BitXorOperation();
  int foldInts(int left, int right) => left ^ right;
}

class ShiftLeftOperation extends BinaryIntOperation {
  const ShiftLeftOperation();
  int foldInts(int left, int right) {
    // TODO(floitsch): find a better way to guard against excessive shifts to
    // the left.
    if (right > 100 || right < 0) return null;
    return left << right;
  }
}

class ShiftRightOperation extends BinaryIntOperation {
  const ShiftRightOperation();
  int foldInts(int left, int right) {
    if (right < 0) return null;
    return left >> right;
  }
}

class BinaryBoolOperation implements BinaryOperation {
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
  const BooleanAnd();
  bool foldBools(bool left, bool right) => left && right;
}

class BooleanOr extends BinaryBoolOperation {
  const BooleanOr();
  bool foldBools(bool left, bool right) => left || right;
}

class ArithmeticNumOperation implements BinaryOperation {
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
  }

  bool isDivide() => false;
  num foldInts(int left, int right) => foldNums(left, right);
  abstract num foldNums(num left, num right);
}

class SubtractOperation extends ArithmeticNumOperation {
  const SubtractOperation();
  num foldNums(num left, num right) => left - right;
}

class MultiplyOperation extends ArithmeticNumOperation {
  const MultiplyOperation();
  num foldNums(num left, num right) => left * right;
}

class ModuloOperation extends ArithmeticNumOperation {
  const ModuloOperation();
  int foldInts(int left, int right) {
    if (right == 0) return null;
    return left % right;
  }
  num foldNums(num left, num right) => left % right;
}

class TruncatingDivideOperation extends ArithmeticNumOperation {
  const TruncatingDivideOperation();
  int foldInts(int left, int right) {
    if (right == 0) return null;
    return left ~/ right;
  }
  num foldNums(num left, num right) => left ~/ right;
}

class DivideOperation extends ArithmeticNumOperation {
  const DivideOperation();
  num foldNums(num left, num right) => left / right;
  bool isDivide() => true;
}

class AddOperation implements BinaryOperation {
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
  const LessOperation();
  bool foldNums(num left, num right) => left < right;
}

class LessEqualOperation extends RelationalNumOperation {
  const LessEqualOperation();
  bool foldNums(num left, num right) => left <= right;
}

class GreaterOperation extends RelationalNumOperation {
  const GreaterOperation();
  bool foldNums(num left, num right) => left > right;
}

class GreaterEqualOperation extends RelationalNumOperation {
  const GreaterEqualOperation();
  bool foldNums(num left, num right) => left >= right;
}

class EqualsOperation implements BinaryOperation {
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
  const IdentityOperation();
  Constant fold(Constant left, Constant right) {
    return new BoolConstant(left == right);
  }
}
