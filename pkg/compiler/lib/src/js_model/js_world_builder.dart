// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common_elements.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../deferred_load.dart';
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../ir/closure.dart';
import '../js_backend/annotations.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/field_analysis.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types_resolution.dart';
import '../kernel/kelements.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../universe/class_hierarchy.dart';
import '../universe/class_set.dart';
import '../universe/feature.dart';
import '../universe/member_usage.dart';
import '../universe/selector.dart';
import '../world.dart';
import 'closure.dart';
import 'elements.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'js_world.dart';
import 'locals.dart';

class JsClosedWorldBuilder {
  final JsKernelToElementMap _elementMap;
  final Map<ClassEntity, ClassHierarchyNode> _classHierarchyNodes =
      new ClassHierarchyNodesMap();
  final Map<ClassEntity, ClassSet> _classSets = <ClassEntity, ClassSet>{};
  final GlobalLocalsMap _globalLocalsMap;
  final ClosureDataBuilder _closureDataBuilder;
  final CompilerOptions _options;
  final AbstractValueStrategy _abstractValueStrategy;

  JsClosedWorldBuilder(this._elementMap, this._globalLocalsMap,
      this._closureDataBuilder, this._options, this._abstractValueStrategy);

  ElementEnvironment get _elementEnvironment => _elementMap.elementEnvironment;
  CommonElements get _commonElements => _elementMap.commonElements;
  DartTypes get _dartTypes => _elementMap.types;

