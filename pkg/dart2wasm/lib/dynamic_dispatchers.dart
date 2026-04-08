// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart';
import 'functions.dart';
import 'translator.dart';

/// Unique dynamic call dispatchers per-module.dispachers
///
/// A dynamic call will use a dynamic call dispatcher in the same module. The
/// dispatcher will be specialized to the shape of the caller.
class DynamicDispatchers {
  final Translator translator;
  final w.ModuleBuilder callingModule;

  final Map<CallShape, CallTarget> _dispatchers = {};

  DynamicDispatchers(this.translator, this.callingModule);

  CallTarget getDispatcher(CallShape shape) {
    return _dispatchers[shape] ??= _DynamicDispatcherCallTarget(
      translator,
      shape,
      callingModule,
    );
  }
}

class _DynamicDispatcherCallTarget extends CallTarget {
  final Translator translator;
  final CallShape callShape;
  final w.ModuleBuilder callingModule;

  _DynamicDispatcherCallTarget(
    this.translator,
    this.callShape,
    this.callingModule,
  ) : assert(
        !translator.isDynamicSubmodule ||
            (callShape.name.text == 'call' && callShape is MethodCallShape),
      ),
      super(makeDynamicDispatcherSignature(translator, callShape));

  @override
  String get name => 'Dynamic dispatcher for $callShape';

  @override
  bool get supportsInlining => false;

  @override
  late final w.BaseFunction function = (() {
    final function = callingModule.functions.define(signature, name);
    final dispatcher = _DynamicDispatcherCodeGenerator(
      translator,
      callShape,
      function,
    );
    translator.compilationQueue.add(CompilationTask(function, dispatcher));
    return function;
  })();
}

/// Generates dispatching code to call the right dynamic function.
class _DynamicDispatcherCodeGenerator extends CodeGenerator {
  final Translator translator;
  final CallShape callerShape;
  final w.FunctionBuilder function;

  _DynamicDispatcherCodeGenerator(
    this.translator,
    this.callerShape,
    this.function,
  );

  @override
  void generate(
    w.InstructionsBuilder b,
    List<w.Local> paramLocals,
    w.Label? returnLabel,
  ) {
    assert(returnLabel == null); // no inlining support atm.
    switch (callerShape) {
      case GetterCallShape():
        _generateGetterCode(translator);
        break;

      case SetterCallShape():
        _generateSetterCode(translator);
        break;

      case MethodCallShape():
        _generateMethodCode(translator);
        break;
    }
  }

  void _generateGetterCode(Translator translator) {
    final nullableReceiverLocal = function.locals[0];
    final b = function.body;

    final noSuchMethodBlock = b.block();

    // Check for `null`.
    final receiverLocal = b.addLocal(translator.topTypeNonNullable);
    b.local_get(nullableReceiverLocal);
    b.br_on_null(noSuchMethodBlock);
    b.local_set(receiverLocal);

    final classIdLocal = b.addLocal(w.NumType.i32);
    b.local_get(receiverLocal);
    b.loadClassId(translator, receiverLocal.type);
    b.local_set(classIdLocal);

    _emitDynamicDispatchTableCall(
      b,
      callerShape,
      classIdLocal,
      receiverLocal,
      (_) {},
      noSuchMethodBlock,
    );

    b.end(); // noSuchMethodBlock

    b.local_get(nullableReceiverLocal);
    createGetterInvocationObject(translator, b, callerShape.name);
    translator.callReference(translator.invokeNoSuchMethod.reference, b);
    b.return_();
    b.end();
  }

