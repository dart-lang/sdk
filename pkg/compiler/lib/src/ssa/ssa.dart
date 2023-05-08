// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa;

import 'package:compiler/src/ssa/metrics.dart';

import '../common.dart';
import '../common/codegen.dart' show CodegenResult, CodegenRegistry;
import '../common/elements.dart' show CommonElements, JElementEnvironment;
import '../common/metrics.dart';
import '../common/tasks.dart' show CompilerTask, Measurer;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../inferrer/types.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js/rewrite_async.dart';
import '../js_backend/backend.dart' show FunctionCompiler;
import '../js_backend/codegen_inputs.dart' show CodegenInputs;
import '../js_backend/namer.dart' show ModularNamer;
import '../js_backend/namer.dart' show ModularNamerImpl;
import '../js_backend/type_reference.dart' show TypeReference;
import '../js_emitter/code_emitter_task.dart' show ModularEmitter;
import '../js_emitter/startup_emitter/emitter.dart' show ModularEmitterImpl;
import '../js_model/elements.dart';
import '../js_model/type_recipe.dart' show TypeExpressionRecipe;
import '../js_model/js_strategy.dart';
import '../js_model/js_world.dart' show JClosedWorld;
import '../options.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse;

import 'codegen.dart';
import 'nodes.dart';
import 'optimize.dart';

class SsaFunctionCompiler implements FunctionCompiler {
  final CompilerOptions _options;
  final DiagnosticReporter _reporter;
  final SsaMetrics _metrics;
  final SsaCodeGeneratorTask generator;
  final SsaBuilderTask _builder;
  final SsaOptimizerTask optimizer;
  final SourceInformationStrategy sourceInformationStrategy;
  late final GlobalTypeInferenceResults _globalInferenceResults;
  late final CodegenInputs _codegen;

  SsaFunctionCompiler(
      this._options,
      this._reporter,
      this._metrics,
      JsBackendStrategy backendStrategy,
      Measurer measurer,
      this.sourceInformationStrategy)
      : generator =
            SsaCodeGeneratorTask(measurer, _options, sourceInformationStrategy),
        _builder = SsaBuilderTask(
            measurer, backendStrategy, sourceInformationStrategy, _metrics),
        optimizer = SsaOptimizerTask(measurer, _options);

  @override
  void initialize(GlobalTypeInferenceResults globalInferenceResults,
      CodegenInputs codegen) {
    _globalInferenceResults = globalInferenceResults;
    _codegen = codegen;
    _builder.onCodegenStart();
  }

  /// Generates JavaScript code for [member].
  /// Using the ssa builder, optimizer and code generator.
  @override
  CodegenResult compile(MemberEntity member) {
    JClosedWorld closedWorld = _globalInferenceResults.closedWorld;
    CodegenRegistry registry =
        CodegenRegistry(closedWorld.elementEnvironment, member);
    ModularNamer namer = ModularNamerImpl(
        registry, closedWorld.commonElements, _codegen.fixedNames);
    ModularEmitter emitter = ModularEmitterImpl(namer, registry, _options);
    if (member is ConstructorEntity &&
        member.enclosingClass == closedWorld.commonElements.jsNullClass) {
      // Work around a problem compiling JSNull's constructor.
      return registry.close(null);
    }

    final graph = _builder.build(member, closedWorld, _globalInferenceResults,
        _codegen, registry, namer, emitter);
    if (graph == null) {
      return registry.close(null);
    }

    optimizer.optimize(member, graph, _codegen, closedWorld,
        _globalInferenceResults, registry, _metrics);
    js.Expression result = generator.generateCode(
        member, graph, _codegen, closedWorld, registry, namer, emitter);
    if (graph.needsAsyncRewrite) {
      SourceInformationBuilder sourceInformationBuilder =
          sourceInformationStrategy.createBuilderForContext(member);
      result = _rewriteAsync(
          _codegen,
          closedWorld.commonElements,
          closedWorld.elementEnvironment,
          registry,
          namer,
          emitter,
          member as FunctionEntity,
          result,
          graph.asyncElementType,
          sourceInformationBuilder.buildAsyncBody(),
          sourceInformationBuilder.buildAsyncExit());
      _codegen.tracer
          .traceJavaScriptText('JavaScript.rewrite', result.debugPrint);
    }
    if (result.sourceInformation == null) {
      result = result.withSourceInformation(
          sourceInformationStrategy.buildSourceMappedMarker());
    }

    return registry.close(result as js.Fun);
  }

