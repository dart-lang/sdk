// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart';
import 'dispatch_table.dart';
import 'functions.dart';
import 'reference_extensions.dart';
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
    final selectors = translator.dispatchTable.dynamicGetterSelectors(
      callerShape.name,
    );
    final ranges = selectors
        .expand(
          (selector) => selector
              .targets(unchecked: false)
              .allTargetRanges
              .map((r) => (range: r.range, value: r.target)),
        )
        .toList();
    ranges.sort((a, b) => a.range.start.compareTo(b.range.start));

    final nullableReceiverLocal = function.locals[0];
    final outputs = function.type.outputs;
    final b = function.body;

    // Check for `null`.
    final receiverLocal = b.addLocal(translator.topTypeNonNullable);
    {
      final nullBlock = b.block([], [translator.topTypeNonNullable]);
      b.local_get(nullableReceiverLocal);
      b.br_on_non_null(nullBlock);
      // Throw `NoSuchMethodError`. Normally this needs to happen via instance
      // invocation of `noSuchMethod` (done in [_callNoSuchMethod]), but we don't
      // have a `Null` class in dart2wasm so we throw directly.
      b.local_get(nullableReceiverLocal);
      createGetterInvocationObject(translator, b, callerShape.name);
      translator.callReference(translator.invokeNoSuchMethod.reference, b);
      b.unreachable();
      b.end(); // nullBlock
      b.local_set(receiverLocal);
    }

    b.local_get(receiverLocal);
    b.loadClassId(translator, receiverLocal.type);
    b.classIdSearch(
      ranges,
      outputs,
      (Reference target) {
        final targetMember = target.asMember;
        final Reference targetReference;
        if (targetMember is Procedure) {
          targetReference = targetMember.isGetter
              ? targetMember.reference
              : targetMember.tearOffReference;
        } else if (targetMember is Field) {
          targetReference = targetMember.getterReference;
        } else {
          throw '_generateGetterCode: member is not a procedure or field: $targetMember';
        }

        final w.BaseFunction targetFunction = translator.functions.getFunction(
          targetReference,
        );
        b.local_get(receiverLocal);
        translator.convertType(
          b,
          receiverLocal.type,
          targetFunction.type.inputs.first,
        );
        translator.callFunction(targetFunction, b);
        // Box return value if needed
        translator.convertType(
          b,
          targetFunction.type.outputs.single,
          outputs.single,
        );
      },
      () {
        b.local_get(nullableReceiverLocal);
        createGetterInvocationObject(translator, b, callerShape.name);
        translator.callReference(translator.invokeNoSuchMethod.reference, b);
      },
    );

    b.return_();
    b.end();
  }

  void _generateSetterCode(Translator translator) {
    final selectors = translator.dispatchTable.dynamicSetterSelectors(
      callerShape.name,
    );
    final ranges = selectors
        .expand(
          (selector) => selector
              .targets(unchecked: false)
              .allTargetRanges
              .map((r) => (range: r.range, value: r.target)),
        )
        .toList();
    ranges.sort((a, b) => a.range.start.compareTo(b.range.start));

    final nullableReceiverLocal = function.locals[0];
    final positionalArgLocal = function.locals[1];

    final b = function.body;

    // Check for `null`.
    final receiverLocal = b.addLocal(translator.topTypeNonNullable);
    {
      final nullBlock = b.block([], [translator.topTypeNonNullable]);
      b.local_get(nullableReceiverLocal);
      b.br_on_non_null(nullBlock);
      // Throw `NoSuchMethodError`. Normally this needs to happen via instance
      // invocation of `noSuchMethod` (done in [_callNoSuchMethod]), but we don't
      // have a `Null` class in dart2wasm so we throw directly.
      b.local_get(nullableReceiverLocal);
      createSetterInvocationObject(
        translator,
        b,
        callerShape.name,
        positionalArgLocal,
      );

      translator.callReference(translator.invokeNoSuchMethod.reference, b);
      b.unreachable();
      b.end(); // nullBlock
      b.local_set(receiverLocal);
    }

    b.local_get(receiverLocal);
    b.loadClassId(translator, receiverLocal.type);
    b.classIdSearch(
      ranges,
      [],
      (Reference target) {
        b.local_get(receiverLocal);
        b.local_get(positionalArgLocal);
        translator.callFunction(
          translator.functions.getDynamicForwarder(target, callerShape),
          b,
        );
      },
      () {
        b.local_get(receiverLocal);
        createSetterInvocationObject(
          translator,
          b,
          callerShape.name,
          positionalArgLocal,
        );
        translator.callReference(translator.invokeNoSuchMethod.reference, b);

        b.drop(); // drop noSuchMethod return value
        b.local_get(positionalArgLocal);
      },
    );

    b.return_();
    b.end();
  }

  void _generateMethodCode(Translator translator) {
    final callerShape = this.callerShape as MethodCallShape;
    final b = function.body;
    final nullableReceiverLocal = function.locals[0]; // ref #Top

    // Check for `null`.
    final receiverLocal = b.addLocal(translator.topTypeNonNullable);
    {
      final nullBlock = b.block([], [translator.topTypeNonNullable]);
      b.local_get(nullableReceiverLocal);
      b.br_on_non_null(nullBlock);
      b.local_get(nullableReceiverLocal);
      for (int i = 0; i < callerShape.totalArgumentCount; ++i) {
        b.local_get(function.locals[1 + i]);
      }
      translator.callFunction(
        translator.functions.getInvocationCreatorStub(callerShape),
        b,
      );
      translator.callReference(translator.invokeNoSuchMethod.reference, b);
      b.unreachable();

      b.end(); // nullBlock
      b.local_set(receiverLocal);
    }

    final classIdLocal = b.addLocal(w.NumType.i32);

    b.local_get(receiverLocal);
    b.loadClassId(translator, receiverLocal.type);
    b.local_set(classIdLocal);

    // Continuation of this block calls `noSuchMethod` on the receiver.
    final noSuchMethodBlock = b.block();

    // Step 1) Look through all possible targets that have the dynamic selector
    // as a method.
    final methodSelectors = translator.dispatchTable.dynamicMethodSelectors(
      callerShape.name,
    );
    for (final selector in methodSelectors) {
      // Accumulates all class ID ranges that have the same target.
      final Map<Reference, List<Range>> targets = {};
      for (final (:range, :target)
          in selector.targets(unchecked: false).allTargetRanges) {
        targets.putIfAbsent(target, () => []).add(range);
      }

      for (final MapEntry(key: target, value: classIdRanges)
          in targets.entries) {
        final Procedure targetMember = target.asMember as Procedure;
        final targetFunction = targetMember.function;

        // Filter out targets that cannot match based on mismatched arguments.
        if (!callerShape.matchesTarget(targetFunction)) {
          continue;
        }

        final classIdNoMatch = b.block();
        final classIdMatch = b.block();

        for (Range classIdRange in classIdRanges) {
          if (classIdRange.length == 1) {
            b.local_get(classIdLocal);
            b.i32_const(classIdRange.start);
            b.i32_eq();
            b.br_if(classIdMatch);
          } else {
            b.local_get(classIdLocal);
            b.i32_const(classIdRange.start);
            b.i32_sub();
            b.i32_const(classIdRange.length);
            b.i32_lt_u();
            b.br_if(classIdMatch);
          }
        }

        b.br(classIdNoMatch);
        b.end(); // classIdMatch

        b.local_get(receiverLocal);
        for (int i = 0; i < callerShape.totalArgumentCount; ++i) {
          b.local_get(function.locals[1 + i]);
        }
        translator.callFunction(
          translator.functions.getDynamicForwarder(target, callerShape),
          b,
        );
        b.return_();
        b.end(); // classIdNoMatch
      }
    }

    // Step 2) The receiver does not have the dynamic selector as a method. Now
    // we look through all possible getters with the dynamic selector name,
    // invoke the getter and then try to call it (via closure call or `.call()`).
    final getterSelectors = translator.dispatchTable.dynamicGetterSelectors(
      callerShape.name,
    );
    final dynamicMainModuleGetterSelectors = translator
        .dynamicMainModuleDispatchTable
        ?.dynamicGetterSelectors(callerShape.name);
    if (getterSelectors.isNotEmpty ||
        dynamicMainModuleGetterSelectors != null) {
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

      final getterValueLocal = b.addLocal(translator.topType);
      void handleGetterSelector(SelectorInfo selector) {
        for (final (:range, :target)
            in selector.targets(unchecked: false).allTargetRanges) {
          final targetMember = target.asMember;
          // We only care about getters here as methods were already handled in
          // the loop in `Step 1` above.
          if (targetMember is Procedure && !targetMember.isGetter) {
            continue;
          }

          for (int classId = range.start; classId <= range.end; ++classId) {
            b.local_get(receiverLocal);
            b.loadClassId(translator, receiverLocal.type);
            b.i32_const(classId);
            b.i32_eq();
            b.if_();

            final Reference targetReference;
            if (targetMember is Procedure) {
              assert(targetMember.isGetter); // methods are skipped above
              targetReference = targetMember.reference;
            } else if (targetMember is Field) {
              targetReference = targetMember.getterReference;
            } else {
              throw StateError('Expected field getter or procedure getter.');
            }

            final w.BaseFunction targetFunction = translator.functions
                .getFunction(targetReference);

            // Get field value
            b.local_get(receiverLocal);
            translator.convertType(
              b,
              receiverLocal.type,
              targetFunction.type.inputs.first,
            );
            translator.callFunction(targetFunction, b);
            translator.convertType(
              b,
              targetFunction.type.outputs.single,
              translator.topType,
            );
            b.local_tee(getterValueLocal);

            // Throw `NoSuchMethodError` if the value is null
            b.br_on_null(noSuchMethodBlock);
            // Reuse `receiverLocal`. This also updates the `noSuchMethod`
            // receiver below.
            b.local_tee(receiverLocal);

            // Invoke "call" if the value is not a closure
            b.loadClassId(translator, receiverLocal.type);
            b.i32_const(
              (translator.closureInfo.classId as AbsoluteClassId).value,
            );
            b.i32_ne();
            b.if_();
            // Value is not a closure
            final callDispatcher = translator
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
            for (int i = 0; i < callerShape.typeCount; ++i) {
              b.local_get(function.locals[1 + i]);
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
            translator.callFunction(callDispatcher, b);
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
                  // This is a call combination that the closure layouter
                  // determined cannot occur in the program (it means the
                  // shape&type checks we already performed earlier must
                  // have thrown an NSM error and we cannot get here).
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

              // The closure representation algorithm has considered dynamic
              // callsites and will have therefore specialized vtable entries
              // for valid call shape of dynamic closure calls.
              if (callerShape.typeCount == 0) {
                // The dynamic callsite has not provided type arguments but the
                // target closure may be generic. The shape&type checking we
                // already performed may have populated default type arguments
                // (of unknown length) for the closure.
                //
                // So we branch on the number of type parameters to invoke the
                // right closure entrypoint.
                final maxTypeCount = translator.closureLayouter
                    .maxTypeArgumentCount();
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
            b.return_();

            b.end(); // class ID
          }
        }
      }

      for (final selector in getterSelectors) {
        handleGetterSelector(selector);
      }

      if (dynamicMainModuleGetterSelectors != null) {
        for (final selector in dynamicMainModuleGetterSelectors) {
          handleGetterSelector(selector);
        }
      }
    }

    b.end(); // noSuchMethodBlock

    // Unable to find a matching member, call `noSuchMethod`
    b.local_get(receiverLocal);
    for (int i = 0; i < callerShape.totalArgumentCount; ++i) {
      b.local_get(function.locals[1 + i]);
    }
    translator.callFunction(
      translator.functions.getInvocationCreatorStub(callerShape),
      b,
    );
    translator.callReference(translator.invokeNoSuchMethod.reference, b);

    b.end();
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
