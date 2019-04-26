// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.strategy;

import 'package:kernel/ast.dart' as ir;

import '../backend_strategy.dart';
import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry, CodegenWorkItem;
import '../common/tasks.dart';
import '../compiler.dart';
import '../deferred_load.dart';
import '../elements/entities.dart';
import '../enqueue.dart';
import '../io/kernel_source_information.dart'
    show KernelSourceInformationStrategy;
import '../io/source_information.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/type_graph_inferrer.dart';
import '../inferrer/types.dart';
import '../js/js_source_mapping.dart';
import '../js_backend/backend.dart';
import '../js_backend/inferred_data.dart';
import '../js_backend/native_data.dart';
import '../kernel/kernel_strategy.dart';
import '../native/behavior.dart';
import '../ssa/builder_kernel.dart';
import '../ssa/nodes.dart';
import '../ssa/ssa.dart';
import '../ssa/types.dart';
import '../universe/codegen_world_builder.dart';
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import '../world.dart';
import 'closure.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'js_world.dart';
import 'js_world_builder.dart';
import 'locals.dart';

class JsBackendStrategy implements BackendStrategy {
  final Compiler _compiler;
  JsKernelToElementMap _elementMap;

  JsBackendStrategy(this._compiler);

  @deprecated
  JsToElementMap get elementMap {
    assert(_elementMap != null,
        "JsBackendStrategy.elementMap has not been created yet.");
    return _elementMap;
  }

  @override
  JClosedWorld createJClosedWorld(
      KClosedWorld closedWorld, OutputUnitData outputUnitData) {
    KernelFrontEndStrategy strategy = _compiler.frontendStrategy;
    _elementMap = new JsKernelToElementMap(
        _compiler.reporter,
        _compiler.environment,
        strategy.elementMap,
        closedWorld.liveMemberUsage,
        closedWorld.annotationsData);
    GlobalLocalsMap _globalLocalsMap = new GlobalLocalsMap();
    ClosureDataBuilder closureDataBuilder = new ClosureDataBuilder(
        _elementMap, _globalLocalsMap, _compiler.options);
    JsClosedWorldBuilder closedWorldBuilder = new JsClosedWorldBuilder(
        _elementMap,
        _globalLocalsMap,
        closureDataBuilder,
        _compiler.options,
        _compiler.abstractValueStrategy);
    return closedWorldBuilder.convertClosedWorld(
        closedWorld, strategy.closureModels, outputUnitData);
  }

  @override
  void registerJClosedWorld(covariant JsClosedWorld closedWorld) {
    _elementMap = closedWorld.elementMap;
  }

  @override
  SourceInformationStrategy get sourceInformationStrategy {
    if (!_compiler.options.generateSourceMap) {
      return const JavaScriptSourceInformationStrategy();
    }
    return new KernelSourceInformationStrategy(this);
  }

  @override
  SsaBuilder createSsaBuilder(CompilerTask task, JavaScriptBackend backend,
      SourceInformationStrategy sourceInformationStrategy) {
    return new KernelSsaBuilder(
        task,
        backend.compiler,
        // ignore:deprecated_member_use_from_same_package
        elementMap);
  }

  @override
  WorkItemBuilder createCodegenWorkItemBuilder(JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults) {
    return new KernelCodegenWorkItemBuilder(
        _compiler.backend, closedWorld, globalInferenceResults);
  }

  @override
  CodegenWorldBuilder createCodegenWorldBuilder(
      NativeBasicData nativeBasicData,
      JClosedWorld closedWorld,
      SelectorConstraintsStrategy selectorConstraintsStrategy) {
    return new CodegenWorldBuilderImpl(
        closedWorld, selectorConstraintsStrategy);
  }

  @override
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement) {
    return _elementMap.getSourceSpan(spannable, currentElement);
  }

  @override
  TypesInferrer createTypesInferrer(
      JClosedWorld closedWorld, InferredDataBuilder inferredDataBuilder) {
    return new TypeGraphInferrer(_compiler, closedWorld, inferredDataBuilder);
  }
}

class KernelCodegenWorkItemBuilder implements WorkItemBuilder {
  final JavaScriptBackend _backend;
  final JClosedWorld _closedWorld;
  final GlobalTypeInferenceResults _globalInferenceResults;

  KernelCodegenWorkItemBuilder(
      this._backend, this._closedWorld, this._globalInferenceResults);

  @override
  CodegenWorkItem createWorkItem(MemberEntity entity) {
    if (entity.isAbstract) return null;
    return new KernelCodegenWorkItem(
        _backend, _closedWorld, _globalInferenceResults, entity);
  }
}

class KernelCodegenWorkItem extends CodegenWorkItem {
  final JavaScriptBackend _backend;
  final JClosedWorld _closedWorld;
  @override
  final MemberEntity element;
  @override
  final CodegenRegistry registry;
  final GlobalTypeInferenceResults _globalInferenceResults;

