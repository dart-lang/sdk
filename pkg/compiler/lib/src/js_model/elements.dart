// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.elements;

import '../common_elements.dart';
import '../constants/constant_system.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../native/behavior.dart';
import '../ordered_typeset.dart';
import '../universe/class_set.dart';
import '../universe/function_set.dart';
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../world.dart';

/// Bidirectional map between 'frontend' and 'backend' elements.
///
/// Frontend elements are what we read in, these typically represents concepts
/// in Dart. Backend elements are what we generate, these may include elements
/// that do not correspond to a Dart concept, such as closure classes.
///
/// Querying for the frontend element for a backend-only element throws an
/// exception.
class JsToFrontendMap {
  LibraryEntity toBackendLibrary(LibraryEntity library) => library;
  LibraryEntity toFrontendLibrary(LibraryEntity library) => library;

  ClassEntity toBackendClass(ClassEntity cls) => cls;
  ClassEntity toFrontendClass(ClassEntity cls) => cls;

  MemberEntity toBackendMember(MemberEntity member) => member;
  MemberEntity toFrontendMember(MemberEntity member) => member;

  DartType toBackendType(DartType type) => type;
  DartType fromFrontendType(DartType type) => type;
}

class JsClosedWorld extends ClosedWorldBase {
  JsClosedWorld(
      {ElementEnvironment elementEnvironment,
      CommonElements commonElements,
      ConstantSystem constantSystem,
      NativeData nativeData,
      InterceptorData interceptorData,
      BackendUsage backendUsage,
      ResolutionWorldBuilder resolutionWorldBuilder,
      Set<ClassEntity> implementedClasses,
      FunctionSet functionSet,
      Set<TypedefElement> allTypedefs,
      Map<ClassEntity, Set<ClassEntity>> mixinUses,
      Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses,
      Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes,
      Map<ClassEntity, ClassSet> classSets})
      : super(
            elementEnvironment: elementEnvironment,
            commonElements: commonElements,
            constantSystem: constantSystem,
            nativeData: nativeData,
            interceptorData: interceptorData,
            backendUsage: backendUsage,
            resolutionWorldBuilder: resolutionWorldBuilder,
            implementedClasses: implementedClasses,
            functionSet: functionSet,
            allTypedefs: allTypedefs,
            mixinUses: mixinUses,
            typesImplementedBySubclasses: typesImplementedBySubclasses,
            classHierarchyNodes: classHierarchyNodes,
            classSets: classSets);

  @override
  bool hasConcreteMatch(ClassEntity cls, Selector selector,
      {ClassEntity stopAtSuperclass}) {
    throw new UnimplementedError('JsClosedWorld.hasConcreteMatch');
  }

  @override
  void registerClosureClass(ClassElement cls) {
    throw new UnimplementedError('JsClosedWorld.registerClosureClass');
  }

  @override
  bool hasElementIn(ClassEntity cls, Selector selector, Entity element) {
    throw new UnimplementedError('JsClosedWorld.hasElementIn');
  }

  @override
  bool checkEntity(Entity element) => true;

  @override
  bool checkClass(ClassEntity cls) => true;

  @override
  bool checkInvariants(ClassEntity cls, {bool mustBeInstantiated: true}) {
    return true;
  }

  @override
  OrderedTypeSet getOrderedTypeSet(ClassEntity cls) {
    throw new UnimplementedError('JsClosedWorld.getOrderedTypeSet');
  }

  @override
  int getHierarchyDepth(ClassEntity cls) {
    throw new UnimplementedError('JsClosedWorld.getHierarchyDepth');
  }

  @override
  ClassEntity getSuperClass(ClassEntity cls) {
    throw new UnimplementedError('JsClosedWorld.getSuperClass');
  }

  @override
  Iterable<ClassEntity> getInterfaces(ClassEntity cls) {
    throw new UnimplementedError('JsClosedWorld.getInterfaces');
  }

  @override
  ClassEntity getAppliedMixin(ClassEntity cls) {
    throw new UnimplementedError('JsClosedWorld.getAppliedMixin');
  }

  @override
  bool isNamedMixinApplication(ClassEntity cls) {
    throw new UnimplementedError('JsClosedWorld.isNamedMixinApplication');
  }
}

class JsNativeData implements NativeData {
  final JsToFrontendMap _map;
  final NativeData _nativeData;

  JsNativeData(this._map, this._nativeData);

  @override
  bool isNativeClass(ClassEntity element) {
    return _nativeData.isNativeClass(_map.toFrontendClass(element));
  }

  @override
  String computeUnescapedJSInteropName(String name) {
    return _nativeData.computeUnescapedJSInteropName(name);
  }

  @override
  String getJsInteropMemberName(MemberEntity element) {
    return _nativeData.getJsInteropMemberName(_map.toFrontendMember(element));
  }

  @override
  String getJsInteropClassName(ClassEntity element) {
    return _nativeData.getJsInteropClassName(_map.toFrontendClass(element));
  }

  @override
  bool isAnonymousJsInteropClass(ClassEntity element) {
    return _nativeData.isAnonymousJsInteropClass(_map.toFrontendClass(element));
  }