  JsClosedWorld convertClosedWorld(
      KClosedWorld closedWorld,
      Map<MemberEntity, ClosureScopeModel> closureModels,
      OutputUnitData kOutputUnitData) {
    JsToFrontendMap map = new JsToFrontendMapImpl(_elementMap);

    NativeData nativeData = _convertNativeData(map, closedWorld.nativeData);
    _elementMap.nativeData = nativeData;
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

    closedWorld.classHierarchy
        .getClassHierarchyNode(closedWorld.commonElements.objectClass)
        .forEachSubclass((ClassEntity cls) {
      convertClassSet(closedWorld.classHierarchy.getClassSet(cls));
      return IterationStep.CONTINUE;
    }, ClassHierarchyNode.ALL);

    Set<MemberEntity> liveInstanceMembers =
        map.toBackendMemberSet(closedWorld.liveInstanceMembers);

    Map<ClassEntity, Set<ClassEntity>> mixinUses =
        map.toBackendClassMap(closedWorld.mixinUses, map.toBackendClassSet);

    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        map.toBackendClassMap(
            closedWorld.typesImplementedBySubclasses, map.toBackendClassSet);

    Set<MemberEntity> assignedInstanceMembers =
        map.toBackendMemberSet(closedWorld.assignedInstanceMembers);

    Set<ClassEntity> liveNativeClasses =
        map.toBackendClassSet(closedWorld.liveNativeClasses);

    Set<MemberEntity> processedMembers =
        map.toBackendMemberSet(closedWorld.liveMemberUsage.keys);

    Set<ClassEntity> extractTypeArgumentsInterfacesNewRti = {};

    RuntimeTypesNeed rtiNeed;

    List<FunctionEntity> callMethods = <FunctionEntity>[];
    ClosureData closureData;
    if (_options.disableRtiOptimization) {
      rtiNeed = new TrivialRuntimeTypesNeed(_elementMap.elementEnvironment);
      closureData = _closureDataBuilder.createClosureEntities(
          this,
          map.toBackendMemberMap(closureModels, identity),
          const TrivialClosureRtiNeed(),
          callMethods);
    } else {
      RuntimeTypesNeedImpl kernelRtiNeed = closedWorld.rtiNeed;
      Set<ir.LocalFunction> localFunctionsNodesNeedingSignature =
          new Set<ir.LocalFunction>();
      for (KLocalFunction localFunction
          in kernelRtiNeed.localFunctionsNeedingSignature) {
        ir.LocalFunction node = localFunction.node;
        localFunctionsNodesNeedingSignature.add(node);
      }
      Set<ir.LocalFunction> localFunctionsNodesNeedingTypeArguments =
          new Set<ir.LocalFunction>();
      for (KLocalFunction localFunction
          in kernelRtiNeed.localFunctionsNeedingTypeArguments) {
        ir.LocalFunction node = localFunction.node;
        localFunctionsNodesNeedingTypeArguments.add(node);
      }

      RuntimeTypesNeedImpl jRtiNeed =
          _convertRuntimeTypesNeed(map, kernelRtiNeed);
      closureData = _closureDataBuilder.createClosureEntities(
          this,
          map.toBackendMemberMap(closureModels, identity),
          new JsClosureRtiNeed(
              jRtiNeed,
              localFunctionsNodesNeedingTypeArguments,
              localFunctionsNodesNeedingSignature),
          callMethods);

      List<FunctionEntity> callMethodsNeedingSignature = <FunctionEntity>[];
      for (ir.LocalFunction node in localFunctionsNodesNeedingSignature) {
        callMethodsNeedingSignature
            .add(closureData.getClosureInfo(node).callMethod);
      }
      List<FunctionEntity> callMethodsNeedingTypeArguments = <FunctionEntity>[];
      for (ir.LocalFunction node in localFunctionsNodesNeedingTypeArguments) {
        callMethodsNeedingTypeArguments
            .add(closureData.getClosureInfo(node).callMethod);
      }
      jRtiNeed.methodsNeedingSignature.addAll(callMethodsNeedingSignature);
      jRtiNeed.methodsNeedingTypeArguments
          .addAll(callMethodsNeedingTypeArguments);

      rtiNeed = jRtiNeed;
    }

    map.registerClosureData(closureData);

    BackendUsage backendUsage =
        _convertBackendUsage(map, closedWorld.backendUsage);

    NoSuchMethodDataImpl oldNoSuchMethodData = closedWorld.noSuchMethodData;
    NoSuchMethodData noSuchMethodData = new NoSuchMethodDataImpl(
        map.toBackendFunctionSet(oldNoSuchMethodData.throwingImpls),
        map.toBackendFunctionSet(oldNoSuchMethodData.otherImpls),
        map.toBackendFunctionSet(oldNoSuchMethodData.forwardingSyntaxImpls));

    JFieldAnalysis allocatorAnalysis =
        JFieldAnalysis.from(closedWorld, map, _options);

    AnnotationsDataImpl oldAnnotationsData = closedWorld.annotationsData;
    AnnotationsData annotationsData = new AnnotationsDataImpl(_options,
        map.toBackendMemberMap(oldAnnotationsData.pragmaAnnotations, identity));

    OutputUnitData outputUnitData =
        _convertOutputUnitData(map, kOutputUnitData, closureData);

    Map<MemberEntity, MemberAccess> memberAccess = map.toBackendMemberMap(
        closedWorld.liveMemberUsage,
        (MemberUsage usage) =>
            new MemberAccess(usage.reads, usage.writes, usage.invokes));

    return new JsClosedWorld(
        _elementMap,
        nativeData,
        interceptorData,
        backendUsage,
        rtiNeed,
        allocatorAnalysis,
        noSuchMethodData,
        implementedClasses,
        liveNativeClasses,
        // TODO(johnniwinther): Include the call method when we can also
        // represent the synthesized call methods for static and instance method
        // closurizations.
        liveInstanceMembers /*..addAll(callMethods)*/,
        assignedInstanceMembers,
        processedMembers,
        extractTypeArgumentsInterfacesNewRti,
        mixinUses,
        typesImplementedBySubclasses,
        new ClassHierarchyImpl(
            _elementMap.commonElements, _classHierarchyNodes, _classSets),
        _abstractValueStrategy,
        annotationsData,
        _globalLocalsMap,
        closureData,
        outputUnitData,
        memberAccess);
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
    Set<RuntimeTypeUse> runtimeTypeUses =
        backendUsage.runtimeTypeUses.map((RuntimeTypeUse runtimeTypeUse) {
      return new RuntimeTypeUse(
          runtimeTypeUse.kind,
          map.toBackendType(runtimeTypeUse.receiverType),
          map.toBackendType(runtimeTypeUse.argumentType));
    }).toSet();

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
        runtimeTypeUses: runtimeTypeUses,
        isFunctionApplyUsed: backendUsage.isFunctionApplyUsed,
        isMirrorsUsed: backendUsage.isMirrorsUsed,
        isNoSuchMethodUsed: backendUsage.isNoSuchMethodUsed,
        isHtmlLoaded: backendUsage.isHtmlLoaded);
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
        nativeBasicData.isAllowInteropUsed,
        nativeClassTagInfo,
        jsInteropLibraries,
        jsInteropClasses,
        anonymousJsInteropClasses,
        jsInteropMembers);
  }

  NativeData _convertNativeData(
      JsToFrontendMap map, NativeDataImpl nativeData) {
    convertNativeBehaviorType(type) {
      if (type is DartType) {
        // TODO(johnniwinther): Avoid free variables in types. If the type
        // pulled from a generic function type it might contain a function
        // type variable that should probably have been replaced by its bound.
        return map.toBackendType(type, allowFreeVariables: true);
      }
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
      newBehavior.sideEffects.add(behavior.sideEffects);
      return newBehavior;
    }

    NativeBasicData nativeBasicData = _convertNativeBasicData(map, nativeData);

    Map<MemberEntity, String> nativeMemberName =
        map.toBackendMemberMap(nativeData.nativeMemberName, identity);
    Map<FunctionEntity, NativeBehavior> nativeMethodBehavior =
        <FunctionEntity, NativeBehavior>{};
    nativeData.nativeMethodBehavior
        .forEach((FunctionEntity method, NativeBehavior behavior) {
      FunctionEntity backendMethod = map.toBackendMember(method);
      if (backendMethod != null) {
        // If [method] isn't used it doesn't have a corresponding backend
        // method.
        nativeMethodBehavior[backendMethod] = convertNativeBehavior(behavior);
      }
    });
    Map<MemberEntity, NativeBehavior> nativeFieldLoadBehavior =
        map.toBackendMemberMap(
            nativeData.nativeFieldLoadBehavior, convertNativeBehavior);
    Map<MemberEntity, NativeBehavior> nativeFieldStoreBehavior =
        map.toBackendMemberMap(
            nativeData.nativeFieldStoreBehavior, convertNativeBehavior);
    return new NativeDataImpl(
        nativeBasicData,
        nativeMemberName,
        nativeMethodBehavior,
        nativeFieldLoadBehavior,
        nativeFieldStoreBehavior);
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
      JsToFrontendMap map, RuntimeTypesNeedImpl rtiNeed) {
    Set<ClassEntity> classesNeedingTypeArguments =
        map.toBackendClassSet(rtiNeed.classesNeedingTypeArguments);
    Set<FunctionEntity> methodsNeedingTypeArguments =
        map.toBackendFunctionSet(rtiNeed.methodsNeedingTypeArguments);
    Set<FunctionEntity> methodsNeedingSignature =
        map.toBackendFunctionSet(rtiNeed.methodsNeedingSignature);
    Set<Selector> selectorsNeedingTypeArguments =
        rtiNeed.selectorsNeedingTypeArguments.map((Selector selector) {
      if (selector.memberName.isPrivate) {
        return new Selector(
            selector.kind,
            new PrivateName(selector.memberName.text,
                map.toBackendLibrary(selector.memberName.library),
                isSetter: selector.memberName.isSetter),
            selector.callStructure);
      }
      return selector;
    }).toSet();
    return new RuntimeTypesNeedImpl(
        _elementEnvironment,
        classesNeedingTypeArguments,
        methodsNeedingSignature,
        methodsNeedingTypeArguments,
        null,
        null,
        selectorsNeedingTypeArguments,
        rtiNeed.instantiationsNeedingTypeArguments);
  }

  /// Construct a closure class and set up the necessary class inference
  /// hierarchy.
  KernelClosureClassInfo buildClosureClass(
      MemberEntity member,
      ir.FunctionNode originalClosureFunctionNode,
      JLibrary enclosingLibrary,
      Map<Local, JRecordField> boxedVariables,
      KernelScopeInfo info,
      KernelToLocalsMap localsMap,
      {bool createSignatureMethod}) {
    ClassEntity superclass = _commonElements.closureClass;

    KernelClosureClassInfo closureClassInfo = _elementMap.constructClosureClass(
        member,
        originalClosureFunctionNode,
        enclosingLibrary,
        boxedVariables,
        info,
        localsMap,
        _dartTypes.interfaceType(superclass, const []),
        createSignatureMethod: createSignatureMethod);

    // Tell the hierarchy that this is the super class. then we can use
    // .getSupertypes(class)
    ClassHierarchyNode parentNode = _classHierarchyNodes[superclass];
    ClassHierarchyNode node = new ClassHierarchyNode(parentNode,
        closureClassInfo.closureClassEntity, parentNode.hierarchyDepth + 1);
    _classHierarchyNodes[closureClassInfo.closureClassEntity] = node;
    _classSets[closureClassInfo.closureClassEntity] = new ClassSet(node);
    node.isDirectlyInstantiated = true;

    return closureClassInfo;
  }

  OutputUnitData _convertOutputUnitData(JsToFrontendMapImpl map,
      OutputUnitData data, ClosureData closureDataLookup) {
    // Convert front-end maps containing K-class and K-local function keys to a
    // backend map using J-classes as keys.
    Map<ClassEntity, OutputUnit> convertClassMap(
        Map<ClassEntity, OutputUnit> classMap,
        Map<Local, OutputUnit> localFunctionMap) {
      var result = <ClassEntity, OutputUnit>{};
      classMap.forEach((ClassEntity entity, OutputUnit unit) {
        ClassEntity backendEntity = map.toBackendClass(entity);
        if (backendEntity != null) {
          // If [entity] isn't used it doesn't have a corresponding backend
          // entity.
          result[backendEntity] = unit;
        }
      });
      localFunctionMap.forEach((Local entity, OutputUnit unit) {
        // Ensure closure classes are included in the output unit corresponding
        // to the local function.
        if (entity is KLocalFunction) {
          var closureInfo = closureDataLookup.getClosureInfo(entity.node);
          result[closureInfo.closureClassEntity] = unit;
        }
      });
      return result;
    }

    // Convert front-end maps containing K-member and K-local function keys to
    // a backend map using J-members as keys.
    Map<MemberEntity, OutputUnit> convertMemberMap(
        Map<MemberEntity, OutputUnit> memberMap,
        Map<Local, OutputUnit> localFunctionMap) {
      var result = <MemberEntity, OutputUnit>{};
      memberMap.forEach((MemberEntity entity, OutputUnit unit) {
        MemberEntity backendEntity = map.toBackendMember(entity);
        if (backendEntity != null) {
          // If [entity] isn't used it doesn't have a corresponding backend
          // entity.
          result[backendEntity] = unit;
        }
      });
      localFunctionMap.forEach((Local entity, OutputUnit unit) {
        // Ensure closure call-methods are included in the output unit
        // corresponding to the local function.
        if (entity is KLocalFunction) {
          var closureInfo = closureDataLookup.getClosureInfo(entity.node);
          result[closureInfo.callMethod] = unit;
          if (closureInfo.signatureMethod != null) {
            result[closureInfo.signatureMethod] = unit;
          }
        }
      });
      return result;
    }

    return new OutputUnitData.from(
        data,
        map.toBackendLibrary,
        convertClassMap,
        convertMemberMap,
        (m) => convertMap<ConstantValue, OutputUnit, OutputUnit>(
            m, map.toBackendConstant, (v) => v));
  }
}

