// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/flow_graph_builder.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/ir_to_text.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/library_index.dart' show LibraryIndex;

/// Build a fragment of IR corresponding to the recognized call or a function body.
/// Parameters are already pushed onto the [builder]'s stack.
typedef BuildIR = void Function(FlowGraphBuilder builder);

/// Base class for recognizing calls depending
/// on their argument types.
abstract class RecognizedCallMatcher {
  /// Returns non-null [BuildIR] function if call is recognized.
  BuildIR? match(List<CType> args);
}

/// Recognizes calls with arbitrary argument types.
class const AnyArgsMatcher(final BuildIR builder)
    implements RecognizedCallMatcher {
  @override
  BuildIR? match(List<CType> args) => builder;
}

/// Recognizes calls to binary [num] operations (except [num./]).
class const BinaryNumOp(
  final BinaryIntOpcode intOp,
  final BinaryDoubleOpcode doubleOp,
) implements RecognizedCallMatcher {
  /// Recognizes the following combinations of argument types:
  ///
  /// int op int -> int
  /// int op double -> double
  /// double op int -> double
  /// double op double -> double
  @override
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
class const NumDiv() implements RecognizedCallMatcher {
  @override
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

/// Recognizes calls to [num.isNaN].
class const NumIsNaN() implements RecognizedCallMatcher {
  @override
  BuildIR? match(List<CType> args) {
    switch (args) {
      case [IntType()]:
        return (FlowGraphBuilder builder) {
          builder.pop();
          builder.addBoolConstant(false);
        };
      case [DoubleType()]:
        return (FlowGraphBuilder builder) {
          final x = builder.pop();
          builder.push(x);
          builder.push(x);
          builder.addComparison(.doubleNotEqual);
        };
    }
    return null;
  }
}

/// Recognizes calls to [num.toDouble].
class const NumToDouble() implements RecognizedCallMatcher {
  @override
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
class const NumToInt() implements RecognizedCallMatcher {
  @override
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
class const NumComparison(
  final ComparisonOpcode intOp,
  final ComparisonOpcode doubleOp,
) implements RecognizedCallMatcher {
  @override
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
class const BinaryIntOp(final BinaryIntOpcode op)
    implements RecognizedCallMatcher {
  @override
  BuildIR? match(List<CType> args) {
    assert(args[0] is IntType && args[1] is IntType);
    return (FlowGraphBuilder builder) {
      builder.addBinaryIntOp(op);
    };
  }
}

/// Recognizes calls to unary [int] operations.
class const UnaryIntOp(final UnaryIntOpcode op)
    implements RecognizedCallMatcher {
  @override
  BuildIR? match(List<CType> args) {
    assert(args[0] is IntType);
    return (FlowGraphBuilder builder) {
      builder.addUnaryIntOp(op);
    };
  }
}

/// Recognizes calls to binary [double] operations.
class const BinaryDoubleOp(final BinaryDoubleOpcode op)
    implements RecognizedCallMatcher {
  @override
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
class const UnaryDoubleOp(final UnaryDoubleOpcode op)
    implements RecognizedCallMatcher {
  @override
  BuildIR? match(List<CType> args) {
    assert(args[0] is DoubleType);
    return (FlowGraphBuilder builder) {
      builder.addUnaryDoubleOp(op);
    };
  }
}

class const UnsafeCast() implements RecognizedCallMatcher {
  @override
  BuildIR? match(List<CType> args) {
    return (FlowGraphBuilder builder) {
      final value = builder.pop();
      final typeArgs = builder.pop();
      final testedType = CType.fromStaticType(switch (typeArgs) {
        TypeArguments() => typeArgs.types.single,
        Constant(
          value: ConstantValue(constant: TypeArgumentsConstant(:var types)),
        ) =>
          types.single,
        _ =>
          throw 'Unexpected unsafeCast type arguments ${IrToText.instruction(typeArgs)}',
      });
      final typeParameters = switch (typeArgs) {
        TypeArguments() => [
          for (var i = 0, n = typeArgs.inputCount; i < n; ++i)
            typeArgs.inputDefAt(i),
        ],
        Constant() => <Definition>[],
        _ =>
          throw 'Unexpected unsafeCast type arguments ${IrToText.instruction(typeArgs)}',
      };
      builder.push(value);
      builder.addTypeCast(
        testedType,
        typeParameters: typeParameters,
        isChecked: false,
      );
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

  /// Recognized static method calls.
  Map<ast.Member, RecognizedCallMatcher> get staticInvocations;

  /// Function body of the recognized functions.
  BuildIR? getRecognizedFunctionBody(CFunction function);
}

/// Recognized methods shared by all back-ends.
class CommonRecognizedMethods implements RecognizedMethods {
  final LibraryIndex index;
  final bool requireMethods;

  CommonRecognizedMethods({this.requireMethods = true})
    : index = GlobalContext.instance.coreLibraries;

  @override
  late final instanceInvocations = <ast.Member, RecognizedCallMatcher>{
    // Note: `const` is omitted on the values of null-aware map entries to work
    // around a prebuilt SDK CFE bug in `_translateNullAwareMapEntry`.
    ?getProcedure('dart:core', 'num', '+'): BinaryNumOp(
      BinaryIntOpcode.add,
      BinaryDoubleOpcode.add,
    ),
    ?getProcedure('dart:core', 'num', '-'): BinaryNumOp(
      BinaryIntOpcode.sub,
      BinaryDoubleOpcode.sub,
    ),
    ?getProcedure('dart:core', 'num', '*'): BinaryNumOp(
      BinaryIntOpcode.mul,
      BinaryDoubleOpcode.mul,
    ),
    ?getProcedure('dart:core', 'num', '%'): BinaryNumOp(
      BinaryIntOpcode.mod,
      BinaryDoubleOpcode.mod,
    ),
    ?getProcedure('dart:core', 'num', '~/'): BinaryNumOp(
      BinaryIntOpcode.truncatingDiv,
      BinaryDoubleOpcode.truncatingDiv,
    ),
    ?getProcedure('dart:core', 'num', 'remainder'): BinaryNumOp(
      BinaryIntOpcode.rem,
      BinaryDoubleOpcode.rem,
    ),
    ?getProcedure('dart:core', 'num', '/'): NumDiv(),
    ?getProcedure('dart:core', 'num', 'toDouble'): NumToDouble(),
    ?getProcedure('dart:core', 'num', 'toInt'): NumToInt(),
    ?getProcedure('dart:core', 'num', '=='): NumComparison(
      ComparisonOpcode.intEqual,
      ComparisonOpcode.doubleEqual,
    ),
    ?getProcedure('dart:core', 'num', '<'): NumComparison(
      ComparisonOpcode.intLess,
      ComparisonOpcode.doubleLess,
    ),
    ?getProcedure('dart:core', 'num', '<='): NumComparison(
      ComparisonOpcode.intLessOrEqual,
      ComparisonOpcode.doubleLessOrEqual,
    ),
    ?getProcedure('dart:core', 'num', '>'): NumComparison(
      ComparisonOpcode.intGreater,
      ComparisonOpcode.doubleGreater,
    ),
    ?getProcedure('dart:core', 'num', '>='): NumComparison(
      ComparisonOpcode.intGreaterOrEqual,
      ComparisonOpcode.doubleGreaterOrEqual,
    ),
    ?getProcedure('dart:core', 'int', '|'): BinaryIntOp(BinaryIntOpcode.bitOr),
    ?getProcedure('dart:core', 'int', '&'): BinaryIntOp(BinaryIntOpcode.bitAnd),
    ?getProcedure('dart:core', 'int', '^'): BinaryIntOp(BinaryIntOpcode.bitXor),
    ?getProcedure('dart:core', 'int', '<<'): BinaryIntOp(
      BinaryIntOpcode.shiftLeft,
    ),
    ?getProcedure('dart:core', 'int', '>>'): BinaryIntOp(
      BinaryIntOpcode.shiftRight,
    ),
    ?getProcedure('dart:core', 'int', '>>>'): BinaryIntOp(
      BinaryIntOpcode.unsignedShiftRight,
    ),
    ?getProcedure('dart:core', 'int', 'unary-'): UnaryIntOp(UnaryIntOpcode.neg),
    ?getProcedure('dart:core', 'int', '~'): UnaryIntOp(UnaryIntOpcode.bitNot),
    ?getProcedure('dart:core', 'int', 'abs'): UnaryIntOp(UnaryIntOpcode.abs),
    ?getProcedure('dart:core', 'double', '+'): BinaryDoubleOp(
      BinaryDoubleOpcode.add,
    ),
    ?getProcedure('dart:core', 'double', '-'): BinaryDoubleOp(
      BinaryDoubleOpcode.sub,
    ),
    ?getProcedure('dart:core', 'double', '*'): BinaryDoubleOp(
      BinaryDoubleOpcode.mul,
    ),
    ?getProcedure('dart:core', 'double', '%'): BinaryDoubleOp(
      BinaryDoubleOpcode.mod,
    ),
    ?getProcedure('dart:core', 'double', '/'): BinaryDoubleOp(
      BinaryDoubleOpcode.div,
    ),
    ?getProcedure('dart:core', 'double', '~/'): BinaryDoubleOp(
      BinaryDoubleOpcode.truncatingDiv,
    ),
    ?getProcedure('dart:core', 'double', 'remainder'): BinaryDoubleOp(
      BinaryDoubleOpcode.rem,
    ),
    ?getProcedure('dart:core', 'double', 'unary-'): UnaryDoubleOp(
      UnaryDoubleOpcode.neg,
    ),
    ?getProcedure('dart:core', 'double', 'abs'): UnaryDoubleOp(
      UnaryDoubleOpcode.abs,
    ),
    ?getProcedure('dart:core', 'double', 'round'): UnaryDoubleOp(
      UnaryDoubleOpcode.round,
    ),
    ?getProcedure('dart:core', 'double', 'ceil'): UnaryDoubleOp(
      UnaryDoubleOpcode.ceil,
    ),
    ?getProcedure('dart:core', 'double', 'floor'): UnaryDoubleOp(
      UnaryDoubleOpcode.floor,
    ),
    ?getProcedure('dart:core', 'double', 'truncate'): UnaryDoubleOp(
      UnaryDoubleOpcode.truncate,
    ),
    ?getProcedure('dart:core', 'double', 'roundToDouble'): UnaryDoubleOp(
      UnaryDoubleOpcode.roundToDouble,
    ),
    ?getProcedure('dart:core', 'double', 'ceilToDouble'): UnaryDoubleOp(
      UnaryDoubleOpcode.ceilToDouble,
    ),
    ?getProcedure('dart:core', 'double', 'floorToDouble'): UnaryDoubleOp(
      UnaryDoubleOpcode.floorToDouble,
    ),
    ?getProcedure('dart:core', 'double', 'truncateToDouble'): UnaryDoubleOp(
      UnaryDoubleOpcode.truncateToDouble,
    ),
  };

  @override
  late final instanceGetters = <ast.Member, RecognizedCallMatcher>{
    ?getProcedure('dart:core', 'num', 'get:isNaN'): NumIsNaN(),
    ?getProcedure('dart:core', 'int', 'get:sign'): UnaryIntOp(
      UnaryIntOpcode.sign,
    ),
    ?getProcedure('dart:core', 'int', 'get:bitLength'): UnaryIntOp(
      UnaryIntOpcode.bitLength,
    ),
    ?getProcedure('dart:core', 'double', 'get:sign'): UnaryDoubleOp(
      UnaryDoubleOpcode.sign,
    ),
  };

  late final _recognizedMembers = <ast.Member, BuildIR>{
    // dart:core
    ?getTopLevelProcedure(
      'dart:core',
      'identical',
    ): (FlowGraphBuilder builder) {
      builder.addComparison(.identical);
    },
  };

  @override
  late final staticInvocations = <ast.Member, RecognizedCallMatcher>{
    for (final MapEntry(key: member, value: builder)
        in _recognizedMembers.entries)
      member: AnyArgsMatcher(builder),

    // dart:_internal
    ?getTopLevelProcedure('dart:_internal', 'unsafeCast'): UnsafeCast(),
  };

  @override
  BuildIR? getRecognizedFunctionBody(CFunction function) =>
      _recognizedMembers[function.member];

  ast.Procedure? getProcedure(
    String libraryUri,
    String className,
    String memberName,
  ) => requireMethods
      ? index.getProcedure(libraryUri, className, memberName)
      : index.tryGetProcedure(libraryUri, className, memberName);

  ast.Procedure? getTopLevelProcedure(String libraryUri, String name) =>
      requireMethods
      ? index.getTopLevelProcedure(libraryUri, name)
      : index.tryGetProcedure(libraryUri, LibraryIndex.topLevel, name);
}
