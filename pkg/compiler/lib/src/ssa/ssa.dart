// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa;

import '../common/codegen.dart' show CodegenWorkItem;
import '../common/tasks.dart' show CompilerTask;
import '../elements/elements.dart' show Element, FunctionElement;
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart' show JavaScriptBackend, FunctionCompiler;
import '../js_backend/element_strategy.dart' show ElementCodegenWorkItem;
import '../world.dart' show ClosedWorld;

import 'builder.dart';
import 'builder_kernel.dart';
import 'codegen.dart';
import 'nodes.dart';
import 'optimize.dart';

class SsaFunctionCompiler implements FunctionCompiler {
  final SsaCodeGeneratorTask generator;
  final SsaBuilderTask _builder;
  final SsaOptimizerTask optimizer;
  final JavaScriptBackend backend;

  SsaFunctionCompiler(JavaScriptBackend backend,
      SourceInformationStrategy sourceInformationFactory, bool useKernel)
      : generator = new SsaCodeGeneratorTask(backend, sourceInformationFactory),
        _builder = useKernel
            ? new SsaKernelBuilderTask(backend, sourceInformationFactory)
            : new SsaAstBuilderTask(backend, sourceInformationFactory),
        optimizer = new SsaOptimizerTask(backend),
        backend = backend;

  /// Generates JavaScript code for `work.element`.
  /// Using the ssa builder, optimizer and codegenerator.
  js.Fun compile(ElementCodegenWorkItem work, ClosedWorld closedWorld) {
    HGraph graph = _builder.build(work, closedWorld);
    if (graph == null) return null;
    optimizer.optimize(work, graph, closedWorld);
    Element element = work.element;
    js.Expression result = generator.generateCode(work, graph, closedWorld);
    if (element is FunctionElement) {
      // TODO(sigmund): replace by kernel transformer when `useKernel` is true.
      result = backend.rewriteAsync(element, result);
    }
    return result;
  }

  Iterable<CompilerTask> get tasks {
    return <CompilerTask>[_builder, optimizer, generator];
  }
}

abstract class SsaBuilderTask implements CompilerTask {
  /// Creates the [HGraph] for [work] or returns `null` if no code is needed
  /// for [work].
  HGraph build(CodegenWorkItem work, ClosedWorld closedWorld);
}
