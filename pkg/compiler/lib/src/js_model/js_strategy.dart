// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.strategy;

import '../closure.dart' show ClosureConversionTask;
import '../common/tasks.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../elements/elements.dart' show TypedefElement;
import '../elements/entities.dart';
import '../enqueue.dart';
import '../io/source_information.dart';
import '../js_emitter/sorter.dart';
import '../js/js_source_mapping.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/constant_system_javascript.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../kernel/closure.dart';
import '../kernel/element_map.dart';
import '../kernel/element_map_impl.dart';
import '../kernel/kernel_backend_strategy.dart';
import '../kernel/kernel_strategy.dart';
import '../ssa/ssa.dart';
import '../universe/class_set.dart';
import '../universe/world_builder.dart';
import '../util/emptyset.dart';
import '../world.dart';
import 'elements.dart';

class JsBackendStrategy implements KernelBackendStrategy {
  final Compiler _compiler;
  final JsToFrontendMap _map = new JsToFrontendMapImpl();
  ElementEnvironment _elementEnvironment;
  CommonElements _commonElements;
  KernelToElementMapForBuilding _elementMap;
  ClosureConversionTask _closureDataLookup;
  final GlobalLocalsMap _globalLocalsMap = new GlobalLocalsMap();

  JsBackendStrategy(this._compiler);

  KernelToElementMapForBuilding get elementMap {
    if (_elementMap == null) {
      KernelFrontEndStrategy strategy = _compiler.frontendStrategy;
      KernelToElementMapForBuilding elementMap = strategy.elementMap;
      _elementMap = new JsKernelToElementMap(
          _map, _elementEnvironment, _commonElements, elementMap);
    }
    return _elementMap;
  }

  GlobalLocalsMap get globalLocalsMapForTesting => _globalLocalsMap;

  @override
  ClosedWorldRefiner createClosedWorldRefiner(ClosedWorld closedWorld) {
    _elementEnvironment =
        new JsElementEnvironment(_map, closedWorld.elementEnvironment);
    _commonElements = new JsCommonElements(_map, closedWorld.commonElements);
    BackendUsage backendUsage =
        new JsBackendUsage(_map, closedWorld.backendUsage);
    NativeData nativeData = new JsNativeData(_map, closedWorld.nativeData);
    InterceptorData interceptorData = new InterceptorDataImpl(
        nativeData,
        _commonElements,
        // TODO(johnniwinther): Convert these.
        const {},
        new Set(),
        new Set());

    Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes =
        <ClassEntity, ClassHierarchyNode>{};
    Map<ClassEntity, ClassSet> classSets = <ClassEntity, ClassSet>{};
    Set<ClassEntity> implementedClasses = new Set<ClassEntity>();

    ClassHierarchyNode convertClassHierarchyNode(ClassHierarchyNode node) {
      ClassEntity cls = _map.toBackendClass(node.cls);
      if (closedWorld.isImplemented(node.cls)) {
        implementedClasses.add(cls);
      }
      ClassHierarchyNode newNode = classHierarchyNodes.putIfAbsent(cls, () {
        ClassHierarchyNode parentNode;
        if (node.parentNode != null) {
          parentNode = convertClassHierarchyNode(node.parentNode);
        }
        return new ClassHierarchyNode(parentNode, cls, node.hierarchyDepth);
      });
      newNode.isAbstractlyInstantiated = node.isAbstractlyInstantiated;
      newNode.isDirectlyInstantiated = node.isDirectlyInstantiated;
      return newNode;
    }

    ClassSet convertClassSet(ClassSet classSet) {
      ClassEntity cls = _map.toBackendClass(classSet.cls);
      return classSets.putIfAbsent(cls, () {
        ClassHierarchyNode newNode = convertClassHierarchyNode(classSet.node);
        ClassSet newClassSet = new ClassSet(newNode);
        for (ClassHierarchyNode subtype in classSet.subtypeNodes) {
          ClassHierarchyNode newSubtype = convertClassHierarchyNode(subtype);
          newClassSet.addSubtype(newSubtype);
        }
        return newClassSet;
      });
    }

    closedWorld
        .getClassHierarchyNode(closedWorld.commonElements.objectClass)
        .forEachSubclass((ClassEntity cls) {
      convertClassSet(closedWorld.getClassSet(cls));
    }, ClassHierarchyNode.ALL);

    return new JsClosedWorld(
        elementEnvironment: _elementEnvironment,
        commonElements: _commonElements,
        constantSystem: const JavaScriptConstantSystem(),
        backendUsage: backendUsage,
        nativeData: nativeData,
        interceptorData: interceptorData,
        classHierarchyNodes: classHierarchyNodes,
        classSets: classSets,
        implementedClasses: implementedClasses,
        // TODO(johnniwinther): Support this.
        allTypedefs: new ImmutableEmptySet<TypedefElement>());
  }

  @override
  Sorter get sorter {
    throw new UnimplementedError('JsBackendStrategy.sorter');
  }

  @override
  ClosureConversionTask get closureDataLookup =>
      _closureDataLookup ??= new KernelClosureConversionTask(
          _compiler.measurer, elementMap, _globalLocalsMap);

  @override
  SourceInformationStrategy get sourceInformationStrategy =>
      const JavaScriptSourceInformationStrategy();

  @override
  SsaBuilder createSsaBuilder(CompilerTask task, JavaScriptBackend backend,
      SourceInformationStrategy sourceInformationStrategy) {
    return new KernelSsaBuilder(
        task, backend.compiler, elementMap, _globalLocalsMap);
  }

  @override
  WorkItemBuilder createCodegenWorkItemBuilder(ClosedWorld closedWorld) {
    return new KernelCodegenWorkItemBuilder(_compiler.backend, closedWorld);
  }

  @override
  CodegenWorldBuilder createCodegenWorldBuilder(
      NativeBasicData nativeBasicData,
      ClosedWorld closedWorld,
      SelectorConstraintsStrategy selectorConstraintsStrategy) {
    return new KernelCodegenWorldBuilder(
        elementMap,
        closedWorld.elementEnvironment,
        nativeBasicData,
        closedWorld,
        selectorConstraintsStrategy);
  }
}
