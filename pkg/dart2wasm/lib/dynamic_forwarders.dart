// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart' show CallTarget, CodeGenerator, MacroAssembler;
import 'dispatch_table.dart';
import 'reference_extensions.dart';
import 'translator.dart';

/// Stores forwarders for dynamic gets, sets, and invocations. See [Forwarder]
/// for details. Each module will contain its own forwarders for the names
/// invoked from it.
class DynamicForwarders {
  final Translator translator;
  final w.ModuleBuilder callingModule;

  final Map<Name, CallTarget> _getterForwarderOfName = {};
  final Map<Name, CallTarget> _setterForwarderOfName = {};
  final Map<CallShape, CallTarget> _methodForwarderOfName = {};

  DynamicForwarders(this.translator, this.callingModule);

  CallTarget getDynamicGetForwarder(Name name) =>
      _getterForwarderOfName[name] ??= _DynamicForwarderCallTarget(translator,
          _ForwarderKind.Getter, CallShape(name, 0, 0, []), callingModule);

  CallTarget getDynamicSetForwarder(Name name) =>
      _setterForwarderOfName[name] ??= _DynamicForwarderCallTarget(translator,
          _ForwarderKind.Setter, CallShape(name, 0, 1, []), callingModule);

  CallTarget getDynamicInvocationForwarder(CallShape shape) {
    // Add Wasm function to the map before generating the forwarder code, to
    // allow recursive calls in the "call" forwarder.
    var forwarder = _methodForwarderOfName[shape];
    if (forwarder == null) {
      forwarder = _DynamicForwarderCallTarget(
          translator, _ForwarderKind.Method, shape, callingModule);
      _methodForwarderOfName[shape] = forwarder;
    }
    return forwarder;
  }
}

class CallShape {
  final Name name;
  final int typeCount;
  final int positionalCount;
  final List<String> named;

  CallShape(this.name, this.typeCount, this.positionalCount, this.named);

  int get totalArgumentCount => typeCount + positionalCount + named.length;

  bool matchesTarget(FunctionNode target) {
    if (typeCount != target.typeParameters.length && typeCount != 0) {
      return false;
    }
    if (positionalCount < target.requiredParameterCount ||
        positionalCount > target.positionalParameters.length) {
      return false;
    }
    final namedParams = target.namedParameters;
    for (final name in namedParams) {
      if (name.isRequired && !named.contains(name.name)) {
        return false;
      }
    }
    for (final name in named) {
      if (!namedParams.any((n) => n.name == name)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(name, typeCount, positionalCount, Object.hashAll(named));

  @override
  bool operator ==(other) {
    if (other is! CallShape) return false;
    if (name != other.name) return false;
    if (typeCount != other.typeCount) return false;
    if (named.length != other.named.length) return false;
    for (int i = 0; i < named.length; ++i) {
      if (named[i] != other.named[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() =>
      'CallShape($name, $typeCount, $positionalCount, ${named.join('-')})';
}

class _DynamicForwarderCallTarget extends CallTarget {
  final Translator translator;
  final _ForwarderKind _kind;
  final CallShape callShape;
  final w.ModuleBuilder callingModule;

  _DynamicForwarderCallTarget(
      this.translator, this._kind, this.callShape, this.callingModule)
      : assert(!translator.isDynamicSubmodule ||
            (callShape.name.text == 'call' && _kind == _ForwarderKind.Method)),
        super(_functionType(translator, _kind, callShape));

  static w.FunctionType _functionType(
      Translator translator, _ForwarderKind kind, CallShape shape) {
    return switch (kind) {
      _ForwarderKind.Getter => translator.typesBuilder.defineFunction([
          translator.topType,
        ], [
          translator.topType
        ]),
      _ForwarderKind.Setter => translator.typesBuilder.defineFunction([
          translator.topType,
          translator.topType,
        ], [
          translator.topType
        ]),
      _ForwarderKind.Method => translator.typesBuilder.defineFunction([
          translator.topType,
          for (int i = 0; i < shape.typeCount; ++i)
            translator.translateType(translator.typeType),
          for (int i = 0; i < shape.positionalCount; ++i) translator.topType,
          for (int i = 0; i < shape.named.length; ++i) translator.topType,
        ], [
          translator.topType
        ]),
    };
  }

  @override
  String get name => 'Dynamic $_kind forwarder for "$callShape"';

  @override
  bool get supportsInlining => false;

  @override
  late final w.BaseFunction function = (() {
    final function = callingModule.functions.define(signature, name);
    final forwarder =
        _DynamicForwarderCodeGenerator(translator, _kind, callShape, function);
    translator.compilationQueue.add(CompilationTask(function, forwarder));
    return function;
  })();
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
class _DynamicForwarderCodeGenerator extends CodeGenerator {
  final Translator translator;
  final _ForwarderKind _kind;
  final CallShape callerShape;
  final w.FunctionBuilder function;

  _DynamicForwarderCodeGenerator(
      this.translator, this._kind, this.callerShape, this.function);

  @override
  void generate(w.InstructionsBuilder b, List<w.Local> paramLocals,
      w.Label? returnLabel) {
    assert(returnLabel == null); // no inlining support atm.
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
        translator.dispatchTable.dynamicGetterSelectors(callerShape.name);
    final ranges = selectors
        .expand((selector) => selector
            .targets(unchecked: false)
            .allTargetRanges
            .map((r) => (range: r.range, value: r.target)))
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

      translator.callReference(
          translator.noSuchMethodErrorThrowWithInvocation.reference, b);
      b.unreachable();
      b.end(); // nullBlock
      b.local_set(receiverLocal);
    }

    b.local_get(receiverLocal);
    b.loadClassId(translator, receiverLocal.type);
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
      translator.convertType(
          b, targetFunction.type.outputs.single, outputs.single);
    }, () {
      generateNoSuchMethodCall(translator, b, () => b.local_get(receiverLocal),
          () => createGetterInvocationObject(translator, b, callerShape.name));
    });

    b.return_();
    b.end();
  }

  void _generateSetterCode(Translator translator) {
    final selectors =
        translator.dispatchTable.dynamicSetterSelectors(callerShape.name);
    final ranges = selectors
        .expand((selector) => selector
            .targets(unchecked: false)
            .allTargetRanges
            .map((r) => (range: r.range, value: r.target)))
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
          translator, b, callerShape.name, positionalArgLocal);

      translator.callReference(
          translator.noSuchMethodErrorThrowWithInvocation.reference, b);
      b.unreachable();
      b.end(); // nullBlock
      b.local_set(receiverLocal);
    }

    b.local_get(receiverLocal);
    b.loadClassId(translator, receiverLocal.type);
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
              translator, b, callerShape.name, positionalArgLocal));

      b.drop(); // drop noSuchMethod return value
      b.local_get(positionalArgLocal);
    });