  @override
  String getJsInteropLibraryName(LibraryEntity element) {
    return _nativeData.getJsInteropLibraryName(_map.toFrontendLibrary(element));
  }

  @override
  bool isJsInteropMember(MemberEntity element) {
    return _nativeData.isJsInteropMember(_map.toFrontendMember(element));
  }

  @override
  String getFixedBackendMethodPath(FunctionEntity element) {
    return _nativeData
        .getFixedBackendMethodPath(_map.toFrontendMember(element));
  }

  @override
  String getFixedBackendName(MemberEntity element) {
    return _nativeData.getFixedBackendName(_map.toFrontendMember(element));
  }

  @override
  bool hasFixedBackendName(MemberEntity element) {
    return _nativeData.hasFixedBackendName(_map.toFrontendMember(element));
  }

  @override
  NativeBehavior getNativeFieldStoreBehavior(FieldEntity field) {
    return _nativeData
        .getNativeFieldStoreBehavior(_map.toFrontendMember(field));
  }

  @override
  NativeBehavior getNativeFieldLoadBehavior(FieldEntity field) {
    return _nativeData.getNativeFieldLoadBehavior(_map.toFrontendMember(field));
  }

  @override
  NativeBehavior getNativeMethodBehavior(FunctionEntity method) {
    return _nativeData.getNativeMethodBehavior(_map.toFrontendMember(method));
  }

  @override
  bool isNativeMember(MemberEntity element) {
    return _nativeData.isNativeMember(_map.toFrontendMember(element));
  }

  @override
  bool isJsInteropClass(ClassEntity element) {
    return _nativeData.isJsInteropClass(_map.toFrontendClass(element));
  }

  @override
  bool isJsInteropLibrary(LibraryEntity element) {
    return _nativeData.isJsInteropLibrary(_map.toFrontendLibrary(element));
  }

  @override
  bool get isJsInteropUsed {
    return _nativeData.isJsInteropUsed;
  }

  @override
  bool isNativeOrExtendsNative(ClassEntity element) {
    return _nativeData.isNativeOrExtendsNative(_map.toFrontendClass(element));
  }

  @override
  bool hasNativeTagsForcedNonLeaf(ClassEntity cls) {
    return _nativeData.hasNativeTagsForcedNonLeaf(_map.toFrontendClass(cls));
  }

  @override
  List<String> getNativeTagsOfClass(ClassEntity cls) {
    return _nativeData.getNativeTagsOfClass(_map.toFrontendClass(cls));
  }
}

class JsBackendUsage implements BackendUsage {
  final JsToFrontendMap _map;
  final BackendUsage _backendUsage;

  @override
  bool needToInitializeIsolateAffinityTag;
  @override
  bool needToInitializeDispatchProperty;

  JsBackendUsage(this._map, this._backendUsage) {
    needToInitializeIsolateAffinityTag =
        _backendUsage.needToInitializeIsolateAffinityTag;
    needToInitializeDispatchProperty =
        _backendUsage.needToInitializeDispatchProperty;
  }

  @override
  bool isFunctionUsedByBackend(FunctionEntity element) {
    return _backendUsage
        .isFunctionUsedByBackend(_map.toFrontendMember(element));
  }

  @override
  bool isFieldUsedByBackend(FieldEntity element) {
    return _backendUsage.isFieldUsedByBackend(_map.toFrontendMember(element));
  }

  @override
  Iterable<FunctionEntity> get globalFunctionDependencies {
    return _backendUsage.globalFunctionDependencies.map(_map.toBackendMember);
  }

  @override
  Iterable<ClassEntity> get globalClassDependencies {
    return _backendUsage.globalClassDependencies.map(_map.toBackendClass);
  }

  @override
  bool get requiresPreamble => _backendUsage.requiresPreamble;

  @override
  bool get isInvokeOnUsed => _backendUsage.isInvokeOnUsed;

  @override
  bool get isRuntimeTypeUsed => _backendUsage.isRuntimeTypeUsed;

  @override
  bool get isIsolateInUse => _backendUsage.isIsolateInUse;

  @override
  bool get isFunctionApplyUsed => _backendUsage.isFunctionApplyUsed;

  @override
  bool get isNoSuchMethodUsed => _backendUsage.isNoSuchMethodUsed;
}

class JsCommonElements implements CommonElements {
  final JsToFrontendMap _map;
  final CommonElements _commonElements;

  JsCommonElements(this._map, this._commonElements);

  @override
  ClassEntity get objectClass =>
      _map.toBackendClass(_commonElements.objectClass);

  @override
  ClassEntity get expectAssumeDynamicClass =>
      _map.toBackendClass(_commonElements.expectAssumeDynamicClass);

  @override
  ClassEntity get expectTrustTypeAnnotationsClass =>
      _map.toBackendClass(_commonElements.expectTrustTypeAnnotationsClass);

  @override
  ClassEntity get expectNoInlineClass =>
      _map.toBackendClass(_commonElements.expectNoInlineClass);

  @override
  FunctionEntity get callInIsolate =>
      _map.toBackendMember(_commonElements.callInIsolate);

