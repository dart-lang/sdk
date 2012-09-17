// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const JAVA_SCRIPT_CONSTANT_SYSTEM = const JavaScriptConstantSystem();

class JavaScriptBitNotOperation extends BitNotOperation {
  const JavaScriptBitNotOperation();

  Constant fold(Constant constant) {
    if (JAVA_SCRIPT_CONSTANT_SYSTEM.isInt(constant)) {
      // In JavaScript we don't check for -0 and treat it as if it was zero.
      if (constant.isMinusZero()) constant = DART_CONSTANT_SYSTEM.createInt(0);
      IntConstant intConstant = constant;
      // We convert the result of bit-operations to 32 bit unsigned integers.
      return JAVA_SCRIPT_CONSTANT_SYSTEM.createInt32(~intConstant.value);
    }
    return null;
  }
}

/**
 * In JavaScript we truncate the result to an unsigned 32 bit integer. Also, -0
 * is treated as if it was the integer 0.
 */
class JavaScriptBinaryBitOperation implements BinaryOperation {
  final BinaryBitOperation dartBitOperation;

  const JavaScriptBinaryBitOperation(this.dartBitOperation);

  bool isUserDefinable() => dartBitOperation.isUserDefinable();
  SourceString get name => dartBitOperation.name;

  Constant fold(Constant left, Constant right) {
    // In JavaScript we don't check for -0 and treat it as if it was zero.
    if (left.isMinusZero()) left = DART_CONSTANT_SYSTEM.createInt(0);
    if (right.isMinusZero()) right = DART_CONSTANT_SYSTEM.createInt(0);
    IntConstant result = dartBitOperation.fold(left, right);
    if (result != null) {
      // We convert the result of bit-operations to 32 bit unsigned integers.
      return JAVA_SCRIPT_CONSTANT_SYSTEM.createInt32(result.value);
    }
    return result;
  }
}

class JavaScriptShiftRightOperation extends JavaScriptBinaryBitOperation {
  const JavaScriptShiftRightOperation() : super(const ShiftRightOperation());

  Constant fold(Constant left, Constant right) {
    // Truncate the input value to 32 bits if necessary.
    if (left.isInt()) {
      IntConstant intConstant = left;
      int value = intConstant.value;
      int truncatedValue = value & JAVA_SCRIPT_CONSTANT_SYSTEM.BITS32;
      // TODO(floitsch): we should treat the input to right shifts as unsigned.

      // Sign-extend. A 32 bit complement-two value x can be computed by:
      //    x_u - 2^32 (where x_u is its unsigned representation).
      // Example: 0xFFFFFFFF - 0x100000000 => -1.
      // We simply and with the sign-bit and multiply by two. If the sign-bit
      // was set, then the result is 0. Otherwise it will become 2^32.
      final int SIGN_BIT = 0x80000000;
      truncatedValue -= 2 * (truncatedValue & SIGN_BIT);
      if (value != truncatedValue) {
        left = DART_CONSTANT_SYSTEM.createInt(truncatedValue);
      }
    }
    return super.fold(left, right);
  }
}

class JavaScriptNegateOperation implements UnaryOperation {
  final NegateOperation dartNegateOperation = const NegateOperation();

  const JavaScriptNegateOperation();

  bool isUserDefinable() => dartNegateOperation.isUserDefinable();
  SourceString get name => dartNegateOperation.name;

  Constant fold(Constant constant) {
    if (constant.isInt()) {
      IntConstant intConstant = constant;
      if (intConstant.value == 0) {
        return JAVA_SCRIPT_CONSTANT_SYSTEM.createDouble(-0.0);
      }
    }
    return dartNegateOperation.fold(constant);
  }
}

class JavaScriptBinaryArithmeticOperation implements BinaryOperation {
  final BinaryOperation dartArithmeticOperation;

  const JavaScriptBinaryArithmeticOperation(this.dartArithmeticOperation);

  bool isUserDefinable() => dartArithmeticOperation.isUserDefinable();
  SourceString get name => dartArithmeticOperation.name;

  Constant fold(Constant left, Constant right) {
    Constant result = dartArithmeticOperation.fold(left, right);
    if (result == null) return result;
    return JAVA_SCRIPT_CONSTANT_SYSTEM.convertToJavaScriptConstant(result);
  }
}

class JavaScriptIdentityOperation implements BinaryOperation {
  final IdentityOperation dartIdentityOperation = const IdentityOperation();

  const JavaScriptIdentityOperation();

  bool isUserDefinable() => dartIdentityOperation.isUserDefinable();
  SourceString get name => dartIdentityOperation.name;

