// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa;

import '../backend_strategy.dart';
import '../common.dart';
import '../common_elements.dart' show CommonElements, JElementEnvironment;
import '../common/codegen.dart' show CodegenResult, CodegenRegistry;
import '../common/tasks.dart' show CompilerTask, Measurer;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../inferrer/types.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js/rewrite_async.dart';
import '../js_backend/backend.dart' show CodegenInputs, FunctionCompiler;
import '../js_backend/namer.dart' show ModularNamer, ModularNamerImpl;
import '../js_backend/type_reference.dart' show TypeReference;
import '../js_emitter/code_emitter_task.dart' show ModularEmitter;
import '../js_emitter/startup_emitter/emitter.dart' show ModularEmitterImpl;
import '../js_model/elements.dart';
import '../js_model/type_recipe.dart' show TypeExpressionRecipe;
import '../options.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse;
import '../world.dart' show JClosedWorld;

import 'codegen.dart';
import 'nodes.dart';
import 'optimize.dart';

class SsaFunctionCompiler implements FunctionCompiler {
  final CompilerOptions _options;
  final DiagnosticReporter _reporter;
  final SsaCodeGeneratorTask generator;
  final SsaBuilderTask _builder;
  final SsaOptimizerTask optimizer;
  final SourceInformationStrategy sourceInformationStrategy;
  GlobalTypeInferenceResults _globalInferenceResults;
  CodegenInputs _codegen;

  SsaFunctionCompiler(
      this._options,
      this._reporter,
      BackendStrategy backendStrategy,
      Measurer measurer,
      this.sourceInformationStrategy)
      : generator = new SsaCodeGeneratorTask(
            measurer, _options, sourceInformationStrategy),
        _builder = new SsaBuilderTask(
            measurer, backendStrategy, sourceInformationStrategy),
        optimizer = new SsaOptimizerTask(measurer, _options);

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
        new CodegenRegistry(closedWorld.elementEnvironment, member);
    ModularNamer namer = new ModularNamerImpl(
        registry, closedWorld.commonElements, _codegen.fixedNames);
    ModularEmitter emitter = new ModularEmitterImpl(namer, registry, _options);
    if (member.isConstructor &&
        member.enclosingClass == closedWorld.commonElements.jsNullClass) {
      // Work around a problem compiling JSNull's constructor.
      return registry.close(null);
    }

    HGraph graph = _builder.build(member, closedWorld, _globalInferenceResults,
        _codegen, registry, namer, emitter);
    if (graph == null) {
      return registry.close(null);
    }
    optimizer.optimize(member, graph, _codegen, closedWorld,
        _globalInferenceResults, registry);
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
          member,
          result,
          graph.asyncElementType,
          sourceInformationBuilder.buildAsyncBody(),
          sourceInformationBuilder.buildAsyncExit());
    }
    if (result.sourceInformation == null) {
      result = result.withSourceInformation(
          sourceInformationStrategy.buildSourceMappedMarker());
    }

    return registry.close(result);
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
      DartType asyncTypeParameter,
      SourceInformation bodySourceInformation,
      SourceInformation exitSourceInformation) {
    if (element.asyncMarker == AsyncMarker.SYNC) return code;

    AsyncRewriterBase rewriter = null;
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
    return rewriter.rewrite(code, bodySourceInformation, exitSourceInformation);
  }

  /// Returns an optional expression that evaluates [type].  Returns `null` if
  /// the type expression is determined by the outside context and should be
  /// added as a function parameter to the rewritten code.
  // TODO(sra): We could also return an empty list if the generator takes no
  // type (e.g. due to rtiNeed optimization).
  List<js.Expression> _fetchItemTypeNewRti(
      CommonElements commonElements, CodegenRegistry registry, DartType type) {
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
      DartType elementType,
      js.Name name) {
    FunctionEntity startFunction = commonElements.asyncHelperStartSync;
    FunctionEntity completerFactory = commonElements.asyncAwaitCompleterFactory;

    List<js.Expression> itemTypeExpression =
        _fetchItemTypeNewRti(commonElements, registry, elementType);

    AsyncRewriter rewriter = new AsyncRewriter(_reporter, element,
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

    registry.registerStaticUse(new StaticUse.staticInvoke(
        completerFactory,
        const CallStructure.unnamed(0, 1),
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
      DartType asyncTypeParameter,
      js.Name name) {
    List<js.Expression> itemTypeExpression =
        _fetchItemTypeNewRti(commonElements, registry, asyncTypeParameter);

    SyncStarRewriter rewriter = new SyncStarRewriter(_reporter, element,
        endOfIteration:
            emitter.staticFunctionAccess(commonElements.endOfIteration),
        iterableFactory: emitter
            .staticFunctionAccess(commonElements.syncStarIterableFactory),
        iterableFactoryTypeArguments: itemTypeExpression,
        yieldStarExpression:
            emitter.staticFunctionAccess(commonElements.yieldStar),
        uncaughtErrorExpression:
            emitter.staticFunctionAccess(commonElements.syncStarUncaughtError),
        safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
        bodyName: namer.deriveAsyncBodyName(name));

    registry.registerStaticUse(new StaticUse.staticInvoke(
        commonElements.syncStarIterableFactory,
        const CallStructure.unnamed(1, 1),
        [elementEnvironment.getFunctionAsyncOrSyncStarElementType(element)]));

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
      DartType asyncTypeParameter,
      js.Name name) {
    List<js.Expression> itemTypeExpression =
        _fetchItemTypeNewRti(commonElements, registry, asyncTypeParameter);

    AsyncStarRewriter rewriter = new AsyncStarRewriter(_reporter, element,
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

    registry.registerStaticUse(new StaticUse.staticInvoke(
        commonElements.asyncStarStreamControllerFactory,
        const CallStructure.unnamed(1, 1),
        [elementEnvironment.getFunctionAsyncOrSyncStarElementType(element)]));

    return rewriter;
  }

  @override
  Iterable<CompilerTask> get tasks {
    return <CompilerTask>[_builder, optimizer, generator];
  }
}

abstract class SsaBuilder {
  /// Creates the [HGraph] for [member] or returns `null` if no code is needed
  /// for [member].
  HGraph build(
      MemberEntity member,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenInputs codegen,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter);
}

class SsaBuilderTask extends CompilerTask {
  final BackendStrategy _backendStrategy;
  final SourceInformationStrategy _sourceInformationFactory;
  SsaBuilder _builder;

  SsaBuilderTask(
      Measurer measurer, this._backendStrategy, this._sourceInformationFactory)
      : super(measurer);

  @override
  String get name => 'SSA builder';

  void onCodegenStart() {
    _builder =
        _backendStrategy.createSsaBuilder(this, _sourceInformationFactory);
  }

  /// Creates the [HGraph] for [member] or returns `null` if no code is needed
  /// for [member].
  HGraph build(
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
