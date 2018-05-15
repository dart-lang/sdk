// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_backend.element_strategy;

import '../common.dart';
import '../common/codegen.dart';
import '../common/work.dart';
import '../elements/elements.dart';
import '../enqueue.dart';
import '../js_backend/backend.dart';
import '../options.dart';
import '../universe/world_impact.dart';
import '../world.dart';

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
    assert(element.isDeclaration, failedAt(element));
    // Don't generate code for foreign elements.
    if (_backend.isForeign(_closedWorld.commonElements, element)) return null;
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
    assert(element.hasResolvedAst,
        failedAt(element, "$element has no resolved ast."));
    ResolvedAst resolvedAst = element.resolvedAst;
    return new ElementCodegenWorkItem.internal(
        resolvedAst, backend, closedWorld);
  }

  ElementCodegenWorkItem.internal(
      this.resolvedAst, this._backend, this._closedWorld);

  MemberElement get element => resolvedAst.element;

  WorldImpact run() {
    registry = new CodegenRegistry(_closedWorld.elementEnvironment, element);
    return _backend.codegen(this, _closedWorld);
  }

  String toString() => 'CodegenWorkItem(${resolvedAst.element})';
}
