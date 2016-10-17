// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compiler.dart';
import '../common/names.dart';
import '../elements/elements.dart';
import '../kernel/kernel.dart';
import 'package:kernel/ast.dart' as ir;

import 'backend.dart';

/// Visits the compiler main function and builds the kernel representation.
///
/// This creates a mapping from kernel nodes to AST nodes to be used later.
class KernelTask {
  final Compiler _compiler;
  final Kernel kernel;

  KernelTask(JavaScriptBackend backend)
      : this._compiler = backend.compiler,
        this.kernel = new Kernel(backend.compiler);

  ir.Program program;

  /// Builds the kernel IR for the main function.
  ///
  /// May enqueue more elements to the resolution queue.
  void buildKernelIr() {
    program = buildProgram(_compiler.mainApp);
  }

  /// Builds the kernel IR program for the main function exported from
  /// [library].
  ///
  /// May enqueue more elements to the resolution queue.
  ir.Program buildProgram(LibraryElement library) {
    return new ir.Program(kernel.libraryDependencies(library.canonicalUri))
      ..mainMethod =
          kernel.functionToIr(library.findExported(Identifiers.main));
  }
}
