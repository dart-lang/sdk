// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/dispatch_table.dart';
import 'package:dart2wasm/param_info.dart';
import 'package:dart2wasm/translator.dart';
import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

enum DynamicSelectorType {
  setter,
  getter,
  method,
}

class DynamicDispatcher {
  final Translator translator;
  final Map<DynamicSelectorType, Map<String, w.DefinedFunction>>
      dynamicTrampolines = {
    DynamicSelectorType.setter: {},
    DynamicSelectorType.getter: {},
    DynamicSelectorType.method: {},
  };

  DynamicDispatcher(this.translator);

  TranslatorOptions get options => translator.options;

  w.ValueType _callDynamic(CodeGenerator codeGen, DynamicInvocation node) {
    // Handle general dynamic invocation.
    w.Instructions b = codeGen.b;
    w.DefinedFunction function = codeGen.function;

    // Wrap dynamic call body in a block.
    w.Label dynamicBlock = b.block(const [], [translator.topInfo.nullableType]);

    // Evaluate receiver
    codeGen.wrap(node.receiver, translator.topInfo.nullableType);
    w.Local receiverVar = codeGen.addLocal(translator.topInfo.nullableType);
    b.local_set(receiverVar);

    w.Local passedParameterCountLocal = codeGen.addLocal(w.NumType.i32);
    b.i32_const(node.arguments.positional.length);
    b.local_set(passedParameterCountLocal);
    w.ValueType result = _emitDynamicCallBody(function, node, receiverVar,
        passedParameterCountLocal, node.arguments.positional.length,
        preSelector: (SelectorInfo selector) => selector.canApply(node),
        pushArguments: (SelectorInfo selector) {
          // Visit arguments to evaluate them inline.
          w.FunctionType signature = selector.signature;
          ParameterInfo parameterInfo = selector.paramInfo;
          FunctionNode function =
              (selector.paramInfo.member as Procedure).function;
          Arguments arguments = node.arguments;

          // If we have empty type arguments, but the function we are calling
          // requires them, then send a list of bound types instead.
          assert(arguments.types.isEmpty ||
              arguments.types.length == function.typeParameters.length);
          int expectedTypeParameters = function.typeParameters.length;
          List<DartType> typeArguments = expectedTypeParameters == 0
              ? const []
              : arguments.types.isEmpty
                  ? List<DartType>.generate(expectedTypeParameters,
                      (index) => function.typeParameters[index].bound)
                  : arguments.types;

          // TODO(joshualitt): Support type checks for arguments.
          codeGen.visitArgumentsLists(
              arguments.positional, signature, parameterInfo, 1,
              typeArguments: typeArguments, named: arguments.named);
        },
        pushArgumentForNoSuchMethod: (int index) {
          codeGen.wrap(node.arguments.positional[index],
              translator.topInfo.nullableType);
        },
        onCallSuccess: () {
          b.br(dynamicBlock);
        },
        postSelector: () {});
    b.end(); // end block.
    return result;
  }

