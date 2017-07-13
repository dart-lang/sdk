// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.strategy;

import '../closure.dart' show ClosureConversionTask;
import '../common.dart';
import '../common/tasks.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../constants/constant_system.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart';
import '../io/source_information.dart';
import '../js_emitter/sorter.dart';
import '../js/js_source_mapping.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/constant_system_javascript.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/runtime_types.dart';
import '../kernel/element_map.dart';
import '../kernel/element_map_impl.dart';
import '../kernel/kernel_backend_strategy.dart';
import '../kernel/kernel_strategy.dart';
import '../native/behavior.dart';
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

  BackendUsage _convertBackendUsage(
      JsToFrontendMap map, BackendUsageImpl backendUsage) {
    Set<FunctionEntity> globalFunctionDependencies =
        map.toBackendFunctionSet(backendUsage.globalFunctionDependencies);
    Set<ClassEntity> globalClassDependencies =
        map.toBackendClassSet(backendUsage.globalClassDependencies);
    Set<FunctionEntity> helperFunctionsUsed =
        map.toBackendFunctionSet(backendUsage.helperFunctionsUsed);
    Set<ClassEntity> helperClassesUsed =
        map.toBackendClassSet(backendUsage.helperClassesUsed);

    return new BackendUsageImpl(
        globalFunctionDependencies: globalFunctionDependencies,
        globalClassDependencies: globalClassDependencies,
        helperFunctionsUsed: helperFunctionsUsed,
        helperClassesUsed: helperClassesUsed,
        needToInitializeIsolateAffinityTag:
            backendUsage.needToInitializeIsolateAffinityTag,
        needToInitializeDispatchProperty:
            backendUsage.needToInitializeDispatchProperty,
        requiresPreamble: backendUsage.requiresPreamble,
        isInvokeOnUsed: backendUsage.isInvokeOnUsed,
        isRuntimeTypeUsed: backendUsage.isRuntimeTypeUsed,
        isIsolateInUse: backendUsage.isIsolateInUse,
        isFunctionApplyUsed: backendUsage.isFunctionApplyUsed,
        isMirrorsUsed: backendUsage.isMirrorsUsed,
        isNoSuchMethodUsed: backendUsage.isNoSuchMethodUsed);
  }

  NativeBasicData _convertNativeBasicData(
      JsToFrontendMap map, NativeBasicDataImpl nativeBasicData) {
    Map<ClassEntity, NativeClassTag> nativeClassTagInfo =
        <ClassEntity, NativeClassTag>{};
    nativeBasicData.nativeClassTagInfo
        .forEach((ClassEntity cls, NativeClassTag tag) {
      nativeClassTagInfo[map.toBackendClass(cls)] = tag;
    });
    Set<LibraryEntity> jsInteropLibraries =
        map.toBackendLibrarySet(nativeBasicData.jsInteropLibraries);
    Set<ClassEntity> jsInteropClasses =
        map.toBackendClassSet(nativeBasicData.jsInteropClasses);
    return new NativeBasicDataImpl(_elementEnvironment, nativeClassTagInfo,
        jsInteropLibraries, jsInteropClasses);
  }

  NativeData _convertNativeData(
      JsToFrontendMap map, NativeDataImpl nativeData) {
    convertNativeBehaviorType(type) {
      if (type is DartType) return map.toBackendType(type);
      assert(type is SpecialType);
      return type;
    }

    NativeBehavior convertNativeBehavior(NativeBehavior behavior) {
      NativeBehavior newBehavior = new NativeBehavior();

      for (dynamic type in behavior.typesReturned) {
        newBehavior.typesReturned.add(convertNativeBehaviorType(type));
      }
      for (dynamic type in behavior.typesInstantiated) {
        newBehavior.typesInstantiated.add(convertNativeBehaviorType(type));
      }

      newBehavior.codeTemplateText = behavior.codeTemplateText;
      newBehavior.codeTemplate = behavior.codeTemplate;
      newBehavior.throwBehavior = behavior.throwBehavior;
      newBehavior.isAllocation = behavior.isAllocation;
      newBehavior.useGvn = behavior.useGvn;
      return newBehavior;
    }

    NativeBasicData nativeBasicData = _convertNativeBasicData(map, nativeData);

    Map<MemberEntity, String> nativeMemberName =
        map.toBackendMemberMap(nativeData.nativeMemberName, identity);
    Map<FunctionEntity, NativeBehavior> nativeMethodBehavior =
        <FunctionEntity, NativeBehavior>{};
    nativeData.nativeMethodBehavior
        .forEach((FunctionEntity method, NativeBehavior behavior) {
      nativeMethodBehavior[map.toBackendMember(method)] =
          convertNativeBehavior(behavior);
    });
    Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior =
        map.toBackendMemberMap(
            nativeData.nativeFieldLoadBehavior, convertNativeBehavior);
    Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior =
        map.toBackendMemberMap(
            nativeData.nativeFieldStoreBehavior, convertNativeBehavior);
    Map<LibraryEntity, String> jsInteropLibraryNames =
        map.toBackendLibraryMap(nativeData.jsInteropLibraryNames, identity);
    Set<ClassEntity> anonymousJsInteropClasses =
        map.toBackendClassSet(nativeData.anonymousJsInteropClasses);
    Map<ClassEntity, String> jsInteropClassNames =
        map.toBackendClassMap(nativeData.jsInteropClassNames, identity);
    Map<MemberEntity, String> jsInteropMemberNames =
        map.toBackendMemberMap(nativeData.jsInteropMemberNames, identity);

    return new NativeDataImpl(
        nativeBasicData,
        nativeMemberName,
        nativeMethodBehavior,
        nativeFieldLoadBehavior,
        nativeFieldStoreBehavior,
        jsInteropLibraryNames,
        anonymousJsInteropClasses,
        jsInteropClassNames,
        jsInteropMemberNames);
  }

  InterceptorData _convertInterceptorData(JsToFrontendMap map,
      NativeData nativeData, InterceptorDataImpl interceptorData) {
    Map<String, Set<MemberEntity>> interceptedMembers =
        <String, Set<MemberEntity>>{};
    interceptorData.interceptedMembers
        .forEach((String name, Set<MemberEntity> members) {
      interceptedMembers[name] = map.toBackendMemberSet(members);
    });
    return new InterceptorDataImpl(
        nativeData,
        _commonElements,
        interceptedMembers,
        map.toBackendClassSet(interceptorData.interceptedClasses),
        map.toBackendClassSet(
            interceptorData.classesMixedIntoInterceptedClasses));
  }

  RuntimeTypesNeed _convertRuntimeTypesNeed(JsToFrontendMap map,
      BackendUsage backendUsage, RuntimeTypesNeedImpl rtiNeed) {
    Set<ClassEntity> classesNeedingRti =
        map.toBackendClassSet(rtiNeed.classesNeedingRti);
    Set<FunctionEntity> methodsNeedingRti =
        map.toBackendFunctionSet(rtiNeed.methodsNeedingRti);
    // TODO(johnniwinther): Do we need these?
    Set<Local> localFunctionsNeedingRti = rtiNeed.localFunctionsNeedingRti;
    Set<ClassEntity> classesUsingTypeVariableExpression =
        map.toBackendClassSet(rtiNeed.classesUsingTypeVariableExpression);
    return new RuntimeTypesNeedImpl(
        _elementEnvironment,
        backendUsage,
        classesNeedingRti,
        methodsNeedingRti,
        localFunctionsNeedingRti,
        classesUsingTypeVariableExpression);
  }

  @override
  ClosedWorldRefiner createClosedWorldRefiner(
      covariant ClosedWorldBase closedWorld) {
    KernelFrontEndStrategy strategy = _compiler.frontendStrategy;
    _elementMap = new JsKernelToElementMap(
        _compiler.reporter, _compiler.environment, strategy.elementMap);
    _elementEnvironment = _elementMap.elementEnvironment;
    _commonElements = _elementMap.commonElements;
    JsToFrontendMap map = new JsToFrontendMapImpl(_elementMap);
    _closureDataLookup = new KernelClosureConversionTask(
        _compiler.measurer, _elementMap, map, _globalLocalsMap);

    BackendUsage backendUsage =
        _convertBackendUsage(map, closedWorld.backendUsage);
    NativeData nativeData = _convertNativeData(map, closedWorld.nativeData);
    InterceptorData interceptorData =
        _convertInterceptorData(map, nativeData, closedWorld.interceptorData);

    Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes =
        <ClassEntity, ClassHierarchyNode>{};
    Map<ClassEntity, ClassSet> classSets = <ClassEntity, ClassSet>{};
    Set<ClassEntity> implementedClasses = new Set<ClassEntity>();

    ClassHierarchyNode convertClassHierarchyNode(ClassHierarchyNode node) {
      ClassEntity cls = map.toBackendClass(node.cls);
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
      ClassEntity cls = map.toBackendClass(classSet.cls);
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

    Set<MemberEntity> liveInstanceMembers =
        map.toBackendMemberSet(closedWorld.liveInstanceMembers);

    Map<ClassEntity, Set<ClassEntity>> mixinUses =
        map.toBackendClassMap(closedWorld.mixinUses, map.toBackendClassSet);

    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        map.toBackendClassMap(
            closedWorld.typesImplementedBySubclasses, map.toBackendClassSet);

    Iterable<MemberEntity> assignedInstanceMembers =
        map.toBackendMemberSet(closedWorld.assignedInstanceMembers);

    Iterable<ClassEntity> liveNativeClasses =
        map.toBackendClassSet(closedWorld.liveNativeClasses);

    RuntimeTypesNeed rtiNeed =
        _convertRuntimeTypesNeed(map, backendUsage, closedWorld.rtiNeed);

    return new JsClosedWorld(_elementMap,
        elementEnvironment: _elementEnvironment,
        dartTypes: _elementMap.types,
        commonElements: _commonElements,
        constantSystem: const JavaScriptConstantSystem(),
        backendUsage: backendUsage,
        nativeData: nativeData,
        interceptorData: interceptorData,
        rtiNeed: rtiNeed,
        classHierarchyNodes: classHierarchyNodes,
        classSets: classSets,
        implementedClasses: implementedClasses,
        liveNativeClasses: liveNativeClasses,
        liveInstanceMembers: liveInstanceMembers,
        assignedInstanceMembers: assignedInstanceMembers,
        mixinUses: mixinUses,
        typesImplementedBySubclasses: typesImplementedBySubclasses,
        // TODO(johnniwinther): Support this:
        allTypedefs: new ImmutableEmptySet<TypedefEntity>());
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

  @override
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement) {
    return _elementMap.getSourceSpan(spannable, currentElement);
  }
}