class TrivialClosureRtiNeed implements ClosureRtiNeed {
  const TrivialClosureRtiNeed();

  @override
  bool localFunctionNeedsSignature(ir.Node node) => true;

  @override
  bool classNeedsTypeArguments(ClassEntity cls) => true;

  @override
  bool methodNeedsTypeArguments(FunctionEntity method) => true;

  @override
  bool localFunctionNeedsTypeArguments(ir.Node node) => true;

  @override
  bool selectorNeedsTypeArguments(Selector selector) => true;

  @override
  bool methodNeedsSignature(MemberEntity method) => true;

  @override
  bool instantiationNeedsTypeArguments(
          DartType functionType, int typeArgumentCount) =>
      true;
}

class JsClosureRtiNeed implements ClosureRtiNeed {
  final RuntimeTypesNeed rtiNeed;
  final Set<ir.LocalFunction> localFunctionsNodesNeedingTypeArguments;
  final Set<ir.LocalFunction> localFunctionsNodesNeedingSignature;

  JsClosureRtiNeed(this.rtiNeed, this.localFunctionsNodesNeedingTypeArguments,
      this.localFunctionsNodesNeedingSignature);

  @override
  bool localFunctionNeedsSignature(ir.LocalFunction node) {
    return localFunctionsNodesNeedingSignature.contains(node);
  }

