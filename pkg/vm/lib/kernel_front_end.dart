// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the VM-specific translation of Dart source code to kernel binaries.
library vm.kernel_front_end;

import 'dart:async';

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/kernel_generator.dart'
    show kernelForProgram;
import 'package:kernel/ast.dart' show Program;
import 'package:kernel/core_types.dart' show CoreTypes;

// TODO(alexmarkov): Move this transformation to pkg/vm.
import 'package:kernel/transformations/precompiler.dart' as transformPrecompiler
    show transformProgram;

/// Generates a kernel representation of the program whose main library is in
/// the given [source]. Intended for whole program (non-modular) compilation.
///
/// VM-specific replacement of [kernelForProgram].
///
Future<Program> compileToKernel(Uri source, CompilerOptions options,
    {bool aot: false}) async {
  final program = await kernelForProgram(source, options);

  if (aot) {
    _runGlobalTransformations(program, options.strongMode);
  }

  return program;
}

_runGlobalTransformations(Program program, bool strongMode) {
  final coreTypes = new CoreTypes(program);

  // TODO(alexmarkov): AOT-specific whole-program transformations.

  if (strongMode) {
    transformPrecompiler.transformProgram(coreTypes, program);
  }
}
