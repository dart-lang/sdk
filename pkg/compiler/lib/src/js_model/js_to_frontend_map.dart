// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../closure.dart';
import '../common.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import 'element_map_impl.dart';
import 'elements.dart';

/// Map from 'frontend' to 'backend' elements.
///
/// Frontend elements are what we read in, these typically represents concepts
/// in Dart. Backend elements are what we generate, these may include elements
/// that do not correspond to a Dart concept, such as closure classes.
///
/// Querying for the frontend element for a backend-only element throws an
/// exception.
class JsToFrontendMap {
  final JsKernelToElementMap _backend;
  ClosureData? _closureData;

  JsToFrontendMap(this._backend);

  ClassEntity toBackendClass(ClassEntity cls) => cls;
  LibraryEntity toBackendLibrary(LibraryEntity library) => library;

  Entity? toBackendEntity(Entity entity) {
    if (entity is ClassEntity) return toBackendClass(entity);
    if (entity is MemberEntity) return toBackendMember(entity);
    if (entity is TypeVariableEntity) {
      return toBackendTypeVariable(entity);
    }
    assert(entity is LibraryEntity, 'unexpected entity ${entity.runtimeType}');
    return toBackendLibrary(entity as LibraryEntity);
  }

  TypeVariableEntity toBackendTypeVariable(TypeVariableEntity typeVariable) {
    if (typeVariable is JLocalTypeVariable) {
      if (_closureData == null) {
        failedAt(
            typeVariable,
            'ClosureData needs to be registered before converting type variable'
            ' $typeVariable');
      }
      ClosureRepresentationInfo info =
          _closureData!.getClosureInfo(typeVariable.typeDeclaration.node);
      return _backend.elementEnvironment
          .getFunctionTypeVariables(info.callMethod!)[typeVariable.index]
          .element;
    }
    return typeVariable;
  }

  ConstantValue? toBackendConstant(ConstantValue? constant,
      {bool allowNull = false}) {
    if (constant == null) {
      if (!allowNull) {
        throw UnsupportedError('Null not allowed as constant value.');
      }
      return null;
    }
    return constant.accept(
        _ConstantConverter(_backend.types, toBackendEntity), null);
  }

  MemberEntity? toBackendMember(MemberEntity member) =>
      _backend.kToJMembers[member];

  DartType? toBackendType(DartType? type, {bool allowFreeVariables = false}) =>
      type == null
          ? null
          : _TypeConverter(_backend.types,
                  allowFreeVariables: allowFreeVariables)
              .visit(type, toBackendEntity);

  void registerClosureData(ClosureData closureData) {
    assert(_closureData == null, "Closure data has already been registered.");
    _closureData = closureData;
  }

  Set<DartType> toBackendTypeSet(Iterable<DartType> set) {
    return {for (final type in set.map(toBackendType)) type!};
  }

  Set<ClassEntity> toBackendClassSet(Iterable<ClassEntity> set) {
    return Set.of(set);
  }

  Set<MemberEntity> toBackendMemberSet(Iterable<MemberEntity> set) {
    return {
      for (final member in set.map(toBackendMember))
        // Members that are not live don't have a corresponding backend member.
        if (member != null) member
    };
  }

  Set<FieldEntity> toBackendFieldSet(Iterable<FieldEntity> set) {
    return {
      for (final member in set.map(toBackendMember))
        // Members that are not live don't have a corresponding backend member.
        if (member != null) member as FieldEntity
    };
  }

  Set<FunctionEntity> toBackendFunctionSet(Iterable<FunctionEntity> set) {
    return {
      for (final member in set.map(toBackendMember))
        // Members that are not live don't have a corresponding backend member.
        if (member != null) member as FunctionEntity
    };
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
    Map<K, V1> map, K? convertKey(K key), V2 convertValue(V1 value)) {
  Map<K, V2> newMap = {};
  map.forEach((K key, V1 value) {
    K? newKey = convertKey(key);
    V2 newValue = convertValue(value);
    if (newKey != null && newValue != null) {
      // Entities that are not used don't have a corresponding backend entity.
      newMap[newKey] = newValue;
    }
  });
  return newMap;
}

typedef _EntityConverter = Entity? Function(Entity cls);

class _TypeConverter implements DartTypeVisitor<DartType, _EntityConverter> {
  final DartTypes _dartTypes;
  final bool allowFreeVariables;

  final Map<FunctionTypeVariable, FunctionTypeVariable> _functionTypeVariables =
      {};

  _TypeConverter(this._dartTypes, {this.allowFreeVariables = false});

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
    return _dartTypes.interfaceType(converter(type.element) as ClassEntity,
        visitList(type.typeArguments, converter));
  }

  @override
  DartType visitRecordType(RecordType type, _EntityConverter converter) {
    return _dartTypes.recordType(type.shape, visitList(type.fields, converter));
  }

  @override
  DartType visitTypeVariableType(
      TypeVariableType type, _EntityConverter converter) {
    return _dartTypes
        .typeVariableType(converter(type.element) as TypeVariableEntity);
  }

