// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';

const Map<String, Set<String>> _nonSubtypableClassMap = {
  'dart:async': _nonSubtypableDartAsyncClassNames,
  'dart:core': _nonSubtypableDartCoreClassNames,
  'dart:typed_data': _nonSubtypableDartTypedDataClassNames,
};

const Set<String> _nonSubtypableClassNames = {
  ..._nonSubtypableDartCoreClassNames,
  ..._nonSubtypableDartAsyncClassNames,
  ..._nonSubtypableDartTypedDataClassNames,
};

const Set<String> _nonSubtypableDartAsyncClassNames = {'FutureOr'};

const Set<String> _nonSubtypableDartCoreClassNames = {
  'bool',
  'double',
  'Enum',
  'int',
  'Null',
  'num',
  'Record',
  'String',
};

const Set<String> _nonSubtypableDartTypedDataClassNames = {
  'ByteBuffer',
  'ByteData',
  'Endian',
  'Float32List',
  'Float32x4',
  'Float32x4List',
  'Float64List',
  'Float64x2',
  'Float64x2List',
  'Int16List',
  'Int32List',
  'Int32x4',
  'Int32x4List',
  'Int64List',
  'Int8List',
  'TypedData',
  'Uint16List',
  'Uint32List',
  'Uint64List',
  'Uint8ClampedList',
  'Uint8List',
  'UnmodifiableByteBufferView',
  'UnmodifiableByteDataView',
  'UnmodifiableFloat32ListView',
  'UnmodifiableFloat32x4ListView',
  'UnmodifiableFloat64ListView',
  'UnmodifiableFloat64x2ListView',
  'UnmodifiableInt16ListView',
  'UnmodifiableInt32ListView',
  'UnmodifiableInt32x4ListView',
  'UnmodifiableInt64ListView',
  'UnmodifiableInt8ListView',
  'UnmodifiableUint16ListView',
  'UnmodifiableUint32ListView',
  'UnmodifiableUint64ListView',
  'UnmodifiableUint8ClampedListView',
  'UnmodifiableUint8ListView',
};

/// Provide common functionality shared by the various TypeProvider
/// implementations.
abstract class TypeProviderBase implements TypeProvider {
  @override
  bool isObjectGetter(String id) {
    var element = objectType.element3.getGetter(id);
    return element != null && !element.isStatic;
  }

  @override
  bool isObjectMember(String id) {
    return isObjectGetter(id) || isObjectMethod(id);
  }

  @override
  bool isObjectMethod(String id) {
    var element = objectType.element3.getMethod(id);
    return element != null && !element.isStatic;
  }
}

class TypeProviderImpl extends TypeProviderBase {
  final LibraryElementImpl _coreLibrary;
  final LibraryElementImpl _asyncLibrary;

  bool _hasEnumElement = false;
  bool _hasEnumType = false;

  ClassElementImpl? _boolElement;
  ClassElementImpl? _deprecatedElement;
  ClassElementImpl? _doubleElement;
  ClassElementImpl? _enumElement;
  ClassElementImpl? _functionElement;
  ClassElementImpl? _futureElement;
  ClassElementImpl? _futureOrElement;
  ClassElementImpl? _intElement;
  ClassElementImpl? _iterableElement;
  ClassElementImpl? _listElement;
  ClassElementImpl? _mapElement;
  ClassElementImpl? _nullElement;
  ClassElementImpl? _numElement;
  ClassElementImpl? _objectElement;
  ClassElementImpl? _recordElement;
  ClassElementImpl? _setElement;
  ClassElementImpl? _stackTraceElement;
  ClassElementImpl? _streamElement;
  ClassElementImpl? _stringElement;
  ClassElementImpl? _symbolElement;
  ClassElementImpl? _typeElement;

