// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/src/printer.dart' as ast_printer show AstPrinter;
import 'package:kernel/type_environment.dart' show StaticTypeContext;

/// Represents an arbitrary constant value.
///
/// [ConstantValue] is a thin wrapper around [ast.Constant].
/// Constants which do not have corresponding representation in AST
/// (e.g. constant type arguments) have dedicated subclasses of
/// [ast.AuxiliaryConstant].
extension type ConstantValue(ast.Constant constant) {
  factory ConstantValue.fromInt(int value) =>
      ConstantValue(ast.IntConstant(value));
  factory ConstantValue.fromDouble(double value) =>
      ConstantValue(ast.DoubleConstant(value));
  factory ConstantValue.fromBool(bool value) =>
      ConstantValue(ast.BoolConstant(value));
  factory ConstantValue.fromNull() => ConstantValue(ast.NullConstant());
  factory ConstantValue.fromString(String value) =>
      ConstantValue(ast.StringConstant(value));

  int get intValue => (constant as ast.IntConstant).value;
  double get doubleValue => (constant as ast.DoubleConstant).value;
  bool get boolValue => (constant as ast.BoolConstant).value;
  String get stringValue => (constant as ast.StringConstant).value;

  bool get isInt => constant is ast.IntConstant;
  bool get isDouble => constant is ast.DoubleConstant;
  bool get isBool => constant is ast.BoolConstant;
  bool get isNull => constant is ast.NullConstant;
  bool get isString => constant is ast.StringConstant;

  CType get type => switch (constant) {
    ast.IntConstant() => const IntType(),
    ast.DoubleConstant() => const DoubleType(),
    ast.BoolConstant() => const BoolType(),
    ast.NullConstant() => const NullType(),
    ast.StringConstant() => const StringType(),
    TypeArgumentsConstant() => const TypeArgumentsType(),
    _ => StaticType(
      constant.getType(GlobalContext.instance.staticTypeContextForConstants),
    ),
  };

  bool get isZero => switch (constant) {
    ast.IntConstant(:var value) => value == 0,
    ast.DoubleConstant(:var value) => value == 0.0,
    _ => false,
  };

  bool get isNegative => switch (constant) {
    ast.IntConstant(:var value) => value < 0,
    ast.DoubleConstant(:var value) => value.isNegative,
    _ => false,
  };

  String valueToString() => switch (constant) {
    ast.StringConstant(:var value) => '"${value}"',
    ast.PrimitiveConstant(:var value) => value.toString(),
    _ => constant.toString(),
  };
}

/// Utility class to perform operations on constant values.
///
/// Methods of this class return `null` when constant folding
/// cannot be performed (e.g. corresponding operation would
/// throw an exception at runtime).
class ConstantFolding {
  const ConstantFolding();

  ConstantValue comparison(
    ComparisonOpcode op,
    ConstantValue left,
    ConstantValue right,
  ) {
    final result = switch (op) {
      ComparisonOpcode.equal => left.constant == right.constant,
      ComparisonOpcode.notEqual => left.constant != right.constant,
      ComparisonOpcode.identical => left.constant == right.constant,
      ComparisonOpcode.notIdentical => left.constant != right.constant,
      ComparisonOpcode.intEqual => left.intValue == right.intValue,
      ComparisonOpcode.intNotEqual => left.intValue != right.intValue,
      ComparisonOpcode.intLess => left.intValue < right.intValue,
      ComparisonOpcode.intLessOrEqual => left.intValue <= right.intValue,
      ComparisonOpcode.intGreater => left.intValue > right.intValue,
      ComparisonOpcode.intGreaterOrEqual => left.intValue >= right.intValue,
      ComparisonOpcode.intTestIsZero => (left.intValue & right.intValue) == 0,
      ComparisonOpcode.intTestIsNotZero =>
        (left.intValue & right.intValue) != 0,
      ComparisonOpcode.doubleEqual => left.doubleValue == right.doubleValue,
      ComparisonOpcode.doubleNotEqual => left.doubleValue != right.doubleValue,
      ComparisonOpcode.doubleLess => left.doubleValue < right.doubleValue,
      ComparisonOpcode.doubleLessOrEqual =>
        left.doubleValue <= right.doubleValue,
      ComparisonOpcode.doubleGreater => left.doubleValue > right.doubleValue,
      ComparisonOpcode.doubleGreaterOrEqual =>
        left.doubleValue >= right.doubleValue,
    };
    return ConstantValue.fromBool(result);
  }

