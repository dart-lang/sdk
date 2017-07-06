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
import '../kernel/element_map.dart';
import '../kernel/element_map_impl.dart';
import '../kernel/kernel_backend_strategy.dart';
import '../kernel/kernel_strategy.dart';
import '../ssa/ssa.dart';
import '../universe/class_set.dart';
import '../universe/world_builder.dart';
import '../util/emptyset.dart';
import '../world.dart';
import 'closure.dart';
import 'elements.dart';
import 'locals.dart';

class JsBackendStrategy implements KernelBackendStrategy {
  final Compiler _compiler;
  ElementEnvironment _elementEnvironment;
  CommonElements _commonElements;
  JsKernelToElementMap _elementMap;
  ClosureConversionTask _closureDataLookup;
  final GlobalLocalsMap _globalLocalsMap = new GlobalLocalsMap();
  Sorter _sorter;

  JsBackendStrategy(this._compiler);

  KernelToElementMapForBuilding get elementMap {
    assert(_elementMap != null,
        "JsBackendStrategy.elementMap has not been created yet.");
    return _elementMap;
  }

  GlobalLocalsMap get globalLocalsMapForTesting => _globalLocalsMap;

  @override
  ClosedWorldRefiner createClosedWorldRefiner(
      covariant ClosedWorldBase closedWorld) {
    KernelFrontEndStrategy strategy = _compiler.frontendStrategy;
    KernelToElementMapForImpact elementMap = strategy.elementMap;
    _elementMap = new JsKernelToElementMap(
        _compiler.reporter, _compiler.environment, elementMap);
    _elementEnvironment = _elementMap.elementEnvironment;
    _commonElements = _elementMap.commonElements;
    JsToFrontendMap _map = _elementMap.jsToFrontendMap;
    BackendUsage backendUsage =
        new JsBackendUsage(_map, closedWorld.backendUsage);
    _closureDataLookup = new KernelClosureConversionTask(
        _compiler.measurer, _elementMap, _map, _globalLocalsMap);
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

    List<MemberEntity> liveInstanceMembers =
        closedWorld.liveInstanceMembers.map(_map.toBackendMember).toList();

    Map<ClassEntity, Set<ClassEntity>> mixinUses =
        <ClassEntity, Set<ClassEntity>>{};
    closedWorld.mixinUses.forEach((ClassEntity cls, Set<ClassEntity> uses) {
      mixinUses[_map.toBackendClass(cls)] =
          uses.map(_map.toBackendClass).toSet();
    });

    Iterable<MemberEntity> assignedInstanceMembers =
        closedWorld.assignedInstanceMembers.map(_map.toBackendMember).toList();

    return new JsClosedWorld(_elementMap,
        elementEnvironment: _elementEnvironment,
        dartTypes: _elementMap.types,
        commonElements: _commonElements,
        constantSystem: const JavaScriptConstantSystem(),
        backendUsage: backendUsage,
        nativeData: nativeData,
        interceptorData: interceptorData,
        classHierarchyNodes: classHierarchyNodes,
        classSets: classSets,
        implementedClasses: implementedClasses,
        liveInstanceMembers: liveInstanceMembers,
        assignedInstanceMembers: assignedInstanceMembers,
        mixinUses: mixinUses,
        // TODO(johnniwinther): Support these.
        allTypedefs: new ImmutableEmptySet<TypedefElement>(),
        typesImplementedBySubclasses: null);
  }

  @override
  Sorter get sorter {
    return _sorter ??= new KernelSorter(elementMap);
  }

  @override
  ClosureConversionTask get closureDataLookup => _closureDataLookup;

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