  void _generateSetterCode(Translator translator) {
    final nullableReceiverLocal = function.locals[0];
    final positionalArgLocal = function.locals[1];

    final b = function.body;

    final noSuchMethodBlock = b.block();

    // Check for `null`.
    final receiverLocal = b.addLocal(translator.topTypeNonNullable);
    b.local_get(nullableReceiverLocal);
    b.br_on_null(noSuchMethodBlock);
    b.local_set(receiverLocal);

    final classIdLocal = b.addLocal(w.NumType.i32);
    b.local_get(receiverLocal);
    b.loadClassId(translator, receiverLocal.type);
    b.local_set(classIdLocal);

    _emitDynamicDispatchTableCall(
      b,
      callerShape,
      classIdLocal,
      receiverLocal,
      (b) => b.local_get(positionalArgLocal),
      noSuchMethodBlock,
    );

    b.end(); // noSuchMethodBlock
    b.local_get(nullableReceiverLocal);
    createSetterInvocationObject(
      translator,
      b,
      callerShape.name,
      positionalArgLocal,
    );
    translator.callReference(translator.invokeNoSuchMethod.reference, b);

    b.drop(); // drop noSuchMethod return value
    b.local_get(positionalArgLocal);
    b.return_();
    b.end();
  }

  void _generateMethodCode(Translator translator) {
    final callerShape = this.callerShape as MethodCallShape;
    final b = function.body;

    final nullableReceiverLocal = function.locals[0]; // ref #Top

    final noSuchMethodBlock = b.block();

    // Check for `null`.
    final receiverLocal = b.addLocal(translator.topTypeNonNullable);
    b.local_get(nullableReceiverLocal);
    b.br_on_null(noSuchMethodBlock);
    b.local_set(receiverLocal);

    final classIdLocal = b.addLocal(w.NumType.i32);
    b.local_get(receiverLocal);
    b.loadClassId(translator, receiverLocal.type);
    b.local_set(classIdLocal);

    // Try calling the method.
    _emitDynamicDispatchTableCall(b, callerShape, classIdLocal, receiverLocal, (
      b,
    ) {
      for (int i = 0; i < callerShape.totalArgumentCount; ++i) {
        b.local_get(function.locals[1 + i]);
      }
    }, noSuchMethodBlock);

    // Try calling via field.
    _emitDynamicDispatchTableCallViaField(
      b,
      callerShape,
      classIdLocal,
      nullableReceiverLocal,
      receiverLocal,
      noSuchMethodBlock,
    );

    b.end(); // noSuchMethodBlock

    // Unable to find a matching member, call `noSuchMethod`
    b.local_get(nullableReceiverLocal);
    for (int i = 0; i < callerShape.totalArgumentCount; ++i) {
      b.local_get(function.locals[1 + i]);
    }
    translator.callFunction(
      translator.functions.getInvocationCreatorStub(callerShape),
      b,
    );
    translator.callReference(translator.invokeNoSuchMethod.reference, b);
    b.return_();
    b.end();
  }

  // Emits code that tries to invoke the target via the dynamic table.
  //
  // It may
  //   * find the target, call it and return
  //   * explicitly jump to NSM
  //   * continue execution after this call
  //     - caller may continue trying call-via-field
  //     - caller may run NSM
  //
  void _emitDynamicDispatchTableCall(
    w.InstructionsBuilder b,
    CallShape callerShape,
    w.Local classIdLocal,
    w.Local receiverLocal,
    void Function(w.InstructionsBuilder) pushArguments,
    w.Label noSuchMethodBlock,
  ) {
    b.comment('_emitDynamicDispatchTableCall($callerShape)');
    final selector =
        translator.dynamicDispatchTable.dynamicSelectors[callerShape];
    final offset = selector?.offset;
    if (selector == null || offset == null) return;

    final table = translator.dynamicDispatchTable;

    final unsuccessful = b.block();
    final classIdsTable = table.getClassIdsTable(b.moduleBuilder);
    final indexLocal = b.addLocal(w.NumType.i32);
    b.local_get(classIdLocal);
    if (offset != 0) {
      b.i32_const(offset);
      b.i32_add();
    }
    b.local_tee(indexLocal);
    b.table_size(classIdsTable);
    b.i32_ge_u();
    b.br_if(unsuccessful);

    b.local_get(indexLocal);
    b.table_get(classIdsTable);
    b.br_on_null(unsuccessful);
    b.i31_get_u();
    b.local_get(classIdLocal);
    b.i32_eq();

    b.if_(); // classid match
    b.local_get(receiverLocal);
    pushArguments(b);
    b.local_get(indexLocal);
    translator.functions.recordDynamicSelectorUse(selector);
    b.table_get(table.getTargetsTable(b.moduleBuilder));

    // We know that the target class has a method with the correct name, but it
    // may not support the call shape we're using here. In this case the table
    // will have correct class id (so we pass above test) but there's no
    // function to call, as the shape doesn't match.
    // => We have to NSM here and not continue to call-via-field as that's
    //    incorrect.
    b.br_on_null(noSuchMethodBlock);

    b.ref_cast(w.RefType(selector.signature, nullable: false));
    b.call_ref(selector.signature);
    b.return_();
    b.end(); // if_ classid match

    b.end(); // fall through to unsuccessful
  }