  InterfaceTypeImpl? _boolType;
  InterfaceTypeImpl? _deprecatedType;
  InterfaceTypeImpl? _doubleType;
  InterfaceTypeImpl? _doubleTypeQuestion;
  InterfaceTypeImpl? _enumType;
  InterfaceTypeImpl? _functionType;
  InterfaceTypeImpl? _futureDynamicType;
  InterfaceTypeImpl? _futureNullType;
  InterfaceTypeImpl? _futureOrNullType;
  InterfaceTypeImpl? _intType;
  InterfaceTypeImpl? _intTypeQuestion;
  InterfaceTypeImpl? _iterableDynamicType;
  InterfaceTypeImpl? _iterableObjectType;
  InterfaceTypeImpl? _mapObjectObjectType;
  InterfaceTypeImpl? _nullType;
  InterfaceTypeImpl? _numType;
  InterfaceTypeImpl? _numTypeQuestion;
  InterfaceTypeImpl? _objectType;
  InterfaceTypeImpl? _objectQuestionType;
  InterfaceTypeImpl? _recordType;
  InterfaceTypeImpl? _stackTraceType;
  InterfaceTypeImpl? _streamDynamicType;
  InterfaceTypeImpl? _stringType;
  InterfaceTypeImpl? _symbolType;
  InterfaceTypeImpl? _typeType;

  /// Initialize a newly created type provider to provide the types defined in
  /// the given [coreLibrary] and [asyncLibrary].
  TypeProviderImpl({
    required LibraryElementImpl coreLibrary,
    required LibraryElementImpl asyncLibrary,
  }) : _coreLibrary = coreLibrary,
       _asyncLibrary = asyncLibrary;

  @override
  ClassElementImpl get boolElement2 {
    return _boolElement ??= _getClassElement(_coreLibrary, 'bool');
  }

