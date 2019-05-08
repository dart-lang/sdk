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
import '../js_model/elements.dart';
import '../options.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse;
import '../world.dart' show JClosedWorld;

import 'codegen.dart';
import 'nodes.dart';
import 'optimize.dart';

class SsaFunctionCompiler implements FunctionCompiler {
  final DiagnosticReporter _reporter;
  final SsaCodeGeneratorTask generator;
  final SsaBuilderTask _builder;
  final SsaOptimizerTask optimizer;
  final SourceInformationStrategy sourceInformationStrategy;

  SsaFunctionCompiler(
      CompilerOptions options,
      this._reporter,
      BackendStrategy backendStrategy,
      Measurer measurer,
      this.sourceInformationStrategy)
      : generator = new SsaCodeGeneratorTask(
            measurer, options, sourceInformationStrategy),
        _builder = new SsaBuilderTask(
            measurer, backendStrategy, sourceInformationStrategy),
        optimizer = new SsaOptimizerTask(measurer, options);

  @override
  void onCodegenStart(CodegenInputs codegen) {
    _builder.onCodegenStart(codegen);
  }

  /// Generates JavaScript code for `work.element`.
  /// Using the ssa builder, optimizer and code generator.
  @override
  CodegenResult compile(
      MemberEntity member,
      CodegenInputs codegen,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults) {
    CodegenRegistry registry =
        new CodegenRegistry(closedWorld.elementEnvironment, member);
    HGraph graph =
        _builder.build(member, closedWorld, globalInferenceResults, registry);
    if (graph == null) {
      return new CodegenResult(null, registry.worldImpact);
    }
    optimizer.optimize(
        member, graph, codegen, closedWorld, globalInferenceResults, registry);
    js.Expression result =
        generator.generateCode(member, graph, codegen, closedWorld, registry);
    if (graph.needsAsyncRewrite) {
      SourceInformationBuilder sourceInformationBuilder =
          sourceInformationStrategy.createBuilderForContext(member);
      result = _rewriteAsync(
          codegen,
          closedWorld.commonElements,
          closedWorld.elementEnvironment,
          registry,
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

    return new CodegenResult(result, registry.worldImpact);
  }

  js.Expression _rewriteAsync(
      CodegenInputs codegen,
      CommonElements commonElements,
      JElementEnvironment elementEnvironment,
      CodegenRegistry registry,
      FunctionEntity element,
      js.Expression code,
      DartType asyncTypeParameter,
      SourceInformation bodySourceInformation,
      SourceInformation exitSourceInformation) {
    if (element.asyncMarker == AsyncMarker.SYNC) return code;

    AsyncRewriterBase rewriter = null;
    js.Name name = codegen.namer.methodPropertyName(
        element is JGeneratorBody ? element.function : element);

    switch (element.asyncMarker) {
      case AsyncMarker.ASYNC:
        rewriter = _makeAsyncRewriter(
            codegen,
            commonElements,
            elementEnvironment,
            registry,
            element,
            code,
            asyncTypeParameter,
            name);
        break;
      case AsyncMarker.SYNC_STAR:
        rewriter = new SyncStarRewriter(_reporter, element,
            endOfIteration: codegen.emitter
                .staticFunctionAccess(commonElements.endOfIteration),
            iterableFactory: codegen.emitter
                .staticFunctionAccess(commonElements.syncStarIterableFactory),
            iterableFactoryTypeArguments:
                _fetchItemType(codegen, asyncTypeParameter),
            yieldStarExpression:
                codegen.emitter.staticFunctionAccess(commonElements.yieldStar),
            uncaughtErrorExpression: codegen.emitter
                .staticFunctionAccess(commonElements.syncStarUncaughtError),
            safeVariableName: codegen.namer.safeVariablePrefixForAsyncRewrite,
            bodyName: codegen.namer.deriveAsyncBodyName(name));
        registry.registerStaticUse(new StaticUse.staticInvoke(
            commonElements.syncStarIterableFactory,
            const CallStructure.unnamed(1, 1), [
          elementEnvironment.getFunctionAsyncOrSyncStarElementType(element)
        ]));
        break;
      case AsyncMarker.ASYNC_STAR:
        rewriter = new AsyncStarRewriter(_reporter, element,
            asyncStarHelper: codegen.emitter
                .staticFunctionAccess(commonElements.asyncStarHelper),
            streamOfController: codegen.emitter
                .staticFunctionAccess(commonElements.streamOfController),
            wrapBody:
                codegen.emitter.staticFunctionAccess(commonElements.wrapBody),
            newController: codegen.emitter.staticFunctionAccess(
                commonElements.asyncStarStreamControllerFactory),
            newControllerTypeArguments:
                _fetchItemType(codegen, asyncTypeParameter),
            safeVariableName: codegen.namer.safeVariablePrefixForAsyncRewrite,
            yieldExpression: codegen.emitter
                .staticFunctionAccess(commonElements.yieldSingle),
            yieldStarExpression:
                codegen.emitter.staticFunctionAccess(commonElements.yieldStar),
            bodyName: codegen.namer.deriveAsyncBodyName(name));
        registry.registerStaticUse(new StaticUse.staticInvoke(
            commonElements.asyncStarStreamControllerFactory,
            const CallStructure.unnamed(1, 1), [
          elementEnvironment.getFunctionAsyncOrSyncStarElementType(element)
        ]));
        break;
    }
    return rewriter.rewrite(code, bodySourceInformation, exitSourceInformation);
  }

  /// Returns an optional expression that evaluates [type].  Returns `null` if
  /// the type expression is determined by the outside context and should be
  /// added as a function parameter to the rewritten code.
  // TODO(sra): We could also return an empty list if the generator takes no
  // type (e.g. due to rtiNeed optimization).
  List<js.Expression> _fetchItemType(CodegenInputs codegen, DartType type) {
    if (type == null) return null;
    var ast =
        codegen.rtiEncoder.getTypeRepresentation(codegen.emitter, type, null);
    return <js.Expression>[ast];
  }

  AsyncRewriter _makeAsyncRewriter(
      CodegenInputs codegen,
      CommonElements commonElements,
      JElementEnvironment elementEnvironment,
      CodegenRegistry registry,
      FunctionEntity element,
      js.Expression code,
      DartType elementType,
      js.Name name) {
    FunctionEntity startFunction = commonElements.asyncHelperStartSync;
    FunctionEntity completerFactory = commonElements.asyncAwaitCompleterFactory;

    List<js.Expression> itemTypeExpression =
        _fetchItemType(codegen, elementType);

    AsyncRewriter rewriter = new AsyncRewriter(_reporter, element,
        asyncStart: codegen.emitter.staticFunctionAccess(startFunction),
        asyncAwait: codegen.emitter
            .staticFunctionAccess(commonElements.asyncHelperAwait),
        asyncReturn: codegen.emitter
            .staticFunctionAccess(commonElements.asyncHelperReturn),
        asyncRethrow: codegen.emitter
            .staticFunctionAccess(commonElements.asyncHelperRethrow),
        wrapBody: codegen.emitter.staticFunctionAccess(commonElements.wrapBody),
        completerFactory:
            codegen.emitter.staticFunctionAccess(completerFactory),
        completerFactoryTypeArguments: itemTypeExpression,
        safeVariableName: codegen.namer.safeVariablePrefixForAsyncRewrite,
        bodyName: codegen.namer.deriveAsyncBodyName(name));

    registry.registerStaticUse(new StaticUse.staticInvoke(
        completerFactory,
        const CallStructure.unnamed(0, 1),
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
      CodegenRegistry registry);
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

  void onCodegenStart(CodegenInputs codegen) {
    _builder = _backendStrategy.createSsaBuilder(
        this, codegen, _sourceInformationFactory);
  }

  /// Creates the [HGraph] for [member] or returns `null` if no code is needed
  /// for [member].
  HGraph build(
      MemberEntity member,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenRegistry registry) {
    return _builder.build(
        member, closedWorld, globalInferenceResults, registry);
  }
}
