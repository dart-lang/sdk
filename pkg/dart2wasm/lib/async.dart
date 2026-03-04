// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart';
import 'state_machine.dart';
import 'translator.dart' show CompilationTask;

mixin AsyncCodeGeneratorMixin on StateMachineEntryAstCodeGenerator {
  late final ClassInfo asyncSuspendStateInfo =
      translator.classInfo[translator.asyncSuspendStateClass]!;

  @override
  void generateOuter(
      FunctionNode functionNode, Context? context, Source functionSource) {
    final resumeFun = _defineInnerBodyFunction(functionNode);

    // Outer (wrapper) function creates async state, calls the inner function
    // (which runs until first suspension point, i.e. `await`), and returns the
    // completer's future.

    // (1) Create async state.

    final asyncStateLocal = b.addLocal(
        w.RefType(asyncSuspendStateInfo.struct, nullable: false),
        name: "asyncState");

    // AsyncResumeFun _resume
    translator.globals.readGlobal(b, translator.makeFunctionRef(resumeFun));

    // WasmStructRef? _context
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(context.currentLocal);
    } else {
      b.ref_null(w.HeapType.struct);
    }

    // _Future _future
    types.makeType(this, functionNode.emittedValueType!);
    call(translator.makeFuture.reference);

    // Allocate `_AsyncSuspendState`
    call(translator.newAsyncSuspendState.reference);
    b.local_set(asyncStateLocal);

    // (2) Call inner function.
    //
    // Note: the inner function does not throw, so we don't need a `try` block
    // here.

    b.local_get(asyncStateLocal);
    b.ref_null(translator.topType.heapType); // await value
    b.ref_null(translator.topType.heapType); // error value
    b.ref_null(translator.stackTraceType.heapType); // stack trace
    translator.callFunction(resumeFun, b);
    b.drop(); // drop null

    // (3) Return the future.

    b.local_get(asyncStateLocal);
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateFuture);
    b.return_();
    b.end();

    translator.compilationQueue.add(CompilationTask(
        resumeFun,
        AsyncStateMachineCodeGenerator(translator, resumeFun, enclosingMember,
            functionNode, functionSource, closures)));
  }

  w.FunctionBuilder _defineInnerBodyFunction(FunctionNode functionNode) =>
      b.moduleBuilder.functions.define(
          translator.typesBuilder.defineFunction([
            asyncSuspendStateInfo.nonNullableType, // _AsyncSuspendState
            translator.topType, // Object?, await value
            translator.topType, // Object?, error value
            translator.stackTraceTypeNullable // StackTrace?, error stack trace
          ], [
            // Inner function does not return a value, but it's Dart type is
            // `void Function(...)` and all Dart functions return a value, so we
            // add a return type.
            translator.topType
          ]),
          "${function.functionName} inner");
}

/// Generates code for async procedures.
class AsyncProcedureCodeGenerator
    extends ProcedureStateMachineEntryCodeGenerator
    with AsyncCodeGeneratorMixin {
  AsyncProcedureCodeGenerator(
      super.translator, super.function, super.enclosingMember);
}

/// Generates code for async closures.
class AsyncLambdaCodeGenerator extends LambdaStateMachineEntryCodeGenerator
    with AsyncCodeGeneratorMixin {
  AsyncLambdaCodeGenerator(
      super.translator, super.enclosingMember, super.lambda, super.closures);
}

class AsyncStateMachineCodeGenerator extends StateMachineCodeGenerator {
  AsyncStateMachineCodeGenerator(
      super.translator,
      super.function,
      super.enclosingMember,
      super.functionNode,
      super.functionSource,
      super.closures);

  late final ClassInfo asyncSuspendStateInfo =
      translator.classInfo[translator.asyncSuspendStateClass]!;

  w.Local get _suspendStateLocal => function.locals[0];
  w.Local get _awaitValueLocal => function.locals[1];
  w.Local get _pendingExceptionLocal => function.locals[2];
  w.Local get _pendingStackTraceLocal => function.locals[3];

