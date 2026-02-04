// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph_builder.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/library_index.dart' show LibraryIndex;

/// Build a fragment of IR corresponding to the body of
/// recognized method or recognized call.
typedef BuildIR = void Function(FlowGraphBuilder builder);

/// Base class for recognizing calls depending
/// on their argument types.
abstract class RecognizedCallMatcher {
  /// Returns non-null [BuildIR] function if call is recognized.
  BuildIR? match(List<CType> args);
}

/// Recognizes calls to binary [num] operations (except [num./]).
class BinaryNumOp implements RecognizedCallMatcher {
  final BinaryIntOpcode intOp;
  final BinaryDoubleOpcode doubleOp;

  const BinaryNumOp(this.intOp, this.doubleOp);

  /// Recognizes the following combinations of argument types:
  ///
  /// int op int -> int
  /// int op double -> double
  /// double op int -> double
  /// double op double -> double
  BuildIR? match(List<CType> args) {
    switch (args) {
      case [IntType(), IntType()]:
        return (FlowGraphBuilder builder) {
          builder.addBinaryIntOp(intOp);
        };
      case [IntType(), DoubleType()]:
        return (FlowGraphBuilder builder) {
          final right = builder.pop();
          builder.addUnaryIntOp(UnaryIntOpcode.toDouble);
          builder.push(right);
          builder.addBinaryDoubleOp(doubleOp);
        };
      case [DoubleType(), DoubleType()]:
        return (FlowGraphBuilder builder) {
          builder.addBinaryDoubleOp(doubleOp);
        };
      case [DoubleType(), IntType()]:
        return (FlowGraphBuilder builder) {
          builder.addUnaryIntOp(UnaryIntOpcode.toDouble);
          builder.addBinaryDoubleOp(doubleOp);
        };
    }
    return null;
  }
}

/// Recognizes calls to [num./].
class NumDiv implements RecognizedCallMatcher {
  const NumDiv();

  BuildIR? match(List<CType> args) {
    switch (args) {
      case [IntType(), IntType()]:
        return (FlowGraphBuilder builder) {
          final right = builder.pop();
          builder.addUnaryIntOp(UnaryIntOpcode.toDouble);
          builder.push(right);
          builder.addUnaryIntOp(UnaryIntOpcode.toDouble);
          builder.addBinaryDoubleOp(BinaryDoubleOpcode.div);
        };
      case [IntType(), DoubleType()]:
        return (FlowGraphBuilder builder) {
          final right = builder.pop();
          builder.addUnaryIntOp(UnaryIntOpcode.toDouble);
          builder.push(right);
          builder.addBinaryDoubleOp(BinaryDoubleOpcode.div);
        };
      case [DoubleType(), DoubleType()]:
        return (FlowGraphBuilder builder) {
          builder.addBinaryDoubleOp(BinaryDoubleOpcode.div);
        };
      case [DoubleType(), IntType()]:
        return (FlowGraphBuilder builder) {
          builder.addUnaryIntOp(UnaryIntOpcode.toDouble);
          builder.addBinaryDoubleOp(BinaryDoubleOpcode.div);
        };
    }
    return null;
  }
}

/// Recognizes calls to [num.toDouble].
class NumToDouble implements RecognizedCallMatcher {
  const NumToDouble();

  BuildIR? match(List<CType> args) {
    switch (args) {
      case [IntType()]:
        return (FlowGraphBuilder builder) {
          builder.addUnaryIntOp(UnaryIntOpcode.toDouble);
        };
      case [DoubleType()]:
        return (FlowGraphBuilder builder) {
          // no-op
        };
    }
    return null;
  }
}

/// Recognizes calls to [num.toInt].
class NumToInt implements RecognizedCallMatcher {
  const NumToInt();

  BuildIR? match(List<CType> args) {
    switch (args) {
      case [IntType()]:
        return (FlowGraphBuilder builder) {
          // no-op
        };
      case [DoubleType()]:
        return (FlowGraphBuilder builder) {
          builder.addUnaryDoubleOp(UnaryDoubleOpcode.truncate);
        };
    }
    return null;
  }
}

/// Recognizes calls to [num] comparisons.
class NumComparison implements RecognizedCallMatcher {
  final ComparisonOpcode intOp;
  final ComparisonOpcode doubleOp;

  const NumComparison(this.intOp, this.doubleOp);

  BuildIR? match(List<CType> args) {
    switch (args) {
      case [IntType(), IntType()]:
        return (FlowGraphBuilder builder) {
          builder.addComparison(intOp);
        };
      case [DoubleType(), DoubleType()]:
        return (FlowGraphBuilder builder) {
          builder.addComparison(doubleOp);
        };
    }
    // TODO(alexmarkov): support other combinations.
    return null;
  }
}