  @override
  FunctionEntity get currentIsolate =>
      _map.toBackendMember(_commonElements.currentIsolate);

  @override
  FunctionEntity get startRootIsolate =>
      _map.toBackendMember(_commonElements.startRootIsolate);

  @override
  ClassEntity get jsBuiltinEnum =>
      _map.toBackendClass(_commonElements.jsBuiltinEnum);

  @override
  ClassEntity get jsGetNameEnum =>
      _map.toBackendClass(_commonElements.jsGetNameEnum);

  @override
  ClassEntity get typedArrayOfIntClass =>
      _map.toBackendClass(_commonElements.typedArrayOfIntClass);

  @override
  ClassEntity get typedArrayClass =>
      _map.toBackendClass(_commonElements.typedArrayClass);

  @override
  bool isSymbolValidatedConstructor(ConstructorEntity element) =>
      _commonElements
          .isSymbolValidatedConstructor(_map.toFrontendMember(element));

  @override
  FieldEntity get symbolImplementationField =>
      _map.toBackendMember(_commonElements.symbolImplementationField);

  @override
  ConstructorEntity get symbolValidatedConstructor =>
      _map.toBackendMember(_commonElements.symbolValidatedConstructor);

  @override
  final Selector symbolValidatedConstructorSelector = null;

  @override
  ClassEntity get symbolImplementationClass =>
      _map.toBackendClass(_commonElements.symbolImplementationClass);

  @override
  FunctionEntity get hashCodeForNativeObject =>
      _map.toBackendMember(_commonElements.hashCodeForNativeObject);

  @override
  FunctionEntity get toStringForNativeObject =>
      _map.toBackendMember(_commonElements.toStringForNativeObject);

  @override
  FunctionEntity get convertRtiToRuntimeType =>
      _map.toBackendMember(_commonElements.convertRtiToRuntimeType);

  @override
  FunctionEntity get defineProperty =>
      _map.toBackendMember(_commonElements.defineProperty);

  @override
  FunctionEntity get cyclicThrowHelper =>
      _map.toBackendMember(_commonElements.cyclicThrowHelper);

  @override
  FunctionEntity get createInvocationMirror =>
      _map.toBackendMember(_commonElements.createInvocationMirror);

  @override
  FunctionEntity get fallThroughError =>
      _map.toBackendMember(_commonElements.fallThroughError);

  @override
  FunctionEntity get createRuntimeType =>
      _map.toBackendMember(_commonElements.createRuntimeType);

  @override
  FunctionEntity get throwNoSuchMethod =>
      _map.toBackendMember(_commonElements.throwNoSuchMethod);

  @override
  FunctionEntity get checkDeferredIsLoaded =>
      _map.toBackendMember(_commonElements.checkDeferredIsLoaded);

  @override
  FunctionEntity get subtypeOfRuntimeTypeCast =>
      _map.toBackendMember(_commonElements.subtypeOfRuntimeTypeCast);

  @override
  FunctionEntity get assertSubtypeOfRuntimeType =>
      _map.toBackendMember(_commonElements.assertSubtypeOfRuntimeType);

  @override
  FunctionEntity get checkSubtypeOfRuntimeType =>
      _map.toBackendMember(_commonElements.checkSubtypeOfRuntimeType);

  @override
  FunctionEntity get functionTypeTest =>
      _map.toBackendMember(_commonElements.functionTypeTest);

  @override
  FunctionEntity get subtypeCast =>
      _map.toBackendMember(_commonElements.subtypeCast);

  @override
  FunctionEntity get assertSubtype =>
      _map.toBackendMember(_commonElements.assertSubtype);

  @override
  FunctionEntity get checkSubtype =>
      _map.toBackendMember(_commonElements.checkSubtype);

  @override
  FunctionEntity get assertIsSubtype =>
      _map.toBackendMember(_commonElements.assertIsSubtype);

  @override
  FunctionEntity get runtimeTypeToString =>
      _map.toBackendMember(_commonElements.runtimeTypeToString);

  @override
  FunctionEntity get getRuntimeTypeArgument =>
      _map.toBackendMember(_commonElements.getRuntimeTypeArgument);

  @override
  FunctionEntity get getRuntimeTypeArguments =>
      _map.toBackendMember(_commonElements.getRuntimeTypeArguments);

  @override
  FunctionEntity get computeSignature =>
      _map.toBackendMember(_commonElements.computeSignature);

  @override
  FunctionEntity get getTypeArgumentByIndex =>
      _map.toBackendMember(_commonElements.getTypeArgumentByIndex);

  @override
  FunctionEntity get getRuntimeTypeInfo =>
      _map.toBackendMember(_commonElements.getRuntimeTypeInfo);

  @override
  FunctionEntity get setRuntimeTypeInfo =>
      _map.toBackendMember(_commonElements.setRuntimeTypeInfo);

  @override
  FunctionEntity get traceFromException =>
      _map.toBackendMember(_commonElements.traceFromException);

  @override
  FunctionEntity get closureConverter =>
      _map.toBackendMember(_commonElements.closureConverter);

  @override
  FunctionEntity get throwExpressionHelper =>
      _map.toBackendMember(_commonElements.throwExpressionHelper);

