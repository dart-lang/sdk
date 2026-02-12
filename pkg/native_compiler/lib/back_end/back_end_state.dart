// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/instructions.dart';
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/stack_frame.dart';
import 'package:native_compiler/back_end/stub_code_generator.dart';
import 'package:native_compiler/runtime/object_layout.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

/// Hold back-end state shared between code generation
/// and register allocation.
class BackEndState {
  /// Runtime offsets and constants.
  late final VMOffsets vmOffsets;

  /// Layout of Dart objects.
  late final ObjectLayout objectLayout;

  /// Reusable stubs.
  late final StubFactory stubFactory;

  /// Block order for the code generation.
  late final List<Block> codeGenBlockOrder;

  /// Layout of the stack frame.
  late final StackFrame stackFrame;

  /// Locations of inputs/outputs/temps, result of register allocation.
  late final Map<OperandId, Location> operandLocations;

  /// Consumer of the generated [Code].
  late final CodeConsumer consumeGeneratedCode;
}
