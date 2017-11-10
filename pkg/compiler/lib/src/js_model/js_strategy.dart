// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.strategy;

import 'package:kernel/ast.dart' as ir;

import '../closure.dart' show ClosureConversionTask;
import '../common.dart';
import '../common/tasks.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../deferred_load.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart';
import '../io/source_information.dart';
import '../inferrer/kernel_inferrer_engine.dart';
import '../js_emitter/sorter.dart';
import '../js/js_source_mapping.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/constant_system_javascript.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../kernel/element_map.dart';
import '../kernel/element_map_impl.dart';
import '../kernel/kernel_backend_strategy.dart';
import '../kernel/kernel_strategy.dart';
import '../kernel/kelements.dart';
import '../native/behavior.dart';
import '../ssa/ssa.dart';
import '../types/types.dart';
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
  KernelClosureConversionTask _closureDataLookup;
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
  ClosedWorldRefiner createClosedWorldRefiner(ClosedWorld closedWorld) {
    KernelFrontEndStrategy strategy = _compiler.frontendStrategy;
    _elementMap = new JsKernelToElementMap(
        _compiler.reporter, _compiler.environment, strategy.elementMap);
    _elementEnvironment = _elementMap.elementEnvironment;
    _commonElements = _elementMap.commonElements;
    _closureDataLookup = new KernelClosureConversionTask(
        _compiler.measurer, _elementMap, _globalLocalsMap);
    JsClosedWorldBuilder closedWorldBuilder =
        new JsClosedWorldBuilder(_elementMap, _closureDataLookup);
    return closedWorldBuilder._convertClosedWorld(
        closedWorld, strategy.closureModels);
  }

  @override
  OutputUnitData convertOutputUnitData(OutputUnitData data) {
    JsToFrontendMapImpl map = new JsToFrontendMapImpl(_elementMap);

    // TODO(sigmund): make this more flexible to support scenarios where we have
    // a 1-n mapping (a k-entity that maps to multiple j-entities).
    Entity toBackendEntity(Entity entity) {
      if (entity is ClassEntity) return map.toBackendClass(entity);
      if (entity is MemberEntity) return map.toBackendMember(entity);
      if (entity is TypeVariableEntity) {
        return map.toBackendTypeVariable(entity);
      }
      if (entity is Local) {
        // TODO(sigmund): ensure we don't store locals in OuputUnitData
        return entity;
      }
      assert(
          entity is LibraryEntity, 'unexpected entity ${entity.runtimeType}');
      return map.toBackendLibrary(entity);
    }

    ConstantValue toBackendConstant(ConstantValue constant) {
      return constant.accept(new ConstantConverter(toBackendEntity), null);
    }

    return new OutputUnitData.from(
        data,
        (m) => convertMap<Entity, OutputUnit>(m, toBackendEntity, (v) => v),
        (m) => convertMap<ConstantValue, OutputUnit>(
            m, toBackendConstant, (v) => v));
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

  @override
  TypesInferrer createTypesInferrer(ClosedWorldRefiner closedWorldRefiner,
      {bool disableTypeInference: false}) {
    return new KernelTypeGraphInferrer(_compiler, _elementMap, _globalLocalsMap,
        _closureDataLookup, closedWorldRefiner.closedWorld, closedWorldRefiner,
        disableTypeInference: disableTypeInference);
  }
}

class JsClosedWorldBuilder {
  final JsKernelToElementMap _elementMap;
  final Map<ClassEntity, ClassHierarchyNode> _classHierarchyNodes =
      <ClassEntity, ClassHierarchyNode>{};
  final Map<ClassEntity, ClassSet> _classSets = <ClassEntity, ClassSet>{};
  final KernelClosureConversionTask _closureConversionTask;

  JsClosedWorldBuilder(this._elementMap, this._closureConversionTask);

  ElementEnvironment get _elementEnvironment => _elementMap.elementEnvironment;
  CommonElements get _commonElements => _elementMap.commonElements;

