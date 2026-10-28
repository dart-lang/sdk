// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  void convertType(w.ValueType from, w.ValueType to) {
    if (from.isSubtypeOf(to)) return;
    if (!to.nullable && from.withNullability(false).isSubtypeOf(to)) {
      b.ref_as_non_null();
      return;
    }
    throw UnimplementedError('Unsupported type conversion from $from to $to');
  }
}

final class DevWasmInstructionLowerer
    extends WasmInstructionLowerer<DevCfgToWasm> {
  DevWasmInstructionLowerer(super.gen);

  @override
  void visitParameter(Parameter instr) {
    assert(instr.isFunctionParameter);
    gen.locals[instr] = b.locals[instr.variable.index];
  }

  @override
  void instantiateConstant(Constant instr, w.ValueType expectedType) {
    final value = instr.value;
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
      _pushArguments(instr, printFunction.type);
      b.call(printFunction);
      return;
    }
    final signature = gen.moduleCompiler.functionTypeFor(target);
    _pushArguments(instr, signature);
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
    _pushArguments(instr, signature);
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

  /// Pushes [instr]'s arguments for a call to [signature].
  void _pushArguments(CallInstruction instr, w.FunctionType signature) {
    assert(instr.inputCount == signature.inputs.length);
    for (int i = 0; i < instr.inputCount; ++i) {
      final argLocal = gen.getLocal(instr.inputDefAt(i));
      b.local_get(argLocal);
      gen.convertType(argLocal.type, signature.inputs[i]);
    }
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
