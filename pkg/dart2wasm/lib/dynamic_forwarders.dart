// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'code_generator.dart' show MacroAssembler;
import 'dispatch_table.dart';
import 'reference_extensions.dart';
import 'translator.dart';

/// Stores forwarders for dynamic gets, sets, and invocations. See [Forwarder]
/// for details. Each module will contain its own forwarders for the names
/// invoked from it.
class DynamicForwarders {
  final Translator translator;
  final w.ModuleBuilder callingModule;

  final Map<String, Forwarder> _getterForwarderOfName = {};
  final Map<String, Forwarder> _setterForwarderOfName = {};
  final Map<String, Forwarder> _methodForwarderOfName = {};

  DynamicForwarders(this.translator, this.callingModule);

  Forwarder getDynamicGetForwarder(String memberName) =>
      _getterForwarderOfName[memberName] ??= Forwarder._(
          translator, _ForwarderKind.Getter, memberName, callingModule)
        .._generateCode(translator);

  Forwarder getDynamicSetForwarder(String memberName) =>
      _setterForwarderOfName[memberName] ??= Forwarder._(
          translator, _ForwarderKind.Setter, memberName, callingModule)
        .._generateCode(translator);

  Forwarder getDynamicInvocationForwarder(String memberName) {
    // Add Wasm function to the map before generating the forwarder code, to
    // allow recursive calls in the "call" forwarder.
    var forwarder = _methodForwarderOfName[memberName];
    if (forwarder == null) {
      forwarder = Forwarder._(
          translator, _ForwarderKind.Method, memberName, callingModule);
      _methodForwarderOfName[memberName] = forwarder;
      forwarder._generateCode(translator);
    }
    return forwarder;
  }
}

/// A function that "forwards" a dynamic get, set, or invocation to the right
/// type checking member.
///
/// A forwarder function takes 4 arguments:
///
/// - The receiver of the dynamic get, set, or invocation
/// - A Dart list for type arguments (empty in gets and sets)
/// - A Dart list of positional arguments (empty in gets)
/// - A Dart list of named arguments (empty in gets and sets)
///
/// It compares the receiver class ID with the IDs of classes with a matching
/// member name ([memberName]). When it finds a match, it compares the passed
/// arguments with expected parameters, adjusts parameter lists with default
/// values, and calls the matching member's type checker method, which type
/// checks the passed arguments before calling the actual member.
///
/// A forwarder calls `noSuchMethod` on the receiver when a matching member is
/// not found, or the passed arguments do not match the expected parameters of
/// the member.
class Forwarder {
  final _ForwarderKind _kind;

  final String memberName;

  final w.FunctionBuilder function;

  Forwarder._(Translator translator, this._kind, this.memberName,
      w.ModuleBuilder module)
      : function = module.functions.define(_kind.functionType(translator),
            "$_kind forwarder for '$memberName'");

  void _generateCode(Translator translator) {
    switch (_kind) {
      case _ForwarderKind.Getter:
        _generateGetterCode(translator);
        break;

      case _ForwarderKind.Setter:
        _generateSetterCode(translator);
        break;

      case _ForwarderKind.Method:
        _generateMethodCode(translator);
        break;
    }
  }

  void _generateGetterCode(Translator translator) {
    final selectors =
        translator.dispatchTable.dynamicGetterSelectors(memberName);
    final ranges = selectors
        .expand((selector) =>
            selector.targetRanges.map((r) => (range: r.range, value: r.target)))
        .toList();
    ranges.sort((a, b) => a.range.start.compareTo(b.range.start));

    final receiverLocal = function.locals[0];
    final outputs = _kind.functionType(translator).outputs;

    final b = function.body;
    b.local_get(receiverLocal);
    b.struct_get(translator.topInfo.struct, FieldIndex.classId);
    b.classIdSearch(ranges, outputs, (Reference target) {
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

      final w.BaseFunction targetFunction =
          translator.functions.getFunction(targetReference);
      b.local_get(receiverLocal);
      translator.convertType(
          b, receiverLocal.type, targetFunction.type.inputs.first);
      translator.callFunction(targetFunction, b);
      // Box return value if needed
      translator.convertType(b, targetFunction.type.outputs.single,
          _kind.functionType(translator).outputs.single);
    }, () {
      generateNoSuchMethodCall(translator, b, () => b.local_get(receiverLocal),
          () => createGetterInvocationObject(translator, b, memberName));
    });

    b.return_();
    b.end();
  }

