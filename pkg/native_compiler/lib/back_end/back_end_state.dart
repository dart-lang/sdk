// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/instructions.dart';
import 'package:native_compiler/back_end/code_generator.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

/// Hold back-end state shared between code generation
/// and register allocation.
class BackEndState {
  late final VMOffsets vmOffsets;

  /// Block order for the code generation.
  late final List<Block> codeGenBlockOrder;

  /// Locations of inputs/outputs/temps, result of register allocation.
  late final Map<OperandId, Location> operandLocations;

  /// Consumer of the generated [Code].
  late final CodeConsumer consumeGeneratedCode;
}