  @override
  FunctionEntity get wrapExceptionHelper =>
      _map.toBackendMember(_commonElements.wrapExceptionHelper);

  @override
  FunctionEntity get stringInterpolationHelper =>
      _map.toBackendMember(_commonElements.stringInterpolationHelper);

  @override
  FunctionEntity get checkString =>
      _map.toBackendMember(_commonElements.checkString);

  @override
  FunctionEntity get checkNum => _map.toBackendMember(_commonElements.checkNum);

  @override
  FunctionEntity get checkInt => _map.toBackendMember(_commonElements.checkInt);

  @override
  FunctionEntity get throwConcurrentModificationError =>
      _map.toBackendMember(_commonElements.throwConcurrentModificationError);

  @override
  FunctionEntity get checkConcurrentModificationError =>
      _map.toBackendMember(_commonElements.checkConcurrentModificationError);

  @override
  FunctionEntity get throwAbstractClassInstantiationError => _map
      .toBackendMember(_commonElements.throwAbstractClassInstantiationError);

  @override
  FunctionEntity get throwTypeError =>
      _map.toBackendMember(_commonElements.throwTypeError);

  @override
  FunctionEntity get throwRuntimeError =>
      _map.toBackendMember(_commonElements.throwRuntimeError);

  @override
  FunctionEntity get exceptionUnwrapper =>
      _map.toBackendMember(_commonElements.exceptionUnwrapper);

  @override
  FunctionEntity get throwIndexOutOfRangeException =>
      _map.toBackendMember(_commonElements.throwIndexOutOfRangeException);

  @override
  FunctionEntity get throwIllegalArgumentException =>
      _map.toBackendMember(_commonElements.throwIllegalArgumentException);

  @override
  FunctionEntity get isJsIndexable =>
      _map.toBackendMember(_commonElements.isJsIndexable);

  @override
  FunctionEntity get closureFromTearOff =>
      _map.toBackendMember(_commonElements.closureFromTearOff);

  @override
  FunctionEntity get traceHelper =>
      _map.toBackendMember(_commonElements.traceHelper);

  @override
  FunctionEntity get boolConversionCheck =>
      _map.toBackendMember(_commonElements.boolConversionCheck);

  @override
  FunctionEntity get loadLibraryWrapper =>
      _map.toBackendMember(_commonElements.loadLibraryWrapper);

  @override
  FunctionEntity get mainHasTooManyParameters =>
      _map.toBackendMember(_commonElements.mainHasTooManyParameters);

  @override
  FunctionEntity get missingMain =>
      _map.toBackendMember(_commonElements.missingMain);

  @override
  FunctionEntity get badMain => _map.toBackendMember(_commonElements.badMain);

  @override
  FunctionEntity get requiresPreambleMarker =>
      _map.toBackendMember(_commonElements.requiresPreambleMarker);

  @override
  FunctionEntity get getIsolateAffinityTagMarker =>
      _map.toBackendMember(_commonElements.getIsolateAffinityTagMarker);

  @override
  FunctionEntity get assertUnreachableMethod =>
      _map.toBackendMember(_commonElements.assertUnreachableMethod);

  @override
  FunctionEntity get assertHelper =>
      _map.toBackendMember(_commonElements.assertHelper);

  @override
  FunctionEntity get assertThrow =>
      _map.toBackendMember(_commonElements.assertThrow);

  @override
  FunctionEntity get assertTest =>
      _map.toBackendMember(_commonElements.assertTest);

  @override
  FunctionEntity get invokeOnMethod =>
      _map.toBackendMember(_commonElements.invokeOnMethod);

  @override
  ConstructorEntity get typeVariableConstructor =>
      _map.toBackendMember(_commonElements.typeVariableConstructor);

  @override
  ClassEntity get nativeAnnotationClass =>
      _map.toBackendClass(_commonElements.nativeAnnotationClass);

  @override
  ClassEntity get patchAnnotationClass =>
      _map.toBackendClass(_commonElements.patchAnnotationClass);

  @override
  ClassEntity get annotationJSNameClass =>
      _map.toBackendClass(_commonElements.annotationJSNameClass);

  @override
  ClassEntity get annotationReturnsClass =>
      _map.toBackendClass(_commonElements.annotationReturnsClass);

  @override
  ClassEntity get annotationCreatesClass =>
      _map.toBackendClass(_commonElements.annotationCreatesClass);

  @override
  ClassEntity get generalConstantMapClass =>
      _map.toBackendClass(_commonElements.generalConstantMapClass);

  @override
  ClassEntity get constantProtoMapClass =>
      _map.toBackendClass(_commonElements.constantProtoMapClass);

  @override
  ClassEntity get constantStringMapClass =>
      _map.toBackendClass(_commonElements.constantStringMapClass);

  @override
  ClassEntity get constantMapClass =>
      _map.toBackendClass(_commonElements.constantMapClass);

  @override
  ClassEntity get stackTraceHelperClass =>
      _map.toBackendClass(_commonElements.stackTraceHelperClass);