  void _generateSetterCode(Translator translator) {
    final selectors =
        translator.dispatchTable.dynamicSetterSelectors(memberName);
    final ranges = selectors
        .expand((selector) =>
            selector.targetRanges.map((r) => (range: r.range, value: r.target)))
        .toList();
    ranges.sort((a, b) => a.range.start.compareTo(b.range.start));

    final receiverLocal = function.locals[0];
    final positionalArgLocal = function.locals[1];

    final b = function.body;
    b.local_get(receiverLocal);
    b.struct_get(translator.topInfo.struct, FieldIndex.classId);
    b.classIdSearch(ranges, [positionalArgLocal.type], (Reference target) {
      final Member targetMember = target.asMember;
      b.local_get(receiverLocal);
      b.local_get(positionalArgLocal);
      translator.callReference(targetMember.typeCheckerReference, b);
    }, () {
      generateNoSuchMethodCall(
          translator,
          b,
          () => b.local_get(receiverLocal),
          () => createSetterInvocationObject(
              translator, b, memberName, positionalArgLocal));

      b.drop(); // drop noSuchMethod return value
      b.local_get(positionalArgLocal);
    });

    b.return_();
    b.end();
  }

  void _generateMethodCode(Translator translator) {
    final b = function.body;

    final receiverLocal = function.locals[0]; // ref #Top
    final typeArgsLocal = function.locals[1]; // ref WasmArray
    final positionalArgsLocal = function.locals[2]; // ref WasmArray
    final namedArgsLocal = function.locals[3]; // ref WasmArray

    final classIdLocal = b.addLocal(w.NumType.i32);

    // Continuation of this block calls `noSuchMethod` on the receiver.
    final noSuchMethodBlock = b.block();

    final numArgsLocal = b.addLocal(w.NumType.i32);

    final methodSelectors =
        translator.dispatchTable.dynamicMethodSelectors(memberName);
    for (final selector in methodSelectors) {
      // Accumulates all class ID ranges that have the same target.
      final Map<Reference, List<Range>> targets = {};
      for (final (:range, :target) in selector.targetRanges) {
        targets.putIfAbsent(target, () => []).add(range);
      }

      for (final MapEntry(key: target, value: classIdRanges)
          in targets.entries) {
        final Procedure targetMember = target.asMember as Procedure;
        final targetMemberParamInfo = translator.paramInfoForDirectCall(target);

        b.local_get(receiverLocal);
        b.struct_get(translator.topInfo.struct, FieldIndex.classId);
        b.local_set(classIdLocal);

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

        // Check number of type arguments. It needs to be 0 or match the
        // member's type parameters.
        if (targetMemberParamInfo.typeParamCount == 0) {
          // typeArgs.length == 0
          b.local_get(typeArgsLocal);
          b.array_len();
          b.i32_eqz();
        } else {
          // typeArgs.length == 0 || typeArgs.length == typeParams.length
          b.local_get(typeArgsLocal);
          b.array_len();
          b.local_tee(numArgsLocal);
          b.i32_eqz();
          b.local_get(numArgsLocal);
          b.i32_const(targetMemberParamInfo.typeParamCount);
          b.i32_eq();
          b.i32_or();
        }
        b.i32_eqz();
        b.br_if(noSuchMethodBlock);

        // Check number of positional parameters and add missing optional
        // arguments
        final nRequired =
            targetMemberParamInfo.positional.where((arg) => arg == null).length;
        final nTotal = targetMemberParamInfo.positional.length;

        // positionalArgs.length >= nRequired &&
        //   positionalArgs.length <= nTotal
        b.local_get(positionalArgsLocal);
        b.array_len();
        b.local_tee(numArgsLocal);
        b.i32_const(nRequired);
        b.i32_ge_u();
        b.local_get(numArgsLocal);
        b.i32_const(nTotal);
        b.i32_le_u();
        b.i32_and();
        b.i32_eqz();
        b.br_if(noSuchMethodBlock);

        // Add default values of optional positional parameters if needed
        w.Local? adjustedPositionalArgsLocal;
        if (nRequired != nTotal) {
          adjustedPositionalArgsLocal =
              b.addLocal(translator.nullableObjectArrayTypeRef);
          b.i32_const(nTotal);
          b.array_new_default(translator.nullableObjectArrayType);
          b.local_set(adjustedPositionalArgsLocal);

          // Copy passed arguments
          final argIdxLocal = b.addLocal(w.NumType.i32);
          b.i32_const(0);
          b.local_set(argIdxLocal);

          final loopBlock = b.loop();
          b.local_get(argIdxLocal);
          b.local_get(numArgsLocal);
          b.i32_lt_u();
          b.if_();
          b.local_get(adjustedPositionalArgsLocal);
          b.local_get(argIdxLocal);
          b.local_get(positionalArgsLocal);
          b.local_get(argIdxLocal);
          b.array_get(translator.nullableObjectArrayType);
          b.array_set(translator.nullableObjectArrayType);
          b.local_get(argIdxLocal);
          b.i32_const(1);
          b.i32_add();
          b.local_set(argIdxLocal);
          b.br(loopBlock);
          b.end(); // end if
          b.end(); // end loop

          // Add optional parameters
          for (var optionalParamIdx = nRequired;
              optionalParamIdx < nTotal;
              optionalParamIdx += 1) {
            b.local_get(argIdxLocal);
            b.i32_const(optionalParamIdx);
            b.i32_le_u();
            b.if_();

            final param = targetMemberParamInfo.positional[optionalParamIdx]!;

            b.local_get(adjustedPositionalArgsLocal);
            b.i32_const(optionalParamIdx);
            translator.constants
                .instantiateConstant(b, param, translator.topInfo.nullableType);
            b.array_set(translator.nullableObjectArrayType);
            b.end();
          }
        }

        // Check named arguments and adjust the named argument list. Named
        // parameters in the member should be in the list or have a default
        // value.
        w.Local? adjustedNamedArgsLocal;
        if (targetMemberParamInfo.named.isEmpty) {
          // namedArgs.length == 0
          b.local_get(namedArgsLocal);
          b.array_len();
          b.i32_eqz();
          b.i32_eqz();
          b.br_if(noSuchMethodBlock);
        } else {
          adjustedNamedArgsLocal =
              b.addLocal(translator.nullableObjectArrayTypeRef);
          b.i32_const(targetMemberParamInfo.named.length);
          b.array_new_default(translator.nullableObjectArrayType);
          b.local_set(adjustedNamedArgsLocal);

          final namedParameterIdxLocal = b.addLocal(
              translator.classInfo[translator.boxedIntClass]!.nullableType);

          final remainingNamedArgsLocal = numArgsLocal;
          b.local_get(namedArgsLocal);
          b.array_len();
          b.i32_const(1);
          b.i32_shr_u();
          b.local_set(remainingNamedArgsLocal);

          final targetMemberFunction = targetMember.function;

          Expression? initializerForNamedParamInMember(String paramName) {
            for (int i = 0;
                i < targetMemberFunction.namedParameters.length;
                i += 1) {
              if (targetMemberFunction.namedParameters[i].name == paramName) {
                return targetMemberFunction.namedParameters[i].initializer;
              }
            }
            return null;
          }

          for (int nameIdx = 0;
              nameIdx < targetMemberParamInfo.names.length;
              ++nameIdx) {
            final String name = targetMemberParamInfo.names[nameIdx];
            final Constant? paramInfoDefaultValue =
                targetMemberParamInfo.named[name];
            final Expression? functionNodeDefaultValue =
                initializerForNamedParamInMember(name);

            b.local_get(namedArgsLocal);
            translator.constants.instantiateConstant(
                b,
                SymbolConstant(name, null),
                translator.classInfo[translator.symbolClass]!.nonNullableType);

            translator.callReference(
                translator.getNamedParameterIndex.reference, b);
            b.local_tee(namedParameterIdxLocal);

            b.ref_is_null();
            b.i32_eqz();
            b.if_();
            b.local_get(remainingNamedArgsLocal);
            b.i32_const(1);
            b.i32_sub();
            b.local_set(remainingNamedArgsLocal);
            b.end();

            b.local_get(namedParameterIdxLocal);
            b.ref_is_null();
            if (functionNodeDefaultValue == null &&
                paramInfoDefaultValue == null) {
              // Required parameter missing
              b.br_if(noSuchMethodBlock);

              // Copy provided named parameter.

              b.local_get(adjustedNamedArgsLocal);
              b.i32_const(nameIdx);

              b.local_get(namedArgsLocal);
              b.local_get(namedParameterIdxLocal);
              translator.convertType(
                  b, namedParameterIdxLocal.type, w.NumType.i64);
              b.i32_wrap_i64();
              b.array_get(translator.nullableObjectArrayType);

              b.array_set(translator.nullableObjectArrayType);
            } else {
              // Optional, either has a default in the member or not used by
              // the member
              b.if_();

              b.local_get(adjustedNamedArgsLocal);
              b.i32_const(nameIdx);

              if (functionNodeDefaultValue != null) {
                // Used by the member, has a default value
                translator.constants.instantiateConstant(
                    b,
                    (functionNodeDefaultValue as ConstantExpression).constant,
                    translator.topInfo.nullableType);
              } else {
                // Not used by the member
                translator.constants.instantiateConstant(
                  b,
                  paramInfoDefaultValue!,
                  translator.topInfo.nullableType,
                );
              }
              b.array_set(translator.nullableObjectArrayType);

              b.else_();

              b.local_get(adjustedNamedArgsLocal);
              b.i32_const(nameIdx);
              b.local_get(namedArgsLocal);
              b.local_get(namedParameterIdxLocal);
              translator.convertType(
                  b, namedParameterIdxLocal.type, w.NumType.i64);
              b.i32_wrap_i64();
              b.array_get(translator.nullableObjectArrayType);
              b.array_set(translator.nullableObjectArrayType);

              b.end();
            }
          }

          // Check that all named arguments are used. If not, it means that the
          // call site has extra names that the member doesn't have.
          b.local_get(remainingNamedArgsLocal);
          b.i32_eqz();
          b.i32_eqz();
          b.br_if(noSuchMethodBlock);
        }

        b.local_get(receiverLocal);
        b.local_get(typeArgsLocal);
        b.local_get(adjustedPositionalArgsLocal ?? positionalArgsLocal);
        b.local_get(adjustedNamedArgsLocal ?? namedArgsLocal);
        translator.callReference(targetMember.typeCheckerReference, b);
        b.return_();
        b.end(); // classIdNoMatch
      }
    }

    final getterSelectors =
        translator.dispatchTable.dynamicGetterSelectors(memberName);
    final getterValueLocal = b.addLocal(translator.topInfo.nullableType);
    for (final selector in getterSelectors) {
      for (final (:range, :target) in selector.targetRanges) {
        for (int classId = range.start; classId <= range.end; ++classId) {
          final targetMember = target.asMember;
          // This loop checks getters and fields. Methods are considered in the
          // previous loop, skip them here.
          if (targetMember is Procedure && !targetMember.isGetter) {
            continue;
          }

          b.local_get(receiverLocal);
          b.struct_get(translator.topInfo.struct, FieldIndex.classId);
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
            throw '_generateMethodCode: member is not a procedure or field: $targetMember';
          }

          final w.BaseFunction targetFunction =
              translator.functions.getFunction(targetReference);

          // Get field value
          b.local_get(receiverLocal);
          translator.convertType(
              b, receiverLocal.type, targetFunction.type.inputs.first);
          translator.callFunction(targetFunction, b);
          translator.convertType(b, targetFunction.type.outputs.single,
              translator.topInfo.nullableType);
          b.local_tee(getterValueLocal);

          // Throw `NoSuchMethodError` if the value is null
          b.br_on_null(noSuchMethodBlock);
          // Reuse `receiverLocal`. This also updates the `noSuchMethod` receiver
          // below.
          b.local_tee(receiverLocal);

          // Invoke "call" if the value is not a closure
          b.struct_get(translator.topInfo.struct, FieldIndex.classId);
          b.i32_const(translator.closureInfo.classId);
          b.i32_ne();
          b.if_();
          // Value is not a closure
          final callForwarder = translator
              .getDynamicForwardersForModule(b.module)
              .getDynamicInvocationForwarder("call")
              .function;
          b.local_get(receiverLocal);
          b.local_get(typeArgsLocal);
          b.local_get(positionalArgsLocal);
          b.local_get(namedArgsLocal);
          b.call(callForwarder);
          b.return_();
          b.end();

          // Cast the closure to `#ClosureBase`
          final closureBaseType = w.RefType.def(
              translator.closureLayouter.closureBaseStruct,
              nullable: false);
          final closureLocal = b.addLocal(closureBaseType);
          b.local_get(receiverLocal);
          b.ref_cast(closureBaseType);
          b.local_set(closureLocal);

          generateDynamicFunctionCall(
              translator,
              b,
              closureLocal,
              typeArgsLocal,
              positionalArgsLocal,
              namedArgsLocal,
              noSuchMethodBlock);
          b.return_();

          b.end(); // class ID
        }
      }
    }

