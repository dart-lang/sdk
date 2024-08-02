// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart';
import 'state_machine.dart';

mixin SyncStarCodeGeneratorMixin on StateMachineEntryAstCodeGenerator {
  late final ClassInfo suspendStateInfo =
      translator.classInfo[translator.suspendStateClass]!;

  late final ClassInfo syncStarIterableInfo =
      translator.classInfo[translator.syncStarIterableClass]!;

  @override
  void generateOuter(
      FunctionNode functionNode, Context? context, Source functionSource) {
    final resumeFun = _defineInnerBodyFunction(functionNode);

    // Instantiate a [_SyncStarIterable] containing the context and resume
    // function for this `sync*` function.
    DartType elementType = functionNode.emittedValueType!;
    translator.functions.recordClassAllocation(syncStarIterableInfo.classId);
    b.i32_const(syncStarIterableInfo.classId);
    b.i32_const(initialIdentityHash);
    types.makeType(this, elementType);
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(context.currentLocal);
    } else {
      b.ref_null(w.HeapType.struct);
    }
    b.global_get(translator.makeFunctionRef(resumeFun));
    b.struct_new(syncStarIterableInfo.struct);
    b.return_();
    b.end();

    SyncStarStateMachineCodeGenerator(translator, resumeFun, enclosingMember,
            functionNode, functionSource, closures)
        .generate(resumeFun.locals.toList(), null);
  }

  w.FunctionBuilder _defineInnerBodyFunction(FunctionNode functionNode) =>
      m.functions.define(
          m.types.defineFunction([
            suspendStateInfo.nonNullableType, // _SuspendState
            translator.topInfo.nullableType, // Object?, error value
            translator.stackTraceInfo.repr
                .nullableType // StackTrace?, error stack trace
          ], const [
            // bool for whether the generator has more to do
            w.NumType.i32
          ]),
          "${function.functionName} inner");
}

/// Generates code for sync* procedures.
class SyncStarProcedureCodeGenerator
    extends ProcedureStateMachineEntryCodeGenerator
    with SyncStarCodeGeneratorMixin {
  SyncStarProcedureCodeGenerator(
      super.translator, super.function, super.enclosingMember);
}

/// Generates code for sync* closures.
class SyncStarLambdaCodeGenerator extends LambdaStateMachineEntryCodeGenerator
    with SyncStarCodeGeneratorMixin {
  SyncStarLambdaCodeGenerator(
      super.translator, super.enclosingMember, super.lambda, super.closures);
}

/// A specialized code generator for generating code for `sync*` functions.
///
/// This will create an "outer" function which is a small function that just
/// instantiates and returns a [_SyncStarIterable], plus an "inner" function
/// containing the body of the `sync*` function.
///
/// For the inner function, all statements containing any `yield` or `yield*`
/// statements will be translated to an explicit control flow graph implemented
/// via a switch (via the Wasm `br_table` instruction) in a loop. This enables
/// the function to suspend its execution at yield points and jump back to the
/// point of suspension when the execution is resumed.
///
/// Local state is preserved via the closure contexts, which will implicitly
/// capture all local variables in a `sync*` function even if they are not
/// captured by any lambdas.
class SyncStarStateMachineCodeGenerator extends StateMachineCodeGenerator {
  SyncStarStateMachineCodeGenerator(
      super.translator,
      super.function,
      super.enclosingMember,
      super.functionNode,
      super.functionSource,
      super.closures);

  late final ClassInfo suspendStateInfo =
      translator.classInfo[translator.suspendStateClass]!;

  late final ClassInfo syncStarIterableInfo =
      translator.classInfo[translator.syncStarIterableClass]!;

  late final ClassInfo syncStarIteratorInfo =
      translator.classInfo[translator.syncStarIteratorClass]!;

  // Note: These locals are only available in "inner" functions.
  w.Local get _suspendStateLocal => function.locals[0];
  w.Local get _pendingExceptionLocal => function.locals[1];
  w.Local get _pendingStackTraceLocal => function.locals[2];

  @override
  void setSuspendStateCurrentException(void Function() emitValue) {
    b.local_get(_suspendStateLocal);
    emitValue();
    b.struct_set(
        suspendStateInfo.struct, FieldIndex.suspendStateCurrentException);
  }

  @override
  void getSuspendStateCurrentException() {
    b.local_get(_suspendStateLocal);
    b.struct_get(
        suspendStateInfo.struct, FieldIndex.suspendStateCurrentException);
  }

  @override
  void setSuspendStateCurrentStackTrace(void Function() emitValue) {
    b.local_get(_suspendStateLocal);
    emitValue();
    b.struct_set(suspendStateInfo.struct,
        FieldIndex.suspendStateCurrentExceptionStackTrace);
  }