  ConstantValue? binaryIntOp(
    BinaryIntOpcode op,
    ConstantValue left,
    ConstantValue right,
  ) {
    final a = left.intValue;
    final b = right.intValue;
    switch (op) {
      case BinaryIntOpcode.add:
        return ConstantValue.fromInt(a + b);
      case BinaryIntOpcode.sub:
        return ConstantValue.fromInt(a - b);
      case BinaryIntOpcode.mul:
        return ConstantValue.fromInt(a * b);
      case BinaryIntOpcode.truncatingDiv:
        return (b != 0) ? ConstantValue.fromInt(a ~/ b) : null;
      case BinaryIntOpcode.mod:
        return (b != 0) ? ConstantValue.fromInt(a % b) : null;
      case BinaryIntOpcode.rem:
        return (b != 0) ? ConstantValue.fromInt(a.remainder(b)) : null;
      case BinaryIntOpcode.bitOr:
        return ConstantValue.fromInt(a | b);
      case BinaryIntOpcode.bitAnd:
        return ConstantValue.fromInt(a & b);
      case BinaryIntOpcode.bitXor:
        return ConstantValue.fromInt(a ^ b);
      case BinaryIntOpcode.shiftLeft:
        return (b >= 0) ? ConstantValue.fromInt(a << b) : null;
      case BinaryIntOpcode.shiftRight:
        return (b >= 0) ? ConstantValue.fromInt(a >> b) : null;
      case BinaryIntOpcode.unsignedShiftRight:
        return (b >= 0) ? ConstantValue.fromInt(a >>> b) : null;
    }
  }

  ConstantValue? unaryIntOp(UnaryIntOpcode op, ConstantValue operand) {
    final x = operand.intValue;
    switch (op) {
      case UnaryIntOpcode.neg:
        return ConstantValue.fromInt(-x);
      case UnaryIntOpcode.bitNot:
        return ConstantValue.fromInt(~x);
      case UnaryIntOpcode.toDouble:
        return ConstantValue.fromDouble(x.toDouble());
      case UnaryIntOpcode.abs:
        return ConstantValue.fromInt(x.abs());
      case UnaryIntOpcode.sign:
        return ConstantValue.fromInt(x.sign);
    }
  }

  ConstantValue? binaryDoubleOp(
    BinaryDoubleOpcode op,
    ConstantValue left,
    ConstantValue right,
  ) {
    final a = left.doubleValue;
    final b = right.doubleValue;
    switch (op) {
      case BinaryDoubleOpcode.add:
        return ConstantValue.fromDouble(a + b);
      case BinaryDoubleOpcode.sub:
        return ConstantValue.fromDouble(a - b);
      case BinaryDoubleOpcode.mul:
        return ConstantValue.fromDouble(a * b);
      case BinaryDoubleOpcode.mod:
        return ConstantValue.fromDouble(a % b);
      case BinaryDoubleOpcode.rem:
        return ConstantValue.fromDouble(a.remainder(b));
      case BinaryDoubleOpcode.div:
        return ConstantValue.fromDouble(a / b);
      case BinaryDoubleOpcode.truncatingDiv:
        final doubleResult = a / b;
        return doubleResult.isFinite
            ? ConstantValue.fromInt(doubleResult.truncate())
            : null;
    }
  }