    b.return_();
    b.end();
  }

  void _generateMethodCode(Translator translator) {
    final b = function.body;

    final nullableReceiverLocal = function.locals[0]; // ref #Top

    // Load type parameter as WasmArray<_Type>
    final typeArgsLocal = b.addLocal(translator.typeArrayTypeRef);
    if (callerShape.typeCount == 0) {
      final emptyArray = translator.constants
          .makeArrayOf(translator.coreTypes.typeNonNullableRawType, []);
      translator.constants
          .instantiateConstant(b, emptyArray, translator.typeArrayTypeRef);
    } else {
      for (int i = 0; i < callerShape.typeCount; ++i) {
        b.local_get(function.locals[1 + i]);
      }
      b.array_new_fixed(translator.typeArrayType, callerShape.typeCount);
    }
    b.local_set(typeArgsLocal);

    // Load positional parameters as WasmArray<Object?>
    final positionalArgsLocal =
        b.addLocal(translator.nullableObjectArrayTypeRef);
    if (callerShape.positionalCount == 0) {
      final emptyArray = translator.constants
          .makeArrayOf(translator.coreTypes.objectNullableRawType, []);
      translator.constants.instantiateConstant(
          b, emptyArray, translator.nullableObjectArrayTypeRef);
    } else {
      for (int i = 0; i < callerShape.positionalCount; ++i) {
        b.local_get(function.locals[1 + callerShape.typeCount + i]);
      }
      b.array_new_fixed(
          translator.nullableObjectArrayType, callerShape.positionalCount);
    }
    b.local_set(positionalArgsLocal);

    // Load named parameters as WasmArray<Object?>
    final namedArgsLocal = b.addLocal(translator.nullableObjectArrayTypeRef);
    if (callerShape.named.isEmpty) {
      final emptyArray = translator.constants
          .makeArrayOf(translator.coreTypes.objectNullableRawType, []);
      translator.constants.instantiateConstant(
          b, emptyArray, translator.nullableObjectArrayTypeRef);
    } else {
      for (int i = 0; i < callerShape.named.length; ++i) {
        translator.constants.instantiateConstant(
            b,
            translator.symbols.symbolForNamedParameter(callerShape.named[i]),
            translator.topType);
        b.local_get(function.locals[
            1 + callerShape.typeCount + callerShape.positionalCount + i]);
      }
      b.array_new_fixed(
          translator.nullableObjectArrayType, callerShape.named.length * 2);
    }
    b.local_set(namedArgsLocal);

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
      createInvocationObject(translator, b, callerShape.name, typeArgsLocal,
          positionalArgsLocal, namedArgsLocal);

      translator.callReference(
          translator.noSuchMethodErrorThrowWithInvocation.reference, b);
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

    final methodSelectors =
        translator.dispatchTable.dynamicMethodSelectors(callerShape.name);
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
        final targetMemberParamInfo = translator.paramInfoForDirectCall(target);
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
        b.local_get(typeArgsLocal);

        if (callerShape.positionalCount ==
            targetMemberParamInfo.positional.length) {
          b.local_get(positionalArgsLocal);
        } else {
          final targetPositionals = targetFunction.positionalParameters;
          for (int i = 0; i < targetMemberParamInfo.positional.length; ++i) {
            if (i < callerShape.positionalCount) {
              b.local_get(function.locals[1 + callerShape.typeCount + i]);
              continue;
            }
            final defaultValue = targetMemberParamInfo.positional[i];
            // The target (a type checker function) has a signature that is
            // created based on the union/merged of all members of the selector.
            //
            // Some implementations of the selector may have more positionals
            // than others, hence the `i < targetPositionals.length`.
            final defaultFunctionValue = i < targetPositionals.length
                ? (targetPositionals[i].initializer as ConstantExpression?)
                    ?.constant
                : null;
            translator.constants.instantiateConstant(
                b, defaultFunctionValue ?? defaultValue!, translator.topType);
          }
          b.array_new_fixed(translator.nullableObjectArrayType,
              targetMemberParamInfo.positional.length);
        }

        Expression? initializerForNamedParamInMember(String paramName) {
          for (int i = 0; i < targetFunction.namedParameters.length; i++) {
            if (targetFunction.namedParameters[i].name == paramName) {
              return targetFunction.namedParameters[i].initializer;
            }
          }
          return null;
        }

        if (targetMemberParamInfo.names.isEmpty) {
          final emptyArray = translator.constants
              .makeArrayOf(translator.coreTypes.objectNullableRawType, []);
          translator.constants.instantiateConstant(
              b, emptyArray, translator.nullableObjectArrayTypeRef);
        } else {
          // The type checker forwarder expects all named arguments as an array of
          // values (i.e. not array of (symbol, value) pairs).
          for (int i = 0; i < targetMemberParamInfo.names.length; ++i) {
            final name = targetMemberParamInfo.names[i];
            final index = callerShape.named.indexOf(name);
            if (index != -1) {
              b.local_get(function.locals[1 +
                  callerShape.typeCount +
                  callerShape.positionalCount +
                  index]);
              continue;
            }
            final defaultValue = targetMemberParamInfo.named[name];
            final defaultFunctionValue =
                (initializerForNamedParamInMember(name) as ConstantExpression?)
                    ?.constant;
            assert(defaultValue != null || defaultFunctionValue != null);
            translator.constants.instantiateConstant(
                b, defaultFunctionValue ?? defaultValue!, translator.topType);
          }
          b.array_new_fixed(translator.nullableObjectArrayType,
              targetMemberParamInfo.named.length);
        }

        translator.callReference(targetMember.typeCheckerReference, b);
        b.return_();
        b.end(); // classIdNoMatch
      }
    }

    final getterValueLocal = b.addLocal(translator.topType);
    void handleGetterSelector(SelectorInfo selector) {
      for (final (:range, :target)
          in selector.targets(unchecked: false).allTargetRanges) {
        final targetMember = target.asMember;
        // This loop checks getters and fields. Methods are considered in the
        // previous loop, skip them here.
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
            throw '_generateMethodCode: member is not a procedure or field: $targetMember';
          }

          final w.BaseFunction targetFunction =
              translator.functions.getFunction(targetReference);

          // Get field value
          b.local_get(receiverLocal);
          translator.convertType(
              b, receiverLocal.type, targetFunction.type.inputs.first);
          translator.callFunction(targetFunction, b);
          translator.convertType(
              b, targetFunction.type.outputs.single, translator.topType);
          b.local_tee(getterValueLocal);

          // Throw `NoSuchMethodError` if the value is null
          b.br_on_null(noSuchMethodBlock);
          // Reuse `receiverLocal`. This also updates the `noSuchMethod` receiver
          // below.
          b.local_tee(receiverLocal);

          // Invoke "call" if the value is not a closure
          b.loadClassId(translator, receiverLocal.type);
          b.i32_const(
              (translator.closureInfo.classId as AbsoluteClassId).value);
          b.i32_ne();
          b.if_();
          // Value is not a closure
          final callForwarder = translator
              .getDynamicForwardersForModule(b.moduleBuilder)
              .getDynamicInvocationForwarder(CallShape(
                  Name('call'),
                  callerShape.typeCount,
                  callerShape.positionalCount,
                  callerShape.named))
              .function;

          b.local_get(receiverLocal);
          for (int i = 0; i < callerShape.typeCount; ++i) {
            b.local_get(function.locals[1 + i]);
          }
          for (int i = 0; i < callerShape.positionalCount; ++i) {
            b.local_get(function.locals[1 + callerShape.typeCount + i]);
          }
          for (int i = 0; i < callerShape.named.length; ++i) {
            b.local_get(function.locals[
                1 + callerShape.typeCount + callerShape.positionalCount + i]);
          }
          translator.callFunction(callForwarder, b);
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

          generateDynamicClosureCallShapeAndTypeCheck(
              translator,
              b,
              closureLocal,
              typeArgsLocal,
              positionalArgsLocal,
              namedArgsLocal,
              noSuchMethodBlock);
          if (translator.dynamicModuleSupportEnabled) {
            generateDynamicClosureCallViaDynamicEntry(
                translator,
                b,
                closureLocal,
                typeArgsLocal,
                positionalArgsLocal,
                namedArgsLocal);
          } else {
            void emitCallForTypeCount(int typeCount) {
              final representation = translator.closureLayouter
                  .getClosureRepresentation(typeCount,
                      callerShape.positionalCount, callerShape.named);
              if (representation == null) {
                // This is a call combination that the closure layouter determined
                // cannot occur in the program (it means the shape&type checks
                // we already performed earlier must have thrown an NSM error
                // and we cannot get here).
                b.unreachable();
                return;
              }

              b.local_get(closureLocal);
              b.struct_get(translator.closureLayouter.closureBaseStruct,
                  FieldIndex.closureContext);
              for (int i = 0; i < typeCount; ++i) {
                b.local_get(typeArgsLocal);
                b.i32_const(i);
                b.array_get(translator.typeArrayType);
              }
              for (int i = 0; i < callerShape.positionalCount; ++i) {
                b.local_get(function.locals[1 + callerShape.typeCount + i]);
              }
              for (int i = 0; i < callerShape.named.length; ++i) {
                b.local_get(function.locals[1 +
                    callerShape.typeCount +
                    callerShape.positionalCount +
                    i]);
              }

              final vtable = representation.vtableStruct;
              final vtableIndex = representation.fieldIndexForSignature(
                  callerShape.positionalCount, callerShape.named);

              b.local_get(closureLocal);
              b.struct_get(translator.closureLayouter.closureBaseStruct,
                  FieldIndex.closureVtable);
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
              // already performed may have populated default type arguments (of
              // unknown length) for the closure.
              //
              // So we
              final maxTypeCount =
                  translator.closureLayouter.maxTypeArgumentCount();
              b.emitDenseTableBranch([translator.topType], maxTypeCount, () {
                b.local_get(typeArgsLocal);
                b.array_len();
              }, (int typeCount) {
                emitCallForTypeCount(typeCount);
              }, () {
                b.unreachable();
              });
            } else {
              emitCallForTypeCount(callerShape.typeCount);
            }
          }
          b.return_();

          b.end(); // class ID
        }
      }
    }

    final getterSelectors =
        translator.dispatchTable.dynamicGetterSelectors(callerShape.name);
    for (final selector in getterSelectors) {
      handleGetterSelector(selector);
    }

    final dynamicMainModuleGetterSelectors = translator
        .dynamicMainModuleDispatchTable
        ?.dynamicGetterSelectors(callerShape.name);
    if (dynamicMainModuleGetterSelectors != null) {
      for (final selector in dynamicMainModuleGetterSelectors) {
        handleGetterSelector(selector);
      }
    }

    b.end(); // noSuchMethodBlock

    // Unable to find a matching member, call `noSuchMethod`
    generateNoSuchMethodCall(
        translator,
        b,
        () => b.local_get(receiverLocal),
        () => createInvocationObject(translator, b, callerShape.name,
            typeArgsLocal, positionalArgsLocal, namedArgsLocal));

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
    w.Label noSuchMethodBlock) {
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
    w.Local namedArgsLocal) {
  assert(translator.dynamicModuleSupportEnabled ||
      translator.closureLayouter.usesFunctionApplyWithNamedArguments);

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
  b.struct_get(translator.closureLayouter.vtableBaseStruct,
      translator.closureLayouter.vtableDynamicClosureCallEntryIndex!);
  b.call_ref(translator.dynamicCallVtableEntryFunctionType);
}