  @override
  bool classNeedsTypeArguments(ClassEntity cls) =>
      rtiNeed.classNeedsTypeArguments(cls);

  @override
  bool methodNeedsTypeArguments(FunctionEntity method) =>
      rtiNeed.methodNeedsTypeArguments(method);

  @override
  bool localFunctionNeedsTypeArguments(ir.LocalFunction node) {
    return localFunctionsNodesNeedingTypeArguments.contains(node);
  }

  @override
  bool selectorNeedsTypeArguments(Selector selector) =>
      rtiNeed.selectorNeedsTypeArguments(selector);

  @override
  bool methodNeedsSignature(MemberEntity method) =>
      rtiNeed.methodNeedsSignature(method);

  @override
  bool instantiationNeedsTypeArguments(
          DartType functionType, int typeArgumentCount) =>
      rtiNeed.instantiationNeedsTypeArguments(functionType, typeArgumentCount);
}

/// Map from 'frontend' to 'backend' elements.
///
/// Frontend elements are what we read in, these typically represents concepts
/// in Dart. Backend elements are what we generate, these may include elements
/// that do not correspond to a Dart concept, such as closure classes.
///
/// Querying for the frontend element for a backend-only element throws an
/// exception.
abstract class JsToFrontendMap {
  LibraryEntity toBackendLibrary(LibraryEntity library);