  @override
  ClassEntity get VoidRuntimeType =>
      _map.toBackendClass(_commonElements.VoidRuntimeType);

  @override
  ClassEntity get jsIndexingBehaviorInterface =>
      _map.toBackendClass(_commonElements.jsIndexingBehaviorInterface);

  @override
  ClassEntity get jsInvocationMirrorClass =>
      _map.toBackendClass(_commonElements.jsInvocationMirrorClass);

  @override
  ClassEntity get irRepresentationClass =>
      _map.toBackendClass(_commonElements.irRepresentationClass);

  @override
  ClassEntity get forceInlineClass =>
      _map.toBackendClass(_commonElements.forceInlineClass);

  @override
  ClassEntity get noInlineClass =>
      _map.toBackendClass(_commonElements.noInlineClass);

  @override
  ClassEntity get noThrowsClass =>
      _map.toBackendClass(_commonElements.noThrowsClass);

  @override
  ClassEntity get noSideEffectsClass =>
      _map.toBackendClass(_commonElements.noSideEffectsClass);

  @override
  ClassEntity get typeVariableClass =>
      _map.toBackendClass(_commonElements.typeVariableClass);

  @override
  ClassEntity get constMapLiteralClass =>
      _map.toBackendClass(_commonElements.constMapLiteralClass);

  @override
  ClassEntity get typeLiteralClass =>
      _map.toBackendClass(_commonElements.typeLiteralClass);

  @override
  ClassEntity get boundClosureClass =>
      _map.toBackendClass(_commonElements.boundClosureClass);

  @override
  ClassEntity get closureClass =>
      _map.toBackendClass(_commonElements.closureClass);

  @override
  FunctionEntity findHelperFunction(String name) {
    return _map.toBackendMember(_commonElements.findHelperFunction(name));
  }

  @override
  ClassEntity get jsAnonymousClass =>
      _map.toBackendClass(_commonElements.jsAnonymousClass);

  @override
  ClassEntity get jsAnnotationClass =>
      _map.toBackendClass(_commonElements.jsAnnotationClass);

  @override
  FunctionEntity get jsStringOperatorAdd =>
      _map.toBackendMember(_commonElements.jsStringOperatorAdd);

  @override
  FunctionEntity get jsStringToString =>
      _map.toBackendMember(_commonElements.jsStringToString);

  @override
  FunctionEntity get jsStringSplit =>
      _map.toBackendMember(_commonElements.jsStringSplit);

  @override
  FunctionEntity get jsArrayAdd =>
      _map.toBackendMember(_commonElements.jsArrayAdd);

  @override
  FunctionEntity get jsArrayRemoveLast =>
      _map.toBackendMember(_commonElements.jsArrayRemoveLast);

  @override
  ConstructorEntity get jsArrayTypedConstructor =>
      _map.toBackendMember(_commonElements.jsArrayTypedConstructor);

  @override
  MemberEntity get jsIndexableLength =>
      _map.toBackendMember(_commonElements.jsIndexableLength);

  @override
  FunctionEntity get getNativeInterceptorMethod =>
      _map.toBackendMember(_commonElements.getNativeInterceptorMethod);

  @override
  FunctionEntity get getInterceptorMethod =>
      _map.toBackendMember(_commonElements.getInterceptorMethod);

  @override
  FunctionEntity get findIndexForNativeSubclassType =>
      _map.toBackendMember(_commonElements.findIndexForNativeSubclassType);

  @override
  ClassEntity get jsUInt31Class =>
      _map.toBackendClass(_commonElements.jsUInt31Class);

  @override
  ClassEntity get jsUInt32Class =>
      _map.toBackendClass(_commonElements.jsUInt32Class);

  @override
  ClassEntity get jsPositiveIntClass =>
      _map.toBackendClass(_commonElements.jsPositiveIntClass);

  @override
  ClassEntity get jsUnmodifiableArrayClass =>
      _map.toBackendClass(_commonElements.jsUnmodifiableArrayClass);

  @override
  ClassEntity get jsExtendableArrayClass =>
      _map.toBackendClass(_commonElements.jsExtendableArrayClass);

  @override
  ClassEntity get jsFixedArrayClass =>
      _map.toBackendClass(_commonElements.jsFixedArrayClass);

  @override
  ClassEntity get jsMutableArrayClass =>
      _map.toBackendClass(_commonElements.jsMutableArrayClass);

  @override
  ClassEntity get jsMutableIndexableClass =>
      _map.toBackendClass(_commonElements.jsMutableIndexableClass);

  @override
  ClassEntity get jsIndexableClass =>
      _map.toBackendClass(_commonElements.jsIndexableClass);

  @override
  ClassEntity get jsJavaScriptObjectClass =>
      _map.toBackendClass(_commonElements.jsJavaScriptObjectClass);

  @override
  ClassEntity get jsJavaScriptFunctionClass =>
      _map.toBackendClass(_commonElements.jsJavaScriptFunctionClass);

  @override
  ClassEntity get jsUnknownJavaScriptObjectClass =>
      _map.toBackendClass(_commonElements.jsUnknownJavaScriptObjectClass);

