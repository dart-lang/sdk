// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'kernel_nodes.dart';
import 'util.dart' as util;

enum ExternType { memory }

final class MemoryLimits {
  final int minSize;
  final int? maxSize;

  MemoryLimits({required this.minSize, this.maxSize});

  /// Read the `MemoryType` annotation on a member.
  static MemoryLimits? readAnnotation(KernelNodes nodes, Member member) {
    final memoryType = util.getPragma<InstanceConstant>(
        nodes.coreTypes, member, 'wasm:memory-type');
    if (memoryType == null ||
        memoryType.classNode != nodes.wasmMemoryTypeClass) {
      return null;
    }

    final (minSize, maxSize) = _readMemoryType(nodes, memoryType);

    return MemoryLimits(
      minSize: minSize,
      maxSize: maxSize,
    );
  }

  static (int, int?) _readMemoryType(
      KernelNodes nodes, InstanceConstant constant) {
    final limits = constant.fieldValues.values.single;
    return _readLimits(nodes, limits as InstanceConstant);
  }

  static (int, int?) _readLimits(KernelNodes nodes, InstanceConstant constant) {
    final minimum = (constant
            .fieldValues[nodes.wasmLimitsMinimum.fieldReference] as IntConstant)
        .value;
    final maximumConstant =
        constant.fieldValues[nodes.wasmLimitsMaximum.fieldReference];
    final maximum = switch (maximumConstant) {
      IntConstant(:final value) => value,
      _ => null,
    };

    return (minimum, maximum);
  }
}
