// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common/elements.dart';
import '../constants/values.dart';
import '../deferred_load/output_unit.dart' show OutputUnit, OutputUnitData;
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_strategy.dart';
import '../ir/closure.dart';
import '../js_backend/annotations.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/field_analysis.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types_resolution.dart';
import '../kernel/kernel_world.dart';
import '../options.dart';
import '../universe/class_hierarchy.dart';
import '../universe/class_set.dart';
import '../universe/feature.dart';
import '../universe/member_usage.dart';
import '../universe/record_shape.dart';
import '../universe/selector.dart';
import 'closure.dart';
import 'elements.dart';
import 'element_map_impl.dart';
import 'js_to_frontend_map.dart';
import 'js_world.dart';
import 'records.dart';

class JClosedWorldBuilder {
  final JsKernelToElementMap _elementMap;
  final Map<ClassEntity, ClassHierarchyNode> _classHierarchyNodes =
      ClassHierarchyNodesMap();
  final Map<ClassEntity, ClassSet> _classSets = <ClassEntity, ClassSet>{};
  final ClosureDataBuilder _closureDataBuilder;
  final RecordDataBuilder _recordDataBuilder;
  final CompilerOptions _options;
  final DiagnosticReporter _reporter;
  final AbstractValueStrategy _abstractValueStrategy;

  JClosedWorldBuilder(
      this._elementMap,
      this._closureDataBuilder,
      this._recordDataBuilder,
      this._options,
      this._reporter,
      this._abstractValueStrategy);

  ElementEnvironment get _elementEnvironment => _elementMap.elementEnvironment;
  CommonElements get _commonElements => _elementMap.commonElements;
  DartTypes get _dartTypes => _elementMap.types;