  @override
  DartType visitFunctionType(FunctionType type, _EntityConverter converter) {
    List<FunctionTypeVariable> typeVariables = <FunctionTypeVariable>[];
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      typeVariables.add(_functionTypeVariables[typeVariable] =
          _dartTypes.functionTypeVariable(typeVariable.index));
    }
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      _functionTypeVariables[typeVariable]!.bound =
          visit(typeVariable.bound, converter);
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
    DartType? result = _functionTypeVariables[type];
    if (result == null && allowFreeVariables) {
      return type;
    }
    if (result == null) {
      throw failedAt(CURRENT_ELEMENT_SPANNABLE,
          "Function type variable $type not found in $_functionTypeVariables");
    }
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
  final Entity? Function(Entity) toBackendEntity;
  final _TypeConverter typeConverter;

  _ConstantConverter(this._dartTypes, this.toBackendEntity)
      : typeConverter = _TypeConverter(_dartTypes);

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
  ConstantValue visitLateSentinel(LateSentinelConstantValue constant, _) =>
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
    return FunctionConstantValue(
        toBackendEntity(constant.element) as FunctionEntity,
        typeConverter.visit(constant.type, toBackendEntity) as FunctionType);
  }

  @override
  ConstantValue visitList(ListConstantValue constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    List<ConstantValue> entries = _handleValues(constant.entries);
    if (identical(entries, constant.entries) && type == constant.type) {
      return constant;
    }
    return ListConstantValue(type as InterfaceType, entries);
  }

  @override
  ConstantValue visitSet(
      covariant constant_system.JavaScriptSetConstant constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    List<ConstantValue> values = _handleValues(constant.values);
    JavaScriptObjectConstantValue? indexObject =
        constant.indexObject?.accept(this, null);
    if (identical(values, constant.values) &&
        identical(indexObject, constant.indexObject) &&
        type == constant.type) {
      return constant;
    }
    return constant_system.JavaScriptSetConstant(
        type as InterfaceType, values, indexObject);
  }

  @override
  ConstantValue visitMap(
      covariant constant_system.JavaScriptMapConstant constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    ListConstantValue keyList = constant.keyList.accept(this, null);
    ListConstantValue valueList = constant.valueList.accept(this, null);
    JavaScriptObjectConstantValue? indexObject =
        constant.indexObject?.accept(this, null);
    if (identical(keyList, constant.keyList) &&
        identical(valueList, constant.valueList) &&
        identical(indexObject, constant.indexObject) &&
        type == constant.type) {
      return constant;
    }
    return constant_system.JavaScriptMapConstant(type as InterfaceType, keyList,
        valueList, constant.onlyStringKeys, indexObject);
  }

  @override
  ConstantValue visitConstructed(ConstructedConstantValue constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    Map<FieldEntity, ConstantValue> fields = {};
    constant.fields.forEach((f, v) {
      FieldEntity backendField = toBackendEntity(f) as FieldEntity;
      fields[backendField] = v.accept(this, null);
    });
    return ConstructedConstantValue(type as InterfaceType, fields);
  }

  @override
  ConstantValue visitRecord(RecordConstantValue constant, _) {
    // TODO(50081): An alternative is to lower the record to
    // ConstructedConstantValue with possible a ListConstantValue argument. One
    // way to do this would be to have two constant_systems - a K-system and a
    // J-system. The K-system would produce a RecordConstantValue, the J-system
    // the lowered form.
    List<ConstantValue> values = _handleValues(constant.values);
    if (identical(values, constant.values)) return constant;
    return RecordConstantValue(constant.shape, values);
  }

  @override
  ConstantValue visitJavaScriptObject(
      JavaScriptObjectConstantValue constant, _) {
    List<ConstantValue> keys = _handleValues(constant.keys);
    List<ConstantValue> values = _handleValues(constant.values);
    if (identical(keys, constant.keys) && identical(values, constant.values)) {
      return constant;
    }
    return JavaScriptObjectConstantValue(keys, values);
  }

  @override
  ConstantValue visitType(TypeConstantValue constant, _) {
    DartType type = typeConverter.visit(constant.type, toBackendEntity);
    DartType representedType =
        typeConverter.visit(constant.representedType, toBackendEntity);
    if (type == constant.type && representedType == constant.representedType) {
      return constant;
    }
    return TypeConstantValue(representedType, type as InterfaceType);
  }

  @override
  ConstantValue visitInterceptor(InterceptorConstantValue constant, _) {
    // Interceptor constants are only created in the SSA graph builder.
    throw UnsupportedError(
        "Unexpected visitInterceptor ${constant.toStructuredText(_dartTypes)}");
  }

  @override
  ConstantValue visitDeferredGlobal(DeferredGlobalConstantValue constant, _) {
    // Deferred global constants are only created in the SSA graph builder.
    throw UnsupportedError(
        "Unexpected DeferredGlobalConstantValue ${constant.toStructuredText(_dartTypes)}");
  }

  @override
  ConstantValue visitInstantiation(InstantiationConstantValue constant, _) {
    ConstantValue function = constant.function.accept(this, null);
    List<DartType> typeArguments =
        typeConverter.convertTypes(constant.typeArguments, toBackendEntity);
    return InstantiationConstantValue(
        typeArguments, function as FunctionConstantValue);
  }

  List<ConstantValue> _handleValues(List<ConstantValue> values) {
    List<ConstantValue>? result;
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
