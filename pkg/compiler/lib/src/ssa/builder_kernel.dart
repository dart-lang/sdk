// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common/codegen.dart' show CodegenWorkItem;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../kernel/kernel.dart';
import '../kernel/kernel_visitor.dart';
import '../resolution/tree_elements.dart';
import 'graph_builder.dart';
import 'locals_handler.dart';
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
      } catch (e) {
        throw "Failed to convert to Kernel IR: $e";
      }
      KernelSsaBuilder builder = new KernelSsaBuilder(function, element,
          work.resolvedAst, backend.compiler, sourceInformationFactory);
      return builder.build();
    });
  }
}

// DESIGN NOTE: I am implementing this by essentially copying the methods in
// [SsaBuilder], but trying to use Kernel IR instead of our AST nodes. In places
// where there is functionality in the [SsaBuilder] that is not yet needed in
// this builder, I am adding a comment that tells what the [SsaBuilder] does at
// that location.
class KernelSsaBuilder extends ir.Visitor with GraphBuilder {
  final IrFunction function;
  final FunctionElement functionElement;
  final ResolvedAst resolvedAst;
  final Compiler compiler;

  JavaScriptBackend get backend => compiler.backend;

  LocalsHandler localsHandler;
  SourceInformationBuilder sourceInformationBuilder;

  KernelSsaBuilder(this.function, this.functionElement, this.resolvedAst,
      this.compiler, SourceInformationStrategy sourceInformationFactory) {
    graph.element = functionElement;
    // TODO(het): Should sourceInformationBuilder be in GraphBuilder?
    this.sourceInformationBuilder =
        sourceInformationFactory.createBuilderForContext(resolvedAst);
    graph.sourceInformation =
        sourceInformationBuilder.buildVariableDeclaration();
    this.localsHandler =
        new LocalsHandler(this, functionElement, null, compiler);
  }

  HGraph build() {
    if (function.kind == ir.ProcedureKind.Method) {
      buildMethod(function, functionElement);
    } else {
      compiler.reporter.internalError(
          functionElement,
          "Unable to convert this kind of Kernel "
          "procedure to SSA: ${function.kind}");
    }
    assert(graph.isValid());
    return graph;
  }

  /// Builds a SSA graph for [method].
  void buildMethod(IrFunction method, FunctionElement functionElement) {
    // TODO(het): Determine whether or not this method is called in a loop and
    // set [graph.isCalledInLoop].
    openFunction(method, functionElement);
  }

  void openFunction(IrFunction method, FunctionElement functionElement) {
    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);
    // TODO(het): Register parameters with a locals handler
    localsHandler.startFunction(functionElement, resolvedAst.node);
    close(new HGoto()).addSuccessor(block);

    open(block);

    // TODO(het): If this is a constructor then add the type parameters of the
    // enclosing class as parameters to the method. This must be done before
    // adding normal parameters because their types may contain references to
    // the class type parameters.
  }
}