  @override
  ClassEntity get jsPlainJavaScriptObjectClass =>
      _map.toBackendClass(_commonElements.jsPlainJavaScriptObjectClass);

  @override
  ClassEntity get jsBoolClass =>
      _map.toBackendClass(_commonElements.jsBoolClass);

  @override
  ClassEntity get jsNullClass =>
      _map.toBackendClass(_commonElements.jsNullClass);

  @override
  ClassEntity get jsDoubleClass =>
      _map.toBackendClass(_commonElements.jsDoubleClass);

  @override
  ClassEntity get jsIntClass => _map.toBackendClass(_commonElements.jsIntClass);

  @override
  ClassEntity get jsNumberClass =>
      _map.toBackendClass(_commonElements.jsNumberClass);

  @override
  ClassEntity get jsArrayClass =>
      _map.toBackendClass(_commonElements.jsArrayClass);

  @override
  ClassEntity get jsStringClass =>
      _map.toBackendClass(_commonElements.jsStringClass);

  @override
  ClassEntity get jsInterceptorClass =>
      _map.toBackendClass(_commonElements.jsInterceptorClass);

  @override
  ClassEntity get jsConstClass =>
      _map.toBackendClass(_commonElements.jsConstClass);

  @override
  FunctionEntity get preserveLibraryNamesMarker =>
      _map.toBackendMember(_commonElements.preserveLibraryNamesMarker);

  @override
  FunctionEntity get preserveUrisMarker =>
      _map.toBackendMember(_commonElements.preserveUrisMarker);

  @override
  FunctionEntity get preserveMetadataMarker =>
      _map.toBackendMember(_commonElements.preserveMetadataMarker);

  @override
  FunctionEntity get preserveNamesMarker =>
      _map.toBackendMember(_commonElements.preserveNamesMarker);

  @override
  FunctionEntity get disableTreeShakingMarker =>
      _map.toBackendMember(_commonElements.disableTreeShakingMarker);

  @override
  ConstructorEntity get streamIteratorConstructor =>
      _map.toBackendMember(_commonElements.streamIteratorConstructor);

  @override
  ConstructorEntity get asyncStarControllerConstructor =>
      _map.toBackendMember(_commonElements.asyncStarControllerConstructor);

  @override
  ClassEntity get asyncStarController =>
      _map.toBackendClass(_commonElements.asyncStarController);

  @override
  ConstructorEntity get syncCompleterConstructor =>
      _map.toBackendMember(_commonElements.syncCompleterConstructor);

  @override
  ConstructorEntity get syncStarIterableConstructor =>
      _map.toBackendMember(_commonElements.syncStarIterableConstructor);

  @override
  ClassEntity get controllerStream =>
      _map.toBackendClass(_commonElements.controllerStream);

  @override
  ClassEntity get futureImplementation =>
      _map.toBackendClass(_commonElements.futureImplementation);

  @override
  ClassEntity get syncStarIterable =>
      _map.toBackendClass(_commonElements.syncStarIterable);

  @override
  FunctionEntity get endOfIteration =>
      _map.toBackendMember(_commonElements.endOfIteration);

  @override
  FunctionEntity get streamOfController =>
      _map.toBackendMember(_commonElements.streamOfController);

  @override
  FunctionEntity get asyncStarHelper =>
      _map.toBackendMember(_commonElements.asyncStarHelper);

  @override
  FunctionEntity get syncStarUncaughtError =>
      _map.toBackendMember(_commonElements.syncStarUncaughtError);

  @override
  FunctionEntity get yieldSingle =>
      _map.toBackendMember(_commonElements.yieldSingle);

  @override
  FunctionEntity get yieldStar =>
      _map.toBackendMember(_commonElements.yieldStar);

  @override
  FunctionEntity get wrapBody => _map.toBackendMember(_commonElements.wrapBody);

  @override
  FunctionEntity get asyncHelperAwait =>
      _map.toBackendMember(_commonElements.asyncHelperAwait);

  @override
  FunctionEntity get asyncHelperRethrow =>
      _map.toBackendMember(_commonElements.asyncHelperRethrow);

  @override
  FunctionEntity get asyncHelperReturn =>
      _map.toBackendMember(_commonElements.asyncHelperReturn);

  @override
  FunctionEntity get asyncHelperStart =>
      _map.toBackendMember(_commonElements.asyncHelperStart);

  @override
  bool isDefaultNoSuchMethodImplementation(FunctionEntity element) {
    return _commonElements
        .isDefaultNoSuchMethodImplementation(_map.toFrontendMember(element));
  }

  @override
  FunctionEntity get objectNoSuchMethod =>
      _map.toBackendMember(_commonElements.objectNoSuchMethod);

  @override
  FunctionEntity get mapLiteralUntypedEmptyMaker =>
      _map.toBackendMember(_commonElements.mapLiteralUntypedEmptyMaker);

  @override
  FunctionEntity get mapLiteralUntypedMaker =>
      _map.toBackendMember(_commonElements.mapLiteralUntypedMaker);

  @override
  ConstructorEntity get mapLiteralConstructorEmpty =>
      _map.toBackendMember(_commonElements.mapLiteralConstructorEmpty);