  /// Tries to perform a dynamic method invocation via calling through getter.
  ///
  /// The caller established that the receiver does not have the method, but it
  /// may have a getter with same name that returns a callable (closure or
  /// object with `.call` method).
  void _emitDynamicDispatchTableCallViaField(
    w.InstructionsBuilder b,
    CallShape callerShape,
    w.Local classIdLocal,
    w.Local nullableReceiverLocal,
    w.Local receiverLocal,
    w.Label noSuchMethodBlock,
  ) {
    b.comment('_emitDynamicDispatchTableCallViaField');
    final selector = translator
        .dynamicDispatchTable
        .dynamicSelectors[GetterCallShape(callerShape.name)];
    final offset = selector?.offset;
    if (selector == null || offset == null) return;

    final table = translator.dynamicDispatchTable;

    final classIdsTable = table.getClassIdsTable(b.moduleBuilder);
    final indexLocal = b.addLocal(w.NumType.i32);
    b.local_get(classIdLocal);
    if (offset != 0) {
      b.i32_const(offset);
      b.i32_add();
    }
    b.local_tee(indexLocal);
    b.table_size(classIdsTable);
    b.i32_ge_u();
    b.br_if(noSuchMethodBlock);

    b.local_get(indexLocal);
    b.table_get(classIdsTable);
    b.br_on_null(noSuchMethodBlock);
    b.i31_get_u();
    b.local_get(classIdLocal);
    b.i32_eq();
    b.if_();
    // Match! Load from targets table and call getter.
    b.local_get(receiverLocal);
    b.local_get(indexLocal);
    translator.functions.recordDynamicSelectorUse(selector);
    b.call_indirect(selector.signature, table.getTargetsTable(b.moduleBuilder));
    // This also updates the `noSuchMethod` receiver.
    b.local_tee(nullableReceiverLocal);

    // Throw `NoSuchMethodError` if the value is null
    b.br_on_null(noSuchMethodBlock);
    b.local_tee(receiverLocal);

    _emitCallWithReceiver(b, receiverLocal, noSuchMethodBlock);
    b.return_();
    b.end();
  }

  /// Try to call a callable object (closure or object with `.call()` method)
  ///
  /// The caller established that the dynamic call receiver doesn't have a
  /// method, but it had a getter with same name. It called the getter which may
  /// have returned a callable object.
  ///
  /// This method tries to call it.
  void _emitCallWithReceiver(
    w.InstructionsBuilder b,
    w.Local receiverLocal,
    w.Label noSuchMethodBlock,
  ) {
    final callerShape = this.callerShape as MethodCallShape;

    // Invoke "call" if the value is not a closure
    b.loadClassId(translator, receiverLocal.type);
    b.i32_const((translator.closureInfo.classId as AbsoluteClassId).value);
    b.i32_ne();
    b.if_();
    // Value is not a closure
    final callForwarder = translator
        .getDynamicDispatchersForModule(b.moduleBuilder)
        .getDispatcher(
          MethodCallShape(
            Name('call'),
            callerShape.typeCount,
            callerShape.positionalCount,
            callerShape.named,
          ),
        )
        .function;

    b.local_get(receiverLocal);
    for (int i = 0; i < callerShape.totalArgumentCount; ++i) {
      b.local_get(function.locals[1 + i]);
    }
    translator.callFunction(callForwarder, b);
    b.return_();
    b.end();

    // Cast the closure to `#ClosureBase`
    final closureBaseType = w.RefType.def(
      translator.closureLayouter.closureBaseStruct,
      nullable: false,
    );
    final closureLocal = b.addLocal(closureBaseType);
    b.local_get(receiverLocal);
    b.ref_cast(closureBaseType);
    b.local_set(closureLocal);

    _emitClosureCall(b, closureLocal, noSuchMethodBlock);
  }