    b.end(); // noSuchMethodBlock

    // Unable to find a matching member, call `noSuchMethod`
    generateNoSuchMethodCall(
        translator,
        b,
        () => b.local_get(receiverLocal),
        () => createInvocationObject(translator, b, memberName, typeArgsLocal,
            positionalArgsLocal, namedArgsLocal));

    b.end();
  }
}

enum _ForwarderKind {
  Getter,
  Setter,
  Method;

  @override
  String toString() {
    return switch (this) {
      _ForwarderKind.Getter => "get",
      _ForwarderKind.Setter => "set",
      _ForwarderKind.Method => "method"
    };
  }

  w.FunctionType functionType(Translator translator) {
    return switch (this) {
      _ForwarderKind.Getter => translator.dynamicGetForwarderFunctionType,
      _ForwarderKind.Setter => translator.dynamicSetForwarderFunctionType,
      _ForwarderKind.Method => translator.dynamicInvocationForwarderFunctionType
    };
  }
}

/// Generate code that checks shape and type of the closure and generate a call
/// to its dynamic call vtable entry.
///
/// [closureLocal] should be a local of type `ref #ClosureBase` containing a
/// closure value.
///
/// [typeArgsLocal], [posArgsLocal], [namedArgsLocal] are the locals for type,
/// positional, and named arguments, respectively. Types of these locals must
/// be `ref WasmListBase`.
///
/// [noSuchMethodBlock] is used as the `br` target when the shape check fails.
void generateDynamicFunctionCall(
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
  final functionTypeLocal =
      b.addLocal(translator.closureLayouter.functionTypeType);
  b.local_get(closureLocal);
  b.struct_get(translator.closureLayouter.closureBaseStruct,
      FieldIndex.closureRuntimeType);
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
      translator
          .fieldIndex[translator.functionTypeTypeParameterDefaultsField]!);
  b.local_set(typeArgsLocal);
  b.end();

  // Check closure shape
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

  // Type check passed, call vtable entry
  b.local_get(closureLocal);
  b.local_get(typeArgsLocal);
  b.local_get(posArgsLocal);
  b.local_get(namedArgsLocal);

  // Get vtable
  b.local_get(closureLocal);
  b.struct_get(
      translator.closureLayouter.closureBaseStruct, FieldIndex.closureVtable);

  // Get entry function
  b.struct_get(translator.closureLayouter.vtableBaseStruct, 0);

  b.call_ref(translator.dynamicCallVtableEntryFunctionType);
}