  w.ValueType _emitDynamicCallBody(
      w.DefinedFunction function,
      Expression node,
      w.Local receiverVar,
      w.Local passedParameterCountLocal,
      int maxParameterCount,
      {required bool preSelector(SelectorInfo selector),
      required void pushArguments(SelectorInfo selector),
      required void onCallSuccess(),
      required void postSelector(),
      required void pushArgumentForNoSuchMethod(int index)}) {
    w.Instructions b = function.body;
    w.Local addLocal(w.ValueType type) => function.addLocal(type);

    // We make a copy of the list of selectors to avoid concurrent
    // modification.
    List<SelectorInfo> selectors =
        translator.dispatchTable.selectorsForDynamicNode(node)?.toList() ?? [];

    // Test the receiver's class ID against every class that implements a given
    // selector. If there is a match then invoke the selector, otherwise calls
    // `Object.noSuchMethod`.
    // TODO(joshualitt): We have a couple different options for optimization. If
    // all we care about is code size, we might do best to use constant maps or
    // one function per selector. On the other hand, we could also try a hybrid
    // IC like approach using globals, rewiring logic, and a state machine.
    w.Local cidLocal = addLocal(w.NumType.i32);

    // Outer block searches through the methods and invokes the method if it
    // finds one
    b.block([], [translator.topInfo.nullableType]);

    // Inner block checks whether the receiver is null. If it is, then throws
    // an exception.
    //
    // `null` has the same members as `Object`[*], and when the member in a
    // get, set, or invocation expression is known to be a member of `Object`
    // the Kernal AST for the expression is [InstanceGet], [InstanceSet], or
    // [InstanceInvocation]. So here we know that the member is not a member of
    // `Object` (and `null`) and we just throw an exception.
    //
    // [*]: Except `operator ==`, but this difference cannot be observed as
    // it's not possible to tear-off an operator.
    final nullBlock = b.block([], [translator.topInfo.nonNullableType]);
    b.local_get(receiverVar);
    b.br_on_non_null(nullBlock);

    // Throw `NoSuchMethodError`. Normally this needs to happen via instance
    // invocation of `noSuchMethod` (done in [_callNoSuchMethod]), but we don't
    // have a `Null` class in dart2wasm so we throw directly.
    b.local_get(receiverVar);
    _createInvocationObject(function, node, maxParameterCount,
        passedParameterCountLocal, pushArgumentForNoSuchMethod);
    w.BaseFunction f = translator.functions
        .getFunction(translator.noSuchMethodErrorThrowWithInvocation.reference);
    b.call(f);
    b.unreachable();
    b.end(); // nullBlock

    b.struct_get(translator.topInfo.struct, FieldIndex.classId);
    b.local_set(cidLocal);
    for (SelectorInfo selector in selectors) {
      if (!preSelector(selector)) {
        continue;
      }
      translator.functions.activateSelector(selector);
      for (int classID in selector.classIds) {
        final Reference target = selector.targets[classID]!;
        if (target.asMember.isAbstract) {
          continue;
        }

        b.local_get(cidLocal);
        b.i32_const(classID);
        b.i32_eq();
        b.if_();

        b.comment("Dynamic invocation of '${selector.name}'");
        b.local_get(receiverVar);
        translator.convertType(function, translator.topInfo.nullableType,
            selector.signature.inputs[0]);

        pushArguments(selector);

        final w.BaseFunction targetFunction =
            translator.functions.getFunction(target);
        b.call(targetFunction);

        w.ValueType result =
            translator.outputOrVoid(selector.signature.outputs);
        translator.convertType(
            function, result, translator.topInfo.nullableType);
        onCallSuccess();
        b.end(); // end if
      }
      postSelector();
    }

    // Handle the case where no test succeeded.
    _callNoSuchMethod(function, node, receiverVar, cidLocal, maxParameterCount,
        passedParameterCountLocal, pushArgumentForNoSuchMethod);

    b.end();

    return translator.topInfo.nullableType;
  }

  String _nameFromNode(Expression node) {
    if (node is DynamicGet) {
      return node.name.text;
    } else if (node is DynamicSet) {
      return node.name.text;
    } else if (node is DynamicInvocation) {
      return node.name.text;
    } else {
      throw 'Dynamic invocation of $node not supported';
    }
  }

