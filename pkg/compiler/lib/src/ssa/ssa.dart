// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa;

import '../common/codegen.dart' show CodegenWorkItem;
import '../common/tasks.dart' show CompilerTask, Measurer;
import '../elements/elements.dart' show MethodElement;
import '../elements/entities.dart' show MemberEntity;
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart' show JavaScriptBackend, FunctionCompiler;
import '../world.dart' show ClosedWorld;

import 'codegen.dart';
import 'nodes.dart';
import 'optimize.dart';

class SsaFunctionCompiler implements FunctionCompiler {
  final SsaCodeGeneratorTask generator;
  final SsaBuilderTask _builder;
  final SsaOptimizerTask optimizer;
  final JavaScriptBackend backend;

  SsaFunctionCompiler(JavaScriptBackend backend, Measurer measurer,
      SourceInformationStrategy sourceInformationFactory)
      : generator = new SsaCodeGeneratorTask(backend, sourceInformationFactory),
        _builder = backend.compiler.backendStrategy
            .createSsaBuilderTask(backend, sourceInformationFactory),
        optimizer = new SsaOptimizerTask(backend),
        backend = backend;

  /// Generates JavaScript code for `work.element`.
  /// Using the ssa builder, optimizer and codegenerator.
  js.Fun compile(CodegenWorkItem work, ClosedWorld closedWorld) {
    HGraph graph = _builder.build(work, closedWorld);
    if (graph == null) return null;
    optimizer.optimize(work, graph, closedWorld);
    MemberEntity element = work.element;
    js.Expression result = generator.generateCode(work, graph, closedWorld);
    if (element is MethodElement) {
      // TODO(sigmund): replace by kernel transformer when `useKernel` is true.
      result =
          backend.rewriteAsync(closedWorld.commonElements, element, result);
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