/// Recognizes calls to binary [int] operations.
class BinaryIntOp implements RecognizedCallMatcher {
  final BinaryIntOpcode op;

  const BinaryIntOp(this.op);

  BuildIR? match(List<CType> args) {
    assert(args[0] is IntType && args[1] is IntType);
    return (FlowGraphBuilder builder) {
      builder.addBinaryIntOp(op);
    };
  }
}

/// Recognizes calls to unary [int] operations.
class UnaryIntOp implements RecognizedCallMatcher {
  final UnaryIntOpcode op;

  const UnaryIntOp(this.op);

  BuildIR? match(List<CType> args) {
    assert(args[0] is IntType);
    return (FlowGraphBuilder builder) {
      builder.addUnaryIntOp(op);
    };
  }
}

/// Recognizes calls to binary [double] operations.
class BinaryDoubleOp implements RecognizedCallMatcher {
  final BinaryDoubleOpcode op;

  const BinaryDoubleOp(this.op);

  BuildIR? match(List<CType> args) {
    assert(args[0] is DoubleType);
    switch (args[1]) {
      case IntType():
        return (FlowGraphBuilder builder) {
          builder.addUnaryIntOp(UnaryIntOpcode.toDouble);
          builder.addBinaryDoubleOp(op);
        };
      case DoubleType():
        return (FlowGraphBuilder builder) {
          builder.addBinaryDoubleOp(op);
        };
      default:
        return null;
    }
  }
}

/// Recognizes calls to unary [double] operations.
class UnaryDoubleOp implements RecognizedCallMatcher {
  final UnaryDoubleOpcode op;

  const UnaryDoubleOp(this.op);

  BuildIR? match(List<CType> args) {
    assert(args[0] is DoubleType);
    return (FlowGraphBuilder builder) {
      builder.addUnaryDoubleOp(op);
    };
  }
}

/// Recognize certain Dart methods and calls based on the
/// target and static types and build IR for them.
abstract class RecognizedMethods {
  /// Recognized instance method calls.
  Map<ast.Member, RecognizedCallMatcher> get instanceInvocations;

  /// Recognized instance getter calls.
  Map<ast.Member, RecognizedCallMatcher> get instanceGetters;
}

/// Recognized methods shared by all back-ends.
class CommonRecognizedMethods implements RecognizedMethods {
  final LibraryIndex index;

  CommonRecognizedMethods() : index = GlobalContext.instance.coreTypes.index;

