// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../common.dart';
import '../common/names.dart';
import '../common/resolution.dart';
import '../common_elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/constants.dart';
import '../ir/impact.dart';
import '../ir/impact_data.dart';
import '../ir/runtime_type_analysis.dart';
import '../ir/scope.dart';
import '../ir/static_type.dart';
import '../ir/util.dart';
import '../ir/visitors.dart';
import '../js_backend/annotations.dart';
import '../js_backend/native_data.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../resolution/registry.dart' show ResolutionWorldImpactBuilder;
import '../universe/call_structure.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart';
import '../universe/world_builder.dart';
import 'element_map.dart';

/// Visitor that computes the world impact of a member.
class KernelImpactBuilder extends ImpactBuilderBase
    with KernelImpactRegistryMixin {
  @override
  final ResolutionWorldImpactBuilder impactBuilder;
  @override
  final KernelToElementMap elementMap;
  @override
  final DiagnosticReporter reporter;
  @override
  final CompilerOptions _options;
  @override
  final MemberEntity currentMember;
  final Set<PragmaAnnotation> _annotations;
  @override
  final ConstantValuefier _constantValuefier;

  KernelImpactBuilder(
      this.elementMap,
      this.currentMember,
      this.reporter,
      this._options,
      ir.StaticTypeContext staticTypeContext,
      StaticTypeCacheImpl staticTypeCache,
      VariableScopeModel variableScopeModel,
      this._annotations,
      this._constantValuefier)
      : this.impactBuilder = new ResolutionWorldImpactBuilder(
            elementMap.commonElements.dartTypes, currentMember),
        super(staticTypeContext, staticTypeCache, elementMap.classHierarchy,
            variableScopeModel);

  @override
  CommonElements get commonElements => elementMap.commonElements;

  @override
  NativeBasicData get _nativeBasicData => elementMap.nativeBasicData;

  @override
  bool get useAsserts => _options.enableUserAssertions;

  @override
  bool get inferEffectivelyFinalVariableTypes =>
      !_annotations.contains(PragmaAnnotation.disableFinal);
}

/// Converts a [ImpactData] object based on kernel to the corresponding
/// [ResolutionImpact] based on the K model.
class KernelImpactConverter extends KernelImpactRegistryMixin {
  @override
  final ResolutionWorldImpactBuilder impactBuilder;
  @override
  final KernelToElementMap elementMap;
  @override
  final DiagnosticReporter reporter;
  @override
  final CompilerOptions _options;
  @override
  final MemberEntity currentMember;
  @override
  final ConstantValuefier _constantValuefier;
  @override
  final ir.StaticTypeContext staticTypeContext;

  KernelImpactConverter(this.elementMap, this.currentMember, this.reporter,
      this._options, this._constantValuefier, this.staticTypeContext)
      : this.impactBuilder = new ResolutionWorldImpactBuilder(
            elementMap.commonElements.dartTypes, currentMember);

  @override
  ir.TypeEnvironment get typeEnvironment => elementMap.typeEnvironment;

  @override
  CommonElements get commonElements => elementMap.commonElements;

  @override
  NativeBasicData get _nativeBasicData => elementMap.nativeBasicData;

  /// Converts a [ImpactData] object based on kernel to the corresponding
  /// [ResolutionImpact] based on the K model.
  ResolutionImpact convert(ImpactData impactData) {
    impactData.apply(this);
    return impactBuilder;
  }
}

/// [ImpactRegistry] that converts kernel based impact data to world impact
/// object based on the K model.
abstract class KernelImpactRegistryMixin implements ImpactRegistry {
  CompilerOptions get _options;
  DiagnosticReporter get reporter;
  KernelToElementMap get elementMap;
  MemberEntity get currentMember;
  ResolutionWorldImpactBuilder get impactBuilder;
  ir.TypeEnvironment get typeEnvironment;
  CommonElements get commonElements;
  DartTypes get dartTypes => commonElements.dartTypes;
  NativeBasicData get _nativeBasicData;
  ConstantValuefier get _constantValuefier;
  ir.StaticTypeContext get staticTypeContext;

  String typeToString(DartType type) =>
      type.toStructuredText(dartTypes, _options);

