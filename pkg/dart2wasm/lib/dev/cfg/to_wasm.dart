// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import '../../cfg/to_wasm.dart';

/// Translates a [FlowGraph] (CFG IR) to WebAssembly bytecode for the dev
/// compiler.
final class DevCfgToWasm extends CfgToWasm {
  @override
  late final DevWasmInstructionLowerer lowerer = DevWasmInstructionLowerer(
    this,
  );

  DevCfgToWasm(super.graph, super.b, {super.cfgLog});

  @override
  w.ValueType translateType(CType type) {
    return switch (type) {
      IntType() => w.NumType.i64,
      DoubleType() => w.NumType.f64,
      BoolType() => w.NumType.i32,
      NullType() || NeverType() => const w.RefType.none(nullable: true),
      _ => throw UnimplementedError('Unsupported type: $type'),
    };
  }

  @override
  void convertType(w.ValueType from, w.ValueType to) {
    if (from.isSubtypeOf(to)) return;
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
    } else if (value.isNull && expectedType is w.RefType) {
      b.ref_null(w.HeapType.none);
    } else {
      throw UnimplementedError('Unsupported constant: ${value.constant}');
    }
  }
}
