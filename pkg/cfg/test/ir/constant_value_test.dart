// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  final component = readVmPlatformKernelFile();
  final coreTypes = CoreTypes(component);
  final classHierarchy = ClassHierarchy(component, coreTypes);
  final typeEnvironment = TypeEnvironment(coreTypes, classHierarchy);
  final globalContext = GlobalContext(typeEnvironment: typeEnvironment);

  group('constant values', () {
    setUp(() {
      GlobalContext.setCurrentContext(globalContext);
    });

    tearDown(() {
      GlobalContext.setCurrentContext(null);
    });

    test('int', () {
      final values = <int>[
        0x80000000_00000000,
        0x7fffffff_ffffffff,
        -1,
        0,
        1,
        42,
        -0xffffffff,
      ];
      for (final v in values) {
        final cv = ConstantValue.fromInt(v);
        expect(ConstantValue(ast.IntConstant(v)), equals(cv));
        expect(cv.isInt, isTrue);
        expect(cv.isDouble, isFalse);
        expect(cv.isBool, isFalse);
        expect(cv.isNull, isFalse);
        expect(cv.isString, isFalse);
        expect(cv.intValue, equals(v));
        expect(cv.type is IntType, isTrue);
        expect(cv.isZero, equals(v == 0));
        expect(cv.isNegative, equals(v < 0));
        expect(cv.valueToString(), equals(v.toString()));
      }
    });

    test('double', () {
      final values = <double>[
        -1.0,
        -0.0,
        0.0,
        1.0,
        double.infinity,
        double.negativeInfinity,
        double.nan,
        1e100,
      ];
      for (final v in values) {
        final cv = ConstantValue.fromDouble(v);
        expect(ConstantValue(ast.DoubleConstant(v)), equals(cv));
        expect(cv.isInt, isFalse);
        expect(cv.isDouble, isTrue);
        expect(cv.isBool, isFalse);
        expect(cv.isNull, isFalse);
        expect(cv.isString, isFalse);
        expect(cv.doubleValue, same(v));
        expect(cv.type is DoubleType, isTrue);
        expect(cv.isZero, equals(v == 0.0));
        expect(cv.isNegative, equals(v.isNegative));
        expect(cv.valueToString(), equals(v.toString()));
      }
    });

    test('bool', () {
      final values = <bool>[true, false];
      for (final v in values) {
        final cv = ConstantValue.fromBool(v);
        expect(ConstantValue(ast.BoolConstant(v)), equals(cv));
        expect(cv.isInt, isFalse);
        expect(cv.isDouble, isFalse);
        expect(cv.isBool, isTrue);
        expect(cv.isNull, isFalse);
        expect(cv.isString, isFalse);
        expect(cv.boolValue, equals(v));
        expect(cv.type is BoolType, isTrue);
        expect(cv.isZero, isFalse);
        expect(cv.isNegative, isFalse);
        expect(cv.valueToString(), equals(v.toString()));
      }
    });

    test('null', () {
      final cv = ConstantValue.fromNull();
      expect(ConstantValue(ast.NullConstant()), equals(cv));
      expect(cv.isInt, isFalse);
      expect(cv.isDouble, isFalse);
      expect(cv.isBool, isFalse);
      expect(cv.isNull, isTrue);
      expect(cv.isString, isFalse);
      expect(cv.type is NullType, isTrue);
      expect(cv.isZero, isFalse);
      expect(cv.isNegative, isFalse);
      expect(cv.valueToString(), equals(null.toString()));
    });

    test('string', () {
      final values = <String>['', 'a', 'abcdef'];
      for (final v in values) {
        final cv = ConstantValue.fromString(v);
        expect(ConstantValue(ast.StringConstant(v)), equals(cv));
        expect(cv.isInt, isFalse);
        expect(cv.isDouble, isFalse);
        expect(cv.isBool, isFalse);
        expect(cv.isNull, isFalse);
        expect(cv.isString, isTrue);
        expect(cv.stringValue, equals(v));
        expect(cv.type is StringType, isTrue);
        expect(cv.isZero, isFalse);
        expect(cv.isNegative, isFalse);
        expect(cv.valueToString(), equals('"$v"'));
      }
    });

    test('type arguments', () {
      final values = <List<ast.DartType>>[
        [],
        [coreTypes.stringNullableRawType],
        [coreTypes.intNonNullableRawType, coreTypes.stringNonNullableRawType],
      ];
      for (final v in values) {
        final cv = ConstantValue(TypeArgumentsConstant(v));
        expect(ConstantValue(TypeArgumentsConstant(List.of(v))), equals(cv));
        expect(cv.isInt, isFalse);
        expect(cv.isDouble, isFalse);
        expect(cv.isBool, isFalse);
        expect(cv.isNull, isFalse);
        expect(cv.isString, isFalse);
        expect(cv.type is TypeArgumentsType, isTrue);
        expect(cv.isZero, isFalse);
        expect(cv.isNegative, isFalse);
      }
    });
  });

  group('constant folding', () {
    final constantFolding = const ConstantFolding();

    setUp(() {
      GlobalContext.setCurrentContext(globalContext);
    });

    tearDown(() {
      GlobalContext.setCurrentContext(null);
    });

    test('comparison - equal', () {
      void eq(ConstantValue left, ConstantValue right) {
        expect(
          constantFolding
              .comparison(ComparisonOpcode.equal, left, right)
              .boolValue,
          isTrue,
        );
        expect(
          constantFolding
              .comparison(ComparisonOpcode.notEqual, left, right)
              .boolValue,
          isFalse,
        );
      }

      void ne(ConstantValue left, ConstantValue right) {
        expect(
          constantFolding
              .comparison(ComparisonOpcode.equal, left, right)
              .boolValue,
          isFalse,
        );
        expect(
          constantFolding
              .comparison(ComparisonOpcode.notEqual, left, right)
              .boolValue,
          isTrue,
        );
      }

      eq(ConstantValue.fromString('a'), ConstantValue.fromString('a'));
      ne(ConstantValue.fromString('a'), ConstantValue.fromString('b'));
      eq(ConstantValue.fromInt(42), ConstantValue.fromInt(42));
      ne(ConstantValue.fromInt(42), ConstantValue.fromInt(43));
      ne(ConstantValue.fromInt(0), ConstantValue.fromDouble(0.0));
      eq(
        ConstantValue.fromDouble(double.nan),
        ConstantValue.fromDouble(double.nan),
      );
      ne(ConstantValue.fromDouble(0.0), ConstantValue.fromDouble(-0.0));
    });

    test('comparison - identical', () {
      void eq(ConstantValue left, ConstantValue right) {
        expect(
          constantFolding
              .comparison(ComparisonOpcode.identical, left, right)
              .boolValue,
          isTrue,
        );
        expect(
          constantFolding
              .comparison(ComparisonOpcode.notIdentical, left, right)
              .boolValue,
          isFalse,
        );
      }

      void ne(ConstantValue left, ConstantValue right) {
        expect(
          constantFolding
              .comparison(ComparisonOpcode.identical, left, right)
              .boolValue,
          isFalse,
        );
        expect(
          constantFolding
              .comparison(ComparisonOpcode.notIdentical, left, right)
              .boolValue,
          isTrue,
        );
      }

      eq(ConstantValue.fromString('a'), ConstantValue.fromString('a'));
      ne(ConstantValue.fromString('a'), ConstantValue.fromString('b'));
      eq(ConstantValue.fromInt(42), ConstantValue.fromInt(42));
      ne(ConstantValue.fromInt(42), ConstantValue.fromInt(43));
      ne(ConstantValue.fromInt(0), ConstantValue.fromDouble(0.0));
      eq(
        ConstantValue.fromDouble(double.nan),
        ConstantValue.fromDouble(double.nan),
      );
      ne(ConstantValue.fromDouble(0.0), ConstantValue.fromDouble(-0.0));
    });

    test('comparison - int', () {
      final values = <(int, int)>[
        (0, 1),
        (1, 0),
        (42, 6),
        (10, -5),
        (-3, 1),
        (0x80000000_00000000, -1),
        (-10, 0x7fffffff_ffffffff),
      ];

      void testOp(
        ComparisonOpcode opcode,
        bool Function(int, int) expectedBehavior,
      ) {
        for (final pair in values) {
          expect(
            constantFolding
                .comparison(
                  opcode,
                  ConstantValue.fromInt(pair.$1),
                  ConstantValue.fromInt(pair.$2),
                )
                .boolValue,
            equals(expectedBehavior(pair.$1, pair.$2)),
          );
        }
      }

      testOp(ComparisonOpcode.intEqual, (int a, int b) => a == b);
      testOp(ComparisonOpcode.intNotEqual, (int a, int b) => a != b);
      testOp(ComparisonOpcode.intLess, (int a, int b) => a < b);
      testOp(ComparisonOpcode.intLessOrEqual, (int a, int b) => a <= b);
      testOp(ComparisonOpcode.intGreater, (int a, int b) => a > b);
      testOp(ComparisonOpcode.intGreaterOrEqual, (int a, int b) => a >= b);
    });

    test('comparison - double', () {
      final values = <(double, double)>[
        (1.0, 1.0),
        (1.0, -1.0),
        (0.0, -0.0),
        (42.0, double.infinity),
        (double.negativeInfinity, -1e100),
        (1.0, double.nan),
        (double.nan, double.nan),
      ];

      void testOp(
        ComparisonOpcode opcode,
        bool Function(double, double) expectedBehavior,
      ) {
        for (final pair in values) {
          expect(
            constantFolding
                .comparison(
                  opcode,
                  ConstantValue.fromDouble(pair.$1),
                  ConstantValue.fromDouble(pair.$2),
                )
                .boolValue,
            equals(expectedBehavior(pair.$1, pair.$2)),
          );
        }
      }

      testOp(ComparisonOpcode.doubleEqual, (double a, double b) => a == b);
      testOp(ComparisonOpcode.doubleNotEqual, (double a, double b) => a != b);
      testOp(ComparisonOpcode.doubleLess, (double a, double b) => a < b);
      testOp(
        ComparisonOpcode.doubleLessOrEqual,
        (double a, double b) => a <= b,
      );
      testOp(ComparisonOpcode.doubleGreater, (double a, double b) => a > b);
      testOp(
        ComparisonOpcode.doubleGreaterOrEqual,
        (double a, double b) => a >= b,
      );
    });

    test('binary int op', () {
      final values = <(int, int)>[
        (0, 1),
        (1, 0),
        (42, 6),
        (10, -5),
        (-3, 1),
        (0x80000000_00000000, -1),
        (-10, 0x7fffffff_ffffffff),
      ];

      void testOp(
        BinaryIntOpcode opcode,
        int Function(int, int) expectedBehavior,
      ) {
        for (final pair in values) {
          ConstantValue? expected;
          try {
            expected = ConstantValue.fromInt(
              expectedBehavior(pair.$1, pair.$2),
            );
          } on Error {
            // Ignore runtime errors.
          }
          expect(
            constantFolding.binaryIntOp(
              opcode,
              ConstantValue.fromInt(pair.$1),
              ConstantValue.fromInt(pair.$2),
            ),
            equals(expected),
          );
        }
      }

      testOp(BinaryIntOpcode.add, (int a, int b) => a + b);
      testOp(BinaryIntOpcode.sub, (int a, int b) => a - b);
      testOp(BinaryIntOpcode.mul, (int a, int b) => a * b);
      testOp(BinaryIntOpcode.truncatingDiv, (int a, int b) => a ~/ b);
      testOp(BinaryIntOpcode.mod, (int a, int b) => a % b);
      testOp(BinaryIntOpcode.rem, (int a, int b) => a.remainder(b));
      testOp(BinaryIntOpcode.bitOr, (int a, int b) => a | b);
      testOp(BinaryIntOpcode.bitAnd, (int a, int b) => a & b);
      testOp(BinaryIntOpcode.bitXor, (int a, int b) => a ^ b);
      testOp(BinaryIntOpcode.shiftLeft, (int a, int b) => a << b);
      testOp(BinaryIntOpcode.shiftRight, (int a, int b) => a >> b);
      testOp(BinaryIntOpcode.unsignedShiftRight, (int a, int b) => a >>> b);
    });

    test('unary int op', () {
      final values = <int>[
        0,
        1,
        -1,
        42,
        -123,
        0x80000000_00000000,
        0x7fffffff_ffffffff,
      ];

      void testOp(UnaryIntOpcode opcode, num Function(int) expectedBehavior) {
        for (final v in values) {
          final expected = expectedBehavior(v);
          final expectedConstValue = switch (expected) {
            double() => ConstantValue.fromDouble(expected),
            int() => ConstantValue.fromInt(expected),
          };
          expect(
            constantFolding.unaryIntOp(opcode, ConstantValue.fromInt(v)),
            equals(expectedConstValue),
          );
        }
      }

      testOp(UnaryIntOpcode.neg, (int v) => -v);
      testOp(UnaryIntOpcode.bitNot, (int v) => ~v);
      testOp(UnaryIntOpcode.toDouble, (int v) => v.toDouble());
      testOp(UnaryIntOpcode.abs, (int v) => v.abs());
      testOp(UnaryIntOpcode.sign, (int v) => v.sign);
    });

    test('binary double op', () {
      final values = <(double, double)>[
        (1.0, 1.0),
        (1.0, -1.0),
        (0.0, -0.0),
        (42.0, double.infinity),
        (double.negativeInfinity, -1e100),
        (1.0, double.nan),
        (double.nan, double.nan),
      ];

      void testOp(
        BinaryDoubleOpcode opcode,
        num Function(double, double) expectedBehavior,
      ) {
        for (final pair in values) {
          ConstantValue? expectedConstValue;
          try {
            final expected = expectedBehavior(pair.$1, pair.$2);
            expectedConstValue = switch (expected) {
              double() => ConstantValue.fromDouble(expected),
              int() => ConstantValue.fromInt(expected),
            };
          } on Error {
            // Ignore runtime errors.
          }
          expect(
            constantFolding.binaryDoubleOp(
              opcode,
              ConstantValue.fromDouble(pair.$1),
              ConstantValue.fromDouble(pair.$2),
            ),
            equals(expectedConstValue),
          );
        }
      }

      testOp(BinaryDoubleOpcode.add, (double a, double b) => a + b);
      testOp(BinaryDoubleOpcode.sub, (double a, double b) => a - b);
      testOp(BinaryDoubleOpcode.mul, (double a, double b) => a * b);
      testOp(BinaryDoubleOpcode.mod, (double a, double b) => a % b);
      testOp(BinaryDoubleOpcode.rem, (double a, double b) => a.remainder(b));
      testOp(BinaryDoubleOpcode.div, (double a, double b) => a / b);
      testOp(BinaryDoubleOpcode.truncatingDiv, (double a, double b) => a ~/ b);
    });

    test('unary double op', () {
      final values = <double>[
        1.0,
        -1.0,
        0.0,
        -0.0,
        42.0,
        -1e100,
        double.infinity,
        double.negativeInfinity,
        double.nan,
      ];

      void testOp(
        UnaryDoubleOpcode opcode,
        num Function(double) expectedBehavior,
      ) {
        for (final v in values) {
          ConstantValue? expectedConstValue;
          try {
            final expected = expectedBehavior(v);
            expectedConstValue = switch (expected) {
              double() => ConstantValue.fromDouble(expected),
              int() => ConstantValue.fromInt(expected),
            };
          } on Error {
            // Ignore runtime errors.
          }
          expect(
            constantFolding.unaryDoubleOp(opcode, ConstantValue.fromDouble(v)),
            equals(expectedConstValue),
          );
        }
      }

      testOp(UnaryDoubleOpcode.neg, (double v) => -v);
      testOp(UnaryDoubleOpcode.abs, (double v) => v.abs());
      testOp(UnaryDoubleOpcode.sign, (double v) => v.sign);
      testOp(UnaryDoubleOpcode.square, (double v) => v * v);
      testOp(UnaryDoubleOpcode.round, (double v) => v.round());
      testOp(UnaryDoubleOpcode.floor, (double v) => v.floor());
      testOp(UnaryDoubleOpcode.ceil, (double v) => v.ceil());
      testOp(UnaryDoubleOpcode.truncate, (double v) => v.truncate());
      testOp(UnaryDoubleOpcode.roundToDouble, (double v) => v.roundToDouble());
      testOp(UnaryDoubleOpcode.floorToDouble, (double v) => v.floorToDouble());
      testOp(UnaryDoubleOpcode.ceilToDouble, (double v) => v.ceilToDouble());
      testOp(
        UnaryDoubleOpcode.truncateToDouble,
        (double v) => v.truncateToDouble(),
      );
    });
  });
}
