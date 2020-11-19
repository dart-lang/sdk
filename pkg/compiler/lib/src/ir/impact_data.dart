// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../serialization/serialization.dart';
import '../util/enumset.dart';
import 'constants.dart';
import 'impact.dart';
import 'runtime_type_analysis.dart';
import 'static_type.dart';

/// [ImpactRegistry] that stores registered impact in an [ImpactData] object.
abstract class ImpactRegistryMixin implements ImpactRegistry {
  final ImpactDataImpl _data = new ImpactDataImpl();

  ImpactData get impactData => _data;

  void _registerFeature(_Feature feature) {
    _data._features ??= new EnumSet<_Feature>();
    _data._features.add(feature);
  }

  void _registerTypeUse(ir.DartType type, _TypeUseKind kind) {
    _data._typeUses ??= [];
    _data._typeUses.add(new _TypeUse(type, kind));
  }

  @override
  void registerSuperInitializer(
      ir.Constructor source,
      ir.Constructor target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    _data._superInitializers ??= [];
    _data._superInitializers.add(new _SuperInitializer(
        source,
        target,
        new _CallStructure(
            positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerSuperSet(ir.Name name) {
    _data._superSets ??= [];
    _data._superSets.add(name);
  }

  @override
  void registerSuperGet(ir.Name name) {
    _data._superGets ??= [];
    _data._superGets.add(name);
  }

  @override
  void registerSuperInvocation(ir.Name name, int positionalArguments,
      List<String> namedArguments, List<ir.DartType> typeArguments) {
    _data._superInvocations ??= [];
    _data._superInvocations.add(new _SuperInvocation(
        name,
        new _CallStructure(
            positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerInstanceSet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target) {
    _data._instanceSets ??= [];
    _data._instanceSets
        .add(new _InstanceAccess(receiverType, relation, target));
  }

  @override
  void registerDynamicSet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name) {
    _data._dynamicSets ??= [];
    _data._dynamicSets.add(new _DynamicAccess(receiverType, relation, name));
  }

  @override
  void registerInstanceGet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target) {
    _data._instanceGets ??= [];
    _data._instanceGets
        .add(new _InstanceAccess(receiverType, relation, target));
  }

  @override
  void registerDynamicGet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name) {
    _data._dynamicGets ??= [];
    _data._dynamicGets.add(new _DynamicAccess(receiverType, relation, name));
  }

  @override
  void registerFunctionInvocation(
      ir.DartType receiverType,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    _data._functionInvocations ??= [];
    _data._functionInvocations.add(new _FunctionInvocation(
        receiverType,
        new _CallStructure(
            positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerInstanceInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Member target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    _data._instanceInvocations ??= [];
    _data._instanceInvocations.add(new _InstanceInvocation(
        receiverType,
        relation,
        target,
        new _CallStructure(
            positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerDynamicInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Name name,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    _data._dynamicInvocations ??= [];
    _data._dynamicInvocations.add(new _DynamicInvocation(
        receiverType,
        relation,
        name,
        new _CallStructure(
            positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerLocalFunctionInvocation(
      ir.FunctionDeclaration localFunction,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    _data._localFunctionInvocations ??= [];
    _data._localFunctionInvocations.add(new _LocalFunctionInvocation(
        localFunction,
        new _CallStructure(
            positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerStaticInvocation(
      ir.Procedure target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency import) {
    _data._staticInvocations ??= [];
    _data._staticInvocations.add(new _StaticInvocation(
        target,
        new _CallStructure(positionalArguments, namedArguments, typeArguments),
        import));
  }

  @override
  void registerNew(
      ir.Member constructor,
      ir.InterfaceType type,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency import,
      {bool isConst}) {
    _data._constructorInvocations ??= [];
    _data._constructorInvocations.add(new _ConstructorInvocation(
        constructor,
        type,
        new _CallStructure(positionalArguments, namedArguments, typeArguments),
        import,
        isConst: isConst));
  }

  @override
  void registerConstInstantiation(ir.Class cls, List<ir.DartType> typeArguments,
      ir.LibraryDependency import) {
    _data._constInstantiations ??= [];
    _data._constInstantiations
        .add(new _ConstInstantiation(cls, typeArguments, import));
  }

  @override
  void registerLazyField() {
    _registerFeature(_Feature.lazyField);
  }

  @override
  void registerParameterCheck(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.parameterCheck);
  }

  @override
  void registerRedirectingInitializer(
      ir.Constructor constructor,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    _data._redirectingInitializers ??= [];
    _data._redirectingInitializers.add(new _RedirectingInitializer(
        constructor,
        new _CallStructure(
            positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerLoadLibrary() {
    _registerFeature(_Feature.loadLibrary);
  }

  @override
  void registerFieldInitialization(ir.Field node) {
    _data._fieldInitializers ??= [];
    _data._fieldInitializers.add(node);
  }

  @override
  void registerFieldConstantInitialization(
      ir.Field node, ConstantReference constant) {
    _data._fieldConstantInitializers ??= {};
    _data._fieldConstantInitializers.putIfAbsent(node, () => []).add(constant);
  }

  @override
  void registerTypeLiteral(ir.DartType type, ir.LibraryDependency import) {
    _data._typeLiterals ??= [];
    _data._typeLiterals.add(new _TypeLiteral(type, import));
  }

  @override
  void registerCatchType(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.catchType);
  }

  @override
  void registerStackTrace() {
    _registerFeature(_Feature.stackTrace);
  }

  @override
  void registerCatch() {
    _registerFeature(_Feature.catchClause);
  }

  @override
  void registerAsyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation) {
    _data._forInData ??= [];
    _data._forInData.add(new _ForInData(
        iterableType, iteratorType, iteratorClassRelation,
        isAsync: true));
  }

  @override
  void registerSyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation) {
    _data._forInData ??= [];
    _data._forInData.add(new _ForInData(
        iterableType, iteratorType, iteratorClassRelation,
        isAsync: false));
  }

  @override
  void registerThrow() {
    _registerFeature(_Feature.throwExpression);
  }

  @override
  void registerAsCast(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.asCast);
  }

  @override
  void registerImplicitCast(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.implicitCast);
  }

  @override
  void registerIsCheck(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.isCheck);
  }

  @override
  void registerLocalWithoutInitializer() {
    _registerFeature(_Feature.localWithoutInitializer);
  }

  @override
  void registerLocalFunction(ir.TreeNode node) {
    _data._localFunctions ??= [];
    _data._localFunctions.add(node);
  }

  @override
  void registerStringConcatenation() {
    _registerFeature(_Feature.stringConcatenation);
  }

  @override
  void registerAsyncStar(ir.DartType elementType) {
    _registerTypeUse(elementType, _TypeUseKind.asyncStarMarker);
  }

  @override
  void registerAsync(ir.DartType elementType) {
    _registerTypeUse(elementType, _TypeUseKind.asyncMarker);
  }

  @override
  void registerSyncStar(ir.DartType elementType) {
    _registerTypeUse(elementType, _TypeUseKind.syncStarMarker);
  }

  @override
  void registerGenericInstantiation(
      ir.FunctionType expressionType, List<ir.DartType> typeArguments) {
    _data._genericInstantiations ??= [];
    _data._genericInstantiations
        .add(new _GenericInstantiation(expressionType, typeArguments));
  }

  @override
  void registerAssert({bool withMessage}) {
    _registerFeature(withMessage
        ? _Feature.assertWithMessage
        : _Feature.assertWithoutMessage);
  }

  @override
  void registerStaticSet(ir.Member member, ir.LibraryDependency import) {
    _data._staticSets ??= [];
    _data._staticSets.add(new _StaticAccess(member, import));
  }

  @override
  void registerStaticGet(ir.Member member, ir.LibraryDependency import) {
    _data._staticGets ??= [];
    _data._staticGets.add(new _StaticAccess(member, import));
  }

  @override
  void registerStaticTearOff(
      ir.Procedure procedure, ir.LibraryDependency import) {
    _data._staticTearOffs ??= [];
    _data._staticTearOffs.add(new _StaticAccess(procedure, import));
  }

  @override
  void registerMapLiteral(ir.DartType keyType, ir.DartType valueType,
      {bool isConst, bool isEmpty}) {
    _data._mapLiterals ??= [];
    _data._mapLiterals.add(new _MapLiteral(keyType, valueType,
        isConst: isConst, isEmpty: isEmpty));
  }

  @override
  void registerListLiteral(ir.DartType elementType,
      {bool isConst, bool isEmpty}) {
    _data._listLiterals ??= [];
    _data._listLiterals.add(
        new _ContainerLiteral(elementType, isConst: isConst, isEmpty: isEmpty));
  }

  @override
  void registerSetLiteral(ir.DartType elementType,
      {bool isConst, bool isEmpty}) {
    _data._setLiterals ??= [];
    _data._setLiterals.add(
        new _ContainerLiteral(elementType, isConst: isConst, isEmpty: isEmpty));
  }

  @override
  void registerNullLiteral() {
    _registerFeature(_Feature.nullLiteral);
  }

  @override
  void registerSymbolLiteral(String value) {
    _data._symbolLiterals ??= {};
    _data._symbolLiterals.add(value);
  }

  @override
  void registerStringLiteral(String value) {
    _data._stringLiterals ??= {};
    _data._stringLiterals.add(value);
  }

  @override
  void registerBoolLiteral(bool value) {
    _data._boolLiterals ??= {};
    _data._boolLiterals.add(value);
  }

  @override
  void registerDoubleLiteral(double value) {
    _data._doubleLiterals ??= {};
    _data._doubleLiterals.add(value);
  }

  @override
  void registerIntLiteral(int value) {
    _data._intLiterals ??= {};
    _data._intLiterals.add(value);
  }

  @override
  void registerRuntimeTypeUse(ir.PropertyGet node, RuntimeTypeUseKind kind,
      ir.DartType receiverType, ir.DartType argumentType) {
    _data._runtimeTypeUses ??= [];
    _data._runtimeTypeUses
        .add(new _RuntimeTypeUse(node, kind, receiverType, argumentType));
  }

  @override
  void registerConstructorNode(ir.Constructor node) {
    _data._constructorNodes ??= [];
    _data._constructorNodes.add(node);
  }

  @override
  void registerFieldNode(ir.Field node) {
    _data._fieldNodes ??= [];
    _data._fieldNodes.add(node);
  }

  @override
  void registerProcedureNode(ir.Procedure node) {
    _data._procedureNodes ??= [];
    _data._procedureNodes.add(node);
  }

  @override
  void registerStaticInvocationNode(ir.StaticInvocation node) {
    _data._staticInvocationNodes ??= [];
    _data._staticInvocationNodes.add(node);
  }

  @override
  void registerSwitchStatementNode(ir.SwitchStatement node) {
    _data._switchStatementNodes ??= [];
    _data._switchStatementNodes.add(node);
  }

  @override
  void registerConstConstructorInvocationNode(ir.ConstructorInvocation node) {
    _data._constConstructorInvocationNodes ??= [];
    _data._constConstructorInvocationNodes.add(node);
  }
}

/// Data object that contains the world impact data derived purely from kernel.
abstract class ImpactData {
  factory ImpactData.fromDataSource(DataSource source) =
      ImpactDataImpl.fromDataSource;

  void toDataSink(DataSink sink);

  /// Registers the impact data with [registry].
  void apply(ImpactRegistry registry);
}

class ImpactDataImpl implements ImpactData {
  static const String tag = 'ImpactData';

  List<_SuperInitializer> _superInitializers;
  List<ir.Name> _superSets;
  List<ir.Name> _superGets;
  List<_SuperInvocation> _superInvocations;
  List<_InstanceAccess> _instanceSets;
  List<_DynamicAccess> _dynamicSets;
  List<_InstanceAccess> _instanceGets;
  List<_DynamicAccess> _dynamicGets;
  List<_FunctionInvocation> _functionInvocations;
  List<_InstanceInvocation> _instanceInvocations;
  List<_DynamicInvocation> _dynamicInvocations;
  List<_LocalFunctionInvocation> _localFunctionInvocations;
  List<_StaticInvocation> _staticInvocations;
  List<_ConstructorInvocation> _constructorInvocations;
  List<_ConstInstantiation> _constInstantiations;
  EnumSet<_Feature> _features;
  List<_TypeUse> _typeUses;
  List<_RedirectingInitializer> _redirectingInitializers;
  List<ir.Field> _fieldInitializers;
  Map<ir.Field, List<ConstantReference>> _fieldConstantInitializers;
  List<_TypeLiteral> _typeLiterals;
  List<ir.TreeNode> _localFunctions;
  List<_GenericInstantiation> _genericInstantiations;
  List<_StaticAccess> _staticSets;
  List<_StaticAccess> _staticGets;
  List<_StaticAccess> _staticTearOffs;
  List<_MapLiteral> _mapLiterals;
  List<_ContainerLiteral> _listLiterals;
  List<_ContainerLiteral> _setLiterals;
  Set<String> _symbolLiterals;
  Set<String> _stringLiterals;
  Set<bool> _boolLiterals;
  Set<double> _doubleLiterals;
  Set<int> _intLiterals;
  List<_RuntimeTypeUse> _runtimeTypeUses;
  List<_ForInData> _forInData;

  // TODO(johnniwinther): Remove these when CFE provides constants.
  List<ir.Constructor> _constructorNodes;
  List<ir.Field> _fieldNodes;
  List<ir.Procedure> _procedureNodes;
  List<ir.SwitchStatement> _switchStatementNodes;
  List<ir.StaticInvocation> _staticInvocationNodes;
  List<ir.ConstructorInvocation> _constConstructorInvocationNodes;

  ImpactDataImpl();

  ImpactDataImpl.fromDataSource(DataSource source) {
    source.begin(tag);
    _superInitializers = source.readList(
        () => new _SuperInitializer.fromDataSource(source),
        emptyAsNull: true);
    _superSets = source.readList(() => source.readName(), emptyAsNull: true);
    _superGets = source.readList(() => source.readName(), emptyAsNull: true);
    _superInvocations = source.readList(
        () => new _SuperInvocation.fromDataSource(source),
        emptyAsNull: true);
    _instanceSets = source.readList(
        () => new _InstanceAccess.fromDataSource(source),
        emptyAsNull: true);
    _dynamicSets = source.readList(
        () => new _DynamicAccess.fromDataSource(source),
        emptyAsNull: true);
    _instanceGets = source.readList(
        () => new _InstanceAccess.fromDataSource(source),
        emptyAsNull: true);
    _dynamicGets = source.readList(
        () => new _DynamicAccess.fromDataSource(source),
        emptyAsNull: true);
    _functionInvocations = source.readList(
        () => new _FunctionInvocation.fromDataSource(source),
        emptyAsNull: true);
    _instanceInvocations = source.readList(
        () => new _InstanceInvocation.fromDataSource(source),
        emptyAsNull: true);
    _dynamicInvocations = source.readList(
        () => new _DynamicInvocation.fromDataSource(source),
        emptyAsNull: true);
    _localFunctionInvocations = source.readList(
        () => new _LocalFunctionInvocation.fromDataSource(source),
        emptyAsNull: true);
    _staticInvocations = source.readList(
        () => new _StaticInvocation.fromDataSource(source),
        emptyAsNull: true);
    _constructorInvocations = source.readList(
        () => new _ConstructorInvocation.fromDataSource(source),
        emptyAsNull: true);
    _features = new EnumSet<_Feature>.fromValue(source.readInt());
    _typeUses = source.readList(() => new _TypeUse.fromDataSource(source),
        emptyAsNull: true);
    _redirectingInitializers = source.readList(
        () => new _RedirectingInitializer.fromDataSource(source),
        emptyAsNull: true);
    _fieldInitializers = source.readMemberNodes(emptyAsNull: true);
    _fieldConstantInitializers =
        source.readMemberNodeMap(source.readTreeNodes, emptyAsNull: true);
    _typeLiterals = source.readList(
        () => new _TypeLiteral.fromDataSource(source),
        emptyAsNull: true);
    _localFunctions = source.readTreeNodes(emptyAsNull: true);
    _genericInstantiations = source.readList(
        () => new _GenericInstantiation.fromDataSource(source),
        emptyAsNull: true);
    _staticSets = source.readList(
        () => new _StaticAccess.fromDataSource(source),
        emptyAsNull: true);
    _staticGets = source.readList(
        () => new _StaticAccess.fromDataSource(source),
        emptyAsNull: true);
    _staticTearOffs = source.readList(
        () => new _StaticAccess.fromDataSource(source),
        emptyAsNull: true);
    _mapLiterals = source.readList(() => new _MapLiteral.fromDataSource(source),
        emptyAsNull: true);
    _listLiterals = source.readList(
        () => new _ContainerLiteral.fromDataSource(source),
        emptyAsNull: true);
    _setLiterals = source.readList(
        () => new _ContainerLiteral.fromDataSource(source),
        emptyAsNull: true);
    _symbolLiterals = source.readStrings(emptyAsNull: true).toSet();
    _stringLiterals = source.readStrings(emptyAsNull: true).toSet();
    _boolLiterals =
        source.readList(() => source.readBool(), emptyAsNull: true).toSet();
    _doubleLiterals = source
        .readList(() => source.readDoubleValue(), emptyAsNull: true)
        .toSet();
    _intLiterals = source
        .readList(() => source.readIntegerValue(), emptyAsNull: true)
        .toSet();
    _runtimeTypeUses = source.readList(
        () => new _RuntimeTypeUse.fromDataSource(source),
        emptyAsNull: true);

    // TODO(johnniwinther): Remove these when CFE provides constants.
    _constructorNodes =
        source.readMemberNodes<ir.Constructor>(emptyAsNull: true);
    _fieldNodes = source.readMemberNodes<ir.Field>(emptyAsNull: true);
    _procedureNodes = source.readMemberNodes<ir.Procedure>(emptyAsNull: true);
    _switchStatementNodes =
        source.readTreeNodes<ir.SwitchStatement>(emptyAsNull: true);
    _staticInvocationNodes =
        source.readTreeNodes<ir.StaticInvocation>(emptyAsNull: true);
    _constConstructorInvocationNodes =
        source.readTreeNodes<ir.ConstructorInvocation>(emptyAsNull: true);
    source.end(tag);
  }

  @override
  void toDataSink(DataSink sink) {
    sink.begin(tag);

    sink.writeList(
        _superInitializers, (_SuperInitializer o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_superSets, sink.writeName, allowNull: true);
    sink.writeList(_superGets, sink.writeName, allowNull: true);
    sink.writeList(
        _superInvocations, (_SuperInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_instanceSets, (_InstanceAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_dynamicSets, (_DynamicAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_instanceGets, (_InstanceAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_dynamicGets, (_DynamicAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(
        _functionInvocations, (_FunctionInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(
        _instanceInvocations, (_InstanceInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(
        _dynamicInvocations, (_DynamicInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_localFunctionInvocations,
        (_LocalFunctionInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(
        _staticInvocations, (_StaticInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_constructorInvocations,
        (_ConstructorInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeInt(_features?.value ?? 0);
    sink.writeList(_typeUses, (_TypeUse o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_redirectingInitializers,
        (_RedirectingInitializer o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeMemberNodes(_fieldInitializers, allowNull: true);
    sink.writeMemberNodeMap(_fieldConstantInitializers, sink.writeTreeNodes,
        allowNull: true);
    sink.writeList(_typeLiterals, (_TypeLiteral o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeTreeNodes(_localFunctions, allowNull: true);
    sink.writeList(
        _genericInstantiations, (_GenericInstantiation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_staticSets, (_StaticAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_staticGets, (_StaticAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_staticTearOffs, (_StaticAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_mapLiterals, (_MapLiteral o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_listLiterals, (_ContainerLiteral o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_setLiterals, (_ContainerLiteral o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeStrings(_symbolLiterals, allowNull: true);
    sink.writeStrings(_stringLiterals, allowNull: true);
    sink.writeList(_boolLiterals, sink.writeBool, allowNull: true);
    sink.writeList(_doubleLiterals, sink.writeDoubleValue, allowNull: true);
    sink.writeList(_intLiterals, sink.writeIntegerValue, allowNull: true);
    sink.writeList(_runtimeTypeUses, (_RuntimeTypeUse o) => o.toDataSink(sink),
        allowNull: true);

    // TODO(johnniwinther): Remove these when CFE provides constants.
    sink.writeMemberNodes(_constructorNodes, allowNull: true);
    sink.writeMemberNodes(_fieldNodes, allowNull: true);
    sink.writeMemberNodes(_procedureNodes, allowNull: true);
    sink.writeTreeNodes(_switchStatementNodes, allowNull: true);
    sink.writeTreeNodes(_staticInvocationNodes, allowNull: true);
    sink.writeTreeNodes(_constConstructorInvocationNodes, allowNull: true);

    sink.end(tag);
  }

  @override
  void apply(ImpactRegistry registry) {
    if (_superInitializers != null) {
      for (_SuperInitializer data in _superInitializers) {
        registry.registerSuperInitializer(
            data.source,
            data.target,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_superSets != null) {
      for (ir.Name data in _superSets) {
        registry.registerSuperSet(data);
      }
    }
    if (_superGets != null) {
      for (ir.Name data in _superGets) {
        registry.registerSuperGet(data);
      }
    }
    if (_superInvocations != null) {
      for (_SuperInvocation data in _superInvocations) {
        registry.registerSuperInvocation(
            data.name,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_instanceSets != null) {
      for (_InstanceAccess data in _instanceSets) {
        registry.registerInstanceSet(
            data.receiverType, data.classRelation, data.target);
      }
    }
    if (_dynamicSets != null) {
      for (_DynamicAccess data in _dynamicSets) {
        registry.registerDynamicSet(
            data.receiverType, data.classRelation, data.name);
      }
    }
    if (_instanceGets != null) {
      for (_InstanceAccess data in _instanceGets) {
        registry.registerInstanceGet(
            data.receiverType, data.classRelation, data.target);
      }
    }
    if (_dynamicGets != null) {
      for (_DynamicAccess data in _dynamicGets) {
        registry.registerDynamicGet(
            data.receiverType, data.classRelation, data.name);
      }
    }
    if (_functionInvocations != null) {
      for (_FunctionInvocation data in _functionInvocations) {
        registry.registerFunctionInvocation(
            data.receiverType,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_instanceInvocations != null) {
      for (_InstanceInvocation data in _instanceInvocations) {
        registry.registerInstanceInvocation(
            data.receiverType,
            data.classRelation,
            data.target,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_dynamicInvocations != null) {
      for (_DynamicInvocation data in _dynamicInvocations) {
        registry.registerDynamicInvocation(
            data.receiverType,
            data.classRelation,
            data.name,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_localFunctionInvocations != null) {
      for (_LocalFunctionInvocation data in _localFunctionInvocations) {
        registry.registerLocalFunctionInvocation(
            data.localFunction,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_staticInvocations != null) {
      for (_StaticInvocation data in _staticInvocations) {
        registry.registerStaticInvocation(
            data.target,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments,
            data.import);
        ;
      }
    }
    if (_constructorInvocations != null) {
      for (_ConstructorInvocation data in _constructorInvocations) {
        registry.registerNew(
            data.constructor,
            data.type,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments,
            data.import,
            isConst: data.isConst);
      }
    }
    if (_constInstantiations != null) {
      for (_ConstInstantiation data in _constInstantiations) {
        registry.registerConstInstantiation(
            data.cls, data.typeArguments, data.import);
      }
    }
    if (_features != null) {
      for (_Feature data in _features.iterable(_Feature.values)) {
        switch (data) {
          case _Feature.lazyField:
            registry.registerLazyField();
            break;
          case _Feature.loadLibrary:
            registry.registerLoadLibrary();
            break;
          case _Feature.stackTrace:
            registry.registerStackTrace();
            break;
          case _Feature.catchClause:
            registry.registerCatch();
            break;
          case _Feature.throwExpression:
            registry.registerThrow();
            break;
          case _Feature.localWithoutInitializer:
            registry.registerLocalWithoutInitializer();
            break;
          case _Feature.stringConcatenation:
            registry.registerStringConcatenation();
            break;
          case _Feature.assertWithMessage:
            registry.registerAssert(withMessage: true);
            break;
          case _Feature.assertWithoutMessage:
            registry.registerAssert(withMessage: false);
            break;
          case _Feature.nullLiteral:
            registry.registerNullLiteral();
            break;
        }
      }
    }
    if (_typeUses != null) {
      for (_TypeUse data in _typeUses) {
        switch (data.kind) {
          case _TypeUseKind.parameterCheck:
            registry.registerParameterCheck(data.type);
            break;
          case _TypeUseKind.catchType:
            registry.registerCatchType(data.type);
            break;
          case _TypeUseKind.asCast:
            registry.registerAsCast(data.type);
            break;
          case _TypeUseKind.implicitCast:
            registry.registerImplicitCast(data.type);
            break;
          case _TypeUseKind.isCheck:
            registry.registerIsCheck(data.type);
            break;
          case _TypeUseKind.asyncStarMarker:
            registry.registerAsyncStar(data.type);
            break;
          case _TypeUseKind.asyncMarker:
            registry.registerAsync(data.type);
            break;
          case _TypeUseKind.syncStarMarker:
            registry.registerSyncStar(data.type);
            break;
        }
      }
    }
    if (_redirectingInitializers != null) {
      for (_RedirectingInitializer data in _redirectingInitializers) {
        registry.registerRedirectingInitializer(
            data.constructor,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_fieldInitializers != null) {
      for (ir.Field data in _fieldInitializers) {
        registry.registerFieldInitialization(data);
      }
    }
    if (_fieldConstantInitializers != null) {
      _fieldConstantInitializers
          .forEach((ir.Field field, List<ConstantReference> constants) {
        for (ConstantReference constant in constants) {
          registry.registerFieldConstantInitialization(field, constant);
        }
      });
    }
    if (_typeLiterals != null) {
      for (_TypeLiteral data in _typeLiterals) {
        registry.registerTypeLiteral(data.type, data.import);
      }
    }
    if (_localFunctions != null) {
      for (ir.TreeNode data in _localFunctions) {
        registry.registerLocalFunction(data);
      }
    }
    if (_genericInstantiations != null) {
      for (_GenericInstantiation data in _genericInstantiations) {
        registry.registerGenericInstantiation(
            data.expressionType, data.typeArguments);
      }
    }
    if (_staticSets != null) {
      for (_StaticAccess data in _staticSets) {
        registry.registerStaticSet(data.target, data.import);
      }
    }
    if (_staticGets != null) {
      for (_StaticAccess data in _staticGets) {
        registry.registerStaticGet(data.target, data.import);
      }
    }
    if (_staticTearOffs != null) {
      for (_StaticAccess data in _staticTearOffs) {
        registry.registerStaticTearOff(data.target, data.import);
      }
    }
    if (_mapLiterals != null) {
      for (_MapLiteral data in _mapLiterals) {
        registry.registerMapLiteral(data.keyType, data.valueType,
            isConst: data.isConst, isEmpty: data.isEmpty);
      }
    }
    if (_listLiterals != null) {
      for (_ContainerLiteral data in _listLiterals) {
        registry.registerListLiteral(data.elementType,
            isConst: data.isConst, isEmpty: data.isEmpty);
      }
    }
    if (_setLiterals != null) {
      for (_ContainerLiteral data in _setLiterals) {
        registry.registerSetLiteral(data.elementType,
            isConst: data.isConst, isEmpty: data.isEmpty);
      }
    }
    if (_symbolLiterals != null) {
      for (String data in _symbolLiterals) {
        registry.registerSymbolLiteral(data);
      }
    }
    if (_stringLiterals != null) {
      for (String data in _stringLiterals) {
        registry.registerStringLiteral(data);
      }
    }
    if (_boolLiterals != null) {
      for (bool data in _boolLiterals) {
        registry.registerBoolLiteral(data);
      }
    }
    if (_doubleLiterals != null) {
      for (double data in _doubleLiterals) {
        registry.registerDoubleLiteral(data);
      }
    }
    if (_intLiterals != null) {
      for (int data in _intLiterals) {
        registry.registerIntLiteral(data);
      }
    }
    if (_runtimeTypeUses != null) {
      for (_RuntimeTypeUse data in _runtimeTypeUses) {
        registry.registerRuntimeTypeUse(
            data.node, data.kind, data.receiverType, data.argumentType);
      }
    }
    if (_forInData != null) {
      for (_ForInData data in _forInData) {
        if (data.isAsync) {
          registry.registerAsyncForIn(
              data.iterableType, data.iteratorType, data.iteratorClassRelation);
        } else {
          registry.registerSyncForIn(
              data.iterableType, data.iteratorType, data.iteratorClassRelation);
        }
      }
    }

    // TODO(johnniwinther): Remove these when CFE provides constants.
    if (_constructorNodes != null) {
      for (ir.Constructor data in _constructorNodes) {
        registry.registerConstructorNode(data);
      }
    }
    if (_fieldNodes != null) {
      for (ir.Field data in _fieldNodes) {
        registry.registerFieldNode(data);
      }
    }
    if (_procedureNodes != null) {
      for (ir.Procedure data in _procedureNodes) {
        registry.registerProcedureNode(data);
      }
    }
    if (_switchStatementNodes != null) {
      for (ir.SwitchStatement data in _switchStatementNodes) {
        registry.registerSwitchStatementNode(data);
      }
    }
    if (_staticInvocationNodes != null) {
      for (ir.StaticInvocation data in _staticInvocationNodes) {
        registry.registerStaticInvocationNode(data);
      }
    }
    if (_constConstructorInvocationNodes != null) {
      for (ir.ConstructorInvocation data in _constConstructorInvocationNodes) {
        registry.registerConstConstructorInvocationNode(data);
      }
    }
  }
}

class _CallStructure {
  static const String tag = '_CallStructure';

  final List<ir.DartType> typeArguments;
  final int positionalArguments;
  final List<String> namedArguments;

  _CallStructure.internal(
      this.typeArguments, this.positionalArguments, this.namedArguments);

  factory _CallStructure(int positionalArguments, List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    return new _CallStructure.internal(
        typeArguments, positionalArguments, namedArguments);
  }

  factory _CallStructure.fromDataSource(DataSource source) {
    source.begin(tag);
    List<ir.DartType> typeArguments = source.readDartTypeNodes();
    int positionalArguments = source.readInt();
    List<String> namedArguments = source.readStrings();
    source.end(tag);
    return new _CallStructure.internal(
        typeArguments, positionalArguments, namedArguments);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNodes(typeArguments);
    sink.writeInt(positionalArguments);
    sink.writeStrings(namedArguments);
    sink.end(tag);
  }
}

class _SuperInitializer {
  static const String tag = '_SuperInitializer';

  final ir.Constructor source;
  final ir.Constructor target;
  final _CallStructure callStructure;

  _SuperInitializer(this.source, this.target, this.callStructure);

  factory _SuperInitializer.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.Constructor sourceConstructor = source.readMemberNode();
    ir.Constructor targetConstructor = source.readMemberNode();
    _CallStructure callStructure = new _CallStructure.fromDataSource(source);
    source.end(tag);
    return new _SuperInitializer(
        sourceConstructor, targetConstructor, callStructure);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberNode(source);
    sink.writeMemberNode(target);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _SuperInvocation {
  static const String tag = '_SuperInvocation';

  final ir.Name name;
  final _CallStructure callStructure;

  _SuperInvocation(this.name, this.callStructure);

  factory _SuperInvocation.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.Name name = source.readName();
    _CallStructure callStructure = new _CallStructure.fromDataSource(source);
    source.end(tag);
    return new _SuperInvocation(name, callStructure);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeName(name);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _InstanceAccess {
  static const String tag = '_InstanceAccess';

  final ir.DartType receiverType;
  final ClassRelation classRelation;
  final ir.Member target;

  _InstanceAccess(this.receiverType, this.classRelation, this.target);

  factory _InstanceAccess.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    ClassRelation classRelation = source.readEnum(ClassRelation.values);
    ir.Member target = source.readMemberNode();
    source.end(tag);
    return new _InstanceAccess(receiverType, classRelation, target);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    sink.writeEnum(classRelation);
    sink.writeMemberNode(target);
    sink.end(tag);
  }
}

class _DynamicAccess {
  static const String tag = '_DynamicAccess';

  final ir.DartType receiverType;
  final ClassRelation classRelation;
  final ir.Name name;

  _DynamicAccess(this.receiverType, this.classRelation, this.name);

  factory _DynamicAccess.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    ClassRelation classRelation = source.readEnum(ClassRelation.values);
    ir.Name name = source.readName();
    source.end(tag);
    return new _DynamicAccess(receiverType, classRelation, name);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    sink.writeEnum(classRelation);
    sink.writeName(name);
    sink.end(tag);
  }
}

class _FunctionInvocation {
  static const String tag = '_FunctionInvocation';

  final ir.DartType receiverType;
  final _CallStructure callStructure;

  _FunctionInvocation(this.receiverType, this.callStructure);

  factory _FunctionInvocation.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    _CallStructure callStructure = new _CallStructure.fromDataSource(source);
    source.end(tag);
    return new _FunctionInvocation(receiverType, callStructure);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _InstanceInvocation {
  static const String tag = '_InstanceInvocation';

  final ir.DartType receiverType;
  final ClassRelation classRelation;
  final ir.Member target;
  final _CallStructure callStructure;

  _InstanceInvocation(
      this.receiverType, this.classRelation, this.target, this.callStructure);

  factory _InstanceInvocation.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    ClassRelation classRelation = source.readEnum(ClassRelation.values);
    ir.Member target = source.readMemberNode();
    _CallStructure callStructure = new _CallStructure.fromDataSource(source);
    source.end(tag);
    return new _InstanceInvocation(
        receiverType, classRelation, target, callStructure);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    sink.writeEnum(classRelation);
    sink.writeMemberNode(target);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _DynamicInvocation {
  static const String tag = '_DynamicInvocation';

  final ir.DartType receiverType;
  final ClassRelation classRelation;
  final ir.Name name;
  final _CallStructure callStructure;

  _DynamicInvocation(
      this.receiverType, this.classRelation, this.name, this.callStructure);

  factory _DynamicInvocation.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    ClassRelation classRelation = source.readEnum(ClassRelation.values);
    ir.Name name = source.readName();
    _CallStructure callStructure = new _CallStructure.fromDataSource(source);
    source.end(tag);
    return new _DynamicInvocation(
        receiverType, classRelation, name, callStructure);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    sink.writeEnum(classRelation);
    sink.writeName(name);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _LocalFunctionInvocation {
  static const String tag = '_LocalFunctionInvocation';

  final ir.FunctionDeclaration localFunction;
  final _CallStructure callStructure;

  _LocalFunctionInvocation(this.localFunction, this.callStructure);

  factory _LocalFunctionInvocation.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.FunctionDeclaration localFunction = source.readTreeNode();
    _CallStructure callStructure = new _CallStructure.fromDataSource(source);
    source.end(tag);
    return new _LocalFunctionInvocation(localFunction, callStructure);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeTreeNode(localFunction);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _StaticInvocation {
  static const String tag = '_StaticInvocation';

  final ir.Procedure target;
  final _CallStructure callStructure;
  final ir.LibraryDependency import;

  _StaticInvocation(this.target, this.callStructure, this.import);

  factory _StaticInvocation.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.Procedure target = source.readMemberNode();
    _CallStructure callStructure = new _CallStructure.fromDataSource(source);
    ir.LibraryDependency import = source.readLibraryDependencyNodeOrNull();
    source.end(tag);
    return new _StaticInvocation(target, callStructure, import);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberNode(target);
    callStructure.toDataSink(sink);
    sink.writeLibraryDependencyNodeOrNull(import);
    sink.end(tag);
  }
}

class _ConstructorInvocation {
  static const String tag = '_ConstructorInvocation';

  final ir.Member constructor;
  final ir.InterfaceType type;
  final _CallStructure callStructure;
  final ir.LibraryDependency import;
  final bool isConst;

  _ConstructorInvocation(
      this.constructor, this.type, this.callStructure, this.import,
      {this.isConst});

  factory _ConstructorInvocation.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.Member constructor = source.readMemberNode();
    ir.InterfaceType type = source.readDartTypeNode();
    _CallStructure callStructure = new _CallStructure.fromDataSource(source);
    ir.LibraryDependency import = source.readLibraryDependencyNodeOrNull();
    bool isConst = source.readBool();
    source.end(tag);
    return new _ConstructorInvocation(constructor, type, callStructure, import,
        isConst: isConst);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberNode(constructor);
    sink.writeDartTypeNode(type);
    callStructure.toDataSink(sink);
    sink.writeLibraryDependencyNodeOrNull(import);
    sink.writeBool(isConst);
    sink.end(tag);
  }
}

class _ConstInstantiation {
  final ir.Class cls;
  final List<ir.DartType> typeArguments;
  final ir.LibraryDependency import;

  _ConstInstantiation(this.cls, this.typeArguments, this.import);
}

enum _Feature {
  lazyField,
  loadLibrary,
  stackTrace,
  catchClause,
  throwExpression,
  localWithoutInitializer,
  stringConcatenation,
  assertWithMessage,
  assertWithoutMessage,
  nullLiteral,
}

class _TypeUse {
  static const String tag = '_TypeUse';

  final ir.DartType type;
  final _TypeUseKind kind;

  _TypeUse(this.type, this.kind);

  factory _TypeUse.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.DartType type = source.readDartTypeNode();
    _TypeUseKind kind = source.readEnum(_TypeUseKind.values);
    source.end(tag);
    return new _TypeUse(type, kind);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(type);
    sink.writeEnum(kind);
    sink.end(tag);
  }
}

enum _TypeUseKind {
  parameterCheck,
  catchType,
  asCast,
  implicitCast,
  isCheck,
  asyncStarMarker,
  asyncMarker,
  syncStarMarker,
}

class _RedirectingInitializer {
  static const String tag = '_RedirectingInitializer';

  final ir.Constructor constructor;
  final _CallStructure callStructure;

  _RedirectingInitializer(this.constructor, this.callStructure);

  factory _RedirectingInitializer.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.Constructor constructor = source.readMemberNode();
    _CallStructure callStructure = new _CallStructure.fromDataSource(source);
    source.end(tag);
    return new _RedirectingInitializer(constructor, callStructure);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberNode(constructor);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _TypeLiteral {
  static const String tag = '_TypeLiteral';

  final ir.DartType type;
  final ir.LibraryDependency import;

  _TypeLiteral(this.type, this.import);

  factory _TypeLiteral.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.DartType type = source.readDartTypeNode();
    ir.LibraryDependency import = source.readLibraryDependencyNodeOrNull();
    source.end(tag);
    return new _TypeLiteral(type, import);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(type);
    sink.writeLibraryDependencyNodeOrNull(import);
    sink.end(tag);
  }
}

class _GenericInstantiation {
  static const String tag = '_GenericInstantiation';

  final ir.FunctionType expressionType;
  final List<ir.DartType> typeArguments;

  _GenericInstantiation(this.expressionType, this.typeArguments);

  factory _GenericInstantiation.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.FunctionType expressionType = source.readDartTypeNode();
    List<ir.DartType> typeArguments = source.readDartTypeNodes();
    source.end(tag);
    return new _GenericInstantiation(expressionType, typeArguments);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(expressionType);
    sink.writeDartTypeNodes(typeArguments);
    sink.end(tag);
  }
}

class _StaticAccess {
  static const String tag = '_StaticAccess';

  final ir.Member target;
  final ir.LibraryDependency import;

  _StaticAccess(this.target, this.import);

  factory _StaticAccess.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.Member target = source.readMemberNode();
    ir.LibraryDependency import = source.readLibraryDependencyNodeOrNull();
    source.end(tag);
    return new _StaticAccess(target, import);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberNode(target);
    sink.writeLibraryDependencyNodeOrNull(import);
    sink.end(tag);
  }
}

class _MapLiteral {
  static const String tag = '_MapLiteral';

  final ir.DartType keyType;
  final ir.DartType valueType;
  final bool isConst;
  final bool isEmpty;

  _MapLiteral(this.keyType, this.valueType, {this.isConst, this.isEmpty});

  factory _MapLiteral.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.DartType keyType = source.readDartTypeNode();
    ir.DartType valueType = source.readDartTypeNode();
    bool isConst = source.readBool();
    bool isEmpty = source.readBool();
    source.end(tag);
    return _MapLiteral(keyType, valueType, isConst: isConst, isEmpty: isEmpty);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(keyType);
    sink.writeDartTypeNode(valueType);
    sink.writeBool(isConst);
    sink.writeBool(isEmpty);
    sink.end(tag);
  }
}

class _ContainerLiteral {
  static const String tag = '_ContainerLiteral';

  final ir.DartType elementType;
  final bool isConst;
  final bool isEmpty;

  _ContainerLiteral(this.elementType, {this.isConst, this.isEmpty});

  factory _ContainerLiteral.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.DartType elementType = source.readDartTypeNode();
    bool isConst = source.readBool();
    bool isEmpty = source.readBool();
    return new _ContainerLiteral(elementType,
        isConst: isConst, isEmpty: isEmpty);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(elementType);
    sink.writeBool(isConst);
    sink.writeBool(isEmpty);
    sink.end(tag);
  }
}

class _RuntimeTypeUse {
  static const String tag = '_RuntimeTypeUse';

  final ir.PropertyGet node;
  final RuntimeTypeUseKind kind;
  final ir.DartType receiverType;
  final ir.DartType argumentType;

  _RuntimeTypeUse(this.node, this.kind, this.receiverType, this.argumentType);

  factory _RuntimeTypeUse.fromDataSource(DataSource source) {
    source.begin(tag);
    ir.TreeNode node = source.readTreeNode();
    RuntimeTypeUseKind kind = source.readEnum(RuntimeTypeUseKind.values);
    ir.DartType receiverType = source.readDartTypeNode();
    ir.DartType argumentType = source.readDartTypeNode(allowNull: true);
    return new _RuntimeTypeUse(node, kind, receiverType, argumentType);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeTreeNode(node);
    sink.writeEnum(kind);
    sink.writeDartTypeNode(receiverType);
    sink.writeDartTypeNode(argumentType, allowNull: true);
    sink.end(tag);
  }
}

class _ForInData {
  final ir.DartType iterableType;
  final ir.DartType iteratorType;
  final ClassRelation iteratorClassRelation;
  final bool isAsync;

  _ForInData(this.iterableType, this.iteratorType, this.iteratorClassRelation,
      {this.isAsync});
}
