// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:wasm_builder/wasm_builder.dart' as w;

import '../../cfg/to_wasm.dart';
import '../compile.dart';

/// Translates a [FlowGraph] (CFG IR) to WebAssembly bytecode for the dev
/// compiler.
final class DevCfgToWasm extends CfgToWasm {
  final ModuleCompiler moduleCompiler;

  @override
  late final DevWasmInstructionLowerer lowerer = DevWasmInstructionLowerer(
    this,
  );

  DevCfgToWasm(this.moduleCompiler, super.graph, super.b, {super.cfgLog});

  @override
  w.ValueType translateType(CType type) => moduleCompiler.translateType(type);

  @override
  void convertType(w.ValueType from, w.ValueType to) =>
      moduleCompiler.convertType(b, from, to);
}

final class DevWasmInstructionLowerer
    extends WasmInstructionLowerer<DevCfgToWasm> {
  DevWasmInstructionLowerer(super.gen);

  @override
  void visitParameter(Parameter instr) {
    assert(instr.isFunctionParameter);
    final function = gen.graph.function;
    final index = instr.variable.index;
    final param = b.locals[index];
    final type = gen.translateType(instr.type);
    // Reuse the parameter's local if it already has the parameter's type.
    final local = param.type == type ? param : b.addLocal(type);
    gen.locals[instr] = local;
    final isOptional =
        index >= function.numberOfRequiredPositionalParameters &&
        !(function.hasNamedParameters && function.isRequiredParameter(index));
    if (isOptional) {
      _pushParameterOrDefault(
        param,
        function.getParameterDefaultValue(index),
        type,
      );
      b.local_set(local);
    } else if (local != param) {
      b.local_get(param);
      gen.convertType(param.type, type);
      b.local_set(local);
    }
  }

  /// Pushes [param] as [type], or [defaultValue] if the caller omitted it.
  void _pushParameterOrDefault(
    w.Local param,
    ConstantValue defaultValue,
    w.ValueType type,
  ) {
    b.local_get(param);
    b.global_get(gen.moduleCompiler.defaultValueSentinel);
    b.ref_eq();
    b.if_(const [], [type]);
    final defaultType = gen.translateType(defaultValue.type);
    _pushConstant(defaultValue, defaultType);
    gen.convertType(defaultType, type);
    b.else_();
    b.local_get(param);
    gen.convertType(param.type, type);
    b.end();
  }

  @override
  void instantiateConstant(Constant instr, w.ValueType expectedType) =>
      _pushConstant(instr.value, expectedType);

  /// Pushes constant [value] as [expectedType].
  void _pushConstant(ConstantValue value, w.ValueType expectedType) {
    if (value.isInt && expectedType == w.NumType.i64) {
      b.i64_const(value.intValue);
    } else if (value.isDouble && expectedType == w.NumType.f64) {
      b.f64_const(value.doubleValue);
    } else if (value.isBool && expectedType == w.NumType.i32) {
      b.i32_const(value.boolValue ? 1 : 0);
    } else if (value.isString) {
      gen.convertType(pushString(b, value.stringValue), expectedType);
    } else if (value.isNull && expectedType is w.RefType) {
      b.ref_null(w.HeapType.none);
    } else {
      throw UnimplementedError('Unsupported constant: ${value.constant}');
    }
  }

  @override
  void visitDirectCall(DirectCall instr) {
    final target = instr.target;
    // TODO(dart2wasm): Support other targets and type arguments.
    if ((target is! RegularFunction && target is! GenerativeConstructor) ||
        instr.hasTypeArguments) {
      throw UnimplementedError('Unsupported directCall to $target');
    }
    final member = target.member;
    final coreTypes = GlobalContext.instance.coreTypes;
    if (target is GenerativeConstructor &&
        member.enclosingClass == coreTypes.objectClass) {
      // Skip calls to the constructor for Object, as this is empty
      return;
    }
    // TODO(dart2wasm): Remove once dart:core is compiled.
    if (member == coreTypes.printProcedure) {
      final printFunction = gen.moduleCompiler.runtime.print;
      _pushArguments(instr, target, printFunction.type);
      b.call(printFunction);
      return;
    }
    final signature = gen.moduleCompiler.functionTypeFor(target);
    _pushArguments(instr, target, signature);
    gen.moduleCompiler.callStatic(b, memberLabel(member), signature);
    _storeResult(instr, signature);
  }

  @override
  void visitInterfaceCall(InterfaceCall instr) {
    final target = instr.interfaceTarget;
    // TODO(dart2wasm): Support getters, setters, and type arguments.
    if (target is! RegularFunction || instr.hasTypeArguments) {
      throw UnimplementedError('Unsupported interfaceCall to $target');
    }
    final signature = gen.moduleCompiler.functionTypeFor(target);
    _pushArguments(instr, target, signature);
    gen.moduleCompiler.callInstance(
      b,
      gen.getLocal(instr.receiver),
      instanceMemberName(target.member),
      signature,
    );
    _storeResult(instr, signature);
  }

  @override
  void visitAllocateObject(AllocateObject instr) {
    if (instr.hasTypeArguments) {
      throw UnimplementedError('Unsupported allocation of ${instr.type}');
    }
    final cls = (instr.type.dartType as ast.InterfaceType).classNode;
    gen.moduleCompiler.allocateObject(b, cls);
    b.local_set(gen.getLocal(instr));
  }

  /// Pushes [instr]'s arguments for a call to [target] with [signature].
  ///
  /// Pushes the receiver (if any), positional arguments (in order), then named
  /// arguments (sorted). Omitted arguments push
  /// [ModuleCompiler.defaultValueSentinel].
  void _pushArguments(
    CallInstruction instr,
    CFunction target,
    w.FunctionType signature,
  ) {
    final sentinel = gen.moduleCompiler.defaultValueSentinel;
    final shape = instr.argumentsShape;
    final functionNode = target.functionNode!;
    final positionalEnd =
        (target.hasReceiverParameter ? 1 : 0) +
        functionNode.positionalParameters.length;
    final namedParameters = functionNode.namedParameters;
    assert(signature.inputs.length == positionalEnd + namedParameters.length);
    // Push the receiver (if any) and positionals.
    for (var index = 0; index < positionalEnd; index++) {
      if (index < shape.positional) {
        _pushArgument(instr, index, signature.inputs[index]);
      } else {
        b.global_get(sentinel);
      }
    }
    // Push named parameters.
    final namedIndices = {
      for (var i = 0; i < shape.named.length; i++)
        shape.named[i]: shape.positional + i,
    };
    for (var i = 0; i < namedParameters.length; i++) {
      final index = namedIndices[namedParameters[i].parameterName];
      if (index == null) {
        b.global_get(sentinel);
      } else {
        _pushArgument(instr, index, signature.inputs[positionalEnd + i]);
      }
    }
  }

  /// Pushes [instr]'s [index]th argument as [type].
  void _pushArgument(CallInstruction instr, int index, w.ValueType type) {
    final argLocal = gen.getLocal(instr.inputDefAt(index));
    b.local_get(argLocal);
    gen.convertType(argLocal.type, type);
  }

  /// Stores [instr]'s result or drops it if unused.
  void _storeResult(CallInstruction instr, w.FunctionType signature) {
    if (signature.outputs.isEmpty) return;
    if (!instr.hasUses) {
      b.drop();
      return;
    }
    final resultLocal = gen.getLocal(instr);
    gen.convertType(signature.outputs.single, resultLocal.type);
    b.local_set(resultLocal);
  }
}