  @override
  void setSuspendStateCurrentException(void Function() emitValue) {
    b.local_get(_suspendStateLocal);
    emitValue();
    b.struct_set(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentException);
  }

  @override
  void getSuspendStateCurrentException() {
    b.local_get(_suspendStateLocal);
    b.struct_get(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentException);
  }

  @override
  void setSuspendStateCurrentStackTrace(void Function() emitValue) {
    b.local_get(_suspendStateLocal);
    emitValue();
    b.struct_set(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentExceptionStackTrace);
  }

  @override
  void getSuspendStateCurrentStackTrace() {
    b.local_get(_suspendStateLocal);
    b.struct_get(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentExceptionStackTrace);
  }

  @override
  void setSuspendStateCurrentReturnValue(void Function() emitValue) {
    b.local_get(_suspendStateLocal);
    emitValue();
    b.struct_set(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentReturnValue);
  }

  @override
  void getSuspendStateCurrentReturnValue() {
    b.local_get(_suspendStateLocal);
    b.struct_get(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentReturnValue);
  }

  @override
  void emitReturn(void Function() emitValue) {
    b.local_get(_suspendStateLocal);
    emitValue();
    call(translator.getFunctionEntry(
        translator.asyncSuspendStateComplete.reference,
        uncheckedEntry: true));
    b.return_();
  }

  @override
  void generateInner(FunctionNode functionNode, Context? context) {
    // void Function(_AsyncSuspendState, Object?, Object?, StackTrace?)

    final functionBody = functionNode.body!;

    // Set up locals for contexts and `this`.
    thisLocal = null;
    Context? localContext = context;
    while (localContext != null) {
      if (!localContext.isEmpty) {
        localContext.currentLocal = b.addLocal(
            w.RefType.def(localContext.struct, nullable: true),
            name: "context");
        if (localContext.containsThis) {
          assert(thisLocal == null);
          thisLocal = b.addLocal(
              localContext
                  .struct.fields[localContext.thisFieldIndex].type.unpacked
                  .withNullability(false),
              name: "this");
          translator
              .getDummyValuesCollectorForModule(b.moduleBuilder)
              .instantiateLocalDummyValue(b, thisLocal!.type);
          b.local_set(thisLocal!);

          preciseThisLocal = thisLocal;
        }
      }
      localContext = localContext.parent;
    }

    // Read target index from the suspend state.
    targetIndexLocal = addLocal(w.NumType.i32, name: "targetIndex");
    b.local_get(_suspendStateLocal);
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateTargetIndex);
    b.local_set(targetIndexLocal);

    // The outer `try` block calls `completeOnError` on exceptions.
    b.try_legacy();

    // Switch on the target index.
    masterLoop = b.loop(const [], const []);
    labels = List.generate(targets.length, (_) => b.block()).reversed.toList();

    // There should be at least two states: inner and after targets for the
    // [FunctionNode].
    assert(labels.length >= 2);

    // Use the last target label as the default `br_table` target.
    final brTableLabels = labels.sublist(0, labels.length - 1);
    final brTableDefaultLabel = labels.last;
    b.local_get(targetIndexLocal);
    b.br_table(brTableLabels, brTableDefaultLabel);

    // Initial state
    final StateTarget initialTarget = targets.first;
    emitTargetLabel(initialTarget);

    b.restoreSuspendStateContext(
        _suspendStateLocal,
        asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateContext,
        closures,
        context,
        thisLocal);

    translateStatement(functionBody);

    // Final state: return.
    emitTargetLabel(targets.last);
    b.local_get(_suspendStateLocal);
    b.ref_null(translator.topType.heapType);
    call(translator.getFunctionEntry(
        translator.asyncSuspendStateComplete.reference,
        uncheckedEntry: true));
    b.return_();
    b.end(); // masterLoop