  void _emitClosureCall(
    w.InstructionsBuilder b,
    w.Local closureLocal,
    w.Label noSuchMethodBlock,
  ) {
    final (typeArgsLocal, positionalArgsLocal, namedArgsLocal) =
        _createArgumentArrays(b);

    final callerShape = this.callerShape as MethodCallShape;
    generateDynamicClosureCallShapeAndTypeCheck(
      translator,
      b,
      closureLocal,
      typeArgsLocal,
      positionalArgsLocal,
      namedArgsLocal,
      noSuchMethodBlock,
    );
    if (translator.dynamicModuleSupportEnabled) {
      generateDynamicClosureCallViaDynamicEntry(
        translator,
        b,
        closureLocal,
        typeArgsLocal,
        positionalArgsLocal,
        namedArgsLocal,
      );
    } else {
      void emitCallForTypeCount(int typeCount) {
        final representation = translator.closureLayouter
            .getClosureRepresentation(
              typeCount,
              callerShape.positionalCount,
              callerShape.named,
            );
        if (representation == null) {
          b.unreachable();
          return;
        }

        b.local_get(closureLocal);
        b.struct_get(
          translator.closureLayouter.closureBaseStruct,
          FieldIndex.closureContext,
        );
        for (int i = 0; i < typeCount; ++i) {
          b.local_get(typeArgsLocal);
          b.i32_const(i);
          b.array_get(translator.typeArrayType);
        }
        for (int i = 0; i < callerShape.positionalCount; ++i) {
          b.local_get(function.locals[1 + callerShape.typeCount + i]);
        }
        for (int i = 0; i < callerShape.named.length; ++i) {
          b.local_get(
            function.locals[1 +
                callerShape.typeCount +
                callerShape.positionalCount +
                i],
          );
        }

        final vtable = representation.vtableStruct;
        final vtableIndex = representation.fieldIndexForSignature(
          callerShape.positionalCount,
          callerShape.named,
        );

        b.local_get(closureLocal);
        b.struct_get(
          translator.closureLayouter.closureBaseStruct,
          FieldIndex.closureVtable,
        );
        b.ref_cast(w.RefType(vtable, nullable: false));
        b.struct_get(vtable, vtableIndex);
        b.call_ref(vtable.getVtableEntryAt(vtableIndex));
      }

      if (callerShape.typeCount == 0) {
        final maxTypeCount = translator.closureLayouter.maxTypeArgumentCount();
        b.emitDenseTableBranch(
          [translator.topType],
          maxTypeCount,
          () {
            b.local_get(typeArgsLocal);
            b.array_len();
          },
          (int typeCount) {
            emitCallForTypeCount(typeCount);
          },
          () {
            b.unreachable();
          },
        );
      } else {
        emitCallForTypeCount(callerShape.typeCount);
      }
    }
  }