  late final instanceInvocations = <ast.Member, RecognizedCallMatcher>{
    index.getProcedure('dart:core', 'num', '+'): const BinaryNumOp(
      BinaryIntOpcode.add,
      BinaryDoubleOpcode.add,
    ),
    index.getProcedure('dart:core', 'num', '-'): const BinaryNumOp(
      BinaryIntOpcode.sub,
      BinaryDoubleOpcode.sub,
    ),
    index.getProcedure('dart:core', 'num', '*'): const BinaryNumOp(
      BinaryIntOpcode.mul,
      BinaryDoubleOpcode.mul,
    ),
    index.getProcedure('dart:core', 'num', '%'): const BinaryNumOp(
      BinaryIntOpcode.mod,
      BinaryDoubleOpcode.mod,
    ),
    index.getProcedure('dart:core', 'num', '~/'): const BinaryNumOp(
      BinaryIntOpcode.truncatingDiv,
      BinaryDoubleOpcode.truncatingDiv,
    ),
    index.getProcedure('dart:core', 'num', 'remainder'): const BinaryNumOp(
      BinaryIntOpcode.rem,
      BinaryDoubleOpcode.rem,
    ),
    index.getProcedure('dart:core', 'num', '/'): const NumDiv(),
    index.getProcedure('dart:core', 'num', 'toDouble'): const NumToDouble(),
    index.getProcedure('dart:core', 'num', 'toInt'): const NumToInt(),
    index.getProcedure('dart:core', 'num', '=='): const NumComparison(
      ComparisonOpcode.intEqual,
      ComparisonOpcode.doubleEqual,
    ),
    index.getProcedure('dart:core', 'num', '<'): const NumComparison(
      ComparisonOpcode.intLess,
      ComparisonOpcode.doubleLess,
    ),
    index.getProcedure('dart:core', 'num', '<='): const NumComparison(
      ComparisonOpcode.intLessOrEqual,
      ComparisonOpcode.doubleLessOrEqual,
    ),
    index.getProcedure('dart:core', 'num', '>'): const NumComparison(
      ComparisonOpcode.intGreater,
      ComparisonOpcode.doubleGreater,
    ),
    index.getProcedure('dart:core', 'num', '>='): const NumComparison(
      ComparisonOpcode.intGreaterOrEqual,
      ComparisonOpcode.doubleGreaterOrEqual,
    ),
    index.getProcedure('dart:core', 'int', '|'): const BinaryIntOp(
      BinaryIntOpcode.bitOr,
    ),
    index.getProcedure('dart:core', 'int', '&'): const BinaryIntOp(
      BinaryIntOpcode.bitAnd,
    ),
    index.getProcedure('dart:core', 'int', '^'): const BinaryIntOp(
      BinaryIntOpcode.bitXor,
    ),
    index.getProcedure('dart:core', 'int', '<<'): const BinaryIntOp(
      BinaryIntOpcode.shiftLeft,
    ),
    index.getProcedure('dart:core', 'int', '>>'): const BinaryIntOp(
      BinaryIntOpcode.shiftRight,
    ),
    index.getProcedure('dart:core', 'int', '>>>'): const BinaryIntOp(
      BinaryIntOpcode.unsignedShiftRight,
    ),
    index.getProcedure('dart:core', 'int', 'unary-'): const UnaryIntOp(
      UnaryIntOpcode.neg,
    ),
    index.getProcedure('dart:core', 'int', '~'): const UnaryIntOp(
      UnaryIntOpcode.bitNot,
    ),
    index.getProcedure('dart:core', 'int', 'abs'): const UnaryIntOp(
      UnaryIntOpcode.abs,
    ),
    index.getProcedure('dart:core', 'double', '+'): const BinaryDoubleOp(
      BinaryDoubleOpcode.add,
    ),
    index.getProcedure('dart:core', 'double', '-'): const BinaryDoubleOp(
      BinaryDoubleOpcode.sub,
    ),
    index.getProcedure('dart:core', 'double', '*'): const BinaryDoubleOp(
      BinaryDoubleOpcode.mul,
    ),
    index.getProcedure('dart:core', 'double', '%'): const BinaryDoubleOp(
      BinaryDoubleOpcode.mod,
    ),
    index.getProcedure('dart:core', 'double', '/'): const BinaryDoubleOp(
      BinaryDoubleOpcode.div,
    ),
    index.getProcedure('dart:core', 'double', '~/'): const BinaryDoubleOp(
      BinaryDoubleOpcode.truncatingDiv,
    ),
    index.getProcedure('dart:core', 'double', 'remainder'):
        const BinaryDoubleOp(BinaryDoubleOpcode.rem),
    index.getProcedure('dart:core', 'double', 'unary-'): const UnaryDoubleOp(
      UnaryDoubleOpcode.neg,
    ),
    index.getProcedure('dart:core', 'double', 'abs'): const UnaryDoubleOp(
      UnaryDoubleOpcode.abs,
    ),
    index.getProcedure('dart:core', 'double', 'round'): const UnaryDoubleOp(
      UnaryDoubleOpcode.round,
    ),
    index.getProcedure('dart:core', 'double', 'ceil'): const UnaryDoubleOp(
      UnaryDoubleOpcode.ceil,
    ),
    index.getProcedure('dart:core', 'double', 'floor'): const UnaryDoubleOp(
      UnaryDoubleOpcode.floor,
    ),
    index.getProcedure('dart:core', 'double', 'truncate'): const UnaryDoubleOp(
      UnaryDoubleOpcode.truncate,
    ),
    index.getProcedure('dart:core', 'double', 'roundToDouble'):
        const UnaryDoubleOp(UnaryDoubleOpcode.roundToDouble),
    index.getProcedure('dart:core', 'double', 'ceilToDouble'):
        const UnaryDoubleOp(UnaryDoubleOpcode.ceilToDouble),
    index.getProcedure('dart:core', 'double', 'floorToDouble'):
        const UnaryDoubleOp(UnaryDoubleOpcode.floorToDouble),
    index.getProcedure('dart:core', 'double', 'truncateToDouble'):
        const UnaryDoubleOp(UnaryDoubleOpcode.truncateToDouble),
  };

  late final instanceGetters = <ast.Member, RecognizedCallMatcher>{
    index.getProcedure('dart:core', 'int', 'get:sign'): const UnaryIntOp(
      UnaryIntOpcode.sign,
    ),
    index.getProcedure('dart:core', 'double', 'get:sign'): const UnaryDoubleOp(
      UnaryDoubleOpcode.sign,
    ),
  };
}