  ClassEntity toBackendClass(ClassEntity cls);

  /// Returns the backend member corresponding to [member]. If a member isn't
  /// live, it doesn't have a corresponding backend member and `null` is
  /// returned instead.
  MemberEntity toBackendMember(MemberEntity member);

  DartType toBackendType(DartType type, {bool allowFreeVariables: false});

  ConstantValue toBackendConstant(ConstantValue value, {bool allowNull: false});

  /// Register [closureData] with this map.
  ///
  /// [ClosureData] holds the relation between local function and the backend
  /// entities. Before this has been registered, type variables of local
  /// functions cannot be converted into backend equivalents.
  void registerClosureData(ClosureData closureData);

  Set<LibraryEntity> toBackendLibrarySet(Iterable<LibraryEntity> set) {
    return set.map(toBackendLibrary).toSet();
  }

  Set<ClassEntity> toBackendClassSet(Iterable<ClassEntity> set) {
    // TODO(johnniwinther): Filter unused classes.
    return set.map(toBackendClass).toSet();
  }

  Set<MemberEntity> toBackendMemberSet(Iterable<MemberEntity> set) {
    return set.map(toBackendMember).where((MemberEntity member) {
      // Members that are not live don't have a corresponding backend member.
      return member != null;
    }).toSet();
  }

  Set<FieldEntity> toBackendFieldSet(Iterable<FieldEntity> set) {
    Set<FieldEntity> newSet = new Set<FieldEntity>();
    for (FieldEntity element in set) {
      FieldEntity backendField = toBackendMember(element);
      if (backendField != null) {
        // Members that are not live don't have a corresponding backend member.
        newSet.add(backendField);
      }
    }
    return newSet;
  }