  (w.Local, w.Local, w.Local) _createArgumentArrays(w.InstructionsBuilder b) {
    final callerShape = this.callerShape as MethodCallShape;
    // Load type parameter as WasmArray<_Type>
    final typeArgsLocal = b.addLocal(translator.typeArrayTypeRef);
    if (callerShape.typeCount == 0) {
      final emptyArray = translator.constants.makeArrayOf(
        translator.coreTypes.typeNonNullableRawType,
        [],
      );
      translator.constants.instantiateConstant(
        b,
        emptyArray,
        translator.typeArrayTypeRef,
      );
    } else {
      for (int i = 0; i < callerShape.typeCount; ++i) {
        b.local_get(function.locals[1 + i]);
      }
      b.array_new_fixed(translator.typeArrayType, callerShape.typeCount);
    }
    b.local_set(typeArgsLocal);

    // Load positional parameters as WasmArray<Object?>
    final positionalArgsLocal = b.addLocal(
      translator.nullableObjectArrayTypeRef,
    );
    if (callerShape.positionalCount == 0) {
      final emptyArray = translator.constants.makeArrayOf(
        translator.coreTypes.objectNullableRawType,
        [],
      );
      translator.constants.instantiateConstant(
        b,
        emptyArray,
        translator.nullableObjectArrayTypeRef,
      );
    } else {
      for (int i = 0; i < callerShape.positionalCount; ++i) {
        b.local_get(function.locals[1 + callerShape.typeCount + i]);
      }
      b.array_new_fixed(
        translator.nullableObjectArrayType,
        callerShape.positionalCount,
      );
    }
    b.local_set(positionalArgsLocal);

    // Load named parameters as WasmArray<Object?>
    final namedArgsLocal = b.addLocal(translator.nullableObjectArrayTypeRef);
    if (callerShape.named.isEmpty) {
      final emptyArray = translator.constants.makeArrayOf(
        translator.coreTypes.objectNullableRawType,
        [],
      );
      translator.constants.instantiateConstant(
        b,
        emptyArray,
        translator.nullableObjectArrayTypeRef,
      );
    } else {
      for (int i = 0; i < callerShape.named.length; ++i) {
        translator.constants.instantiateConstant(
          b,
          translator.symbols.symbolForNamedParameter(callerShape.named[i]),
          translator.topType,
        );
        b.local_get(
          function.locals[1 +
              callerShape.typeCount +
              callerShape.positionalCount +
              i],
        );
      }
      b.array_new_fixed(
        translator.nullableObjectArrayType,
        callerShape.named.length * 2,
      );
    }
    b.local_set(namedArgsLocal);

    return (typeArgsLocal, positionalArgsLocal, namedArgsLocal);
  }
}

/// Generate code that checks shape and type of the closure.
///
/// [closureLocal] should be a local of type `ref #ClosureBase` containing a
/// closure value.
///
///   * [typeArgsLocal] is a `WasmArray<_Type>`
///   * [posArgsLocal] is a `WasmArray<Object?>`
///   * [namedArgsLocal] is a `WasmArray<Object?>` - (symbol, value) pairs
///
/// Will update `typeArgsLocal` with default type arguments (if needed).
///
/// [noSuchMethodBlock] is used as the `br` target when the shape check fails.
void generateDynamicClosureCallShapeAndTypeCheck(
  Translator translator,
  w.InstructionsBuilder b,
  w.Local closureLocal,
  w.Local typeArgsLocal,
  w.Local posArgsLocal,
  w.Local namedArgsLocal,
  w.Label noSuchMethodBlock,
) {
  assert(typeArgsLocal.type == translator.typeArrayTypeRef);
  assert(posArgsLocal.type == translator.nullableObjectArrayTypeRef);
  assert(namedArgsLocal.type == translator.nullableObjectArrayTypeRef);

  // Read the `_FunctionType` field
  final functionTypeLocal = b.addLocal(
    translator.closureLayouter.functionTypeType,
  );
  b.local_get(closureLocal);
  b.struct_get(
    translator.closureLayouter.closureBaseStruct,
    FieldIndex.closureRuntimeType,
  );
  b.local_tee(functionTypeLocal);

  // If no type arguments were supplied but the closure has type parameters, use
  // the default values.
  b.local_get(typeArgsLocal);
  b.array_len();
  b.i32_eqz();
  b.if_();
  b.local_get(functionTypeLocal);
  b.struct_get(
    translator.classInfo[translator.functionTypeClass]!.struct,
    translator.fieldIndex[translator.functionTypeTypeParameterDefaultsField]!,
  );
  b.local_set(typeArgsLocal);
  b.end();

  // Check closure shape
  // [functionTypeLocal] already on the stack.
  b.local_get(typeArgsLocal);
  b.local_get(posArgsLocal);
  b.local_get(namedArgsLocal);
  translator.callReference(translator.checkClosureShape.reference, b);
  b.i32_eqz();
  b.br_if(noSuchMethodBlock);

  // Shape check passed, check types
  if (!translator.options.omitImplicitTypeChecks) {
    b.local_get(functionTypeLocal);
    b.local_get(typeArgsLocal);
    b.local_get(posArgsLocal);
    b.local_get(namedArgsLocal);
    translator.callReference(translator.checkClosureType.reference, b);
    b.drop();
  }

  // Type check passed \o/
}

