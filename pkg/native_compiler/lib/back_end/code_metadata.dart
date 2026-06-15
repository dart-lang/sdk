// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/source_position.dart';
import 'package:kernel/ast.dart' as ast;

class ExceptionHandler._(
  final int index,
  final int outerIndex,
  final bool isSynthetic,
  final bool needsStackTrace,
  final List<ast.DartType> guardTypes,
) {
  late final int pcOffset;

  bool get hasCatchAll => guardTypes.any(_isCatchAll);

  static bool _isCatchAll(ast.DartType guardType) => switch (guardType) {
    ast.DynamicType() => true,
    ast.VoidType() => true,
    ast.InterfaceType() =>
      guardType.classNode == GlobalContext.instance.coreTypes.objectClass,
    ast.FutureOrType() => _isCatchAll(guardType.typeArgument),
    ast.ExtensionType() => _isCatchAll(guardType.extensionTypeErasure),
    _ => false,
  };
}

/// Metadata describing exception handlers.
class ExceptionHandlers {
  /// Whether this code has a top-level async exception handler.
  final bool hasAsyncHandler;
  final Map<CatchBlock, ExceptionHandler> _handlers = {};

  ExceptionHandlers({required this.hasAsyncHandler});

  Iterable<ExceptionHandler> get handlers => _handlers.values;

  ExceptionHandler getHandler(CatchBlock catchBlock) =>
      _handlers[catchBlock] ??= _createHandler(catchBlock);

  ExceptionHandler _createHandler(CatchBlock catchBlock) {
    final outerHandler = catchBlock.exceptionHandler;
    final outerIndex = outerHandler != null
        ? getHandler(outerHandler).index
        : -1;
    var needsStackTrace = false;
    for (final instr in catchBlock) {
      if (instr is! Parameter) break;
      if (instr.variable.isStackTraceVariable) {
        needsStackTrace = instr.hasUses;
        break;
      }
    }
    return ExceptionHandler._(
      _handlers.length,
      outerIndex,
      catchBlock.isSynthetic,
      needsStackTrace,
      catchBlock.guardTypes,
    );
  }

  @override
  int get hashCode =>
      _handlers.isEmpty ? hasAsyncHandler.hashCode : identityHashCode(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (_handlers.isEmpty &&
          other is ExceptionHandlers &&
          other._handlers.isEmpty &&
          this.hasAsyncHandler == other.hasAsyncHandler);
}

class CallSite(
  final int pcOffset,
  final int exceptionHandlerIndex,
  final SourcePosition sourcePosition,
);

/// Metadata describing call sites (aka PC descriptors).
class PcDescriptors {
  final List<CallSite> callSites = [];

  void add(CallSite cs) {
    assert(callSites.isEmpty || callSites.last.pcOffset < cs.pcOffset);
    callSites.add(cs);
  }

  @override
  int get hashCode => callSites.isEmpty ? 37 : identityHashCode(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (callSites.isEmpty && other is PcDescriptors && other.callSites.isEmpty);
}

class ExceptionSite(final int pcOffset) {
  // TODO: add moves
}

/// Metadata describing how to move values from an exception site to the exception handler.
class CatchEntryMoves {
  final List<ExceptionSite> exceptionSites = [];

  void add(ExceptionSite es) {
    exceptionSites.add(es);
  }

  @override
  int get hashCode => exceptionSites.isEmpty ? 31 : identityHashCode(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (exceptionSites.isEmpty &&
          other is CatchEntryMoves &&
          other.exceptionSites.isEmpty);
}

class CodeSourcePosition(
  final int pcOffset,
  final SourcePosition sourcePosition,
);

/// Metadata describing source positions.
class CodeSourceMap {
  final List<CodeSourcePosition> sourcePositions = [];

  void add(CodeSourcePosition sp) {
    if (sourcePositions.isNotEmpty) {
      assert(sourcePositions.last.pcOffset < sp.pcOffset);
      if (sourcePositions.last.sourcePosition == sp.sourcePosition) {
        return;
      }
    }
    sourcePositions.add(sp);
  }

  @override
  int get hashCode => sourcePositions.isEmpty ? 23 : identityHashCode(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (sourcePositions.isEmpty &&
          other is CodeSourceMap &&
          other.sourcePositions.isEmpty);
}