  @override
  InterfaceTypeImpl get boolType {
    return _boolType ??= boolElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  TypeImpl get bottomType {
    return NeverTypeImpl.instance;
  }

  ClassElementImpl get deprecatedElement2 {
    return _deprecatedElement ??= _getClassElement(_coreLibrary, 'Deprecated');
  }

  @override
  InterfaceTypeImpl get deprecatedType {
    return _deprecatedType ??= deprecatedElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get doubleElement2 {
    return _doubleElement ??= _getClassElement(_coreLibrary, "double");
  }

  @override
  InterfaceTypeImpl get doubleType {
    return _doubleType ??= doubleElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get doubleTypeQuestion =>
      _doubleTypeQuestion ??= doubleType.withNullability(
        NullabilitySuffix.question,
      );

  @override
  TypeImpl get dynamicType => DynamicTypeImpl.instance;

  @override
  ClassElementImpl? get enumElement2 {
    if (!_hasEnumElement) {
      _hasEnumElement = true;
      _enumElement = _getClassElement(_coreLibrary, 'Enum');
    }
    return _enumElement;
  }

  @override
  InterfaceTypeImpl? get enumType {
    if (!_hasEnumType) {
      _hasEnumType = true;
      var element = enumElement2;
      if (element != null) {
        _enumType = element.instantiateImpl(
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }
    return _enumType;
  }

  ClassElementImpl get functionElement2 {
    return _functionElement ??= _getClassElement(_coreLibrary, 'Function');
  }

  @override
  InterfaceTypeImpl get functionType {
    return _functionType ??= functionElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl get futureDynamicType {
    return _futureDynamicType ??= futureElement2.instantiateImpl(
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get futureElement2 {
    return _futureElement ??= _getClassElement(_asyncLibrary, 'Future');
  }

  @override
  InterfaceTypeImpl get futureNullType {
    return _futureNullType ??= futureElement2.instantiateImpl(
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get futureOrElement2 {
    return _futureOrElement ??= _getClassElement(_asyncLibrary, 'FutureOr');
  }

  @override
  InterfaceTypeImpl get futureOrNullType {
    return _futureOrNullType ??= futureOrElement2.instantiateImpl(
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get intElement2 {
    return _intElement ??= _getClassElement(_coreLibrary, "int");
  }

  @override
  InterfaceTypeImpl get intType {
    return _intType ??= intElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get intTypeQuestion =>
      _intTypeQuestion ??= intType.withNullability(NullabilitySuffix.question);

  @override
  InterfaceTypeImpl get iterableDynamicType {
    return _iterableDynamicType ??= iterableElement2.instantiateImpl(
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get iterableElement2 {
    return _iterableElement ??= _getClassElement(_coreLibrary, 'Iterable');
  }

  @override
  InterfaceTypeImpl get iterableObjectType {
    return _iterableObjectType ??= iterableElement2.instantiateImpl(
      typeArguments: fixedTypeList(objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get listElement2 {
    return _listElement ??= _getClassElement(_coreLibrary, 'List');
  }

  @override
  ClassElementImpl get mapElement2 {
    return _mapElement ??= _getClassElement(_coreLibrary, 'Map');
  }

  @override
  InterfaceTypeImpl get mapObjectObjectType {
    return _mapObjectObjectType ??= mapElement2.instantiateImpl(
      typeArguments: fixedTypeList(objectType, objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  NeverTypeImpl get neverType => NeverTypeImpl.instance;

  @override
  ClassElementImpl get nullElement2 {
    return _nullElement ??= _getClassElement(_coreLibrary, 'Null');
  }

  @override
  InterfaceTypeImpl get nullType {
    return _nullType ??= nullElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get numElement2 {
    return _numElement ??= _getClassElement(_coreLibrary, 'num');
  }

  @override
  InterfaceTypeImpl get numType {
    return _numType ??= numElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get numTypeQuestion =>
      _numTypeQuestion ??= numType.withNullability(NullabilitySuffix.question);

  @override
  ClassElementImpl get objectElement2 {
    return _objectElement ??= _getClassElement(_coreLibrary, 'Object');
  }

  @override
  InterfaceTypeImpl get objectQuestionType {
    return _objectQuestionType ??= objectElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  @override
  InterfaceTypeImpl get objectType {
    return _objectType ??= objectElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get recordElement2 {
    return _recordElement ??= _getClassElement(_coreLibrary, 'Record');
  }

  @override
  InterfaceTypeImpl get recordType {
    return _recordType ??= recordElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get setElement2 {
    return _setElement ??= _getClassElement(_coreLibrary, 'Set');
  }

  ClassElementImpl get stackTraceElement2 {
    return _stackTraceElement ??= _getClassElement(_coreLibrary, 'StackTrace');
  }

  @override
  InterfaceTypeImpl get stackTraceType {
    return _stackTraceType ??= stackTraceElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl get streamDynamicType {
    return _streamDynamicType ??= streamElement2.instantiateImpl(
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get streamElement2 {
    return _streamElement ??= _getClassElement(_asyncLibrary, 'Stream');
  }

  @override
  ClassElementImpl get stringElement2 {
    return _stringElement ??= _getClassElement(_coreLibrary, 'String');
  }

  @override
  InterfaceTypeImpl get stringType {
    return _stringType ??= stringElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get symbolElement2 {
    return _symbolElement ??= _getClassElement(_coreLibrary, 'Symbol');
  }

  @override
  InterfaceTypeImpl get symbolType {
    return _symbolType ??= symbolElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  ClassElementImpl get typeElement2 {
    return _typeElement ??= _getClassElement(_coreLibrary, 'Type');
  }

  @override
  InterfaceTypeImpl get typeType {
    return _typeType ??= typeElement2.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  VoidTypeImpl get voidType => VoidTypeImpl.instance;

  @override
  InterfaceTypeImpl futureOrType(covariant TypeImpl valueType) {
    return futureOrElement2.instantiateImpl(
      typeArguments: fixedTypeList(valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl futureType(covariant TypeImpl valueType) {
    return futureElement2.instantiateImpl(
      typeArguments: fixedTypeList(valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  bool isNonSubtypableClass2(InterfaceElement element) {
    var name = element.name3;
    if (_nonSubtypableClassNames.contains(name)) {
      var libraryUriStr = element.library2.uri.toString();
      var ofLibrary = _nonSubtypableClassMap[libraryUriStr];
      return ofLibrary != null && ofLibrary.contains(name);
    }
    return false;
  }

  @override
  InterfaceTypeImpl iterableType(covariant TypeImpl elementType) {
    return iterableElement2.instantiateImpl(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl listType(covariant TypeImpl elementType) {
    return listElement2.instantiateImpl(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl mapType(
    covariant TypeImpl keyType,
    covariant TypeImpl valueType,
  ) {
    return mapElement2.instantiateImpl(
      typeArguments: fixedTypeList(keyType, valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl setType(covariant TypeImpl elementType) {
    return setElement2.instantiateImpl(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl streamType(covariant TypeImpl elementType) {
    return streamElement2.instantiateImpl(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /// Return the class with the given [name] from the given [library], or
  /// throw a [StateError] if there is no class with the given name.
  ClassElementImpl _getClassElement(LibraryElementImpl library, String name) {
    var element = library.getClass2(name);
    if (element == null) {
      throw StateError('No definition of type $name');
    }
    return element;
  }
}