  js.Expression _rewriteAsync(
      CodegenInputs codegen,
      CommonElements commonElements,
      JElementEnvironment elementEnvironment,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter,
      FunctionEntity element,
      js.Expression code,
      DartType? asyncTypeParameter,
      SourceInformation? bodySourceInformation,
      SourceInformation? exitSourceInformation) {
    if (element.asyncMarker == AsyncMarker.SYNC) return code;

    late final AsyncRewriterBase rewriter;
    js.Name name = namer.methodPropertyName(
        element is JGeneratorBody ? element.function : element);

    switch (element.asyncMarker) {
      case AsyncMarker.ASYNC:
        rewriter = _makeAsyncRewriter(
            codegen,
            commonElements,
            elementEnvironment,
            registry,
            namer,
            emitter,
            element,
            code,
            asyncTypeParameter,
            name);
        break;
      case AsyncMarker.SYNC_STAR:
        rewriter = _makeSyncStarRewriter(
            codegen,
            commonElements,
            elementEnvironment,
            registry,
            namer,
            emitter,
            element,
            code,
            asyncTypeParameter,
            name);
        break;
      case AsyncMarker.ASYNC_STAR:
        rewriter = _makeAsyncStarRewriter(
            codegen,
            commonElements,
            elementEnvironment,
            registry,
            namer,
            emitter,
            element,
            code,
            asyncTypeParameter,
            name);
        break;
    }
    return rewriter.rewrite(
        code as js.Fun, bodySourceInformation, exitSourceInformation);
  }

  /// Returns an optional expression that evaluates [type].  Returns `null` if
  /// the type expression is determined by the outside context and should be
  /// added as a function parameter to the rewritten code.
  // TODO(sra): We could also return an empty list if the generator takes no
  // type (e.g. due to rtiNeed optimization).
  List<js.Expression>? _fetchItemTypeNewRti(
      CommonElements commonElements, CodegenRegistry registry, DartType? type) {
    if (type == null) return null;
    registry.registerStaticUse(
        StaticUse.staticInvoke(commonElements.findType, CallStructure.ONE_ARG));
    return [TypeReference(TypeExpressionRecipe(type))];
  }

  AsyncRewriter _makeAsyncRewriter(
      CodegenInputs codegen,
      CommonElements commonElements,
      JElementEnvironment elementEnvironment,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter,
      FunctionEntity element,
      js.Expression code,
      DartType? elementType,
      js.Name name) {
    FunctionEntity startFunction = commonElements.asyncHelperStartSync;
    FunctionEntity completerFactory = commonElements.asyncAwaitCompleterFactory;

    final itemTypeExpression =
        _fetchItemTypeNewRti(commonElements, registry, elementType);

    AsyncRewriter rewriter = AsyncRewriter(_reporter, element,
        asyncStart: emitter.staticFunctionAccess(startFunction),
        asyncAwait:
            emitter.staticFunctionAccess(commonElements.asyncHelperAwait),
        asyncReturn:
            emitter.staticFunctionAccess(commonElements.asyncHelperReturn),
        asyncRethrow:
            emitter.staticFunctionAccess(commonElements.asyncHelperRethrow),
        wrapBody: emitter.staticFunctionAccess(commonElements.wrapBody),
        completerFactory: emitter.staticFunctionAccess(completerFactory),
        completerFactoryTypeArguments: itemTypeExpression,
        safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
        bodyName: namer.deriveAsyncBodyName(name));

    registry.registerStaticUse(StaticUse.staticInvoke(
        completerFactory,
        CallStructure.unnamed(0, 1),
        [elementEnvironment.getFunctionAsyncOrSyncStarElementType(element)]));

    return rewriter;
  }