  @override
  ConstructorEntity get mapLiteralConstructor =>
      _map.toBackendMember(_commonElements.mapLiteralConstructor);

  @override
  ClassEntity get mapLiteralClass =>
      _map.toBackendClass(_commonElements.mapLiteralClass);

  @override
  FunctionEntity get objectEquals =>
      _map.toBackendMember(_commonElements.objectEquals);

  @override
  FunctionEntity get unresolvedTopLevelMethodError =>
      _map.toBackendMember(_commonElements.unresolvedTopLevelMethodError);

  @override
  FunctionEntity get unresolvedTopLevelSetterError =>
      _map.toBackendMember(_commonElements.unresolvedTopLevelSetterError);

  @override
  FunctionEntity get unresolvedTopLevelGetterError =>
      _map.toBackendMember(_commonElements.unresolvedTopLevelGetterError);

  @override
  FunctionEntity get unresolvedStaticMethodError =>
      _map.toBackendMember(_commonElements.unresolvedStaticMethodError);

  @override
  FunctionEntity get unresolvedStaticSetterError =>
      _map.toBackendMember(_commonElements.unresolvedStaticSetterError);

  @override
  FunctionEntity get unresolvedStaticGetterError =>
      _map.toBackendMember(_commonElements.unresolvedStaticGetterError);

  @override
  FunctionEntity get unresolvedConstructorError =>
      _map.toBackendMember(_commonElements.unresolvedConstructorError);

  @override
  FunctionEntity get genericNoSuchMethod =>
      _map.toBackendMember(_commonElements.genericNoSuchMethod);

  @override
  FunctionEntity get malformedTypeError =>
      _map.toBackendMember(_commonElements.malformedTypeError);

  @override
  bool isDefaultEqualityImplementation(MemberEntity element) {
    return _commonElements
        .isDefaultEqualityImplementation(_map.toFrontendMember(element));
  }

  @override
  InterfaceType get symbolImplementationType {
    return _map.fromFrontendType(_commonElements.symbolImplementationType);
  }

  @override
  FieldEntity get symbolField =>
      _map.toBackendMember(_commonElements.symbolField);

  @override
  InterfaceType getConstantMapTypeFor(InterfaceType sourceType,
      {bool hasProtoKey: false, bool onlyStringKeys: false}) {
    return _map.fromFrontendType(_commonElements.getConstantMapTypeFor(
        _map.toBackendType(sourceType),
        hasProtoKey: hasProtoKey,
        onlyStringKeys: onlyStringKeys));
  }

  @override
  bool isListSupertype(ClassEntity element) {
    return _commonElements.isListSupertype(_map.toFrontendClass(element));
  }

  @override
  bool isStringOnlySupertype(ClassEntity element) {
    return _commonElements.isStringOnlySupertype(_map.toFrontendClass(element));
  }

  @override
  bool isNumberOrStringSupertype(ClassEntity element) {
    return _commonElements
        .isNumberOrStringSupertype(_map.toFrontendClass(element));
  }

  @override
  InterfaceType streamType([DartType elementType]) {
    return _map.fromFrontendType(
        _commonElements.streamType(_map.toBackendType(elementType)));
  }

  @override
  InterfaceType futureType([DartType elementType]) {
    return _map.fromFrontendType(
        _commonElements.futureType(_map.toBackendType(elementType)));
  }

  @override
  InterfaceType iterableType([DartType elementType]) {
    return _map.fromFrontendType(
        _commonElements.iterableType(_map.toBackendType(elementType)));
  }

  @override
  InterfaceType mapType([DartType keyType, DartType valueType]) {
    return _map.fromFrontendType(_commonElements.mapType(
        _map.toBackendType(keyType), _map.toBackendType(valueType)));
  }

  @override
  InterfaceType listType([DartType elementType]) {
    return _map.fromFrontendType(
        _commonElements.listType(_map.toBackendType(elementType)));
  }

  @override
  InterfaceType get stackTraceType =>
      _map.fromFrontendType(_commonElements.stackTraceType);

  @override
  InterfaceType get typeLiteralType =>
      _map.fromFrontendType(_commonElements.typeLiteralType);

  @override
  InterfaceType get typeType => _map.fromFrontendType(_commonElements.typeType);

  @override
  InterfaceType get nullType => _map.fromFrontendType(_commonElements.nullType);

  @override
  InterfaceType get functionType =>
      _map.fromFrontendType(_commonElements.functionType);

  @override
  InterfaceType get symbolType =>
      _map.fromFrontendType(_commonElements.symbolType);

  @override
  InterfaceType get stringType =>
      _map.fromFrontendType(_commonElements.stringType);

  @override
  InterfaceType get resourceType =>
      _map.fromFrontendType(_commonElements.resourceType);

  @override
  InterfaceType get doubleType =>
      _map.fromFrontendType(_commonElements.doubleType);

  @override
  InterfaceType get intType => _map.fromFrontendType(_commonElements.intType);

  @override
  InterfaceType get numType => _map.fromFrontendType(_commonElements.numType);

  @override
  InterfaceType get boolType => _map.fromFrontendType(_commonElements.boolType);