  @override
  void getSuspendStateCurrentStackTrace() {
    b.local_get(_suspendStateLocal);
    b.struct_get(suspendStateInfo.struct,
        FieldIndex.suspendStateCurrentExceptionStackTrace);
  }

  @override
  void setSuspendStateCurrentReturnValue(void Function() emitValue) {}

  @override
  void getSuspendStateCurrentReturnValue() {}

  @override
  void emitReturn(void Function() emitValue) {
    // Set state target to final state.
    b.local_get(_suspendStateLocal);
    b.i32_const(targets.last.index);
    b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);

    // Return `false`.
    b.i32_const(0);
    b.return_();
  }

  @override
  void generateInner(FunctionNode functionNode, Context? context) {
    // Set up locals for contexts and `this`.
    thisLocal = null;
    Context? localContext = context;
    while (localContext != null) {
      if (!localContext.isEmpty) {
        localContext.currentLocal =
            b.addLocal(w.RefType.def(localContext.struct, nullable: true));
        if (localContext.containsThis) {
          assert(thisLocal == null);
          thisLocal = b.addLocal(localContext
              .struct.fields[localContext.thisFieldIndex].type.unpacked
              .withNullability(false));
          translator.globals.instantiateDummyValue(b, thisLocal!.type);
          b.local_set(thisLocal!);

          preciseThisLocal = thisLocal;
        }
      }
      localContext = localContext.parent;
    }

    // Read target index from the suspend state.
    targetIndexLocal = addLocal(w.NumType.i32);
    b.local_get(_suspendStateLocal);
    b.struct_get(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);
    b.local_set(targetIndexLocal);

    // Switch on the target index.
    masterLoop = b.loop(const [], const [w.NumType.i32]);
    labels = List.generate(targets.length, (_) => b.block()).reversed.toList();
    w.Label defaultLabel = b.block();
    b.local_get(targetIndexLocal);
    b.br_table(labels, defaultLabel);
    b.end(); // defaultLabel
    b.unreachable();

    // Initial state, executed on first [moveNext] on the iterator.
    StateTarget initialTarget = targets.first;
    emitTargetLabel(initialTarget);

    // Clone context on first execution.
    b.restoreSuspendStateContext(_suspendStateLocal, suspendStateInfo.struct,
        FieldIndex.suspendStateContext, closures, context, thisLocal,
        cloneContextFor: functionNode);

    visitStatement(functionNode.body!);

    // Final state: just keep returning.
    emitTargetLabel(targets.last);
    emitReturn(() {});
    b.end(); // masterLoop

    b.return_();
    b.end(); // inner function
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    // Evaluate operand and store it to `_current` for `yield` or
    // `_yieldStarIterable` for `yield*`.
    b.local_get(_suspendStateLocal);
    b.struct_get(suspendStateInfo.struct, FieldIndex.suspendStateIterator);
    wrap(node.expression, translator.topInfo.nullableType);
    if (node.isYieldStar) {
      b.ref_cast(translator.objectInfo.nonNullableType);
      b.struct_set(syncStarIteratorInfo.struct,
          FieldIndex.syncStarIteratorYieldStarIterable);
    } else {
      b.struct_set(
          syncStarIteratorInfo.struct, FieldIndex.syncStarIteratorCurrent);
    }

    // Find the current context.
    Context? context;
    TreeNode contextOwner = node;
    do {
      contextOwner = contextOwner.parent!;
      context = closures.contexts[contextOwner];
    } while (
        contextOwner.parent != null && (context == null || context.isEmpty));

    // Store context.
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(_suspendStateLocal);
      b.local_get(context.currentLocal);
      b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateContext);
    }

    // Set state target to label after yield.
    final StateTarget after = afterTargets[node]!;
    b.local_get(_suspendStateLocal);
    b.i32_const(after.index);
    b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);

    // Return `true`.
    b.i32_const(1);
    b.return_();

    // Resume.
    emitTargetLabel(after);

    b.restoreSuspendStateContext(_suspendStateLocal, suspendStateInfo.struct,
        FieldIndex.suspendStateContext, closures, context, thisLocal);

    // For `yield*`, check for pending exception.
    if (node.isYieldStar) {
      w.Label exceptionCheck = b.block();
      b.local_get(_pendingExceptionLocal);
      b.br_on_null(exceptionCheck);

      exceptionHandlers.forEachFinalizer((finalizer, last) {
        finalizer.setContinuationRethrow(() {
          b.local_get(_pendingExceptionLocal);
          b.ref_as_non_null();
        }, () => b.local_get(_pendingStackTraceLocal));
      });

      b.local_get(_suspendStateLocal);
      b.i32_const(targets.last.index);
      b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);

      b.local_get(_pendingStackTraceLocal);
      b.ref_as_non_null();

      b.throw_(translator.exceptionTag);
      b.end(); // exceptionCheck
    }
  }
}