void createInvocationObject(
    Translator translator,
    w.InstructionsBuilder b,
    String memberName,
    w.Local typeArgsLocal,
    w.Local positionalArgsLocal,
    w.Local namedArgsLocal) {
  translator.constants.instantiateConstant(b, SymbolConstant(memberName, null),
      translator.classInfo[translator.symbolClass]!.nonNullableType);

  b.local_get(typeArgsLocal);
  translator.callReference(translator.typeArgumentsToList.reference, b);
  b.local_get(positionalArgsLocal);
  translator.callReference(translator.positionalParametersToList.reference, b);
  b.local_get(namedArgsLocal);
  translator.callReference(translator.namedParametersToMap.reference, b);
  translator.callReference(
      translator.invocationGenericMethodFactory.reference, b);
}

void createGetterInvocationObject(
  Translator translator,
  w.InstructionsBuilder b,
  String memberName,
) {
  translator.constants.instantiateConstant(b, SymbolConstant(memberName, null),
      translator.classInfo[translator.symbolClass]!.nonNullableType);

  translator.callReference(translator.invocationGetterFactory.reference, b);
}

void createSetterInvocationObject(
  Translator translator,
  w.InstructionsBuilder b,
  String memberName,
  w.Local positionalArgLocal,
) {
  memberName = '$memberName=';

  translator.constants.instantiateConstant(b, SymbolConstant(memberName, null),
      translator.classInfo[translator.symbolClass]!.nonNullableType);

  b.local_get(positionalArgLocal);
  translator.callReference(translator.invocationSetterFactory.reference, b);
}

