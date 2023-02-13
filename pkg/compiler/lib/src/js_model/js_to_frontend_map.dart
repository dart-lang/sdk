// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';

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

  /// Returns the backend class corresponding to [cls]. If [cls] isn't used it
  /// doesn't have a corresponding backend entity and null is returned instead.
  ClassEntity? toBackendClass(ClassEntity cls);

  /// Returns the backend member corresponding to [member]. If a member isn't
  /// live, it doesn't have a corresponding backend member and `null` is
  /// returned instead.
  MemberEntity? toBackendMember(MemberEntity member);

  DartType? toBackendType(DartType? type, {bool allowFreeVariables = false});

  ConstantValue? toBackendConstant(ConstantValue? value,
      {bool allowNull = false});

  Set<DartType> toBackendTypeSet(Iterable<DartType> set) {
    return {for (final type in set.map(toBackendType)) type!};
  }

  Set<LibraryEntity> toBackendLibrarySet(Iterable<LibraryEntity> set) {
    return set.map(toBackendLibrary).toSet();
  }

  Set<ClassEntity> toBackendClassSet(Iterable<ClassEntity> set) {
    final result = <ClassEntity>{};
    for (final cls in set) {
      final backendClass = toBackendClass(cls);
      if (backendClass != null) result.add(backendClass);
    }
    return result;
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
