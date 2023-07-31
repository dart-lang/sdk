// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/dispatch_table.dart';
import 'package:dart2wasm/reference_extensions.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Stores forwarders for dynamic gets, sets, and invocations. See [Forwarder]
/// for details.
class DynamicForwarders {
  final Translator translator;

  final Map<String, Forwarder> _getterForwarderOfName = {};
  final Map<String, Forwarder> _setterForwarderOfName = {};
  final Map<String, Forwarder> _methodForwarderOfName = {};

  DynamicForwarders(this.translator);

  Forwarder getDynamicGetForwarder(String memberName) =>
      _getterForwarderOfName[memberName] ??=
          Forwarder(translator, _ForwarderKind.Getter, memberName)
            .._generateCode(translator);

  Forwarder getDynamicSetForwarder(String memberName) =>
      _setterForwarderOfName[memberName] ??=
          Forwarder(translator, _ForwarderKind.Setter, memberName)
            .._generateCode(translator);

  Forwarder getDynamicInvocationForwarder(String memberName) {
    // Add Wasm function to the map before generating the forwarder code, to
    // allow recursive calls in the "call" forwarder.
    var forwarder = _methodForwarderOfName[memberName];
    if (forwarder == null) {
      forwarder = Forwarder(translator, _ForwarderKind.Method, memberName);
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
  final _ForwarderKind kind;

  final String memberName;

  final w.FunctionBuilder function;

  Forwarder(Translator translator, this.kind, this.memberName)
      : function = translator.m.functions.define(
            kind.functionType(translator), "$kind forwarder for '$memberName'");

  void _generateCode(Translator translator) {
    switch (kind) {
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
    final b = function.body;

    final receiverLocal = function.locals[0];

    final selectors =
        translator.dispatchTable.dynamicGetterSelectors(memberName);
    for (final selector in selectors) {
      translator.functions.activateSelector(selector);
      for (int classID in selector.classIds) {
        final Reference target = selector.targets[classID]!;
        final targetMember = target.asMember;
        if (targetMember.isAbstract) {
          continue;
        }
        final targetClass = targetMember.enclosingClass!;
        final targetClassInfo = translator.classInfo[targetClass]!;

        b.local_get(receiverLocal);
        b.struct_get(translator.topInfo.struct, FieldIndex.classId);
        b.i32_const(classID);
        b.i32_eq();
        b.if_();

        final w.ValueType receiverType = targetClassInfo.nonNullableType;
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
        translator.convertType(function, receiverLocal.type, receiverType);
        b.call(targetFunction);
        // Box return value if needed
        translator.convertType(function, targetFunction.type.outputs.single,
            kind.functionType(translator).outputs.single);
        b.return_();

        b.end();
      }
    }

    generateNoSuchMethodCall(
        translator,
        function,
        () => b.local_get(receiverLocal),
        () => createGetterInvocationObject(translator, function, memberName));

    b.end();
  }

  void _generateSetterCode(Translator translator) {
    final b = function.body;

    final receiverLocal = function.locals[0];
    final positionalArgLocal = function.locals[1];

    final selectors =
        translator.dispatchTable.dynamicSetterSelectors(memberName);
    for (final selector in selectors) {
      translator.functions.activateSelector(selector);
      for (int classID in selector.classIds) {
        final Reference target = selector.targets[classID]!;
        final Member targetMember = target.asMember;
        if (targetMember.isAbstract) {
          continue;
        }

        b.local_get(receiverLocal);
        b.struct_get(translator.topInfo.struct, FieldIndex.classId);
        b.i32_const(classID);
        b.i32_eq();
        b.if_();

        b.local_get(receiverLocal);
        b.local_get(positionalArgLocal);
        b.call(translator.functions
            .getFunction(targetMember.typeCheckerReference));
        b.return_();

        b.end();
      }
    }

    generateNoSuchMethodCall(
        translator,
        function,
        () => b.local_get(receiverLocal),
        () => createSetterInvocationObject(
            translator, function, memberName, positionalArgLocal));

    b.drop(); // drop noSuchMethod return value
    b.local_get(positionalArgLocal);

    b.end();
  }

  void _generateMethodCode(Translator translator) {
    final b = function.body;

    final receiverLocal = function.locals[0]; // ref #Top
    final typeArgsLocal = function.locals[1]; // ref _ListBase
    final positionalArgsLocal = function.locals[2]; // ref _ListBase
    final namedArgsLocal = function.locals[3]; // ref _ListBase

    // Continuation of this block calls `noSuchMethod` on the receiver.
    final noSuchMethodBlock = b.block();

    final numArgsLocal = function.addLocal(w.NumType.i32);

    final methodSelectors =
        translator.dispatchTable.dynamicMethodSelectors(memberName);
    for (final selector in methodSelectors) {
      translator.functions.activateSelector(selector);
      for (int classID in selector.classIds) {
        final Reference target = selector.targets[classID]!;
        final Procedure targetMember = target.asMember as Procedure;
        if (targetMember.isAbstract) {
          continue;
        }

        final targetMemberParamInfo = translator.paramInfoFor(target);

        b.local_get(receiverLocal);
        b.struct_get(translator.topInfo.struct, FieldIndex.classId);
        b.i32_const(classID);
        b.i32_eq();
        b.if_();

        // Check number of type arguments. It needs to be 0 or match the
        // member's type parameters.
        if (targetMemberParamInfo.typeParamCount == 0) {
          // typeArgs.length == 0
          b.local_get(typeArgsLocal);
          translator.getListLength(b);
          b.i32_eqz();
        } else {
          // typeArgs.length == 0 || typeArgs.length == typeParams.length
          b.local_get(typeArgsLocal);
          translator.getListLength(b);
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
        translator.getListLength(b);
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
          adjustedPositionalArgsLocal = function.addLocal(translator
              .classInfo[translator.growableListClass]!.nonNullableType);
          _makeEmptyGrowableList(translator, function, nTotal);
          b.local_set(adjustedPositionalArgsLocal);

          // Copy passed arguments
          final argIdxLocal = function.addLocal(w.NumType.i32);
          b.i32_const(0);
          b.local_set(argIdxLocal);

          final loopBlock = b.loop();
          b.local_get(argIdxLocal);
          b.local_get(numArgsLocal);
          b.i32_lt_u();
          b.if_();
          b.local_get(adjustedPositionalArgsLocal);
          b.local_get(positionalArgsLocal);
          translator.indexList(b, (b) => b.local_get(argIdxLocal));
          b.call(translator.functions
              .getFunction(translator.growableListAdd.reference));
          b.drop();
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
            b.local_get(adjustedPositionalArgsLocal);

            final param = targetMemberParamInfo.positional[optionalParamIdx]!;

            translator.constants.instantiateConstant(
                function, b, param, translator.topInfo.nullableType);

            b.call(translator.functions
                .getFunction(translator.growableListAdd.reference));
            b.drop();

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
          translator.getListLength(b);
          b.i32_eqz();
          b.i32_eqz();
          b.br_if(noSuchMethodBlock);
        } else {
          adjustedNamedArgsLocal = function.addLocal(translator
              .classInfo[translator.growableListClass]!.nonNullableType);
          _makeEmptyGrowableList(
              translator, function, targetMemberParamInfo.named.length);
          b.local_set(adjustedNamedArgsLocal);

          final namedParameterIdxLocal = function.addLocal(
              translator.classInfo[translator.boxedIntClass]!.nullableType);

          final remainingNamedArgsLocal = numArgsLocal;
          b.local_get(namedArgsLocal);
          translator.getListLength(b);
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

          for (final name in targetMemberParamInfo.names) {
            final Constant? paramInfoDefaultValue =
                targetMemberParamInfo.named[name]!;
            final Expression? functionNodeDefaultValue =
                initializerForNamedParamInMember(name);

            b.local_get(namedArgsLocal);
            translator.constants.instantiateConstant(
                function,
                b,
                SymbolConstant(name, null),
                translator.classInfo[translator.symbolClass]!.nonNullableType);

            b.call(translator.functions
                .getFunction(translator.getNamedParameterIndex.reference));
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
              b.local_get(adjustedNamedArgsLocal);
              b.local_get(namedArgsLocal);
              translator.indexList(b, (b) {
                b.local_get(namedParameterIdxLocal);
                translator.convertType(
                    function, namedParameterIdxLocal.type, w.NumType.i64);
                b.i32_wrap_i64();
              });
              b.call(translator.functions
                  .getFunction(translator.growableListAdd.reference));
              b.drop();
            } else {
              // Optional, either has a default in the member or not used by
              // the member
              b.if_();

              b.local_get(adjustedNamedArgsLocal);

              if (functionNodeDefaultValue != null) {
                // Used by the member, has a default value
                translator.constants.instantiateConstant(
                    function,
                    b,
                    (functionNodeDefaultValue as ConstantExpression).constant,
                    translator.topInfo.nullableType);
              } else {
                // Not used by the member
                translator.constants.instantiateConstant(
                  function,
                  b,
                  paramInfoDefaultValue!,
                  translator.topInfo.nullableType,
                );
              }

              b.call(translator.functions
                  .getFunction(translator.growableListAdd.reference));
              b.drop();

              b.else_();

              b.local_get(adjustedNamedArgsLocal);
              b.local_get(namedArgsLocal);
              translator.indexList(b, (b) {
                b.local_get(namedParameterIdxLocal);
                translator.convertType(
                    function, namedParameterIdxLocal.type, w.NumType.i64);
                b.i32_wrap_i64();
              });
              b.call(translator.functions
                  .getFunction(translator.growableListAdd.reference));
              b.drop();

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
        final wasmFunction =
            translator.functions.getFunction(targetMember.typeCheckerReference);
        b.call(wasmFunction);
        b.return_();
        b.end(); // class ID
      }
    }

    final getterSelectors =
        translator.dispatchTable.dynamicGetterSelectors(memberName);
    final getterValueLocal = function.addLocal(translator.topInfo.nullableType);
    for (final selector in getterSelectors) {
      translator.functions.activateSelector(selector);
      for (int classID in selector.classIds) {
        final Reference target = selector.targets[classID]!;
        final targetMember = target.asMember;
        if (targetMember.isAbstract) {
          continue;
        }
        // This loop checks getters and fields. Methods are considered in the
        // previous loop, skip them here.
        if (targetMember is Procedure && !targetMember.isGetter) {
          continue;
        }
        final targetClass = targetMember.enclosingClass!;
        final targetClassInfo = translator.classInfo[targetClass]!;

        b.local_get(receiverLocal);
        b.struct_get(translator.topInfo.struct, FieldIndex.classId);
        b.i32_const(classID);
        b.i32_eq();
        b.if_();

        final w.ValueType receiverType = targetClassInfo.nonNullableType;
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
        translator.convertType(function, receiverLocal.type, receiverType);
        b.call(targetFunction);
        translator.convertType(function, targetFunction.type.outputs.single,
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
        final callForwarder = translator.dynamicForwarders
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
        final closureLocal = function.addLocal(closureBaseType);
        b.local_get(receiverLocal);
        b.ref_cast(closureBaseType);
        b.local_set(closureLocal);

        generateDynamicFunctionCall(
            translator,
            function,
            closureLocal,
            typeArgsLocal,
            positionalArgsLocal,
            namedArgsLocal,
            noSuchMethodBlock);
        b.return_();

        b.end(); // class ID
      }
    }

    b.end(); // noSuchMethodBlock

    // Unable to find a matching member, call `noSuchMethod`
    generateNoSuchMethodCall(
        translator,
        function,
        () => b.local_get(receiverLocal),
        () => createInvocationObject(translator, function, memberName,
            typeArgsLocal, positionalArgsLocal, namedArgsLocal));

    b.end();
  }
}

enum _ForwarderKind {
  Getter,
  Setter,
  Method;

  String toString() {
    switch (this) {
      case _ForwarderKind.Getter:
        return "get";
      case _ForwarderKind.Setter:
        return "set";
      case _ForwarderKind.Method:
        return "method";
    }
  }

  w.FunctionType functionType(Translator translator) {
    switch (this) {
      case _ForwarderKind.Getter:
        return translator.dynamicGetForwarderFunctionType;
      case _ForwarderKind.Setter:
        return translator.dynamicSetForwarderFunctionType;
      case _ForwarderKind.Method:
        return translator.dynamicInvocationForwarderFunctionType;
    }
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
/// be `ref _ListBase`.
///
/// [noSuchMethodBlock] is used as the `br` target when the shape check fails.
void generateDynamicFunctionCall(
  Translator translator,
  w.FunctionBuilder function,
  w.Local closureLocal,
  w.Local typeArgsLocal,
  w.Local posArgsLocal,
  w.Local namedArgsLocal,
  w.Label noSuchMethodBlock,
) {
  final listArgumentType =
      translator.classInfo[translator.listBaseClass]!.nonNullableType;
  assert(typeArgsLocal.type == listArgumentType);
  assert(posArgsLocal.type == listArgumentType);
  assert(namedArgsLocal.type == listArgumentType);

  final b = function.body;

  // Read the `_FunctionType` field
  final functionTypeLocal =
      function.addLocal(translator.closureLayouter.functionTypeType);
  b.local_get(closureLocal);
  b.struct_get(translator.closureLayouter.closureBaseStruct,
      FieldIndex.closureRuntimeType);
  b.local_tee(functionTypeLocal);

  // Check closure shape
  b.local_get(typeArgsLocal);
  b.local_get(posArgsLocal);
  b.local_get(namedArgsLocal);
  b.call(
      translator.functions.getFunction(translator.checkClosureShape.reference));

  b.i32_eqz();
  b.br_if(noSuchMethodBlock);

  // Shape check passed, check types
  if (!translator.options.omitTypeChecks) {
    b.local_get(functionTypeLocal);
    b.local_get(typeArgsLocal);
    b.local_get(posArgsLocal);
    b.local_get(namedArgsLocal);
    b.call(translator.functions
        .getFunction(translator.checkClosureType.reference));
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
    w.FunctionBuilder function,
    String memberName,
    w.Local typeArgsLocal,
    w.Local positionalArgsLocal,
    w.Local namedArgsLocal) {
  final b = function.body;

  translator.constants.instantiateConstant(
      function,
      b,
      SymbolConstant(memberName, null),
      translator.classInfo[translator.symbolClass]!.nonNullableType);

  b.local_get(typeArgsLocal);
  b.local_get(positionalArgsLocal);
  b.local_get(namedArgsLocal);
  b.call(translator.functions
      .getFunction(translator.namedParameterListToMap.reference));
  b.call(translator.functions
      .getFunction(translator.invocationGenericMethodFactory.reference));
}

void createGetterInvocationObject(
  Translator translator,
  w.FunctionBuilder function,
  String memberName,
) {
  final b = function.body;

  translator.constants.instantiateConstant(
      function,
      b,
      SymbolConstant(memberName, null),
      translator.classInfo[translator.symbolClass]!.nonNullableType);

  b.call(translator.functions
      .getFunction(translator.invocationGetterFactory.reference));
}

void createSetterInvocationObject(
  Translator translator,
  w.FunctionBuilder function,
  String memberName,
  w.Local positionalArgLocal,
) {
  final b = function.body;

  memberName = '$memberName=';

  translator.constants.instantiateConstant(
      function,
      b,
      SymbolConstant(memberName, null),
      translator.classInfo[translator.symbolClass]!.nonNullableType);

  b.local_get(positionalArgLocal);
  b.call(translator.functions
      .getFunction(translator.invocationSetterFactory.reference));
}

void generateNoSuchMethodCall(
  Translator translator,
  w.FunctionBuilder function,
  void Function() pushReceiver,
  void Function() pushInvocationObject,
) {
  final b = function.body;

  final SelectorInfo noSuchMethodSelector = translator.dispatchTable
      .selectorForTarget(translator.objectNoSuchMethod.reference);
  translator.functions.activateSelector(noSuchMethodSelector);

  final noSuchMethodParamInfo = noSuchMethodSelector.paramInfo;
  final noSuchMethodWasmFunctionType = noSuchMethodSelector.signature;

  pushReceiver();
  pushInvocationObject();

  final invocationFactory = translator.functions
      .getFunction(translator.invocationGenericMethodFactory.reference);
  translator.convertType(function, invocationFactory.type.outputs[0],
      noSuchMethodSelector.signature.inputs[1]);

  // `noSuchMethod` can have extra parameters as long as they are optional.
  // Push any optional positional parameters.
  int wasmArgIdx = 2;
  for (int positionalArgIdx = 1;
      positionalArgIdx < noSuchMethodParamInfo.positional.length;
      positionalArgIdx += 1) {
    final positionalParameterValue =
        noSuchMethodParamInfo.positional[positionalArgIdx]!;
    translator.constants.instantiateConstant(
        function,
        b,
        positionalParameterValue,
        noSuchMethodWasmFunctionType.inputs[wasmArgIdx]);
    wasmArgIdx += 1;
  }

  // Push any optional named parameters
  for (String namedParameterName in noSuchMethodParamInfo.names) {
    final namedParameterValue =
        noSuchMethodParamInfo.named[namedParameterName]!;
    translator.constants.instantiateConstant(function, b, namedParameterValue,
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

void _makeEmptyGrowableList(
    Translator translator, w.FunctionBuilder function, int capacity) {
  final b = function.body;
  Class cls = translator.growableListClass;
  ClassInfo info = translator.classInfo[cls]!;
  translator.functions.allocateClass(info.classId);
  w.ArrayType arrayType = translator.listArrayType;

  b.i32_const(info.classId);
  b.i32_const(initialIdentityHash);
  translator.constants.instantiateConstant(
      function,
      b,
      TypeLiteralConstant(DynamicType()),
      translator.classInfo[translator.typeClass]!.nonNullableType);
  b.i64_const(0); // _length
  b.i32_const(capacity);
  b.array_new_default(arrayType); // _data
  b.struct_new(info.struct);
}
