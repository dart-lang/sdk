// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/tasks.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../js_backend/element_strategy.dart' show ElementCodegenWorkItem;
import '../kernel/kernel.dart';
import '../world.dart';
import 'builder.dart';
import 'kernel_ast_adapter.dart';
import 'nodes.dart';
import 'builder_kernel.dart';

/// Task for building SSA kernel IR generated from rasta.
class RastaSsaBuilder extends SsaAstBuilderBase {
  final SourceInformationStrategy sourceInformationFactory;

  String get name => 'SSA kernel builder';

  RastaSsaBuilder(CompilerTask task, JavaScriptBackend backend,
      this.sourceInformationFactory)
      : super(task, backend);

  HGraph build(covariant ElementCodegenWorkItem work, ClosedWorld closedWorld) {
    return task.measure(() {
      if (handleConstantField(work.element, work.registry, closedWorld)) {
        // No code is generated for `work.element`.
        return null;
      }
      MemberElement element = work.element.implementation;
      ResolvedAst resolvedAst = work.resolvedAst;
      Kernel kernel = backend.kernelTask.kernel;
      KernelAstAdapter astAdapter = new KernelAstAdapter(kernel, backend,
          work.resolvedAst, kernel.nodeToAst, kernel.nodeToElement);
      KernelAstTypeInferenceMap typeInferenceMap =
          new KernelAstTypeInferenceMap(astAdapter);
      KernelSsaGraphBuilder builder = new KernelSsaGraphBuilder(
          element,
          element.contextClass?.thisType,
          backend.compiler,
          astAdapter,
          typeInferenceMap,
          astAdapter,
          closedWorld,
          backend.compiler.codegenWorldBuilder,
          work.registry,
          backend.compiler.backendStrategy.closureDataLookup,
          backend.emitter.nativeEmitter,
          sourceInformationFactory.createBuilderForContext(work.element),
          resolvedAst.kind == ResolvedAstKind.PARSED ? resolvedAst.node : null);
      HGraph graph = builder.build();

      if (backend.tracer.isEnabled) {
        String name;
        if (element.isClassMember) {
          String className = element.enclosingClass.name;
          String memberName = element.name;
          name = "$className.$memberName";
          if (element.isGenerativeConstructorBody) {
            name = "$name (body)";
          }
        } else {
          name = "${element.name}";
        }
        backend.tracer.traceCompilation(name);
        backend.tracer.traceGraph('builder', graph);
      }

      return graph;
    });
  }
}