  // Builds a [List] at runtime from a list of locals variables.
  void makeList(w.DefinedFunction function, int maxParameterCount,
      w.Local currentParameterCountLocal, void pushArgument(int index)) {
    w.Instructions b = function.body;
    Class cls = translator.fixedLengthListClass;
    ClassInfo info = translator.classInfo[cls]!;
    translator.functions.allocateClass(info.classId);
    w.ArrayType arrayType = translator.listArrayType;

    // Initialize array struct.
    b.local_get(currentParameterCountLocal);
    b.array_new_default(arrayType);
    w.Local arrayLocal =
        function.addLocal(w.RefType.def(arrayType, nullable: false));
    b.local_set(arrayLocal);

    // Fill the array up to min(maxParameterCount, currentParameterCountLocal).
    // Furthermore, currentParameterCountLocal should be < maxParameterCount
    // based on how maxParameterCount is computed.
    w.Label arrayFillBlock = b.block();
    b.local_get(currentParameterCountLocal);
    b.i32_eqz();
    b.br_if(arrayFillBlock);
    for (int i = 0; i < maxParameterCount; i++) {
      b.local_get(arrayLocal);
      b.i32_const(i);
      pushArgument(i);
      b.array_set(arrayType);
      b.i32_const(i);
      b.local_get(currentParameterCountLocal);
      b.i32_eq();
      b.br_if(arrayFillBlock);
    }
    b.end(); // end arrayFillBlock.

    // Initialize [List] object.
    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);
    translator.constants.instantiateConstant(
        function,
        b,
        TypeLiteralConstant(const DynamicType()),
        translator.types.nonNullableTypeType);
    b.local_get(currentParameterCountLocal);
    b.i64_extend_i32_u();
    b.local_get(arrayLocal);
    b.struct_new(info.struct);
  }

  /// Creates an [Invocation] object and calls [noSuchMethod] virtually on the
  /// given non-null receiver.
  w.ValueType _callNoSuchMethod(
      w.DefinedFunction function,
      Expression node,
      w.Local receiverVar,
      w.Local cidLocal,
      int maxParameterCount,
      w.Local currentParameterCountLocal,
      void pushArgumentForNoSuchMethod(int index)) {
    w.Instructions b = function.body;
    Procedure noSuchMethod = translator.objectNoSuchMethod;
    Reference noSuchMethodReference = noSuchMethod.reference;
    SelectorInfo selector =
        translator.dispatchTable.selectorForTarget(noSuchMethodReference);
    w.FunctionType signature = selector.signature;
    b.comment("Dynamic invocation of '${selector.name}'");
    b.local_get(receiverVar);
    b.ref_as_non_null();
    _createInvocationObject(function, node, maxParameterCount,
        currentParameterCountLocal, pushArgumentForNoSuchMethod);
    // TODO(joshualitt): Under some cases we need to provide parameter defaults
    // to the invocation object. However, first we must fix the issue of how to
    // handle different default values.
    // See: language/override/inheritance_no_such_method_test/04
    b.local_get(cidLocal);
    int offset = selector.offset!;
    if (offset != 0) {
      b.i32_const(offset);
      b.i32_add();
    }
    b.call_indirect(signature);
    translator.functions.activateSelector(selector);
    return translator.topInfo.nullableType;
  }

  void _createInvocationObject(
      w.DefinedFunction function,
      Expression node,
      int maxParameterCount,
      w.Local currentParameterCountLocal,
      void pushArgumentForNoSuchMethod(int index)) {
    final w.Instructions b = function.body;
    final w.ValueType symbolValueType =
        translator.classInfo[translator.symbolClass]!.nonNullableType;
    if (node is DynamicGet) {
      translator.constants.instantiateConstant(
          function, b, SymbolConstant(node.name.text, null), symbolValueType);
      w.BaseFunction targetFunction = translator.functions
          .getFunction(translator.invocationGetterFactory.reference);
      b.call(targetFunction);
    } else if (node is DynamicSet) {
      translator.constants.instantiateConstant(function, b,
          SymbolConstant('${node.name.text}=', null), symbolValueType);
      pushArgumentForNoSuchMethod(0);
      w.BaseFunction targetFunction = translator.functions
          .getFunction(translator.invocationSetterFactory.reference);
      b.call(targetFunction);
    } else if (node is DynamicInvocation) {
      translator.constants.instantiateConstant(
          function, b, SymbolConstant(node.name.text, null), symbolValueType);

      // TODO(joshualitt): Consider supporting generic functions.
      makeList(function, maxParameterCount, currentParameterCountLocal,
          pushArgumentForNoSuchMethod);

      // TODO(joshualitt): Consider supporting named arguments.
      translator.constants.instantiateConstant(
          function, b, NullConstant(), translator.objectInfo.nullableType);
      w.BaseFunction targetFunction = translator.functions
          .getFunction(translator.invocationMethodFactory.reference);
      b.call(targetFunction);
    } else {
      throw 'Unexpected node for noSuchMethod: $node';
    }
  }

  // Whether or not we should emit a dynamic trampoline for a given dynamic
  // invocation. If not, we emit the dynamic call inline. We will always emit a
  // trampoline for any invocation where:
  //   1) No valid targets for the invocation have type parameters.
  //   2) No valid targets for the invocation have named parameters.
  //   3) This particular node has no more positional arguments than the maximum
  //      supported by the trampoline.
  bool shouldEmitTrampoline(DynamicInvocation node, int maxParameterCount) {
    if (node.arguments.types.isNotEmpty ||
        node.arguments.named.isNotEmpty ||
        node.arguments.positional.length > maxParameterCount) {
      return false;
    }

    Iterable<SelectorInfo>? selectors =
        translator.dispatchTable.selectorsForDynamicNode(node);

    // Don't bother to emit a trampoline when no classes implement a selector,
    // and just throw `noSuchMethod` inline.
    if (selectors == null) {
      return false;
    }

    for (SelectorInfo selector in selectors) {
      FunctionNode function = (selector.paramInfo.member as Procedure).function;
      if (function.typeParameters.isNotEmpty ||
          function.namedParameters.isNotEmpty ||
          function.positionalParameters.length !=
              function.requiredParameterCount) {
        return false;
      }
    }
    return true;
  }

  int parameterCount(DynamicInvocation node) {
    Iterable<SelectorInfo>? selectors =
        translator.dispatchTable.selectorsForDynamicNode(node);
    if (selectors == null) {
      return 0;
    }

    int parameterCount = 0;
    for (SelectorInfo selector in selectors) {
      parameterCount =
          max(parameterCount, selector.signature.inputs.length - 1);
    }
    return parameterCount;
  }

  w.DefinedFunction _emitTrampoline(Expression node, int maxParameterCount) {
    // Create a new function.
    w.FunctionType functionType = translator.m.addFunctionType([
      w.NumType.i32,
      translator.topInfo.nullableType,
      if (maxParameterCount > 0)
        ...List<w.ValueType>.filled(
            maxParameterCount, translator.topInfo.nullableType)
    ], [
      translator.topInfo.nullableType
    ]);
    w.DefinedFunction function = translator.m
        .addFunction(functionType, "${_nameFromNode(node)} dynamic trampoline");
    w.Instructions b = function.body;

    // Receiver should be the first thing on the stack.
    w.Local passedParameterCountLocal = function.locals[0];
    w.Local receiverVar = function.locals[1];
    List<w.Local> positionalLocals = [];
    for (int i = 0; i < maxParameterCount; i++) {
      positionalLocals.add(function.locals[i + 2]);
    }

    _emitDynamicCallBody(function, node, receiverVar, passedParameterCountLocal,
        maxParameterCount, preSelector: (SelectorInfo selector) {
      // Setup the `if` test to determine if we fall through to
      // `noSuchMethod`.
      w.FunctionType signature = selector.signature;
      int expectedParameterCount = signature.inputs.length - 1;
      b.local_get(passedParameterCountLocal);
      b.i32_const(expectedParameterCount);
      b.i32_eq();
      b.if_();
      return true;
    }, pushArguments: (SelectorInfo selector) {
      // Push the expected number of arguments onto the stack.
      w.FunctionType signature = selector.signature;
      int expectedParameterCount = signature.inputs.length - 1;
      assert(expectedParameterCount <= maxParameterCount);
      for (int i = 0; i < expectedParameterCount; i++) {
        final w.ValueType type = signature.inputs[i + 1];
        // TODO(joshualitt): as checks when requested.
        b.local_get(positionalLocals[i]);
        translator.convertType(function, translator.topInfo.nullableType, type);
      }
    }, pushArgumentForNoSuchMethod: (int index) {
      b.local_get(positionalLocals[index]);
    }, onCallSuccess: () {
      b.return_();
    }, postSelector: () {
      b.end(); // end if.
    });
    b.end(); // end function.
    return function;
  }

  w.ValueType emitDynamicCall(CodeGenerator codeGen, Expression node) {
    late DynamicSelectorType type;
    late String name;
    late Expression receiver;
    late List<Expression> positionalArguments;
    late int maxParameterCount;
    if (node is DynamicGet) {
      type = DynamicSelectorType.getter;
      name = node.name.text;
      receiver = node.receiver;
      positionalArguments = const [];
      maxParameterCount = 0;
    } else if (node is DynamicSet) {
      type = DynamicSelectorType.setter;
      name = node.name.text;
      receiver = node.receiver;
      positionalArguments = [node.value];
      maxParameterCount = 1;
    } else if (node is DynamicInvocation) {
      maxParameterCount = parameterCount(node);

      // Trampolines aren't supported for all [DynamicInvocation]s.
      if (!shouldEmitTrampoline(node, maxParameterCount)) {
        return _callDynamic(codeGen, node);
      }
      type = DynamicSelectorType.method;
      name = node.name.text;
      receiver = node.receiver;
      positionalArguments = node.arguments.positional;
    } else {
      throw 'Dynamic invocation of $node not supported';
    }

    // Check to see if we can reuse a trampoline, if not we create a new one and
    // then insert a call.
    w.DefinedFunction? trampoline = dynamicTrampolines[type]![name];
    if (trampoline == null) {
      trampoline = _emitTrampoline(node, maxParameterCount);
      dynamicTrampolines[type]![name] = trampoline;
    }
    w.Instructions b = codeGen.b;
    b.i32_const(positionalArguments.length);
    codeGen.wrap(receiver, translator.topInfo.nullableType);
    for (Expression e in positionalArguments) {
      codeGen.wrap(e, translator.topInfo.nullableType);
    }

    // Pad to the maximum with nulls. This works because we currently do not
    // support optional parameters of any kind, and we pass the exact number of
    // passed arguments to the trampoline. The trampoline itself will call
    // `noSuchMethod` if the supplied number of arguments is less than the
    // number required for any given selector.
    for (int i = positionalArguments.length; i < maxParameterCount; i++) {
      b.ref_null(w.HeapType.none);
    }
    b.call(dynamicTrampolines[type]![name]!);
    return translator.topInfo.nullableType;
  }
}
