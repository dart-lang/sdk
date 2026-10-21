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
  w.ValueType translateType(CType type) => translateCType(type);

  static w.ValueType translateCType(CType type) {
    return switch (type) {
      IntType() => w.NumType.i64,
      DoubleType() => w.NumType.f64,
      BoolType() => w.NumType.i32,
      // TODO(dart2wasm): Lower String to a Dart object (Wasm struct).
      StringType() => const w.RefType.extern(nullable: false),
      NullType() || NeverType() => const w.RefType.none(nullable: true),
      _ => throw UnimplementedError('Unsupported type: $type'),
    };
  }

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
    if (target is! RegularFunction) {
      throw UnimplementedError('Unsupported directCall target $target');
    }
    final member = target.member;
    if (member is! ast.Procedure) {
      throw UnimplementedError('Unsupported directCall target member $member');
    }
    if (member == GlobalContext.instance.coreTypes.printProcedure) {
      final printFunction = gen.moduleCompiler.runtime.print;
      final argLocal = gen.getLocal(instr.inputDefAt(0));
      b.local_get(argLocal);
      gen.convertType(argLocal.type, printFunction.type.inputs.single);
      b.call(printFunction);
      return;
    }

    final signature = gen.moduleCompiler.functionTypeFor(target);
    for (int i = 0; i < instr.inputCount; ++i) {
      final argLocal = gen.getLocal(instr.inputDefAt(i));
      b.local_get(argLocal);
      gen.convertType(argLocal.type, signature.inputs[i]);
    }
    gen.moduleCompiler.callStatic(b, staticLabel(member), signature);
    if (signature.outputs.isNotEmpty) {
      if (!instr.hasUses) {
        b.drop();
        return;
      }
      final resultLocal = gen.getLocal(instr);
      gen.convertType(signature.outputs.single, resultLocal.type);
      b.local_set(resultLocal);
    }
  }
}