  BoolConstant fold(Constant left, Constant right) {
    BoolConstant result = dartIdentityOperation.fold(left, right);
    if (result == null || result.value) return result;
    // In JavaScript -0.0 === 0 and all doubles are equal to their integer
    // values. Furthermore NaN !== NaN.
    if (left.isNum() && right.isNum()) {
      NumConstant leftNum = left;
      NumConstant rightNum = right;
      double leftDouble = leftNum.value.toDouble();
      double rightDouble = rightNum.value.toDouble();
      return new BoolConstant(leftDouble == rightDouble);
    }
    return result;
  }
}

/**
 * Constant system following the semantics for Dart code that has been
 * compiled to JavaScript.
 */
class JavaScriptConstantSystem implements ConstantSystem {
  const int BITS31 = 0x8FFFFFFF;
  const int BITS32 = 0xFFFFFFFF;
  // The maximum integer value a double can represent without losing
  // precision.
  const int BITS53 = 0x1FFFFFFFFFFFFF;

  final add = const JavaScriptBinaryArithmeticOperation(const AddOperation());
  final bitAnd = const JavaScriptBinaryBitOperation(const BitAndOperation());
  final bitNot = const JavaScriptBitNotOperation();
  final bitOr = const JavaScriptBinaryBitOperation(const BitOrOperation());
  final bitXor = const JavaScriptBinaryBitOperation(const BitXorOperation());
  final booleanAnd = const BooleanAndOperation();
  final booleanOr = const BooleanOrOperation();
  final divide =
      const JavaScriptBinaryArithmeticOperation(const DivideOperation());
  final equal = const EqualsOperation();
  final greaterEqual = const GreaterEqualOperation();
  final greater = const GreaterOperation();
  final identity = const JavaScriptIdentityOperation();
  final lessEqual = const LessEqualOperation();
  final less = const LessOperation();
  final modulo =
      const JavaScriptBinaryArithmeticOperation(const ModuloOperation());
  final multiply =
      const JavaScriptBinaryArithmeticOperation(const MultiplyOperation());
  final negate = const JavaScriptNegateOperation();
  final not = const NotOperation();
  final shiftLeft =
      const JavaScriptBinaryBitOperation(const ShiftLeftOperation());
  final shiftRight = const JavaScriptShiftRightOperation();
  final subtract =
      const JavaScriptBinaryArithmeticOperation(const SubtractOperation());
  final truncatingDivide = const JavaScriptBinaryArithmeticOperation(
      const TruncatingDivideOperation());

  const JavaScriptConstantSystem();

  /**
   * Returns true if the given [value] fits into a double without losing
   * precision.
   */
  bool integerFitsIntoDouble(int value) {
    int absValue = value.abs();
    return (absValue & BITS53) == absValue;
  }

  NumConstant convertToJavaScriptConstant(NumConstant constant) {
    if (constant.isInt()) {
      IntConstant intConstant = constant;
      int intValue = intConstant.value;
      if (!integerFitsIntoDouble(intValue)) {
        return new DoubleConstant(intValue.toDouble());
      }
    } else if (constant.isDouble()) {
      DoubleConstant doubleResult = constant;
      double doubleValue = doubleResult.value;
      if (!doubleValue.isInfinite() && !doubleValue.isNaN() &&
          !constant.isMinusZero()) {
        int intValue = doubleValue.toInt();
        if (intValue == doubleValue && integerFitsIntoDouble(intValue)) {
          return new IntConstant(intValue);
        }
      }
    }
    return constant;
  }

  NumConstant createInt(int i)
      => convertToJavaScriptConstant(new IntConstant(i));
  NumConstant createInt32(int i) => new IntConstant(i & BITS32);
  NumConstant createDouble(double d)
      => convertToJavaScriptConstant(new DoubleConstant(d));
  StringConstant createString(DartString string, Node diagnosticNode)
      => new StringConstant(string, diagnosticNode);
  BoolConstant createBool(bool value) => new BoolConstant(value);
  NullConstant createNull() => new NullConstant();

  // Integer checks don't verify that the number is not -0.0.
  bool isInt(Constant constant) => constant.isInt() || constant.isMinusZero();
  bool isDouble(Constant constant)
      => constant.isDouble() && !constant.isMinusZero();
  bool isString(Constant constant) => constant.isString();
  bool isBool(Constant constant) => constant.isBool();
  bool isNull(Constant constant) => constant.isNull();

  bool isSubtype(Compiler compiler, DartType s, DartType t) {
    // At runtime, an integer is both an integer and a double: the
    // integer type check is Math.floor, which will return true only
    // for real integers, and our double type check is 'typeof number'
    // which will return true for both integers and doubles.
    if (s.element == compiler.intClass && t.element == compiler.doubleClass) {
      return true;
    }
    return compiler.types.isSubtype(s, t);
  }
}
