// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_backend.element_strategy;

import '../backend_strategy.dart';
import '../common.dart';
import '../common/codegen.dart';
import '../common/work.dart';
import '../compiler.dart';
import '../elements/elements.dart';
import '../enqueue.dart';
import '../io/source_information.dart';
import '../js_backend/backend.dart';
import '../js_backend/native_data.dart';
import '../js_emitter/sorter.dart';
import '../ssa/builder.dart';
import '../ssa/rasta_ssa_builder_task.dart';
import '../ssa/ssa.dart';
import '../options.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import '../world.dart';

/// Strategy for using the [Element] model from the resolver as the backend
/// model.
class ElementBackendStrategy implements BackendStrategy {
  final Compiler _compiler;

  ElementBackendStrategy(this._compiler);

  ClosedWorldRefiner createClosedWorldRefiner(ClosedWorldImpl closedWorld) =>
      closedWorld;

  Sorter get sorter => const ElementSorter();

  void convertClosures(ClosedWorldRefiner closedWorldRefiner) {
    _compiler.closureToClassMapper.createClosureClasses(closedWorldRefiner);
  }

  @override
  CodegenWorldBuilder createCodegenWorldBuilder(
      NativeBasicData nativeBasicData,
      ClosedWorld closedWorld,
      SelectorConstraintsStrategy selectorConstraintsStrategy) {
    return new ElementCodegenWorldBuilderImpl(
        _compiler.elementEnvironment,
        nativeBasicData,
        closedWorld,
        _compiler.backend.constants,
        selectorConstraintsStrategy);
  }

  @override
  WorkItemBuilder createCodegenWorkItemBuilder(ClosedWorld closedWorld) {
    return new ElementCodegenWorkItemBuilder(
        _compiler.backend, closedWorld, _compiler.options);
  }

  @override
  SsaBuilderTask createSsaBuilderTask(JavaScriptBackend backend,
      SourceInformationStrategy sourceInformationStrategy) {
    return _compiler.options.useKernel
        ? new RastaSsaBuilderTask(backend, sourceInformationStrategy)
        : new SsaAstBuilderTask(backend, sourceInformationStrategy);
  }
}

/// Builder that creates the work item necessary for the code generation of a
/// [MemberElement].
class ElementCodegenWorkItemBuilder extends WorkItemBuilder {
  final JavaScriptBackend _backend;
  final ClosedWorld _closedWorld;
  final CompilerOptions _options;

  ElementCodegenWorkItemBuilder(
      this._backend, this._closedWorld, this._options);

  @override
  WorkItem createWorkItem(MemberElement element) {
    assert(invariant(element, element.isDeclaration));
    // Don't generate code for foreign elements.
    if (_backend.isForeign(element)) return null;
    if (element.isAbstract) return null;

    // Codegen inlines field initializers. It only needs to generate
    // code for checked setters.
    if (element.isField && element.isInstanceMember) {
      if (!_options.enableTypeAssertions ||
          element.enclosingElement.isClosure) {
        return null;
      }
    }
    return new ElementCodegenWorkItem(_backend, _closedWorld, element);
  }
}

class ElementCodegenWorkItem extends CodegenWorkItem {
  CodegenRegistry registry;
  final ResolvedAst resolvedAst;
  final JavaScriptBackend _backend;
  final ClosedWorld _closedWorld;

  factory ElementCodegenWorkItem(JavaScriptBackend backend,
      ClosedWorld closedWorld, MemberElement element) {
    // If this assertion fails, the resolution callbacks of the backend may be
    // missing call of form registry.registerXXX. Alternatively, the code
    // generation could spuriously be adding dependencies on things we know we
    // don't need.
    assert(invariant(element, element.hasResolvedAst,
        message: "$element has no resolved ast."));
    ResolvedAst resolvedAst = element.resolvedAst;
    return new ElementCodegenWorkItem.internal(
        resolvedAst, backend, closedWorld);
  }

  ElementCodegenWorkItem.internal(
      this.resolvedAst, this._backend, this._closedWorld);

  MemberElement get element => resolvedAst.element;

  WorldImpact run() {
    registry = new CodegenRegistry(element);
    return _backend.codegen(this, _closedWorld);
  }

  String toString() => 'CodegenWorkItem(${resolvedAst.element})';
}
