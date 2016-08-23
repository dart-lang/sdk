// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/codegen.dart' show CodegenWorkItem;
import '../common/tasks.dart' show CompilerTask;
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js_backend/backend.dart' show JavaScriptBackend, FunctionCompiler;
import '../kernel/kernel.dart';
import '../kernel/kernel_visitor.dart';
import '../resolution/tree_elements.dart';

import 'nodes.dart';

class SsaKernelBuilderTask extends CompilerTask {
  final JavaScriptBackend backend;
  final SourceInformationStrategy sourceInformationFactory;

  String get name => 'SSA kernel builder';

  SsaKernelBuilderTask(JavaScriptBackend backend, this.sourceInformationFactory)
      : backend = backend,
        super(backend.compiler.measurer);

  HGraph build(CodegenWorkItem work) {
    return measure(() {
      AstElement element = work.element.implementation;
      TreeElements treeElements = work.resolvedAst.elements;
      Kernel kernel = new Kernel(backend.compiler);
      KernelVisitor visitor = new KernelVisitor(element, treeElements, kernel);
      IrFunction function;
      try {
        function = visitor.buildFunction();
      } catch(e) {
        throw "Failed to convert to Kernel IR: $e";
      }
      throw "Successfully converted to Kernel IR: $function";
    });
  }
}
