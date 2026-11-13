// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'kernel_nodes.dart';
import 'util.dart' as util;

enum ExternType {
  memory,
  table,
  global;

  /// Checks whether [member] defines an external WebAssembly member that can
  /// only be used through intrinsics, returning its [ExternType] if so.
  static ExternType? of(KernelNodes nodes, Member member) {
    if (member
        case Procedure(
          kind: ProcedureKind.Getter,
          isStatic: true,
          isExternal: true,
          function: FunctionNode(returnType: final InterfaceType type),
        )
        when !type.isPotentiallyNullable) {
      if (type.classNode == nodes.wasmMemoryClass) {
        return ExternType.memory;
      }
      if (type.classNode == nodes.wasmTableClass) {
        return ExternType.table;
      }
      if (type.classNode == nodes.wasmGlobalClass ||
          type.classNode == nodes.wasmMutableGlobalClass) {
        return ExternType.global;
      }
    }

    return null;
  }
}

final class WasmMemoryType({
  required final bool shared,
  required final int minSize,
  final int? maxSize,
}) {
  /// Read the `MemoryType` annotation on a member.
  static WasmMemoryType? readAnnotation(KernelNodes nodes, Member member) {
    final memoryType = util.getPragma<Constant>(
      nodes.coreTypes,
      member,
      'wasm:memory-type',
    );
    if (memoryType is! InstanceConstant ||
        memoryType.classNode != nodes.wasmMemoryTypeClass) {
      return null;
    }

    final limits =
        memoryType.fieldValues[nodes.wasmMemoryTypeLimits.fieldReference]
            as InstanceConstant;
    final shared =
        memoryType.fieldValues[nodes.wasmMemoryTypeShared.fieldReference]
            as BoolConstant;
    final (minSize, maxSize) = _readLimits(nodes, limits);
    return WasmMemoryType(
      shared: shared.value,
      minSize: minSize,
      maxSize: maxSize,
    );
  }
}

final class WasmTableType({required final int minSize, final int? maxSize}) {
  /// Read the `TableType` annotation on a member.
  static WasmTableType? readAnnotation(KernelNodes nodes, Member member) {
    final tableType = util.getPragma<Constant>(
      nodes.coreTypes,
      member,
      'wasm:table-type',
    );
    if (tableType is! InstanceConstant ||
        tableType.classNode != nodes.wasmTableTypeClass) {
      return null;
    }

    final limits =
        tableType.fieldValues[nodes.wasmTableTypeLimits.fieldReference]
            as InstanceConstant;
    final (minSize, maxSize) = _readLimits(nodes, limits);
    return WasmTableType(minSize: minSize, maxSize: maxSize);
  }
}

(int, int?) _readLimits(KernelNodes nodes, InstanceConstant constant) {
  final minimum =
      (constant.fieldValues[nodes.wasmLimitsMinimum.fieldReference]
              as IntConstant)
          .value;
  final maximumConstant =
      constant.fieldValues[nodes.wasmLimitsMaximum.fieldReference];
  final maximum = switch (maximumConstant) {
    IntConstant(:final value) => value,
    _ => null,
  };

  return (minimum, maximum);
}