  Set<FunctionEntity> toBackendFunctionSet(Iterable<FunctionEntity> set) {
    Set<FunctionEntity> newSet = new Set<FunctionEntity>();
    for (FunctionEntity element in set) {
      FunctionEntity backendFunction = toBackendMember(element);
      if (backendFunction != null) {
        // Members that are not live don't have a corresponding backend member.
        newSet.add(backendFunction);
      }
    }
    return newSet;
  }

  Map<LibraryEntity, V> toBackendLibraryMap<V>(
      Map<LibraryEntity, V> map, V convert(V value)) {
    return convertMap(map, toBackendLibrary, convert);
  }

  Map<ClassEntity, V> toBackendClassMap<V>(
      Map<ClassEntity, V> map, V convert(V value)) {
    return convertMap(map, toBackendClass, convert);
  }

  Map<MemberEntity, V2> toBackendMemberMap<V1, V2>(
      Map<MemberEntity, V1> map, V2 convert(V1 value)) {
    return convertMap(map, toBackendMember, convert);
  }
}

E identity<E>(E element) => element;

Map<K, V2> convertMap<K, V1, V2>(
    Map<K, V1> map, K convertKey(K key), V2 convertValue(V1 value)) {
  Map<K, V2> newMap = <K, V2>{};
  map.forEach((K key, V1 value) {
    K newKey = convertKey(key);
    V2 newValue = convertValue(value);
    if (newKey != null && newValue != null) {
      // Entities that are not used don't have a corresponding backend entity.
      newMap[newKey] = newValue;
    }
  });
  return newMap;
}

class JsToFrontendMapImpl extends JsToFrontendMap {
  final JsKernelToElementMap _backend;
  ClosureData _closureData;

  JsToFrontendMapImpl(this._backend);

  @override
  DartType toBackendType(DartType type, {bool allowFreeVariables: false}) =>
      type == null
          ? null
          : new _TypeConverter(_backend.types,
                  allowFreeVariables: allowFreeVariables)
              .visit(type, toBackendEntity);

  Entity toBackendEntity(Entity entity) {
    if (entity is ClassEntity) return toBackendClass(entity);
    if (entity is MemberEntity) return toBackendMember(entity);
    if (entity is TypeVariableEntity) {
      return toBackendTypeVariable(entity);
    }
    assert(entity is LibraryEntity, 'unexpected entity ${entity.runtimeType}');
    return toBackendLibrary(entity);
  }

  @override
  LibraryEntity toBackendLibrary(covariant IndexedLibrary library) {
    return _backend.libraries.getEntity(library.libraryIndex);
  }

  @override
  ClassEntity toBackendClass(covariant IndexedClass cls) {
    return _backend.classes.getEntity(cls.classIndex);
  }

  @override
  MemberEntity toBackendMember(covariant IndexedMember member) {
    return _backend.members.getEntity(member.memberIndex);
  }

  @override
  void registerClosureData(ClosureData closureData) {
    assert(_closureData == null, "Closure data has already been registered.");
    _closureData = closureData;
  }

  TypeVariableEntity toBackendTypeVariable(TypeVariableEntity typeVariable) {
    if (typeVariable is KLocalTypeVariable) {
      if (_closureData == null) {
        failedAt(
            typeVariable, "Local function type variables are not supported.");
      }
      ClosureRepresentationInfo info =
          _closureData.getClosureInfo(typeVariable.typeDeclaration.node);
      return _backend.elementEnvironment
          .getFunctionTypeVariables(info.callMethod)[typeVariable.index]
          .element;
    }
    IndexedTypeVariable indexedTypeVariable = typeVariable;
    return _backend.typeVariables
        .getEntity(indexedTypeVariable.typeVariableIndex);
  }

