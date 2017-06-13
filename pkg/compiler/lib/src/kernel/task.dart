// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/names.dart';
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart';
import '../elements/elements.dart';
import 'kernel.dart';
import 'package:kernel/ast.dart' as ir;

/// Visits the compiler main function and builds the kernel representation.
///
/// This creates a mapping from kernel nodes to AST nodes to be used later.
class KernelTask extends CompilerTask {
  get name => "kernel";

  final Compiler _compiler;
  final Kernel kernel;

  KernelTask(Compiler compiler)
      : this._compiler = compiler,
        this.kernel = new Kernel(compiler),
        super(compiler.measurer);

  ir.Program program;

  /// Builds the kernel IR for the main function.
  ///
  /// May enqueue more elements to the resolution queue.
  void buildKernelIr() => measure(() {
        program = buildProgram(_compiler.mainApp);
      });

  /// Builds the kernel IR program for the main function exported from
  /// [library].
  ///
  /// May enqueue more elements to the resolution queue.
  ir.Program buildProgram(LibraryElement library) {
    MethodElement main = library.findExported(Identifiers.main);
    if (main == null) {
      main = _compiler.frontendStrategy.commonElements.missingMain;
    }
    return new ir.Program(
        libraries: kernel.libraryDependencies(library.canonicalUri))
      ..mainMethod = kernel.functionToIr(main);
  }
}
