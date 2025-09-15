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
    var element = objectType.element.getGetter(id);
    return element != null && !element.isStatic;
  }

  @override
  bool isObjectMember(String id) {
    return isObjectGetter(id) || isObjectMethod(id);
  }

  @override
  bool isObjectMethod(String id) {
    var element = objectType.element.getMethod(id);
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
  ClassElementImpl get boolElement {
    _coreLibrary.recordGetDeclaredClass('bool');
    return _boolElement ??= _getClassElement(_coreLibrary, 'bool');
  }

  @Deprecated('Use boolElement instead')
  @override
  ClassElementImpl get boolElement2 {
    return boolElement;
  }

  @override
  InterfaceTypeImpl get boolType {
    return _boolType ??= boolElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  TypeImpl get bottomType {
    return NeverTypeImpl.instance;
  }

  ClassElementImpl get deprecatedElement {
    _coreLibrary.recordGetDeclaredClass('Deprecated');
    return _deprecatedElement ??= _getClassElement(_coreLibrary, 'Deprecated');
  }

  @override
  InterfaceTypeImpl get deprecatedType {
    return _deprecatedType ??= deprecatedElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get doubleElement {
    _coreLibrary.recordGetDeclaredClass('double');
    return _doubleElement ??= _getClassElement(_coreLibrary, "double");
  }

  @Deprecated('Use doubleElement instead')
  @override
  ClassElementImpl get doubleElement2 {
    return doubleElement;
  }

  @override
  InterfaceTypeImpl get doubleType {
    return _doubleType ??= doubleElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get doubleTypeQuestion => _doubleTypeQuestion ??= doubleType
      .withNullability(NullabilitySuffix.question);

  @override
  TypeImpl get dynamicType => DynamicTypeImpl.instance;

  @override
  ClassElementImpl? get enumElement {
    if (!_hasEnumElement) {
      _hasEnumElement = true;
      _coreLibrary.recordGetDeclaredClass('Enum');
      _enumElement = _getClassElement(_coreLibrary, 'Enum');
    }
    return _enumElement;
  }

  @Deprecated('Use enumElement instead.')
  @override
  ClassElementImpl? get enumElement2 {
    return enumElement;
  }

  @override
  InterfaceTypeImpl? get enumType {
    if (!_hasEnumType) {
      _hasEnumType = true;
      var element = enumElement;
      if (element != null) {
        _enumType = element.instantiateImpl(
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }
    return _enumType;
  }

  ClassElementImpl get functionElement {
    _coreLibrary.recordGetDeclaredClass('Function');
    return _functionElement ??= _getClassElement(_coreLibrary, 'Function');
  }

  @override
  InterfaceTypeImpl get functionType {
    return _functionType ??= functionElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl get futureDynamicType {
    return _futureDynamicType ??= futureElement.instantiateImpl(
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get futureElement {
    _asyncLibrary.recordGetDeclaredClass('Future');
    return _futureElement ??= _getClassElement(_asyncLibrary, 'Future');
  }

  @Deprecated('Use futureElement instead.')
  @override
  ClassElementImpl get futureElement2 {
    return futureElement;
  }

  @override
  InterfaceTypeImpl get futureNullType {
    return _futureNullType ??= futureElement.instantiateImpl(
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get futureOrElement {
    _asyncLibrary.recordGetDeclaredClass('FutureOr');
    return _futureOrElement ??= _getClassElement(_asyncLibrary, 'FutureOr');
  }

  @Deprecated('Use futureOrElement instead.')
  @override
  ClassElementImpl get futureOrElement2 {
    return futureOrElement;
  }

  @override
  InterfaceTypeImpl get futureOrNullType {
    return _futureOrNullType ??= futureOrElement.instantiateImpl(
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get intElement {
    _coreLibrary.recordGetDeclaredClass('int');
    return _intElement ??= _getClassElement(_coreLibrary, "int");
  }

  @Deprecated('Use intElement instead.')
  @override
  ClassElementImpl get intElement2 {
    return intElement;
  }

  @override
  InterfaceTypeImpl get intType {
    return _intType ??= intElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get intTypeQuestion =>
      _intTypeQuestion ??= intType.withNullability(NullabilitySuffix.question);

  @override
  InterfaceTypeImpl get iterableDynamicType {
    return _iterableDynamicType ??= iterableElement.instantiateImpl(
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get iterableElement {
    _coreLibrary.recordGetDeclaredClass('Iterable');
    return _iterableElement ??= _getClassElement(_coreLibrary, 'Iterable');
  }

  @Deprecated('Use iterableElement instead')
  @override
  ClassElementImpl get iterableElement2 {
    return iterableElement;
  }

  @override
  InterfaceTypeImpl get iterableObjectType {
    return _iterableObjectType ??= iterableElement.instantiateImpl(
      typeArguments: fixedTypeList(objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get listElement {
    _coreLibrary.recordGetDeclaredClass('List');
    return _listElement ??= _getClassElement(_coreLibrary, 'List');
  }

  @Deprecated('Use listElement instead')
  @override
  ClassElementImpl get listElement2 {
    return listElement;
  }

  @override
  ClassElementImpl get mapElement {
    _coreLibrary.recordGetDeclaredClass('Map');
    return _mapElement ??= _getClassElement(_coreLibrary, 'Map');
  }

  @Deprecated('Use mapElement instead')
  @override
  ClassElementImpl get mapElement2 {
    return mapElement;
  }

  @override
  InterfaceTypeImpl get mapObjectObjectType {
    return _mapObjectObjectType ??= mapElement.instantiateImpl(
      typeArguments: fixedTypeList(objectType, objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  NeverTypeImpl get neverType => NeverTypeImpl.instance;

  @override
  ClassElementImpl get nullElement {
    _coreLibrary.recordGetDeclaredClass('Null');
    return _nullElement ??= _getClassElement(_coreLibrary, 'Null');
  }

  @Deprecated('Use nullElement instead')
  @override
  ClassElementImpl get nullElement2 {
    return nullElement;
  }

  @override
  InterfaceTypeImpl get nullType {
    return _nullType ??= nullElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get numElement {
    _coreLibrary.recordGetDeclaredClass('num');
    return _numElement ??= _getClassElement(_coreLibrary, 'num');
  }

  @Deprecated('Use numElement instead')
  @override
  ClassElementImpl get numElement2 {
    return numElement;
  }

  @override
  InterfaceTypeImpl get numType {
    return _numType ??= numElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get numTypeQuestion =>
      _numTypeQuestion ??= numType.withNullability(NullabilitySuffix.question);

  @override
  ClassElementImpl get objectElement {
    _coreLibrary.recordGetDeclaredClass('Object');
    return _objectElement ??= _getClassElement(_coreLibrary, 'Object');
  }

  @Deprecated('Use objectElement instead')
  @override
  ClassElementImpl get objectElement2 {
    return objectElement;
  }

  @override
  InterfaceTypeImpl get objectQuestionType {
    return _objectQuestionType ??= objectElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  @override
  InterfaceTypeImpl get objectType {
    return _objectType ??= objectElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get recordElement {
    _coreLibrary.recordGetDeclaredClass('Record');
    return _recordElement ??= _getClassElement(_coreLibrary, 'Record');
  }

  @Deprecated('Use recordElement instead')
  @override
  ClassElementImpl get recordElement2 {
    return recordElement;
  }

  @override
  InterfaceTypeImpl get recordType {
    return _recordType ??= recordElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get setElement {
    _coreLibrary.recordGetDeclaredClass('Set');
    return _setElement ??= _getClassElement(_coreLibrary, 'Set');
  }

  @Deprecated('Use setElement instead')
  @override
  ClassElementImpl get setElement2 {
    return setElement;
  }

  ClassElementImpl get stackTraceElement {
    _coreLibrary.recordGetDeclaredClass('StackTrace');
    return _stackTraceElement ??= _getClassElement(_coreLibrary, 'StackTrace');
  }

  @override
  InterfaceTypeImpl get stackTraceType {
    return _stackTraceType ??= stackTraceElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl get streamDynamicType {
    return _streamDynamicType ??= streamElement.instantiateImpl(
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get streamElement {
    _asyncLibrary.recordGetDeclaredClass('Stream');
    return _streamElement ??= _getClassElement(_asyncLibrary, 'Stream');
  }

  @Deprecated('Use streamElement instead')
  @override
  ClassElementImpl get streamElement2 {
    return streamElement;
  }

  @override
  ClassElementImpl get stringElement {
    _coreLibrary.recordGetDeclaredClass('String');
    return _stringElement ??= _getClassElement(_coreLibrary, 'String');
  }

  @Deprecated('Use stringElement instead')
  @override
  ClassElementImpl get stringElement2 {
    return stringElement;
  }

  @override
  InterfaceTypeImpl get stringType {
    return _stringType ??= stringElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get symbolElement {
    _coreLibrary.recordGetDeclaredClass('Symbol');
    return _symbolElement ??= _getClassElement(_coreLibrary, 'Symbol');
  }

  @Deprecated('Use symbolElement instead')
  @override
  ClassElementImpl get symbolElement2 {
    return symbolElement;
  }

  @override
  InterfaceTypeImpl get symbolType {
    return _symbolType ??= symbolElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  ClassElementImpl get typeElement {
    _coreLibrary.recordGetDeclaredClass('Type');
    return _typeElement ??= _getClassElement(_coreLibrary, 'Type');
  }

  @override
  InterfaceTypeImpl get typeType {
    return _typeType ??= typeElement.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  VoidTypeImpl get voidType => VoidTypeImpl.instance;

  @override
  InterfaceTypeImpl futureOrType(covariant TypeImpl valueType) {
    return futureOrElement.instantiateImpl(
      typeArguments: fixedTypeList(valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl futureType(covariant TypeImpl valueType) {
    return futureElement.instantiateImpl(
      typeArguments: fixedTypeList(valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  bool isNonSubtypableClass(InterfaceElement element) {
    var name = element.name;
    if (_nonSubtypableClassNames.contains(name)) {
      var libraryUriStr = element.library.uri.toString();
      var ofLibrary = _nonSubtypableClassMap[libraryUriStr];
      return ofLibrary != null && ofLibrary.contains(name);
    }
    return false;
  }

  @Deprecated('Use isNonSubtypableClass instead')
  @override
  bool isNonSubtypableClass2(InterfaceElement element) {
    return isNonSubtypableClass(element);
  }

  @override
  InterfaceTypeImpl iterableType(covariant TypeImpl elementType) {
    return iterableElement.instantiateImpl(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl listType(covariant TypeImpl elementType) {
    return listElement.instantiateImpl(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl mapType(
    covariant TypeImpl keyType,
    covariant TypeImpl valueType,
  ) {
    return mapElement.instantiateImpl(
      typeArguments: fixedTypeList(keyType, valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl setType(covariant TypeImpl elementType) {
    return setElement.instantiateImpl(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl streamType(covariant TypeImpl elementType) {
    return streamElement.instantiateImpl(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /// Return the class with the given [name] from the given [library], or
  /// throw a [StateError] if there is no class with the given name.
  ClassElementImpl _getClassElement(LibraryElementImpl library, String name) {
    var element = library.getClass(name);
    if (element == null) {
      throw StateError('No definition of type $name');
    }
    return element;
  }
}