  SyncStarRewriter _makeSyncStarRewriter(
      CodegenInputs codegen,
      CommonElements commonElements,
      JElementEnvironment elementEnvironment,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter,
      FunctionEntity element,
      js.Expression code,
      DartType? asyncTypeParameter,
      js.Name name) {
    SyncStarRewriter rewriter = SyncStarRewriter(_reporter, element,
        iteratorCurrentValueProperty: namer.instanceFieldPropertyName(
            commonElements.syncStarIteratorCurrentField),
        iteratorDatumProperty: namer.instanceFieldPropertyName(
            commonElements.syncStarIteratorDatumField),
        yieldStarSelector: namer
            .instanceMethodName(commonElements.syncStarIteratorYieldStarMethod),
        safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
        bodyName: namer.deriveAsyncBodyName(name));

    return rewriter;
  }

  AsyncStarRewriter _makeAsyncStarRewriter(
      CodegenInputs codegen,
      CommonElements commonElements,
      JElementEnvironment elementEnvironment,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter,
      FunctionEntity element,
      js.Expression code,
      DartType? asyncTypeParameter,
      js.Name name) {
    final itemTypeExpression =
        _fetchItemTypeNewRti(commonElements, registry, asyncTypeParameter);

    AsyncStarRewriter rewriter = AsyncStarRewriter(_reporter, element,
        asyncStarHelper:
            emitter.staticFunctionAccess(commonElements.asyncStarHelper),
        streamOfController:
            emitter.staticFunctionAccess(commonElements.streamOfController),
        wrapBody: emitter.staticFunctionAccess(commonElements.wrapBody),
        newController: emitter.staticFunctionAccess(
            commonElements.asyncStarStreamControllerFactory),
        newControllerTypeArguments: itemTypeExpression,
        safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
        yieldExpression:
            emitter.staticFunctionAccess(commonElements.yieldSingle),
        yieldStarExpression:
            emitter.staticFunctionAccess(commonElements.yieldStar),
        bodyName: namer.deriveAsyncBodyName(name));

    registry.registerStaticUse(StaticUse.staticInvoke(
        commonElements.asyncStarStreamControllerFactory,
        CallStructure.unnamed(1, 1),
        [elementEnvironment.getFunctionAsyncOrSyncStarElementType(element)]));

    return rewriter;
  }

  @override
  List<CompilerTask> get tasks {
    return [_builder, optimizer, generator];
  }
}

abstract class SsaBuilder {
  /// Creates the [HGraph] for [member] or returns `null` if no code is needed
  /// for [member].
  HGraph? build(
      MemberEntity member,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenInputs codegen,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter);
}

class SsaBuilderTask extends CompilerTask {
  final JsBackendStrategy _backendStrategy;
  final SourceInformationStrategy _sourceInformationFactory;
  late SsaBuilder _builder;

  final SsaMetrics _ssaMetrics;

  @override
  Metrics metrics = Metrics.none();

  SsaBuilderTask(super.measurer, this._backendStrategy,
      this._sourceInformationFactory, this._ssaMetrics);

  @override
  String get name => 'SSA builder';

  void onCodegenStart() {
    _builder =
        _backendStrategy.createSsaBuilder(this, _sourceInformationFactory);
    metrics = _ssaMetrics;
  }

  /// Creates the [HGraph] for [member] or returns `null` if no code is needed
  /// for [member].
  HGraph? build(
      MemberEntity member,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenInputs codegen,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter) {
    return _builder.build(member, closedWorld, globalInferenceResults, codegen,
        registry, namer, emitter);
  }
}