  @override
  ConstantValue toBackendConstant(ConstantValue constant,
      {bool allowNull: false}) {
    if (constant == null) {
      if (!allowNull) {
        throw new UnsupportedError('Null not allowed as constant value.');
      }
      return null;
    }
    return constant.accept(
        new _ConstantConverter(_backend.types, toBackendEntity), null);
  }
}

typedef Entity _EntityConverter(Entity cls);

class _TypeConverter implements DartTypeVisitor<DartType, _EntityConverter> {
  final DartTypes _dartTypes;
  final bool allowFreeVariables;

  Map<FunctionTypeVariable, FunctionTypeVariable> _functionTypeVariables =
      <FunctionTypeVariable, FunctionTypeVariable>{};

  _TypeConverter(this._dartTypes, {this.allowFreeVariables: false});

  List<DartType> convertTypes(
          List<DartType> types, _EntityConverter converter) =>
      visitList(types, converter);

  @override
  DartType visit(DartType type, _EntityConverter converter) {
    return type.accept(this, converter);
  }

  List<DartType> visitList(List<DartType> types, _EntityConverter converter) {
    List<DartType> list = <DartType>[];
    for (DartType type in types) {
      list.add(visit(type, converter));
    }
    return list;
  }

  @override
  DartType visitLegacyType(LegacyType type, _EntityConverter converter) =>
      _dartTypes.legacyType(visit(type.baseType, converter));

  @override
  DartType visitNullableType(NullableType type, _EntityConverter converter) =>
      _dartTypes.nullableType(visit(type.baseType, converter));

  @override
  DartType visitNeverType(NeverType type, _EntityConverter converter) => type;

  @override
  DartType visitDynamicType(DynamicType type, _EntityConverter converter) =>
      type;

  @override
  DartType visitErasedType(ErasedType type, _EntityConverter converter) => type;

  @override
  DartType visitAnyType(AnyType type, _EntityConverter converter) => type;

  @override
  DartType visitInterfaceType(InterfaceType type, _EntityConverter converter) {
    return _dartTypes.interfaceType(
        converter(type.element), visitList(type.typeArguments, converter));
  }

  @override
  DartType visitTypeVariableType(
      TypeVariableType type, _EntityConverter converter) {
    return _dartTypes.typeVariableType(converter(type.element));
  }

  @override
  DartType visitFunctionType(FunctionType type, _EntityConverter converter) {
    List<FunctionTypeVariable> typeVariables = <FunctionTypeVariable>[];
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      typeVariables.add(_functionTypeVariables[typeVariable] =
          _dartTypes.functionTypeVariable(typeVariable.index));
    }
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      _functionTypeVariables[typeVariable].bound = typeVariable.bound != null
          ? visit(typeVariable.bound, converter)
          : null;
    }
    DartType returnType = visit(type.returnType, converter);
    List<DartType> parameterTypes = visitList(type.parameterTypes, converter);
    List<DartType> optionalParameterTypes =
        visitList(type.optionalParameterTypes, converter);
    List<DartType> namedParameterTypes =
        visitList(type.namedParameterTypes, converter);
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      _functionTypeVariables.remove(typeVariable);
    }
    return _dartTypes.functionType(
        returnType,
        parameterTypes,
        optionalParameterTypes,
        type.namedParameters,
        type.requiredNamedParameters,
        namedParameterTypes,
        typeVariables);
  }

  @override
  DartType visitFunctionTypeVariable(
      FunctionTypeVariable type, _EntityConverter converter) {
    DartType result = _functionTypeVariables[type];
    if (result == null && allowFreeVariables) {
      return type;
    }
    assert(result != null,
        "Function type variable $type not found in $_functionTypeVariables");
    return result;
  }

  @override
  DartType visitVoidType(VoidType type, _EntityConverter converter) =>
      _dartTypes.voidType();

  @override
  DartType visitFutureOrType(FutureOrType type, _EntityConverter converter) =>
      _dartTypes.futureOrType(visit(type.typeArgument, converter));
}

class _ConstantConverter implements ConstantValueVisitor<ConstantValue, Null> {
  final DartTypes _dartTypes;
  final Entity Function(Entity) toBackendEntity;
  final _TypeConverter typeConverter;