  KernelCodegenWorkItem(this._backend, this._closedWorld,
      this._globalInferenceResults, this.element)
      : registry =
            new CodegenRegistry(_closedWorld.elementEnvironment, element);

  @override
  WorldImpact run() {
    return _backend.codegen(this, _closedWorld, _globalInferenceResults);
  }
}

/// Task for building SSA from kernel IR loaded from .dill.
class KernelSsaBuilder implements SsaBuilder {
  final CompilerTask task;
  final Compiler _compiler;
  final JsToElementMap _elementMap;
  FunctionInlineCache _inlineCache;

  KernelSsaBuilder(this.task, this._compiler, this._elementMap);

  @override
  HGraph build(CodegenWorkItem work, JClosedWorld closedWorld,
      GlobalTypeInferenceResults results) {
    _inlineCache ??= new FunctionInlineCache(closedWorld.annotationsData);
    return task.measure(() {
      KernelSsaGraphBuilder builder = new KernelSsaGraphBuilder(
          work.element,
          _elementMap.getMemberThisType(work.element),
          _compiler,
          _elementMap,
          results,
          closedWorld,
          work.registry,
          _compiler.backend.emitter.nativeEmitter,
          _compiler.backend.sourceInformationStrategy,
          _inlineCache);
      return builder.build();
    });
  }
}

class KernelToTypeInferenceMapImpl implements KernelToTypeInferenceMap {
  final GlobalTypeInferenceResults _globalInferenceResults;
  GlobalTypeInferenceMemberResult _targetResults;

  KernelToTypeInferenceMapImpl(
      MemberEntity target, this._globalInferenceResults) {
    _targetResults = _resultOf(target);
  }

  GlobalTypeInferenceMemberResult _resultOf(MemberEntity e) =>
      _globalInferenceResults
          .resultOfMember(e is ConstructorBodyEntity ? e.constructor : e);

  @override
  AbstractValue getReturnTypeOf(FunctionEntity function) {
    return AbstractValueFactory.inferredReturnTypeForElement(
        function, _globalInferenceResults);
  }

  @override
  AbstractValue receiverTypeOfInvocation(
      ir.MethodInvocation node, AbstractValueDomain abstractValueDomain) {
    return _targetResults.typeOfSend(node);
  }

  @override
  AbstractValue receiverTypeOfGet(ir.PropertyGet node) {
    return _targetResults.typeOfSend(node);
  }

  @override
  AbstractValue receiverTypeOfDirectGet(ir.DirectPropertyGet node) {
    return _targetResults.typeOfSend(node);
  }

  @override
  AbstractValue receiverTypeOfSet(
      ir.PropertySet node, AbstractValueDomain abstractValueDomain) {
    return _targetResults.typeOfSend(node);
  }

  @override
  AbstractValue typeOfListLiteral(
      ir.ListLiteral listLiteral, AbstractValueDomain abstractValueDomain) {
    return _globalInferenceResults.typeOfListLiteral(listLiteral) ??
        abstractValueDomain.dynamicType;
  }

  @override
  AbstractValue typeOfIterator(ir.ForInStatement node) {
    return _targetResults.typeOfIterator(node);
  }

  @override
  AbstractValue typeOfIteratorCurrent(ir.ForInStatement node) {
    return _targetResults.typeOfIteratorCurrent(node);
  }

  @override
  AbstractValue typeOfIteratorMoveNext(ir.ForInStatement node) {
    return _targetResults.typeOfIteratorMoveNext(node);
  }

  @override
  bool isJsIndexableIterator(
      ir.ForInStatement node, AbstractValueDomain abstractValueDomain) {
    AbstractValue mask = typeOfIterator(node);
    return abstractValueDomain.isJsIndexableAndIterable(mask).isDefinitelyTrue;
  }

  @override
  AbstractValue inferredIndexType(ir.ForInStatement node) {
    return AbstractValueFactory.inferredTypeForSelector(
        new Selector.index(), typeOfIterator(node), _globalInferenceResults);
  }

  @override
  AbstractValue getInferredTypeOf(MemberEntity member) {
    return AbstractValueFactory.inferredTypeForMember(
        member, _globalInferenceResults);
  }

  @override
  AbstractValue getInferredTypeOfParameter(Local parameter) {
    return AbstractValueFactory.inferredTypeForParameter(
        parameter, _globalInferenceResults);
  }

  @override
  AbstractValue selectorTypeOf(Selector selector, AbstractValue mask) {
    return AbstractValueFactory.inferredTypeForSelector(
        selector, mask, _globalInferenceResults);
  }

  @override
  AbstractValue typeFromNativeBehavior(
      NativeBehavior nativeBehavior, JClosedWorld closedWorld) {
    return AbstractValueFactory.fromNativeBehavior(nativeBehavior, closedWorld);
  }
}