class JsClosedWorld extends ClosedWorldBase with KernelClosedWorldMixin {
  final JsKernelToElementMap elementMap;
  final RuntimeTypesNeed rtiNeed;

  JsClosedWorld(this.elementMap,
      {ElementEnvironment elementEnvironment,
      DartTypes dartTypes,
      CommonElements commonElements,
      ConstantSystem constantSystem,
      NativeData nativeData,
      InterceptorData interceptorData,
      BackendUsage backendUsage,
      this.rtiNeed,
      Set<ClassEntity> implementedClasses,
      Iterable<ClassEntity> liveNativeClasses,
      Iterable<MemberEntity> liveInstanceMembers,
      Iterable<MemberEntity> assignedInstanceMembers,
      Set<TypedefEntity> allTypedefs,
      Map<ClassEntity, Set<ClassEntity>> mixinUses,
      Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses,
      Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes,
      Map<ClassEntity, ClassSet> classSets})
      : super(
            elementEnvironment,
            dartTypes,
            commonElements,
            constantSystem,
            nativeData,
            interceptorData,
            backendUsage,
            implementedClasses,
            liveNativeClasses,
            liveInstanceMembers,
            assignedInstanceMembers,
            allTypedefs,
            mixinUses,
            typesImplementedBySubclasses,
            classHierarchyNodes,
            classSets);

  @override
  void registerClosureClass(ClassEntity cls, bool fromInstanceMember) {
    // Tell the hierarchy that this is the super class. then we can use
    // .getSupertypes(class)
    ClassEntity superclass = fromInstanceMember
        ? commonElements.boundClosureClass
        : commonElements.closureClass;
    ClassHierarchyNode parentNode = getClassHierarchyNode(superclass);
    ClassHierarchyNode node = new ClassHierarchyNode(
        parentNode, cls, getHierarchyDepth(superclass) + 1);
    addClassHierarchyNode(cls, node);
    for (InterfaceType type in getOrderedTypeSet(superclass).types) {
      // TODO(efortuna): assert that the FunctionClass is in this ordered set.
      // If not, we need to explicitly add node as a subtype of FunctionClass.
      ClassSet subtypeSet = getClassSet(type.element);
      subtypeSet.addSubtype(node);
    }
    addClassSet(cls, new ClassSet(node));
    elementMap.addClosureClass(cls, new InterfaceType(superclass, const []));
    node.isDirectlyInstantiated = true;
  }
}