void generateDynamicClosureCallViaPositionalArgs(
    Translator translator,
    w.InstructionsBuilder b,
    w.Local closureLocal,
    w.Local typeArgsLocal,
    w.Local posArgsLocal) {
  assert(!translator.dynamicModuleSupportEnabled &&
      !translator.closureLayouter.usesFunctionApplyWithNamedArguments);

  final maxTypeCount = translator.closureLayouter.maxTypeArgumentCount();
  b.emitDenseTableBranch([translator.topType], maxTypeCount, () {
    b.local_get(typeArgsLocal);
    b.array_len();
  }, (typeCount) {
    final maxPositionalCount =
        translator.closureLayouter.maxPositionalCountFor(typeCount);
    b.emitDenseTableBranch([translator.topType], maxPositionalCount, () {
      b.local_get(posArgsLocal);
      b.array_len();
    }, (posCount) {
      final representation = translator.closureLayouter
          .getClosureRepresentation(typeCount, posCount, []);
      if (representation == null) {
        // This is a call combination that the closure layouter determined
        // cannot occur in the program.
        b.unreachable();
        return;
      }

      b.local_get(closureLocal);
      b.struct_get(translator.closureLayouter.closureBaseStruct,
          FieldIndex.closureContext);
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
      final vtableIndex = representation.fieldIndexForSignature(posCount, []);

      b.local_get(closureLocal);
      b.struct_get(translator.closureLayouter.closureBaseStruct,
          FieldIndex.closureVtable);
      b.ref_cast(w.RefType(vtable, nullable: false));
      b.struct_get(vtable, vtableIndex);
      b.call_ref(vtable.getVtableEntryAt(vtableIndex));
    }, () {
      b.unreachable();
    });
  }, () {
    b.unreachable();
  });
}

