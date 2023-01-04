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

  Forwarder getGetterForwarder(DynamicGet node) {
    final memberName = node.name.text;
    return _getterForwarderOfName[memberName] ??=
        Forwarder(translator, _ForwarderKind.Getter, memberName);
  }

  Forwarder getSetterForwarder(DynamicSet node) {
    final memberName = node.name.text;
    return _setterForwarderOfName[memberName] ??=
        Forwarder(translator, _ForwarderKind.Setter, memberName);
  }

  Forwarder getMethodForwarder(DynamicInvocation node) {
    final memberName = node.name.text;
    return _methodForwarderOfName[memberName] ??=
        Forwarder(translator, _ForwarderKind.Method, memberName);
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

  final w.DefinedFunction function;

  Forwarder(Translator translator, this.kind, this.memberName)
      : function = translator.m.addFunction(kind.functionType(translator),
            "$kind forwarder for '$memberName'") {
    _generateCode(translator, function);
  }

  void _generateCode(Translator translator, w.DefinedFunction function) {
    switch (kind) {
      case _ForwarderKind.Getter:
        _generateGetterCode(translator, function);
        break;

      case _ForwarderKind.Setter:
        _generateSetterCode(translator, function);
        break;

      case _ForwarderKind.Method:
        _generateMethodCode(translator, function);
        break;
    }
  }

  void _generateGetterCode(Translator translator, w.DefinedFunction function) {
    final w.Instructions b = function.body;

    final receiverLocal = function.locals[0];

    final selectors =
        translator.dispatchTable.selectorsForDynamicGet(memberName)?.toList() ??
            [];
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

    _generateNoSuchMethodCall(
        translator,
        function,
        () => b.local_get(receiverLocal),
        () => createGetterInvocationObject(translator, function, memberName));

    b.end();
  }

  void _generateSetterCode(Translator translator, w.DefinedFunction function) {
    final w.Instructions b = function.body;

    final receiverLocal = function.locals[0];
    final positionalArgLocal = function.locals[1];

    final selectors =
        translator.dispatchTable.selectorsForDynamicSet(memberName)?.toList() ??
            [];
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

    _generateNoSuchMethodCall(
        translator,
        function,
        () => b.local_get(receiverLocal),
        () => createSetterInvocationObject(
            translator, function, memberName, positionalArgLocal));

    b.drop(); // drop noSuchMethod return value
    b.local_get(positionalArgLocal);

    b.end();
  }

  void _generateMethodCode(Translator translator, w.DefinedFunction function) {
    final w.Instructions b = function.body;

    final receiverLocal = function.locals[0];
    final typeArgsLocal = function.locals[1];
    final positionalArgsLocal = function.locals[2];
    final namedArgsLocal = function.locals[3];

    final numArgsLocal = function.addLocal(w.NumType.i32);

    final selectors = translator.dispatchTable
            .selectorsForDynamicInvocation(memberName)
            ?.toList() ??
        [];
    for (final selector in selectors) {
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
        final topBlock = b.if_();

        // Check number of type arguments. It needs to be 0 or match the
        // member's type parameters.
        if (targetMemberParamInfo.typeParamCount == 0) {
          b.local_get(typeArgsLocal);
          translator.getListLength(b);
          b.i32_eqz();
        } else {
          b.local_get(typeArgsLocal);
          translator.getListLength(b);
          b.local_tee(numArgsLocal);
          b.i32_eqz();
          b.local_get(numArgsLocal);
          b.i32_const(targetMemberParamInfo.typeParamCount);
          b.i32_eq();
          b.i32_or();
        }
        b.if_();

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
        b.if_();

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

            b.end();
          }
        }

        // Check named arguments and adjust the named argument list. Named
        // parameters in the member should be in the list or have a default
        // value.
        w.Local? adjustedNamedArgsLocal;
        if (targetMemberParamInfo.named.isEmpty) {
          b.local_get(namedArgsLocal);
          translator.getListLength(b);
          b.i32_eqz();
          b.i32_eqz();
          b.br_if(topBlock);
        } else {
          adjustedNamedArgsLocal = function.addLocal(translator
              .classInfo[translator.growableListClass]!.nonNullableType);
          _makeEmptyGrowableList(
              translator, function, targetMemberParamInfo.named.length);
          b.local_set(adjustedNamedArgsLocal);

          final namedParameterValueLocal =
              function.addLocal(translator.topInfo.nullableType);

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
                .getFunction(translator.getNamedParameter.reference));

            b.local_tee(namedParameterValueLocal);
            b.ref_is_null();
            b.i32_eqz();
            b.if_();
            b.local_get(remainingNamedArgsLocal);
            b.i32_const(1);
            b.i32_sub();
            b.local_set(remainingNamedArgsLocal);
            b.end();

            b.local_get(namedParameterValueLocal);
            b.ref_is_null();
            if (functionNodeDefaultValue == null &&
                paramInfoDefaultValue == null) {
              // Required
              b.br_if(topBlock);
              b.local_get(adjustedNamedArgsLocal);
              b.local_get(namedParameterValueLocal);
              b.call(translator.functions
                  .getFunction(translator.growableListAdd.reference));
            } else {
              // Optional, either has a default in the member or not used by
              // the member
              b.if_();

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
              b.local_set(namedParameterValueLocal);

              b.end();
              b.local_get(adjustedNamedArgsLocal);
              b.local_get(namedParameterValueLocal);
              b.call(translator.functions
                  .getFunction(translator.growableListAdd.reference));
            }
          }

          // Check that all named arguments are used. If not, it means that the
          // call site has extra names that the member doesn't have.
          b.local_get(remainingNamedArgsLocal);
          b.i32_eqz();
          b.i32_eqz();
          b.br_if(topBlock);
        }

        b.local_get(receiverLocal);
        b.local_get(typeArgsLocal);
        b.local_get(adjustedPositionalArgsLocal ?? positionalArgsLocal);
        b.local_get(adjustedNamedArgsLocal ?? namedArgsLocal);
        final wasmFunction =
            translator.functions.getFunction(targetMember.typeCheckerReference);
        b.call(wasmFunction);

        b.return_();
        b.end(); // positional args check
        b.end(); // type args check
        b.end();
      }
    }

    // Unable to find a matching member, call `noSuchMethod`
    _generateNoSuchMethodCall(
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

void createInvocationObject(
    Translator translator,
    w.DefinedFunction function,
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
  w.DefinedFunction function,
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
  w.DefinedFunction function,
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

void _generateNoSuchMethodCall(
  Translator translator,
  w.DefinedFunction function,
  void Function() pushReceiver,
  void Function() pushInvocationObject,
) {
  final b = function.body;

  SelectorInfo noSuchMethodSelector = translator.dispatchTable
      .selectorForTarget(translator.objectNoSuchMethod.reference);
  translator.functions.activateSelector(noSuchMethodSelector);

  pushReceiver();
  pushInvocationObject();

  final invocationFactory = translator.functions
      .getFunction(translator.invocationGenericMethodFactory.reference);
  translator.convertType(function, invocationFactory.type.outputs[0],
      noSuchMethodSelector.signature.inputs[1]);

  // Get class id for virtual call
  pushReceiver();
  b.struct_get(translator.topInfo.struct, FieldIndex.classId);

  // Virtual call to noSuchMethod
  int selectorOffset = noSuchMethodSelector.offset!;
  if (selectorOffset != 0) {
    b.i32_const(selectorOffset);
    b.i32_add();
  }
  b.call_indirect(noSuchMethodSelector.signature);
}

void _makeEmptyGrowableList(
    Translator translator, w.DefinedFunction function, int capacity) {
  final w.Instructions b = function.body;
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
