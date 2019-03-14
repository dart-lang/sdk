// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa;

import '../common/codegen.dart' show CodegenWorkItem, CodegenRegistry;
import '../common/tasks.dart' show CompilerTask, Measurer;
import '../elements/entities.dart' show MemberEntity;
import '../inferrer/types.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/field_analysis.dart';
import '../js_backend/backend.dart' show JavaScriptBackend, FunctionCompiler;
import '../universe/call_structure.dart';
import '../universe/use.dart';
import '../world.dart' show JClosedWorld;

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
        _builder = new SsaBuilderTask(backend, sourceInformationFactory),
        optimizer = new SsaOptimizerTask(backend),
        backend = backend;

  @override
  void onCodegenStart() {
    _builder.onCodegenStart();
  }

  /// Generates JavaScript code for `work.element`.
  /// Using the ssa builder, optimizer and code generator.
  @override
  js.Fun compile(CodegenWorkItem work, JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults) {
    HGraph graph = _builder.build(work, closedWorld, globalInferenceResults);
    if (graph == null) return null;
    optimizer.optimize(work, graph, closedWorld, globalInferenceResults);
    MemberEntity element = work.element;
    js.Expression result = generator.generateCode(work, graph, closedWorld);
    if (graph.needsAsyncRewrite) {
      SourceInformationBuilder sourceInformationBuilder =
          backend.sourceInformationStrategy.createBuilderForContext(element);
      result = backend.rewriteAsync(
          closedWorld.commonElements,
          closedWorld.elementEnvironment,
          work.registry,
          element,
          result,
          graph.asyncElementType,
          sourceInformationBuilder.buildAsyncBody(),
          sourceInformationBuilder.buildAsyncExit());
    }
    return result;
  }

  @override
  Iterable<CompilerTask> get tasks {
    return <CompilerTask>[_builder, optimizer, generator];
  }
}

abstract class SsaBuilder {
  /// Creates the [HGraph] for [work] or returns `null` if no code is needed
  /// for [work].
  HGraph build(CodegenWorkItem work, JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults);
}

class SsaBuilderTask extends CompilerTask {
  final JavaScriptBackend _backend;
  final SourceInformationStrategy _sourceInformationFactory;
  SsaBuilder _builder;

  SsaBuilderTask(this._backend, this._sourceInformationFactory)
      : super(_backend.compiler.measurer);

  @override
  String get name => 'SSA builder';

  void onCodegenStart() {
    _builder = _backend.compiler.backendStrategy
        .createSsaBuilder(this, _backend, _sourceInformationFactory);
  }

  /// Creates the [HGraph] for [work] or returns `null` if no code is needed
  /// for [work].
  HGraph build(CodegenWorkItem work, JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults) {
    return _builder.build(work, closedWorld, globalInferenceResults);
  }
}

abstract class SsaBuilderFieldMixin {
  /// Handle field initializer of [element]. Returns `true` if no code
  /// is needed for the field.
  ///
  /// If [element] is a field with a constant initializer, the value is
  /// registered with the world impact. Otherwise the cyclic-throw helper is
  /// registered for the lazy value computation.
  ///
  /// If the field is constant, no code is needed for the field and the method
  /// returns `true`.
  bool handleConstantField(MemberEntity element, CodegenRegistry registry,
      JClosedWorld closedWorld) {
    if (element.isField) {
      FieldAnalysisData fieldData =
          closedWorld.fieldAnalysis.getFieldData(element);
      if (fieldData.initialValue != null) {
        registry.worldImpact
            .registerConstantUse(new ConstantUse.init(fieldData.initialValue));
        // We don't need to generate code for static or top-level
        // variables. For instance variables, we may need to generate
        // the checked setter.
        if (element.isStatic || element.isTopLevel) {
          /// No code is created for this field: All references inline the
          /// constant value.
          return true;
        }
      } else if (fieldData.isLazy) {
        // The generated initializer needs be wrapped in the cyclic-error
        // helper.
        registry.worldImpact.registerStaticUse(new StaticUse.staticInvoke(
            closedWorld.commonElements.cyclicThrowHelper,
            CallStructure.ONE_ARG));
      }
    }
    return false;
  }
}