void generateNoSuchMethodCall(
  Translator translator,
  w.InstructionsBuilder b,
  void Function() pushReceiver,
  void Function() pushInvocationObject,
) {
  final SelectorInfo noSuchMethodSelector = translator.dispatchTable
      .selectorForTarget(translator.objectNoSuchMethod.reference);
  translator.functions.recordSelectorUse(noSuchMethodSelector);

  final noSuchMethodParamInfo = noSuchMethodSelector.paramInfo;
  final noSuchMethodWasmFunctionType = noSuchMethodSelector.signature;

  pushReceiver();
  pushInvocationObject();

  final invocationFactory = translator.functions
      .getFunction(translator.invocationGenericMethodFactory.reference);
  translator.convertType(b, invocationFactory.type.outputs[0],
      noSuchMethodSelector.signature.inputs[1]);

  // `noSuchMethod` can have extra parameters as long as they are optional.
  // Push any optional positional parameters.
  int wasmArgIdx = 2;
  for (int positionalArgIdx = 1;
      positionalArgIdx < noSuchMethodParamInfo.positional.length;
      positionalArgIdx += 1) {
    final positionalParameterValue =
        noSuchMethodParamInfo.positional[positionalArgIdx]!;
    translator.constants.instantiateConstant(b, positionalParameterValue,
        noSuchMethodWasmFunctionType.inputs[wasmArgIdx]);
    wasmArgIdx += 1;
  }

  // Push any optional named parameters
  for (String namedParameterName in noSuchMethodParamInfo.names) {
    final namedParameterValue =
        noSuchMethodParamInfo.named[namedParameterName]!;
    translator.constants.instantiateConstant(b, namedParameterValue,
        noSuchMethodWasmFunctionType.inputs[wasmArgIdx]);
    wasmArgIdx += 1;
  }

  assert(wasmArgIdx == noSuchMethodWasmFunctionType.inputs.length);

  // Get class id for virtual call
  pushReceiver();
  b.struct_get(translator.topInfo.struct, FieldIndex.classId);

  // Virtual call to noSuchMethod
  int selectorOffset = noSuchMethodSelector.offset!;
  if (selectorOffset != 0) {
    b.i32_const(selectorOffset);
    b.i32_add();
  }

  b.call_indirect(noSuchMethodWasmFunctionType);
}

class ClassIdRange {
  final int start;
  final int end; // inclusive

  ClassIdRange(this.start, this.end);
}