    final stackTraceLocal = addLocal(translator.stackTraceType);
    final exceptionLocal = addLocal(translator.topTypeNonNullable);

    void callCompleteError() {
      b.local_get(_suspendStateLocal);
      b.local_get(exceptionLocal);
      b.local_get(stackTraceLocal);
      call(translator.asyncSuspendStateCompleteError.reference);
      b.return_();
    }

    // Handle Dart exceptions.
    b.catch_legacy(translator.getDartExceptionTag(b.moduleBuilder));
    b.local_set(stackTraceLocal);
    b.local_set(exceptionLocal);
    callCompleteError();

    // Handle JS exceptions.
    b.catch_legacy(translator.getJsExceptionTag(b.moduleBuilder));

    final jsExceptionLocal = addLocal(w.RefType.extern(nullable: true));
    b.local_tee(jsExceptionLocal);

    call(translator.boxJsException.reference);
    b.local_tee(exceptionLocal); // ref null #Top

    b.local_get(jsExceptionLocal);
    call(translator.jsExceptionStackTrace.reference);
    b.local_set(stackTraceLocal);

    callCompleteError();

    b.end(); // try

    b.unreachable();
    b.end(); // inner function
  }

  // Handle awaits
  @override
  void visitExpressionStatement(ExpressionStatement node) {
    // All `await` expressions are transformed into variable sets of `await` by
    // `_AwaitTransformer`.
    final expression = node.expression;
    if (expression is VariableSet) {
      final value = expression.value;
      if (value is AwaitExpression) {
        _generateAwait(value, expression.variable);
        return;
      }
    }

    super.visitExpressionStatement(node);
  }

  void _generateAwait(AwaitExpression node, VariableDeclaration awaitValueVar) {
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
      b.struct_set(
          asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateContext);
    }

    // Set state target to label after await.
    final StateTarget after = afterTargets[node]!;
    b.local_get(_suspendStateLocal);
    b.i32_const(after.index);
    b.struct_set(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateTargetIndex);

    final DartType? runtimeType = node.runtimeCheckType;
    DartType? futureTypeParam;
    if (runtimeType != null) {
      final futureType = runtimeType as InterfaceType;
      assert(futureType.classNode == translator.coreTypes.futureClass);
      assert(futureType.typeArguments.length == 1);
      futureTypeParam = futureType.typeArguments[0];
    }

    if (futureTypeParam != null) {
      types.makeType(this, futureTypeParam);
    }
    b.local_get(_suspendStateLocal);

    final awaitHelper = runtimeType == null
        ? translator.awaitHelper
        : translator.awaitHelperWithTypeCheck;

    final awaitHelperType =
        translator.functions.getFunctionType(awaitHelper.reference);

    translateExpression(node.operand, awaitHelperType.inputs.last);
    call(awaitHelper.reference);
    b.return_();

    // Generate resume label
    emitTargetLabel(after);

    b.restoreSuspendStateContext(
        _suspendStateLocal,
        asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateContext,
        closures,
        context,
        thisLocal);

    // Handle exceptions
    final exceptionBlock = b.block();
    b.local_get(_pendingExceptionLocal);
    b.br_on_null(exceptionBlock);

    exceptionHandlers.forEachFinalizer((finalizer, last) {
      finalizer.setContinuationRethrow(() {
        b.local_get(_pendingExceptionLocal);
        b.ref_as_non_null();
      }, () => b.local_get(_pendingStackTraceLocal));
    });

    b.local_get(_pendingStackTraceLocal);
    b.ref_as_non_null();

    b.throw_(translator.getDartExceptionTag(b.moduleBuilder));
    b.end(); // exceptionBlock

    setVariable(awaitValueVar, () {
      b.local_get(_awaitValueLocal);
      translator.convertType(
          b, _awaitValueLocal.type, translateType(awaitValueVar.type));
    });
  }
}