void createInvocationObject(
    Translator translator,
    w.InstructionsBuilder b,
    Name memberName,
    w.Local typeArgsLocal,
    w.Local positionalArgsLocal,
    w.Local namedArgsLocal) {
  translator.constants.instantiateConstant(
      b,
      translator.symbols.methodSymbolFromName(memberName),
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
  Name memberName,
) {
  translator.constants.instantiateConstant(
      b,
      translator.symbols.getterSymbolFromName(memberName),
      translator.classInfo[translator.symbolClass]!.nonNullableType);

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
  translator.functions.recordSelectorUse(noSuchMethodSelector, false);
  final signature = noSuchMethodSelector.signature;

  final targetRanges =
      noSuchMethodSelector.targets(unchecked: false).allTargetRanges;
  final staticDispatchRanges =
      noSuchMethodSelector.targets(unchecked: false).staticDispatchRanges;

  // NOTE: Keep this in sync with
  // `code_generator.dart:AstCodeGenerator._virtualCall`.
  final bool directCall =
      targetRanges.length == 1 && staticDispatchRanges.length == 1;
  final callPolymorphicDispatcher =
      !directCall && staticDispatchRanges.isNotEmpty;

  final noSuchMethodParamInfo = noSuchMethodSelector.paramInfo;
  final noSuchMethodWasmFunctionType = signature;

  pushReceiver();
  if (callPolymorphicDispatcher) {
    b.loadClassId(translator, translator.topTypeNonNullable);
    pushReceiver();
  }
  pushInvocationObject();

  final invocationFactory = translator.functions
      .getFunction(translator.invocationGenericMethodFactory.reference);
  translator.convertType(
      b, invocationFactory.type.outputs[0], signature.inputs[1]);

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

  if (directCall) {
    translator.callReference(targetRanges[0].target, b);
  } else if (callPolymorphicDispatcher) {
    b.invoke(translator
        .getPolymorphicDispatchersForModule(b.moduleBuilder)
        .getPolymorphicDispatcher(noSuchMethodSelector,
            useUncheckedEntry: false));
  } else {
    pushReceiver();
    translator.callDispatchTable(b, noSuchMethodSelector,
        interfaceTarget: translator.objectNoSuchMethod.reference,
        useUncheckedEntry: false);
  }
}

class ClassIdRange {
  final int start;
  final int end; // inclusive

  ClassIdRange(this.start, this.end);
}
