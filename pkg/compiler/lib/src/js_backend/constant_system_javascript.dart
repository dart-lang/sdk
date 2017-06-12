// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constant_system.js;

import '../constant_system_dart.dart';
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../common_elements.dart' show CommonElements;
import '../elements/types.dart';
import '../elements/entities.dart';

const JAVA_SCRIPT_CONSTANT_SYSTEM = const JavaScriptConstantSystem();

class JavaScriptBitNotOperation extends BitNotOperation {
  const JavaScriptBitNotOperation();

  ConstantValue fold(ConstantValue constant) {
    if (JAVA_SCRIPT_CONSTANT_SYSTEM.isInt(constant)) {
      // In JavaScript we don't check for -0 and treat it as if it was zero.
      if (constant.isMinusZero) constant = DART_CONSTANT_SYSTEM.createInt(0);
      IntConstantValue intConstant = constant;
      // We convert the result of bit-operations to 32 bit unsigned integers.
      return JAVA_SCRIPT_CONSTANT_SYSTEM
          .createInt32(~intConstant.primitiveValue);
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

  String get name => dartBitOperation.name;

  ConstantValue fold(ConstantValue left, ConstantValue right) {
    // In JavaScript we don't check for -0 and treat it as if it was zero.
    if (left.isMinusZero) left = DART_CONSTANT_SYSTEM.createInt(0);
    if (right.isMinusZero) right = DART_CONSTANT_SYSTEM.createInt(0);
    IntConstantValue result = dartBitOperation.fold(left, right);
    if (result != null) {
      // We convert the result of bit-operations to 32 bit unsigned integers.
      return JAVA_SCRIPT_CONSTANT_SYSTEM.createInt32(result.primitiveValue);
    }
    return result;
  }

  apply(left, right) => dartBitOperation.apply(left, right);
}

class JavaScriptShiftRightOperation extends JavaScriptBinaryBitOperation {
  const JavaScriptShiftRightOperation() : super(const ShiftRightOperation());

  ConstantValue fold(ConstantValue left, ConstantValue right) {
    // Truncate the input value to 32 bits if necessary.
    if (left.isInt) {
      IntConstantValue intConstant = left;
      int value = intConstant.primitiveValue;
      int truncatedValue = value & JAVA_SCRIPT_CONSTANT_SYSTEM.BITS32;
      if (value < 0) {
        // Sign-extend if the input was negative. The current semantics don't
        // make much sense, since we only look at bit 31.
        // TODO(floitsch): we should treat the input to right shifts as
        // unsigned.

        // A 32 bit complement-two value x can be computed by:
        //    x_u - 2^32 (where x_u is its unsigned representation).
        // Example: 0xFFFFFFFF - 0x100000000 => -1.
        // We simply and with the sign-bit and multiply by two. If the sign-bit
        // was set, then the result is 0. Otherwise it will become 2^32.
        final int SIGN_BIT = 0x80000000;
        truncatedValue -= 2 * (truncatedValue & SIGN_BIT);
      }
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

  String get name => dartNegateOperation.name;

  ConstantValue fold(ConstantValue constant) {
    if (constant.isInt) {
      IntConstantValue intConstant = constant;
      if (intConstant.primitiveValue == 0) {
        return JAVA_SCRIPT_CONSTANT_SYSTEM.createDouble(-0.0);
      }
    }
    return dartNegateOperation.fold(constant);
  }
}

class JavaScriptAddOperation implements BinaryOperation {
  final _addOperation = const AddOperation();
  String get name => _addOperation.name;

  const JavaScriptAddOperation();

  ConstantValue fold(ConstantValue left, ConstantValue right) {
    ConstantValue result = _addOperation.fold(left, right);
    if (result != null && result.isNum) {
      return JAVA_SCRIPT_CONSTANT_SYSTEM.convertToJavaScriptConstant(result);
    }
    return result;
  }

  apply(left, right) => _addOperation.apply(left, right);
}

class JavaScriptRemainderOperation extends ArithmeticNumOperation {
  String get name => 'remainder';

  const JavaScriptRemainderOperation();

  int foldInts(int left, int right) {
    if (right == 0) return null;
    return left.remainder(right);
  }

  num foldNums(num left, num right) => left.remainder(right);
  apply(left, right) => left.remainder(right);
}

class JavaScriptBinaryArithmeticOperation implements BinaryOperation {
  final BinaryOperation dartArithmeticOperation;

  const JavaScriptBinaryArithmeticOperation(this.dartArithmeticOperation);

  String get name => dartArithmeticOperation.name;

  ConstantValue fold(ConstantValue left, ConstantValue right) {
    ConstantValue result = dartArithmeticOperation.fold(left, right);
    if (result == null) return result;
    return JAVA_SCRIPT_CONSTANT_SYSTEM.convertToJavaScriptConstant(result);
  }

  apply(left, right) => dartArithmeticOperation.apply(left, right);
}

class JavaScriptIdentityOperation implements BinaryOperation {
  final IdentityOperation dartIdentityOperation = const IdentityOperation();

  const JavaScriptIdentityOperation();

  String get name => dartIdentityOperation.name;

  BoolConstantValue fold(ConstantValue left, ConstantValue right) {
    BoolConstantValue result = dartIdentityOperation.fold(left, right);
    if (result == null || result.primitiveValue) return result;
    // In JavaScript -0.0 === 0 and all doubles are equal to their integer
    // values. Furthermore NaN !== NaN.
    if (left.isNum && right.isNum) {
      NumConstantValue leftNum = left;
      NumConstantValue rightNum = right;
      double leftDouble = leftNum.primitiveValue.toDouble();
      double rightDouble = rightNum.primitiveValue.toDouble();
      return new BoolConstantValue(leftDouble == rightDouble);
    }
    return result;
  }

  apply(left, right) => identical(left, right);
}

class JavaScriptRoundOperation implements UnaryOperation {
  const JavaScriptRoundOperation();
  String get name => DART_CONSTANT_SYSTEM.round.name;
  ConstantValue fold(ConstantValue constant) {
    // Be careful to round() only values that do not throw on either the host or
    // target platform.
    ConstantValue tryToRound(num value) {
      // Due to differences between browsers, only 'round' easy cases. Avoid
      // cases where nudging the value up or down changes the answer.
      // 13 digits is safely within the ~15 digit precision of doubles.
      const severalULP = 0.0000000000001;
      // Use 'roundToDouble()' to avoid exceptions on rounding the nudged value.
      double rounded = value.roundToDouble();
      double rounded1 = (value * (1.0 + severalULP)).roundToDouble();
      double rounded2 = (value * (1.0 - severalULP)).roundToDouble();
      if (rounded != rounded1 || rounded != rounded2) return null;
      return JAVA_SCRIPT_CONSTANT_SYSTEM
          .convertToJavaScriptConstant(new IntConstantValue(value.round()));
    }

    if (constant.isInt) {
      IntConstantValue intConstant = constant;
      int value = intConstant.primitiveValue;
      if (value >= -double.MAX_FINITE && value <= double.MAX_FINITE) {
        return tryToRound(value);
      }
    }
    if (constant.isDouble) {
      DoubleConstantValue doubleConstant = constant;
      double value = doubleConstant.primitiveValue;
      // NaN and infinities will throw.
      if (value.isNaN) return null;
      if (value.isInfinite) return null;
      return tryToRound(value);
    }
    return null;
  }
}

/**
 * Constant system following the semantics for Dart code that has been
 * compiled to JavaScript.
 */
class JavaScriptConstantSystem extends ConstantSystem {
  final int BITS32 = 0xFFFFFFFF;

  final add = const JavaScriptAddOperation();
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
  final ifNull = const IfNullOperation();
  final lessEqual = const LessEqualOperation();
  final less = const LessOperation();
  final modulo =
      const JavaScriptBinaryArithmeticOperation(const ModuloOperation());
  final multiply =
      const JavaScriptBinaryArithmeticOperation(const MultiplyOperation());
  final negate = const JavaScriptNegateOperation();
  final not = const NotOperation();
  final remainder = const JavaScriptRemainderOperation();
  final shiftLeft =
      const JavaScriptBinaryBitOperation(const ShiftLeftOperation());
  final shiftRight = const JavaScriptShiftRightOperation();
  final subtract =
      const JavaScriptBinaryArithmeticOperation(const SubtractOperation());
  final truncatingDivide = const JavaScriptBinaryArithmeticOperation(
      const TruncatingDivideOperation());
  final codeUnitAt = const CodeUnitAtRuntimeOperation();
  final round = const JavaScriptRoundOperation();

  const JavaScriptConstantSystem();

  /**
   * Returns true if [value] will turn into NaN or infinity
   * at runtime.
   */
  bool integerBecomesNanOrInfinity(int value) {
    double doubleValue = value.toDouble();
    return doubleValue.isNaN || doubleValue.isInfinite;
  }

  NumConstantValue convertToJavaScriptConstant(NumConstantValue constant) {
    if (constant.isInt) {
      IntConstantValue intConstant = constant;
      int intValue = intConstant.primitiveValue;
      if (integerBecomesNanOrInfinity(intValue)) {
        return new DoubleConstantValue(intValue.toDouble());
      }
      // If the integer loses precision with JavaScript numbers, use
      // the floored version JavaScript will use.
      int floorValue = intValue.toDouble().floor().toInt();
      if (floorValue != intValue) {
        return new IntConstantValue(floorValue);
      }
    } else if (constant.isDouble) {
      DoubleConstantValue doubleResult = constant;
      double doubleValue = doubleResult.primitiveValue;
      if (!doubleValue.isInfinite &&
          !doubleValue.isNaN &&
          !constant.isMinusZero) {
        int intValue = doubleValue.truncate();
        if (intValue == doubleValue) {
          return new IntConstantValue(intValue);
        }
      }
    }
    return constant;
  }

  @override
  NumConstantValue createInt(int i) {
    return convertToJavaScriptConstant(new IntConstantValue(i));
  }

  NumConstantValue createInt32(int i) => new IntConstantValue(i & BITS32);
  NumConstantValue createDouble(double d) =>
      convertToJavaScriptConstant(new DoubleConstantValue(d));
  StringConstantValue createString(String string) {
    return new StringConstantValue(string);
  }

  BoolConstantValue createBool(bool value) => new BoolConstantValue(value);
  NullConstantValue createNull() => new NullConstantValue();

  @override
  ListConstantValue createList(InterfaceType type, List<ConstantValue> values) {
    return new ListConstantValue(type, values);
  }

  @override
  ConstantValue createType(CommonElements commonElements, DartType type) {
    InterfaceType instanceType = commonElements.typeLiteralType;
    return new TypeConstantValue(type, instanceType);
  }

  // Integer checks report true for -0.0, INFINITY, and -INFINITY.  At
  // runtime an 'X is int' check is implemented as:
  //
  // typeof(X) === "number" && Math.floor(X) === X
  //
  // We consistently match that runtime semantics at compile time as well.
  bool isInt(ConstantValue constant) {
    return constant.isInt ||
        constant.isMinusZero ||
        constant.isPositiveInfinity ||
        constant.isNegativeInfinity;
  }

  bool isDouble(ConstantValue constant) =>
      constant.isDouble && !constant.isMinusZero;
  bool isString(ConstantValue constant) => constant.isString;
  bool isBool(ConstantValue constant) => constant.isBool;
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

  MapConstantValue createMap(
      CommonElements commonElements,
      InterfaceType sourceType,
      List<ConstantValue> keys,
      List<ConstantValue> values) {
    bool onlyStringKeys = true;
    ConstantValue protoValue = null;
    for (int i = 0; i < keys.length; i++) {
      var key = keys[i];
      if (key.isString) {
        if (key.primitiveValue == JavaScriptMapConstant.PROTO_PROPERTY) {
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

  @override
  ConstantValue createSymbol(CommonElements commonElements, String text) {
    InterfaceType type = commonElements.symbolImplementationType;
    FieldEntity field = commonElements.symbolField;
    ConstantValue argument = createString(text);
    // TODO(johnniwinther): Use type arguments when all uses no longer expect
    // a [FieldElement].
    Map<FieldEntity, ConstantValue> fields = /*<FieldElement, ConstantValue>*/ {
      field: argument
    };
    return new ConstructedConstantValue(type, fields);
  }
}

class JavaScriptMapConstant extends MapConstantValue {
  /**
   * The [PROTO_PROPERTY] must not be used as normal property in any JavaScript
   * object. It would change the prototype chain.
   */
  static const String PROTO_PROPERTY = "__proto__";

  /** The dart class implementing constant map literals. */
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