  JClosedWorld convertClosedWorld(
      KClosedWorld closedWorld,
      Map<MemberEntity, ClosureScopeModel> closureModels,
      OutputUnitData kOutputUnitData) {
    final map = JsToFrontendMap(_elementMap);

    NativeData nativeData =
        closedWorld.nativeData.convert(map, _elementEnvironment);
    _elementMap.nativeData = nativeData;
    InterceptorData interceptorData = _convertInterceptorData(
        map, nativeData, closedWorld.interceptorData as InterceptorDataImpl);

    Set<ClassEntity> implementedClasses = Set<ClassEntity>();

    /// Converts [node] from the frontend world to the corresponding
    /// [ClassHierarchyNode] for the backend world.
    ClassHierarchyNode convertClassHierarchyNode(ClassHierarchyNode node) {
      ClassEntity cls = map.toBackendClass(node.cls);
      if (closedWorld.isImplemented(node.cls)) {
        implementedClasses.add(cls);
      }
      ClassHierarchyNode newNode = _classHierarchyNodes.putIfAbsent(cls, () {
        ClassHierarchyNode? parentNode;
        if (node.parentNode != null) {
          parentNode = convertClassHierarchyNode(node.parentNode!);
        }
        return ClassHierarchyNode(
            parentNode, cls as IndexedClass, node.hierarchyDepth);
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
        ClassSet newClassSet = ClassSet(newNode);
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
    Set<MemberEntity> liveAbstractInstanceMembers =
        map.toBackendMemberSet(closedWorld.liveAbstractInstanceMembers);

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
    RecordData recordData;

    if (_options.disableRtiOptimization) {
      rtiNeed = TrivialRuntimeTypesNeed(_elementMap.elementEnvironment);
      closureData = _closureDataBuilder.createClosureEntities(
          this,
          map.toBackendMemberMap(closureModels, identity),
          const TrivialClosureRtiNeed(),
          callMethods);
    } else {
      RuntimeTypesNeedImpl kernelRtiNeed =
          closedWorld.rtiNeed as RuntimeTypesNeedImpl;
      Set<ir.LocalFunction> localFunctionsNodesNeedingSignature =
          Set<ir.LocalFunction>();
      for (Local localFunction
          in kernelRtiNeed.localFunctionsNeedingSignature) {
        ir.LocalFunction node = (localFunction as JLocalFunction).node;
        localFunctionsNodesNeedingSignature.add(node);
      }
      Set<ir.LocalFunction> localFunctionsNodesNeedingTypeArguments =
          Set<ir.LocalFunction>();
      for (Local localFunction
          in kernelRtiNeed.localFunctionsNeedingTypeArguments) {
        ir.LocalFunction node = (localFunction as JLocalFunction).node;
        localFunctionsNodesNeedingTypeArguments.add(node);
      }

      RuntimeTypesNeedImpl jRtiNeed =
          _convertRuntimeTypesNeed(map, kernelRtiNeed);
      closureData = _closureDataBuilder.createClosureEntities(
          this,
          map.toBackendMemberMap(closureModels, identity),
          JsClosureRtiNeed(jRtiNeed, localFunctionsNodesNeedingTypeArguments,
              localFunctionsNodesNeedingSignature),
          callMethods);

      List<FunctionEntity> callMethodsNeedingSignature = <FunctionEntity>[];
      for (ir.LocalFunction node in localFunctionsNodesNeedingSignature) {
        callMethodsNeedingSignature
            .add(closureData.getClosureInfo(node).callMethod!);
      }
      List<FunctionEntity> callMethodsNeedingTypeArguments = <FunctionEntity>[];
      for (ir.LocalFunction node in localFunctionsNodesNeedingTypeArguments) {
        callMethodsNeedingTypeArguments
            .add(closureData.getClosureInfo(node).callMethod!);
      }
      jRtiNeed.methodsNeedingSignature.addAll(callMethodsNeedingSignature);
      jRtiNeed.methodsNeedingTypeArguments
          .addAll(callMethodsNeedingTypeArguments);

      rtiNeed = jRtiNeed;
    }

    map.registerClosureData(closureData);
    final recordTypes = Set<RecordType>.from(
        map.toBackendTypeSet(closedWorld.instantiatedRecordTypes));
    recordData = _recordDataBuilder.createRecordData(this, recordTypes);

    BackendUsage backendUsage =
        _convertBackendUsage(map, closedWorld.backendUsage as BackendUsageImpl);

    NoSuchMethodData oldNoSuchMethodData = closedWorld.noSuchMethodData;
    NoSuchMethodData noSuchMethodData = NoSuchMethodData(
        map.toBackendFunctionSet(oldNoSuchMethodData.throwingImpls),
        map.toBackendFunctionSet(oldNoSuchMethodData.otherImpls),
        map.toBackendFunctionSet(oldNoSuchMethodData.forwardingSyntaxImpls));

    JFieldAnalysis allocatorAnalysis =
        JFieldAnalysis.from(closedWorld, map, _options);

    AnnotationsDataImpl oldAnnotationsData =
        closedWorld.annotationsData as AnnotationsDataImpl;
    AnnotationsData annotationsData = AnnotationsDataImpl(_options, _reporter,
        map.toBackendMemberMap(oldAnnotationsData.pragmaAnnotations, identity));

    OutputUnitData outputUnitData =
        _convertOutputUnitData(map, kOutputUnitData, closureData);

    Map<MemberEntity, MemberAccess> memberAccess = map.toBackendMemberMap(
        closedWorld.liveMemberUsage,
        (MemberUsage usage) =>
            MemberAccess(usage.reads, usage.writes, usage.invokes));

    return JClosedWorld(
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
        liveAbstractInstanceMembers,
        assignedInstanceMembers,
        processedMembers,
        extractTypeArgumentsInterfacesNewRti,
        mixinUses,
        typesImplementedBySubclasses,
        ClassHierarchyImpl(
            _elementMap.commonElements, _classHierarchyNodes, _classSets),
        _abstractValueStrategy,
        annotationsData,
        closureData,
        recordData,
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
      return RuntimeTypeUse(
          runtimeTypeUse.kind,
          map.toBackendType(runtimeTypeUse.receiverType)!,
          map.toBackendType(runtimeTypeUse.argumentType));
    }).toSet();

    return BackendUsageImpl(
        globalFunctionDependencies: globalFunctionDependencies,
        globalClassDependencies: globalClassDependencies,
        helperFunctionsUsed: helperFunctionsUsed,
        helperClassesUsed: helperClassesUsed,
        needToInitializeIsolateAffinityTag:
            backendUsage.needToInitializeIsolateAffinityTag,
        needToInitializeDispatchProperty:
            backendUsage.needToInitializeDispatchProperty,
        requiresPreamble: backendUsage.requiresPreamble,
        requiresStartupMetrics: backendUsage.requiresStartupMetrics,
        runtimeTypeUses: runtimeTypeUses,
        isFunctionApplyUsed: backendUsage.isFunctionApplyUsed,
        isNoSuchMethodUsed: backendUsage.isNoSuchMethodUsed,
        isHtmlLoaded: backendUsage.isHtmlLoaded);
  }

  InterceptorDataImpl _convertInterceptorData(JsToFrontendMap map,
      NativeData nativeData, InterceptorDataImpl interceptorData) {
    Map<String, Set<MemberEntity>> interceptedMembers =
        <String, Set<MemberEntity>>{};
    interceptorData.interceptedMembers
        .forEach((String name, Set<MemberEntity> members) {
      interceptedMembers[name] = map.toBackendMemberSet(members);
    });
    return InterceptorDataImpl(
        nativeData,
        _commonElements,
        interceptedMembers,
        map.toBackendClassSet(interceptorData.interceptedClasses),
        map.toBackendClassSet(
            interceptorData.classesMixedIntoInterceptedClasses));
  }

  RuntimeTypesNeedImpl _convertRuntimeTypesNeed(
      JsToFrontendMap map, RuntimeTypesNeedImpl rtiNeed) {
    Set<ClassEntity> classesNeedingTypeArguments =
        map.toBackendClassSet(rtiNeed.classesNeedingTypeArguments);
    Set<FunctionEntity> methodsNeedingTypeArguments =
        map.toBackendFunctionSet(rtiNeed.methodsNeedingTypeArguments);
    Set<FunctionEntity> methodsNeedingSignature =
        map.toBackendFunctionSet(rtiNeed.methodsNeedingSignature);
    Set<Selector> selectorsNeedingTypeArguments =
        rtiNeed.selectorsNeedingTypeArguments;
    return RuntimeTypesNeedImpl(
        _elementEnvironment,
        classesNeedingTypeArguments,
        methodsNeedingSignature,
        methodsNeedingTypeArguments,
        const {},
        const {},
        selectorsNeedingTypeArguments,
        rtiNeed.instantiationsNeedingTypeArguments);
  }

  /// Construct a closure class and set up the necessary class inference
  /// hierarchy.
  JsClosureClassInfo buildClosureClass(
      MemberEntity member,
      ir.FunctionNode originalClosureFunctionNode,
      JLibrary enclosingLibrary,
      Map<ir.VariableDeclaration, JContextField> boxedVariables,
      KernelScopeInfo info,
      {required bool createSignatureMethod}) {
    ClassEntity superclass =
        _chooseClosureSuperclass(originalClosureFunctionNode);

    JsClosureClassInfo closureClassInfo = _elementMap.constructClosureClass(
        member,
        originalClosureFunctionNode,
        enclosingLibrary,
        boxedVariables,
        info,
        _dartTypes.interfaceType(superclass, const []),
        createSignatureMethod: createSignatureMethod);

    // Tell the hierarchy that this is the super class. then we can use
    // .getSupertypes(class)
    ClassHierarchyNode parentNode = _classHierarchyNodes[superclass]!;
    ClassHierarchyNode node = ClassHierarchyNode(parentNode,
        closureClassInfo.closureClassEntity, parentNode.hierarchyDepth + 1);
    _classHierarchyNodes[closureClassInfo.closureClassEntity] = node;
    _classSets[closureClassInfo.closureClassEntity] = ClassSet(node);
    node.isDirectlyInstantiated = true;

    return closureClassInfo;
  }

  ClassEntity _chooseClosureSuperclass(ir.FunctionNode node) {
    // Choose a superclass so that similar closures can share the metadata used
    // by `Function.apply`.
    int requiredParameterCount = node.requiredParameterCount;
    if (node.typeParameters.isEmpty &&
        node.namedParameters.isEmpty &&
        requiredParameterCount == node.positionalParameters.length) {
      if (requiredParameterCount == 0) return _commonElements.closureClass0Args;
      if (requiredParameterCount == 2) return _commonElements.closureClass2Args;
    }
    // Note that the base closure class has specialized metadata for the common
    // case of single-argument functions.
    return _commonElements.closureClass;
  }

  /// Called once per [shape]. The class can be used for a record with the
  /// specified shape, or subclassed to provide specialized methods. [getters]
  /// is an out parameter that gathers all the getters created for this shape.
  ClassEntity buildRecordShapeClass(
      RecordShape shape, List<MemberEntity> getters) {
    ClassEntity superclass = _commonElements.recordArityClass(shape.fieldCount);
    IndexedClass recordClass = _elementMap.generateRecordShapeClass(
        shape, _dartTypes.interfaceType(superclass, const []), getters);

    // Tell the hierarchy about the superclass so we can use
    // .getSupertypes(class)
    ClassHierarchyNode parentNode = _classHierarchyNodes[superclass]!;
    ClassHierarchyNode node = ClassHierarchyNode(
        parentNode, recordClass, parentNode.hierarchyDepth + 1);
    _classHierarchyNodes[recordClass] = node;
    _classSets[recordClass] = ClassSet(node);
    node.isDirectlyInstantiated = true;

    return recordClass;
  }

  OutputUnitData _convertOutputUnitData(
      JsToFrontendMap map, OutputUnitData data, ClosureData closureDataLookup) {
    // Convert front-end maps containing K-class and K-local function keys to a
    // backend map using J-classes as keys.
    Map<ClassEntity, OutputUnit> convertClassMap(
        Map<ClassEntity, OutputUnit> classMap,
        Map<Local, OutputUnit> localFunctionMap) {
      final result = <ClassEntity, OutputUnit>{};
      classMap.forEach((ClassEntity entity, OutputUnit unit) {
        final backendEntity = map.toBackendClass(entity as IndexedClass);
        result[backendEntity] = unit;
      });
      localFunctionMap.forEach((Local entity, OutputUnit unit) {
        // Ensure closure classes are included in the output unit corresponding
        // to the local function.
        if (entity is JLocalFunction) {
          var closureInfo = closureDataLookup.getClosureInfo(entity.node);
          result[closureInfo.closureClassEntity!] = unit;
        }
      });
      return result;
    }

    // Convert front-end maps containing K-member and K-local function keys to
    // a backend map using J-members as keys.
    Map<MemberEntity, OutputUnit> convertMemberMap(
        Map<MemberEntity, OutputUnit> memberMap,
        Map<Local, OutputUnit> localFunctionMap) {
      final result = <MemberEntity, OutputUnit>{};
      memberMap.forEach((MemberEntity entity, OutputUnit unit) {
        MemberEntity? backendEntity =
            map.toBackendMember(entity as IndexedMember);
        if (backendEntity != null) {
          result[backendEntity] = unit;
        }
      });
      localFunctionMap.forEach((Local entity, OutputUnit unit) {
        // Ensure closure call-methods are included in the output unit
        // corresponding to the local function.
        if (entity is JLocalFunction) {
          var closureInfo = closureDataLookup.getClosureInfo(entity.node);
          result[closureInfo.callMethod!] = unit;
          if (closureInfo.signatureMethod != null) {
            result[closureInfo.signatureMethod!] = unit;
          }
        }
      });
      return result;
    }

    return OutputUnitData.from(
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
          FunctionType? functionType, int typeArgumentCount) =>
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
      rtiNeed.methodNeedsSignature(method as FunctionEntity);

  @override
  bool instantiationNeedsTypeArguments(
          FunctionType? functionType, int typeArgumentCount) =>
      rtiNeed.instantiationNeedsTypeArguments(functionType, typeArgumentCount);
}