  ConstantValue? unaryDoubleOp(UnaryDoubleOpcode op, ConstantValue operand) {
    final x = operand.doubleValue;
    switch (op) {
      case UnaryDoubleOpcode.neg:
        return ConstantValue.fromDouble(-x);
      case UnaryDoubleOpcode.abs:
        return ConstantValue.fromDouble(x.abs());
      case UnaryDoubleOpcode.sign:
        return ConstantValue.fromDouble(x.sign);
      case UnaryDoubleOpcode.square:
        return ConstantValue.fromDouble(x * x);
      case UnaryDoubleOpcode.round:
        return x.isFinite ? ConstantValue.fromInt(x.round()) : null;
      case UnaryDoubleOpcode.floor:
        return x.isFinite ? ConstantValue.fromInt(x.floor()) : null;
      case UnaryDoubleOpcode.ceil:
        return x.isFinite ? ConstantValue.fromInt(x.ceil()) : null;
      case UnaryDoubleOpcode.truncate:
        return x.isFinite ? ConstantValue.fromInt(x.truncate()) : null;
      case UnaryDoubleOpcode.roundToDouble:
        return ConstantValue.fromDouble(x.roundToDouble());
      case UnaryDoubleOpcode.floorToDouble:
        return ConstantValue.fromDouble(x.floorToDouble());
      case UnaryDoubleOpcode.ceilToDouble:
        return ConstantValue.fromDouble(x.ceilToDouble());
      case UnaryDoubleOpcode.truncateToDouble:
        return ConstantValue.fromDouble(x.truncateToDouble());
    }
  }

  ConstantValue? unaryBoolOp(UnaryBoolOpcode op, ConstantValue operand) {
    final x = operand.boolValue;
    switch (op) {
      case UnaryBoolOpcode.not:
        return ConstantValue.fromBool(!x);
    }
  }

  String? computeToString(ConstantValue value) {
    if (value.isString) {
      return value.stringValue;
    } else if (value.isInt) {
      return value.intValue.toString();
    } else if (value.isBool) {
      return value.boolValue.toString();
    } else if (value.isNull) {
      return null.toString();
    } else if (value.isDouble) {
      return value.doubleValue.toString();
    } else {
      return null;
    }
  }

  ConstantValue? stringInterpolation(List<ConstantValue> operands) {
    final buf = StringBuffer();
    for (final operand in operands) {
      final str = computeToString(operand);
      if (str == null) {
        return null;
      }
      buf.write(str);
    }
    return ConstantValue.fromString(buf.toString());
  }
}

/// Constant type arguments.
class TypeArgumentsConstant extends ast.AuxiliaryConstant {
  final List<ast.DartType> types;

  TypeArgumentsConstant(this.types);

  @override
  void visitChildren(ast.Visitor v) {
    ast.visitList(types, v);
  }

  @override
  void toTextInternal(ast_printer.AstPrinter printer) {
    printer.writeTypeArguments(types);
  }

  @override
  String toString() => toStringInternal();

  @override
  int get hashCode => listHashCode(types);

  @override
  bool operator ==(Object other) {
    return other is TypeArgumentsConstant &&
        listEquals(this.types, other.types);
  }

  @override
  ast.DartType getType(StaticTypeContext context) => const ast.DynamicType();
}

/// Synthetic sentinel value which can be used by certain back-ends to
/// represent the uninitialized value of a late or static field, late variable or
/// value of an optional parameter which was not passed.
class SentinelConstant extends ast.AuxiliaryConstant {
  SentinelConstant();

  @override
  void visitChildren(ast.Visitor v) {}

  @override
  void toTextInternal(ast_printer.AstPrinter printer) => '#sentinel';

  @override
  String toString() => toStringInternal();

  @override
  int get hashCode => 2031;

  @override
  bool operator ==(Object other) => other is SentinelConstant;

  @override
  ast.DartType getType(StaticTypeContext context) => const ast.DynamicType();
}