  _ConstantConverter(this._dartTypes, this.toBackendEntity)
      : typeConverter = new _TypeConverter(_dartTypes);

  @override
  ConstantValue visitNull(NullConstantValue constant, _) => constant;
  @override
  ConstantValue visitInt(IntConstantValue constant, _) => constant;
  @override
  ConstantValue visitDouble(DoubleConstantValue constant, _) => constant;
  @override
  ConstantValue visitBool(BoolConstantValue constant, _) => constant;
  @override
  ConstantValue visitString(StringConstantValue constant, _) => constant;
  @override
  ConstantValue visitDummyInterceptor(
          DummyInterceptorConstantValue constant, _) =>
      constant;
  @override
  ConstantValue visitUnreachable(UnreachableConstantValue constant, _) =>
      constant;
  @override
  ConstantValue visitJsName(JsNameConstantValue constant, _) => constant;
  @override
  ConstantValue visitNonConstant(NonConstantValue constant, _) => constant;

  @override
  ConstantValue visitFunction(FunctionConstantValue constant, _) {
    return new FunctionConstantValue(toBackendEntity(constant.element),
        typeConverter.visit(constant.type, toBackendEntity));
  }

  @override
  ConstantValue visitList(ListConstantValue constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    List<ConstantValue> entries = _handleValues(constant.entries);
    if (identical(entries, constant.entries) && type == constant.type) {
      return constant;
    }
    return new ListConstantValue(type, entries);
  }

  @override
  ConstantValue visitSet(
      covariant constant_system.JavaScriptSetConstant constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    MapConstantValue entries = constant.entries.accept(this, null);
    if (identical(entries, constant.entries) && type == constant.type) {
      return constant;
    }
    return new constant_system.JavaScriptSetConstant(type, entries);
  }

  @override
  ConstantValue visitMap(
      covariant constant_system.JavaScriptMapConstant constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    ListConstantValue keys = constant.keyList.accept(this, null);
    List<ConstantValue> values = _handleValues(constant.values);
    ConstantValue protoValue = constant.protoValue?.accept(this, null);
    if (identical(keys, constant.keys) &&
        identical(values, constant.values) &&
        type == constant.type &&
        protoValue == constant.protoValue) {
      return constant;
    }
    return new constant_system.JavaScriptMapConstant(
        type, keys, values, protoValue, constant.onlyStringKeys);
  }

  @override
  ConstantValue visitConstructed(ConstructedConstantValue constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    Map<FieldEntity, ConstantValue> fields = {};
    constant.fields.forEach((f, v) {
      FieldEntity backendField = toBackendEntity(f);
      assert(backendField != null, "No backend field for $f.");
      fields[backendField] = v.accept(this, null);
    });
    return new ConstructedConstantValue(type, fields);
  }

  @override
  ConstantValue visitType(TypeConstantValue constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    DartType representedType =
        typeConverter.visit(constant.representedType, toBackendEntity);
    if (type == constant.type && representedType == constant.representedType) {
      return constant;
    }
    return new TypeConstantValue(representedType, type);
  }

  @override
  ConstantValue visitInterceptor(InterceptorConstantValue constant, _) {
    // Interceptor constants are only created in the SSA graph builder.
    throw new UnsupportedError(
        "Unexpected visitInterceptor ${constant.toStructuredText(_dartTypes)}");
  }

  @override
  ConstantValue visitDeferredGlobal(DeferredGlobalConstantValue constant, _) {
    // Deferred global constants are only created in the SSA graph builder.
    throw new UnsupportedError(
        "Unexpected DeferredGlobalConstantValue ${constant.toStructuredText(_dartTypes)}");
  }

  @override
  ConstantValue visitInstantiation(InstantiationConstantValue constant, _) {
    ConstantValue function = constant.function.accept(this, null);
    List<DartType> typeArguments =
        typeConverter.convertTypes(constant.typeArguments, toBackendEntity);
    return new InstantiationConstantValue(typeArguments, function);
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