  Object _computeReceiverConstraint(
      ir.DartType receiverType, ClassRelation relation) {
    if (receiverType is ir.InterfaceType) {
      return new StrongModeConstraint(commonElements, _nativeBasicData,
          elementMap.getClass(receiverType.classNode), relation);
    } else if (receiverType is ir.NullType) {
      return new StrongModeConstraint(
          commonElements,
          _nativeBasicData,
          elementMap.getClass(typeEnvironment.coreTypes.deprecatedNullClass),
          relation);
    }
    return null;
  }

  @override
  void registerParameterCheck(ir.DartType irType) {
    DartType type = elementMap.getDartType(irType);
    if (type is! DynamicType) {
      impactBuilder.registerTypeUse(new TypeUse.parameterCheck(type));
    }
  }

  List<DartType> _getTypeArguments(List<ir.DartType> types) {
    if (types.isEmpty) return null;
    return types.map(elementMap.getDartType).toList();
  }

  @override
  void registerLazyField() {
    impactBuilder.registerFeature(Feature.LAZY_FIELD);
  }

  @override
  void registerFieldNode(ir.Field field) {
    if (field.isInstanceMember &&
        _nativeBasicData
            .isNativeClass(elementMap.getClass(field.enclosingClass))) {
      MemberEntity member = elementMap.getMember(field);
      // TODO(johnniwinther): NativeDataBuilder already has the native behavior
      // at this point. Use that instead.
      bool isJsInterop = _nativeBasicData.isJsInteropMember(member);
      List<ConstantValue> metadata =
          elementMap.elementEnvironment.getMemberMetadata(member);
      Iterable<String> createsAnnotations =
          getCreatesAnnotations(dartTypes, reporter, commonElements, metadata);
      Iterable<String> returnsAnnotations =
          getReturnsAnnotations(dartTypes, reporter, commonElements, metadata);
      impactBuilder.registerNativeData(elementMap.getNativeBehaviorForFieldLoad(
          field, createsAnnotations, returnsAnnotations,
          isJsInterop: isJsInterop));
      impactBuilder
          .registerNativeData(elementMap.getNativeBehaviorForFieldStore(field));
    }
  }

  @override
  void registerConstructorNode(ir.Constructor constructor) {
    MemberEntity member = elementMap.getMember(constructor);
    if (constructor.isExternal && !commonElements.isForeignHelper(member)) {
      // TODO(johnniwinther): NativeDataBuilder already has the native behavior
      // at this point. Use that instead.
      bool isJsInterop = _nativeBasicData.isJsInteropMember(member);
      List<ConstantValue> metadata =
          elementMap.elementEnvironment.getMemberMetadata(member);
      Iterable<String> createsAnnotations =
          getCreatesAnnotations(dartTypes, reporter, commonElements, metadata);
      Iterable<String> returnsAnnotations =
          getReturnsAnnotations(dartTypes, reporter, commonElements, metadata);
      impactBuilder.registerNativeData(elementMap.getNativeBehaviorForMethod(
          constructor, createsAnnotations, returnsAnnotations,
          isJsInterop: isJsInterop));
    }
  }