void generateDynamicClosureCallViaDynamicEntry(
  Translator translator,
  w.InstructionsBuilder b,
  w.Local closureLocal,
  w.Local typeArgsLocal,
  w.Local posArgsLocal,
  w.Local namedArgsLocal,
) {
  assert(
    translator.dynamicModuleSupportEnabled ||
        translator.closureLayouter.usesFunctionApplyWithNamedArguments,
  );

  // Type check passed, call vtable entry
  b.local_get(closureLocal);
  b.local_get(typeArgsLocal);
  b.local_get(posArgsLocal);
  b.local_get(namedArgsLocal);

  // Get vtable
  b.local_get(closureLocal);
  b.struct_get(
    translator.closureLayouter.closureBaseStruct,
    FieldIndex.closureVtable,
  );

  // Get entry function
  b.struct_get(
    translator.closureLayouter.vtableBaseStruct,
    translator.closureLayouter.vtableDynamicClosureCallEntryIndex!,
  );
  b.call_ref(translator.dynamicCallVtableEntryFunctionType);
}

void generateDynamicClosureCallViaPositionalArgs(
  Translator translator,
  w.InstructionsBuilder b,
  w.Local closureLocal,
  w.Local typeArgsLocal,
  w.Local posArgsLocal,
) {
  assert(
    !translator.dynamicModuleSupportEnabled &&
        !translator.closureLayouter.usesFunctionApplyWithNamedArguments,
  );

  final maxTypeCount = translator.closureLayouter.maxTypeArgumentCount();
  b.emitDenseTableBranch(
    [translator.topType],
    maxTypeCount,
    () {
      b.local_get(typeArgsLocal);
      b.array_len();
    },
    (typeCount) {
      final maxPositionalCount = translator.closureLayouter
          .maxPositionalCountFor(typeCount);
      b.emitDenseTableBranch(
        [translator.topType],
        maxPositionalCount,
        () {
          b.local_get(posArgsLocal);
          b.array_len();
        },
        (posCount) {
          final representation = translator.closureLayouter
              .getClosureRepresentation(typeCount, posCount, []);
          if (representation == null) {
            // This is a call combination that the closure layouter determined
            // cannot occur in the program.
            b.unreachable();
            return;
          }

          b.local_get(closureLocal);
          b.struct_get(
            translator.closureLayouter.closureBaseStruct,
            FieldIndex.closureContext,
          );
          for (int i = 0; i < typeCount; ++i) {
            b.local_get(typeArgsLocal);
            b.i32_const(i);
            b.array_get(translator.typeArrayType);
          }
          for (int i = 0; i < posCount; ++i) {
            b.local_get(posArgsLocal);
            b.i32_const(i);
            b.array_get(translator.nullableObjectArrayType);
          }

          final vtable = representation.vtableStruct;
          final vtableIndex = representation.fieldIndexForSignature(
            posCount,
            [],
          );

          b.local_get(closureLocal);
          b.struct_get(
            translator.closureLayouter.closureBaseStruct,
            FieldIndex.closureVtable,
          );
          b.ref_cast(w.RefType(vtable, nullable: false));
          b.struct_get(vtable, vtableIndex);
          b.call_ref(vtable.getVtableEntryAt(vtableIndex));
        },
        () {
          b.unreachable();
        },
      );
    },
    () {
      b.unreachable();
    },
  );
}

void createGetterInvocationObject(
  Translator translator,
  w.InstructionsBuilder b,
  Name memberName,
) {
  translator.constants.instantiateConstant(
    b,
    translator.symbols.getterSymbolFromName(memberName),
    translator.classInfo[translator.symbolClass]!.nonNullableType,
  );

  translator.callReference(translator.invocationGetterFactory.reference, b);
}

void createSetterInvocationObject(
  Translator translator,
  w.InstructionsBuilder b,
  Name memberName,
  w.Local positionalArgLocal,
) {
  translator.constants.instantiateConstant(
    b,
    translator.symbols.setterSymbolFromName(memberName),
    translator.classInfo[translator.symbolClass]!.nonNullableType,
  );

  b.local_get(positionalArgLocal);
  translator.callReference(translator.invocationSetterFactory.reference, b);
}