  JsClosedWorld _convertClosedWorld(ClosedWorldBase closedWorld,
      Map<MemberEntity, ScopeModel> closureModels) {
    JsToFrontendMap map = new JsToFrontendMapImpl(_elementMap);

    BackendUsage backendUsage =
        _convertBackendUsage(map, closedWorld.backendUsage);
    NativeData nativeData = _convertNativeData(map, closedWorld.nativeData);
    _elementMap.nativeBasicData = nativeData;
    InterceptorData interceptorData =
        _convertInterceptorData(map, nativeData, closedWorld.interceptorData);

    Set<ClassEntity> implementedClasses = new Set<ClassEntity>();

    /// Converts [node] from the frontend world to the corresponding
    /// [ClassHierarchyNode] for the backend world.
    ClassHierarchyNode convertClassHierarchyNode(ClassHierarchyNode node) {
      ClassEntity cls = map.toBackendClass(node.cls);
      if (closedWorld.isImplemented(node.cls)) {
        implementedClasses.add(cls);
      }
      ClassHierarchyNode newNode = _classHierarchyNodes.putIfAbsent(cls, () {
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

    /// Converts [classSet] from the frontend world to the corresponding
    /// [ClassSet] for the backend world.
    ClassSet convertClassSet(ClassSet classSet) {
      ClassEntity cls = map.toBackendClass(classSet.cls);
      return _classSets.putIfAbsent(cls, () {
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

    Iterable<MemberEntity> processedMembers =
        map.toBackendMemberSet(closedWorld.processedMembers);

    RuntimeTypesNeedImpl kernelRtiNeed = closedWorld.rtiNeed;
    Set<ir.Node> localFunctionsNodes = new Set<ir.Node>();
    for (KLocalFunction localFunction
        in kernelRtiNeed.localFunctionsNeedingRti) {
      localFunctionsNodes.add(localFunction.node);
    }

    var classesNeedingRti =
        map.toBackendClassSet(kernelRtiNeed.classesNeedingRti);
    Iterable<FunctionEntity> callMethods =
        _closureConversionTask.createClosureEntities(
            this,
            map.toBackendMemberMap(closureModels, identity),
            localFunctionsNodes,
            classesNeedingRti);

    List<FunctionEntity> callMethodsNeedingRti = <FunctionEntity>[];
    for (ir.Node node in localFunctionsNodes) {
      callMethodsNeedingRti
          .add(_closureConversionTask.getClosureInfo(node).callMethod);
    }

    RuntimeTypesNeed rtiNeed = _convertRuntimeTypesNeed(map, backendUsage,
        kernelRtiNeed, callMethodsNeedingRti, classesNeedingRti);

    NoSuchMethodDataImpl oldNoSuchMethodData = closedWorld.noSuchMethodData;
    NoSuchMethodData noSuchMethodData = new NoSuchMethodDataImpl(
        map.toBackendFunctionSet(oldNoSuchMethodData.throwingImpls),
        map.toBackendFunctionSet(oldNoSuchMethodData.otherImpls),
        map.toBackendFunctionSet(oldNoSuchMethodData.forwardingSyntaxImpls));

    return new JsClosedWorld(_elementMap,
        elementEnvironment: _elementEnvironment,
        dartTypes: _elementMap.types,
        commonElements: _commonElements,
        constantSystem: const JavaScriptConstantSystem(),
        backendUsage: backendUsage,
        noSuchMethodData: noSuchMethodData,
        nativeData: nativeData,
        interceptorData: interceptorData,
        rtiNeed: rtiNeed,
        classHierarchyNodes: _classHierarchyNodes,
        classSets: _classSets,
        implementedClasses: implementedClasses,
        liveNativeClasses: liveNativeClasses,
        liveInstanceMembers: liveInstanceMembers..addAll(callMethods),
        assignedInstanceMembers: assignedInstanceMembers,
        processedMembers: processedMembers,
        mixinUses: mixinUses,
        typesImplementedBySubclasses: typesImplementedBySubclasses,
        // TODO(johnniwinther): Support this:
        allTypedefs: new ImmutableEmptySet<TypedefEntity>());
  }

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
    Map<LibraryEntity, String> jsInteropLibraries =
        map.toBackendLibraryMap(nativeBasicData.jsInteropLibraries, identity);
    Map<ClassEntity, String> jsInteropClasses =
        map.toBackendClassMap(nativeBasicData.jsInteropClasses, identity);
    Set<ClassEntity> anonymousJsInteropClasses =
        map.toBackendClassSet(nativeBasicData.anonymousJsInteropClasses);
    Map<MemberEntity, String> jsInteropMembers =
        map.toBackendMemberMap(nativeBasicData.jsInteropMembers, identity);
    return new NativeBasicDataImpl(
        _elementEnvironment,
        nativeClassTagInfo,
        jsInteropLibraries,
        jsInteropClasses,
        anonymousJsInteropClasses,
        jsInteropMembers);
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
        map.toBackendLibraryMap(nativeData.jsInteropLibraries, identity);
    Set<ClassEntity> anonymousJsInteropClasses =
        map.toBackendClassSet(nativeData.anonymousJsInteropClasses);
    Map<ClassEntity, String> jsInteropClassNames =
        map.toBackendClassMap(nativeData.jsInteropClasses, identity);
    Map<MemberEntity, String> jsInteropMemberNames =
        map.toBackendMemberMap(nativeData.jsInteropMembers, identity);

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

  RuntimeTypesNeed _convertRuntimeTypesNeed(
      JsToFrontendMap map,
      BackendUsage backendUsage,
      RuntimeTypesNeedImpl rtiNeed,
      List<FunctionEntity> callMethodsNeedingRti,
      Set<ClassEntity> classesNeedingRti) {
    Set<FunctionEntity> methodsNeedingRti =
        map.toBackendFunctionSet(rtiNeed.methodsNeedingRti);
    methodsNeedingRti.addAll(callMethodsNeedingRti);
    Set<ClassEntity> classesUsingTypeVariableExpression =
        map.toBackendClassSet(rtiNeed.classesUsingTypeVariableExpression);
    return new RuntimeTypesNeedImpl(
        _elementEnvironment,
        backendUsage,
        classesNeedingRti,
        methodsNeedingRti,
        null,
        classesUsingTypeVariableExpression);
  }

  /// Construct a closure class and set up the necessary class inference
  /// hierarchy.
  KernelClosureClass buildClosureClass(
      MemberEntity member,
      ir.FunctionNode originalClosureFunctionNode,
      JLibrary enclosingLibrary,
      Map<Local, JRecordField> boxedVariables,
      KernelScopeInfo info,
      ir.Location location,
      KernelToLocalsMap localsMap) {
    ClassEntity superclass = _commonElements.closureClass;

    KernelClosureClass cls = _elementMap.constructClosureClass(
        member,
        originalClosureFunctionNode,
        enclosingLibrary,
        boxedVariables,
        info,
        location,
        localsMap,
        new InterfaceType(superclass, const []));

    // Tell the hierarchy that this is the super class. then we can use
    // .getSupertypes(class)
    ClassHierarchyNode parentNode = _classHierarchyNodes[superclass];
    ClassHierarchyNode node = new ClassHierarchyNode(
        parentNode, cls.closureClassEntity, parentNode.hierarchyDepth + 1);
    _classHierarchyNodes[cls.closureClassEntity] = node;
    _classSets[cls.closureClassEntity] = new ClassSet(node);
    node.isDirectlyInstantiated = true;

    return cls;
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
      NoSuchMethodData noSuchMethodData,
      Set<ClassEntity> implementedClasses,
      Iterable<ClassEntity> liveNativeClasses,
      Iterable<MemberEntity> liveInstanceMembers,
      Iterable<MemberEntity> assignedInstanceMembers,
      Iterable<MemberEntity> processedMembers,
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
            noSuchMethodData,
            implementedClasses,
            liveNativeClasses,
            liveInstanceMembers,
            assignedInstanceMembers,
            processedMembers,
            allTypedefs,
            mixinUses,
            typesImplementedBySubclasses,
            classHierarchyNodes,
            classSets);

  @override
  void registerClosureClass(ClassEntity cls) {
    throw new UnsupportedError('JsClosedWorld.registerClosureClass');
  }
}

class ConstantConverter implements ConstantValueVisitor<ConstantValue, Null> {
  final Entity Function(Entity) toBackendEntity;

  ConstantConverter(this.toBackendEntity);

  ConstantValue visitNull(NullConstantValue constant, _) => constant;
  ConstantValue visitInt(IntConstantValue constant, _) => constant;
  ConstantValue visitDouble(DoubleConstantValue constant, _) => constant;
  ConstantValue visitBool(BoolConstantValue constant, _) => constant;
  ConstantValue visitString(StringConstantValue constant, _) => constant;
  ConstantValue visitSynthetic(SyntheticConstantValue constant, _) => constant;
  ConstantValue visitNonConstant(NonConstantValue constant, _) => constant;

  ConstantValue visitFunction(FunctionConstantValue constant, _) {
    return new FunctionConstantValue(
        toBackendEntity(constant.element), _handleType(constant.type));
  }

  ConstantValue visitList(ListConstantValue constant, _) {
    var type = _handleType(constant.type);
    List<ConstantValue> entries = _handleValues(constant.entries);
    if (identical(entries, constant.entries) && type == constant.type) {
      return constant;
    }
    return new ListConstantValue(type, entries);
  }

  ConstantValue visitMap(MapConstantValue constant, _) {
    var type = _handleType(constant.type);
    List<ConstantValue> keys = _handleValues(constant.keys);
    List<ConstantValue> values = _handleValues(constant.values);
    if (identical(keys, constant.keys) &&
        identical(values, constant.values) &&
        type == constant.type) {
      return constant;
    }
    return new MapConstantValue(type, keys, values);
  }

  ConstantValue visitConstructed(ConstructedConstantValue constant, _) {
    var type = _handleType(constant.type);
    if (type == constant.type && constant.fields.isEmpty) {
      return constant;
    }
    var fields = <FieldEntity, ConstantValue>{};
    constant.fields.forEach((f, v) {
      fields[toBackendEntity(f)] = v.accept(this, null);
    });
    return new ConstructedConstantValue(type, fields);
  }

  ConstantValue visitType(TypeConstantValue constant, _) {
    var type = _handleType(constant.type);
    var representedType = _handleType(constant.representedType);
    if (type == constant.type && representedType == constant.representedType) {
      return constant;
    }
    return new TypeConstantValue(representedType, type);
  }

  ConstantValue visitInterceptor(InterceptorConstantValue constant, _) {
    return new InterceptorConstantValue(toBackendEntity(constant.cls));
  }

  ConstantValue visitDeferred(DeferredConstantValue constant, _) {
    var referenced = constant.referenced.accept(this, null);
    if (referenced == constant.referenced) return constant;
    // TODO(sigmund): do we need a JImport entity?
    return new DeferredConstantValue(referenced, constant.import);
  }

  DartType _handleType(DartType type) {
    if (type is InterfaceType) {
      var element = toBackendEntity(type.element);
      var args = type.typeArguments.map(_handleType).toList();
      return new InterfaceType(element, args);
    }

    // TODO(redemption): handle other types.
    return type;
  }

  List<ConstantValue> _handleValues(List<ConstantValue> values) {
    List<ConstantValue> result;
    for (int i = 0; i < values.length; i++) {
      var value = values[i];
      var newValue = value.accept(this, null);
      if (newValue != value && result == null) {
        result = values.sublist(0, i).toList();
      }
      result?.add(newValue);
    }
    return result ?? values;
  }
}