  @override
  void registerSyncStar(ir.DartType elementType) {
    impactBuilder.registerFeature(Feature.SYNC_STAR);
    impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
        commonElements.syncStarIterableFactory,
        const CallStructure.unnamed(1, 1),
        <DartType>[elementMap.getDartType(elementType)]));
  }

  @override
  void registerAsync(ir.DartType elementType) {
    impactBuilder.registerFeature(Feature.ASYNC);
    impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
        commonElements.asyncAwaitCompleterFactory,
        const CallStructure.unnamed(0, 1),
        <DartType>[elementMap.getDartType(elementType)]));
  }

  @override
  void registerAsyncStar(ir.DartType elementType) {
    impactBuilder.registerFeature(Feature.ASYNC_STAR);
    impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
        commonElements.asyncStarStreamControllerFactory,
        const CallStructure.unnamed(1, 1),
        <DartType>[elementMap.getDartType(elementType)]));
  }

  @override
  void registerProcedureNode(ir.Procedure procedure) {
    MemberEntity member = elementMap.getMember(procedure);
    if (procedure.isExternal && !commonElements.isForeignHelper(member)) {
      // TODO(johnniwinther): NativeDataBuilder already has the native behavior
      // at this point. Use that instead.
      bool isJsInterop = _nativeBasicData.isJsInteropMember(member);
      List<ConstantValue> metadata =
          elementMap.elementEnvironment.getMemberMetadata(member);
      Iterable<String> createsAnnotations =
          getCreatesAnnotations(dartTypes, reporter, commonElements, metadata);
      Iterable<String> returnsAnnotations =
          getReturnsAnnotations(dartTypes, reporter, commonElements, metadata);
      impactBuilder.registerNativeData(elementMap.getNativeBehaviorForMethod(
          procedure, createsAnnotations, returnsAnnotations,
          isJsInterop: isJsInterop));
    }
  }

  @override
  void registerIntLiteral(int value) {
    impactBuilder.registerConstantLiteral(
        new IntConstantValue(new BigInt.from(value).toUnsigned(64)));
  }

  @override
  void registerDoubleLiteral(double value) {
    impactBuilder.registerConstantLiteral(new DoubleConstantValue(value));
  }

  @override
  void registerBoolLiteral(bool value) {
    impactBuilder.registerConstantLiteral(new BoolConstantValue(value));
  }

  @override
  void registerStringLiteral(String value) {
    impactBuilder.registerConstantLiteral(new StringConstantValue(value));
  }

  @override
  void registerSymbolLiteral(String value) {
    impactBuilder.registerConstSymbolName(value);
  }

  @override
  void registerNullLiteral() {
    impactBuilder.registerConstantLiteral(new NullConstantValue());
  }

  @override
  void registerListLiteral(ir.DartType elementType,
      {bool isConst, bool isEmpty}) {
    impactBuilder.registerListLiteral(new ListLiteralUse(
        commonElements.listType(elementMap.getDartType(elementType)),
        isConstant: isConst,
        isEmpty: isEmpty));
  }

  @override
  void registerSetLiteral(ir.DartType elementType,
      {bool isConst, bool isEmpty}) {
    impactBuilder.registerSetLiteral(new SetLiteralUse(
        commonElements.setType(elementMap.getDartType(elementType)),
        isConstant: isConst,
        isEmpty: isEmpty));
  }

  @override
  void registerMapLiteral(ir.DartType keyType, ir.DartType valueType,
      {bool isConst, bool isEmpty}) {
    impactBuilder.registerMapLiteral(new MapLiteralUse(
        commonElements.mapType(
            elementMap.getDartType(keyType), elementMap.getDartType(valueType)),
        isConstant: isConst,
        isEmpty: isEmpty));
  }

  @override
  void registerNew(
      ir.Member target,
      ir.InterfaceType type,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency import,
      {bool isConst}) {
    ConstructorEntity constructor = elementMap.getConstructor(target);
    CallStructure callStructure = new CallStructure(
        positionalArguments + namedArguments.length,
        namedArguments,
        typeArguments.length);
    ImportEntity deferredImport = elementMap.getImport(import);
    impactBuilder.registerStaticUse(isConst
        ? new StaticUse.constConstructorInvoke(constructor, callStructure,
            elementMap.getDartType(type).withoutNullability, deferredImport)
        : new StaticUse.typedConstructorInvoke(constructor, callStructure,
            elementMap.getDartType(type).withoutNullability, deferredImport));
    if (type.typeArguments.any((ir.DartType type) => type is! ir.DynamicType)) {
      impactBuilder.registerFeature(Feature.TYPE_VARIABLE_BOUNDS_CHECK);
    }

    if (commonElements.isSymbolConstructor(constructor)) {
      impactBuilder.registerFeature(Feature.SYMBOL_CONSTRUCTOR);
    }

    if (target.isExternal &&
        constructor.isFromEnvironmentConstructor &&
        !isConst) {
      impactBuilder.registerFeature(Feature.THROW_UNSUPPORTED_ERROR);
      // We need to register the external constructor as live below, so don't
      // return here.
    }
  }

  @override
  void registerConstInstantiation(ir.Class cls, List<ir.DartType> typeArguments,
      ir.LibraryDependency import) {
    ImportEntity deferredImport = elementMap.getImport(import);
    InterfaceType type = elementMap.createInterfaceType(cls, typeArguments);
    impactBuilder
        .registerTypeUse(new TypeUse.constInstantiation(type, deferredImport));
  }

  @override
  void registerConstConstructorInvocationNode(ir.ConstructorInvocation node) {
    assert(node.isConst);
    ConstructorEntity constructor = elementMap.getConstructor(node.target);
    if (commonElements.isSymbolConstructor(constructor)) {
      ConstantValue value = elementMap.getConstantValue(
          staticTypeContext, node.arguments.positional.first);
      if (!value.isString) {
        // TODO(het): Get the actual span for the Symbol constructor argument
        reporter.reportErrorMessage(
            CURRENT_ELEMENT_SPANNABLE,
            MessageKind.STRING_EXPECTED,
            {'type': typeToString(value.getType(elementMap.commonElements))});
        return;
      }
      StringConstantValue stringValue = value;
      impactBuilder.registerConstSymbolName(stringValue.stringValue);
    }
  }

  @override
  void registerSuperInitializer(
      ir.Constructor source,
      ir.Constructor target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    // TODO(johnniwinther): Maybe rewrite `node.target` to point to a
    // synthesized unnamed mixin constructor when needed. This would require us
    // to consider impact building a required pre-step for inference and
    // ssa-building.
    ConstructorEntity constructor =
        elementMap.getSuperConstructor(source, target);
    impactBuilder.registerStaticUse(new StaticUse.superConstructorInvoke(
        constructor,
        new CallStructure(positionalArguments + namedArguments.length,
            namedArguments, typeArguments.length)));
  }

  @override
  void registerStaticInvocation(
      ir.Procedure procedure,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency import) {
    FunctionEntity target = elementMap.getMethod(procedure);
    CallStructure callStructure = new CallStructure(
        positionalArguments + namedArguments.length,
        namedArguments,
        typeArguments.length);
    List<DartType> dartTypeArguments = _getTypeArguments(typeArguments);
    if (commonElements.isExtractTypeArguments(target)) {
      _handleExtractTypeArguments(target, dartTypeArguments, callStructure);
      return;
    } else {
      ImportEntity deferredImport = elementMap.getImport(import);
      impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
          target, callStructure, dartTypeArguments, deferredImport));
    }
  }

  @override
  void registerStaticInvocationNode(ir.StaticInvocation node) {
    switch (elementMap.getForeignKind(node)) {
      case ForeignKind.JS:
        impactBuilder
            .registerNativeData(elementMap.getNativeBehaviorForJsCall(node));
        break;
      case ForeignKind.JS_BUILTIN:
        impactBuilder.registerNativeData(
            elementMap.getNativeBehaviorForJsBuiltinCall(node));
        break;
      case ForeignKind.JS_EMBEDDED_GLOBAL:
        impactBuilder.registerNativeData(
            elementMap.getNativeBehaviorForJsEmbeddedGlobalCall(node));
        break;
      case ForeignKind.JS_INTERCEPTOR_CONSTANT:
        InterfaceType type =
            elementMap.getInterfaceTypeForJsInterceptorCall(node);
        if (type != null) {
          impactBuilder.registerTypeUse(new TypeUse.instantiation(type));
        }
        break;
      case ForeignKind.NONE:
        break;
    }
  }

  void _handleExtractTypeArguments(FunctionEntity target,
      List<DartType> typeArguments, CallStructure callStructure) {
    // extractTypeArguments<Map>(obj, fn) has additional impacts:
    //
    //   1. All classes implementing Map need to carry type arguments (similar
    //      to checking `o is Map<K, V>`).
    //
    //   2. There is an invocation of fn with some number of type arguments.
    //
    impactBuilder.registerStaticUse(
        new StaticUse.staticInvoke(target, callStructure, typeArguments));

    if (typeArguments.length != 1) return;
    DartType matchedType = dartTypes.eraseLegacy(typeArguments.first);

    if (matchedType is! InterfaceType) return;
    InterfaceType interfaceType = matchedType;
    ClassEntity cls = interfaceType.element;
    InterfaceType thisType = elementMap.elementEnvironment.getThisType(cls);

    impactBuilder.registerTypeUse(new TypeUse.isCheck(thisType));

    Selector selector = new Selector.callClosure(
        0, const <String>[], thisType.typeArguments.length);
    impactBuilder.registerDynamicUse(
        new DynamicUse(selector, null, thisType.typeArguments));
  }

  @override
  void registerStaticTearOff(
      ir.Procedure procedure, ir.LibraryDependency import) {
    impactBuilder.registerStaticUse(new StaticUse.staticTearOff(
        elementMap.getMethod(procedure), elementMap.getImport(import)));
  }

  @override
  void registerStaticGet(ir.Member member, ir.LibraryDependency import) {
    impactBuilder.registerStaticUse(new StaticUse.staticGet(
        elementMap.getMember(member), elementMap.getImport(import)));
  }

  @override
  void registerStaticSet(ir.Member member, ir.LibraryDependency import) {
    impactBuilder.registerStaticUse(new StaticUse.staticSet(
        elementMap.getMember(member), elementMap.getImport(import)));
  }

  @override
  void registerSuperInvocation(ir.Name name, int positionalArguments,
      List<String> namedArguments, List<ir.DartType> typeArguments) {
    FunctionEntity method =
        elementMap.getSuperMember(currentMember, name, setter: false);
    List<DartType> dartTypeArguments = _getTypeArguments(typeArguments);
    if (method != null) {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          method,
          new CallStructure(positionalArguments + namedArguments.length,
              namedArguments, typeArguments.length),
          dartTypeArguments));
    } else {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          elementMap.getSuperNoSuchMethod(currentMember.enclosingClass),
          CallStructure.ONE_ARG));
      impactBuilder.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
    }
  }

  @override
  void registerSuperGet(ir.Name name) {
    MemberEntity member =
        elementMap.getSuperMember(currentMember, name, setter: false);
    if (member != null) {
      if (member.isFunction) {
        impactBuilder.registerStaticUse(new StaticUse.superTearOff(member));
      } else {
        impactBuilder.registerStaticUse(new StaticUse.superGet(member));
      }
    } else {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          elementMap.getSuperNoSuchMethod(currentMember.enclosingClass),
          CallStructure.ONE_ARG));
      impactBuilder.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
    }
  }

  @override
  void registerSuperSet(ir.Name name) {
    MemberEntity member =
        elementMap.getSuperMember(currentMember, name, setter: true);
    if (member != null) {
      if (member.isField) {
        impactBuilder.registerStaticUse(new StaticUse.superFieldSet(member));
      } else {
        impactBuilder.registerStaticUse(new StaticUse.superSetterSet(member));
      }
    } else {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          elementMap.getSuperNoSuchMethod(currentMember.enclosingClass),
          CallStructure.ONE_ARG));
      impactBuilder.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
    }
  }

  @override
  void registerLocalFunctionInvocation(
      ir.FunctionDeclaration localFunction,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    CallStructure callStructure = new CallStructure(
        positionalArguments + namedArguments.length,
        namedArguments,
        typeArguments.length);
    List<DartType> dartTypeArguments = _getTypeArguments(typeArguments);
    // Invocation of a local function. No need for dynamic use, but
    // we need to track the type arguments.
    impactBuilder.registerStaticUse(new StaticUse.closureCall(
        elementMap.getLocalFunction(localFunction),
        callStructure,
        dartTypeArguments));
    // TODO(johnniwinther): Yet, alas, we need the dynamic use for now. Remove
    // this when kernel adds an `isFunctionCall` flag to
    // [ir.MethodInvocation].
    impactBuilder.registerDynamicUse(
        new DynamicUse(callStructure.callSelector, null, dartTypeArguments));
  }

  @override
  void registerDynamicInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Name name,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    Selector selector = elementMap.getInvocationSelector(
        name, positionalArguments, namedArguments, typeArguments.length);
    List<DartType> dartTypeArguments = _getTypeArguments(typeArguments);
    impactBuilder.registerDynamicUse(new DynamicUse(selector,
        _computeReceiverConstraint(receiverType, relation), dartTypeArguments));
  }

  @override
  void registerFunctionInvocation(
      ir.DartType receiverType,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    CallStructure callStructure = new CallStructure(
        positionalArguments + namedArguments.length,
        namedArguments,
        typeArguments.length);
    List<DartType> dartTypeArguments = _getTypeArguments(typeArguments);
    impactBuilder.registerDynamicUse(new DynamicUse(
        callStructure.callSelector,
        _computeReceiverConstraint(receiverType, ClassRelation.subtype),
        dartTypeArguments));
  }

  @override
  void registerInstanceInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Member target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    List<DartType> dartTypeArguments = _getTypeArguments(typeArguments);
    impactBuilder.registerDynamicUse(new DynamicUse(
        elementMap.getInvocationSelector(target.name, positionalArguments,
            namedArguments, typeArguments.length),
        _computeReceiverConstraint(receiverType, relation),
        dartTypeArguments));
  }

  @override
  void registerDynamicGet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name) {
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.getter(elementMap.getName(name)),
        _computeReceiverConstraint(receiverType, relation),
        const <DartType>[]));
  }

  @override
  void registerInstanceGet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target) {
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.getter(elementMap.getName(target.name)),
        _computeReceiverConstraint(receiverType, relation),
        const <DartType>[]));
  }

  @override
  void registerDynamicSet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name) {
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.setter(elementMap.getName(name)),
        _computeReceiverConstraint(receiverType, relation),
        const <DartType>[]));
  }

  @override
  void registerInstanceSet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target) {
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.setter(elementMap.getName(target.name)),
        _computeReceiverConstraint(receiverType, relation),
        const <DartType>[]));
  }

  @override
  void registerRuntimeTypeUse(ir.PropertyGet node, RuntimeTypeUseKind kind,
      ir.DartType receiverType, ir.DartType argumentType) {
    DartType receiverDartType = elementMap.getDartType(receiverType);
    DartType argumentDartType =
        argumentType == null ? null : elementMap.getDartType(argumentType);

    if (_options.omitImplicitChecks) {
      switch (kind) {
        case RuntimeTypeUseKind.string:
          if (!_options.laxRuntimeTypeToString) {
            reporter.reportHintMessage(computeSourceSpanFromTreeNode(node),
                MessageKind.RUNTIME_TYPE_TO_STRING);
          }
          break;
        case RuntimeTypeUseKind.equals:
        case RuntimeTypeUseKind.unknown:
          break;
      }
    }
    impactBuilder.registerRuntimeTypeUse(
        new RuntimeTypeUse(kind, receiverDartType, argumentDartType));
  }

  @override
  void registerAssert({bool withMessage}) {
    impactBuilder.registerFeature(
        withMessage ? Feature.ASSERT_WITH_MESSAGE : Feature.ASSERT);
  }

  @override
  void registerGenericInstantiation(
      ir.FunctionType expressionType, List<ir.DartType> typeArguments) {
    // TODO(johnniwinther): Track which arities are used in instantiation.
    impactBuilder.registerInstantiation(new GenericInstantiation(
        elementMap.getDartType(expressionType),
        typeArguments.map(elementMap.getDartType).toList()));
  }

  @override
  void registerStringConcatenation() {
    impactBuilder.registerFeature(Feature.STRING_INTERPOLATION);
    impactBuilder.registerFeature(Feature.STRING_JUXTAPOSITION);
  }

  @override
  void registerLocalFunction(ir.TreeNode node) {
    Local function = elementMap.getLocalFunction(node);
    impactBuilder.registerStaticUse(new StaticUse.closure(function));
  }

  @override
  void registerLocalWithoutInitializer() {
    impactBuilder.registerFeature(Feature.LOCAL_WITHOUT_INITIALIZER);
  }

  @override
  void registerIsCheck(ir.DartType type) {
    impactBuilder
        .registerTypeUse(new TypeUse.isCheck(elementMap.getDartType(type)));
  }

  @override
  void registerImplicitCast(ir.DartType type) {
    impactBuilder.registerTypeUse(
        new TypeUse.implicitCast(elementMap.getDartType(type)));
  }

  @override
  void registerAsCast(ir.DartType type) {
    impactBuilder
        .registerTypeUse(new TypeUse.asCast(elementMap.getDartType(type)));
  }

  @override
  void registerThrow() {
    impactBuilder.registerFeature(Feature.THROW_EXPRESSION);
  }

  @override
  void registerSyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation) {
    Object receiverConstraint =
        _computeReceiverConstraint(iteratorType, iteratorClassRelation);
    impactBuilder.registerFeature(Feature.SYNC_FOR_IN);
    impactBuilder.registerDynamicUse(
        new DynamicUse(Selectors.iterator, receiverConstraint, const []));
    impactBuilder.registerDynamicUse(
        new DynamicUse(Selectors.current, receiverConstraint, const []));
    impactBuilder.registerDynamicUse(
        new DynamicUse(Selectors.moveNext, receiverConstraint, const []));
  }

  @override
  void registerAsyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation) {
    Object receiverConstraint =
        _computeReceiverConstraint(iteratorType, iteratorClassRelation);
    impactBuilder.registerFeature(Feature.ASYNC_FOR_IN);
    impactBuilder.registerDynamicUse(
        new DynamicUse(Selectors.cancel, receiverConstraint, const []));
    impactBuilder.registerDynamicUse(
        new DynamicUse(Selectors.current, receiverConstraint, const []));
    impactBuilder.registerDynamicUse(
        new DynamicUse(Selectors.moveNext, receiverConstraint, const []));
  }

  @override
  void registerCatch() {
    impactBuilder.registerFeature(Feature.CATCH_STATEMENT);
  }

  @override
  void registerStackTrace() {
    impactBuilder.registerFeature(Feature.STACK_TRACE_IN_CATCH);
  }

  @override
  void registerCatchType(ir.DartType type) {
    impactBuilder
        .registerTypeUse(new TypeUse.catchType(elementMap.getDartType(type)));
  }

  @override
  void registerTypeLiteral(ir.DartType type, ir.LibraryDependency import) {
    ImportEntity deferredImport = elementMap.getImport(import);
    impactBuilder.registerTypeUse(
        new TypeUse.typeLiteral(elementMap.getDartType(type), deferredImport));
  }

  @override
  void registerFieldInitialization(ir.Field node) {
    impactBuilder
        .registerStaticUse(new StaticUse.fieldInit(elementMap.getField(node)));
  }

  @override
  void registerFieldConstantInitialization(
      ir.Field node, ConstantReference constant) {
    impactBuilder.registerStaticUse(new StaticUse.fieldConstantInit(
        elementMap.getField(node),
        _constantValuefier.visitConstant(constant.constant)));
  }

  @override
  void registerRedirectingInitializer(
      ir.Constructor constructor,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    ConstructorEntity target = elementMap.getConstructor(constructor);
    impactBuilder.registerStaticUse(new StaticUse.superConstructorInvoke(
        target,
        new CallStructure(positionalArguments + namedArguments.length,
            namedArguments, typeArguments.length)));
  }

  @override
  void registerLoadLibrary() {
    impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
        commonElements.loadDeferredLibrary, CallStructure.ONE_ARG));
    impactBuilder.registerFeature(Feature.LOAD_LIBRARY);
  }

  @override
  void registerSwitchStatementNode(ir.SwitchStatement node) {
    bool overridesEquals(InterfaceType type) {
      if (type == commonElements.symbolImplementationType) {
        // Treat symbol constants as if Symbol doesn't override `==`.
        return false;
      }
      ClassEntity cls = type.element;
      while (cls != null) {
        MemberEntity member =
            elementMap.elementEnvironment.lookupClassMember(cls, '==');
        if (member.isAbstract) {
          cls = elementMap.elementEnvironment.getSuperClass(cls);
        } else {
          return member.enclosingClass != commonElements.objectClass &&
              member.enclosingClass != commonElements.jsInterceptorClass;
        }
      }
      return false;
    }

    for (ir.SwitchCase switchCase in node.cases) {
      for (ir.Expression expression in switchCase.expressions) {
        ConstantValue value =
            elementMap.getConstantValue(staticTypeContext, expression);
        DartType type = value.getType(elementMap.commonElements);
        if (type == commonElements.doubleType) {
          reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(expression),
              MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
              {'type': "double"});
        } else if (type == commonElements.functionType) {
          reporter.reportErrorMessage(computeSourceSpanFromTreeNode(node),
              MessageKind.SWITCH_CASE_FORBIDDEN, {'type': "Function"});
        } else if (value.isObject &&
            type != commonElements.typeLiteralType &&
            overridesEquals(type)) {
          reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(expression),
              MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
              {'type': typeToString(type)});
        }
      }
    }
  }
}