  @override
  InterfaceType get objectType =>
      _map.fromFrontendType(_commonElements.objectType);

  @override
  DynamicType get dynamicType =>
      _map.fromFrontendType(_commonElements.dynamicType);

  @override
  bool isFilledListConstructor(ConstructorEntity element) {
    return _commonElements
        .isFilledListConstructor(_map.toFrontendMember(element));
  }

  @override
  bool isUnnamedListConstructor(ConstructorEntity element) {
    return _commonElements
        .isUnnamedListConstructor(_map.toFrontendMember(element));
  }

  @override
  bool isFunctionApplyMethod(MemberEntity element) {
    return _commonElements
        .isFunctionApplyMethod(_map.toFrontendMember(element));
  }

  @override
  FunctionEntity get functionApplyMethod =>
      _map.toBackendMember(_commonElements.functionApplyMethod);

  @override
  FunctionEntity get identicalFunction =>
      _map.toBackendMember(_commonElements.identicalFunction);

  @override
  ClassEntity get deferredLibraryClass =>
      _map.toBackendClass(_commonElements.deferredLibraryClass);

  @override
  bool isMirrorsUsedConstructor(ConstructorEntity element) {
    return _commonElements
        .isMirrorsUsedConstructor(_map.toFrontendMember(element));
  }

  @override
  ClassEntity get mirrorsUsedClass =>
      _map.toBackendClass(_commonElements.mirrorsUsedClass);

  @override
  bool isMirrorSystemGetNameFunction(MemberEntity element) {
    return _commonElements
        .isMirrorSystemGetNameFunction(_map.toFrontendMember(element));
  }

  @override
  ClassEntity get mirrorSystemClass =>
      _map.toBackendClass(_commonElements.mirrorSystemClass);

  @override
  bool isSymbolConstructor(ConstructorEntity element) {
    return _commonElements.isSymbolConstructor(_map.toFrontendMember(element));
  }

  @override
  ConstructorEntity get symbolConstructorTarget =>
      _map.toBackendMember(_commonElements.symbolConstructorTarget);

  @override
  ClassEntity get typedDataClass =>
      _map.toBackendClass(_commonElements.typedDataClass);

  @override
  LibraryEntity get internalLibrary =>
      _map.toBackendLibrary(_commonElements.internalLibrary);

  @override
  LibraryEntity get isolateHelperLibrary =>
      _map.toBackendLibrary(_commonElements.isolateHelperLibrary);

  @override
  LibraryEntity get foreignLibrary =>
      _map.toBackendLibrary(_commonElements.foreignLibrary);

  @override
  LibraryEntity get interceptorsLibrary =>
      _map.toBackendLibrary(_commonElements.interceptorsLibrary);

  @override
  LibraryEntity get jsHelperLibrary =>
      _map.toBackendLibrary(_commonElements.jsHelperLibrary);

  @override
  LibraryEntity get typedDataLibrary =>
      _map.toBackendLibrary(_commonElements.typedDataLibrary);

  @override
  LibraryEntity get mirrorsLibrary =>
      _map.toBackendLibrary(_commonElements.mirrorsLibrary);

  @override
  LibraryEntity get asyncLibrary =>
      _map.toBackendLibrary(_commonElements.asyncLibrary);

  @override
  LibraryEntity get coreLibrary =>
      _map.toBackendLibrary(_commonElements.coreLibrary);

  @override
  ClassEntity get streamClass =>
      _map.toBackendClass(_commonElements.streamClass);

  @override
  ClassEntity get futureClass =>
      _map.toBackendClass(_commonElements.futureClass);

  @override
  ClassEntity get iterableClass =>
      _map.toBackendClass(_commonElements.iterableClass);

  @override
  ClassEntity get mapClass => _map.toBackendClass(_commonElements.mapClass);

  @override
  ClassEntity get listClass => _map.toBackendClass(_commonElements.listClass);

  @override
  ClassEntity get stackTraceClass =>
      _map.toBackendClass(_commonElements.stackTraceClass);

  @override
  ClassEntity get typeClass => _map.toBackendClass(_commonElements.typeClass);

  @override
  ClassEntity get nullClass => _map.toBackendClass(_commonElements.nullClass);

  @override
  ClassEntity get symbolClass =>
      _map.toBackendClass(_commonElements.symbolClass);

  @override
  ClassEntity get resourceClass =>
      _map.toBackendClass(_commonElements.resourceClass);

  @override
  ClassEntity get functionClass =>
      _map.toBackendClass(_commonElements.functionClass);

  @override
  ClassEntity get stringClass =>
      _map.toBackendClass(_commonElements.stringClass);

  @override
  ClassEntity get doubleClass =>
      _map.toBackendClass(_commonElements.doubleClass);

  @override
  ClassEntity get intClass => _map.toBackendClass(_commonElements.intClass);

  @override
  ClassEntity get numClass => _map.toBackendClass(_commonElements.numClass);

  @override
  ClassEntity get boolClass => _map.toBackendClass(_commonElements.boolClass);

  @override
  FunctionEntity get throwUnsupportedError =>
      _map.toBackendMember(_commonElements.throwUnsupportedError);
}
