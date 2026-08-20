// Copyright (c) 2026 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/functions.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/runtime/object_layout.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

/// Base class for registry of functions implemented in assembly language.
abstract base class AsmIntrinsics(
  final FunctionRegistry functionRegistry,
  final VMOffsets vmOffsets,
  final ObjectLayout objectLayout,
) {
  /// Use [asm] for code generation.
  void setAssembler(Assembler? asm);

  /// Generate code for _SuspendState._resume.
  bool generateSuspendStateResume();

  /// Generate code for _SuspendState._clone.
  bool generateSuspendStateClone();

  /// Generate code for dart:core::_getHash (Object.hashCode / identityHashCode).
  bool generateObjectHashCode();

  /// Generate code for [function] using [asm].
  /// Return true on success, or false if [function] is not implemented in assembly.
  bool generate(CFunction function, Assembler asm) {
    final f = _intrinsicFunctions[function];
    if (f != null) {
      setAssembler(asm);
      try {
        return f();
      } finally {
        setAssembler(null);
      }
    }
    return false;
  }

  late final Map<CFunction, bool Function()> _intrinsicFunctions = {
    // dart:core
    functionRegistry.getFunction(
      GlobalContext.instance.coreLibraries.getTopLevelProcedure(
        'dart:core',
        '_getHash',
      ),
    ): generateObjectHashCode,

    // dart:async
    functionRegistry.getFunction(
      GlobalContext.instance.coreLibraries.getProcedure(
        'dart:async',
        '_SuspendState',
        '_resume',
      ),
    ): generateSuspendStateResume,
    functionRegistry.getFunction(
      GlobalContext.instance.coreLibraries.getProcedure(
        'dart:async',
        '_SuspendState',
        '_clone',
      ),
    ): generateSuspendStateClone,
  };
}
