// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: analyzer_use_new_elements

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

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

const Set<String> _nonSubtypableDartAsyncClassNames = {
  'FutureOr',
};

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
    var element = objectType.element3.getGetter2(id);
    return element != null && !element.isStatic;
  }

  @override
  bool isObjectMember(String id) {
    return isObjectGetter(id) || isObjectMethod(id);
  }

  @override
  bool isObjectMethod(String id) {
    var element = objectType.element3.getMethod2(id);
    return element != null && !element.isStatic;
  }
}

class TypeProviderImpl extends TypeProviderBase {
  final LibraryElementImpl _coreLibrary;
  final LibraryElementImpl _asyncLibrary;

  bool _hasEnumElement = false;
  bool _hasEnumType = false;

  ClassElementImpl2? _boolElement;
  ClassElementImpl2? _deprecatedElement;
  ClassElementImpl2? _doubleElement;
  ClassElementImpl2? _enumElement;
  ClassElementImpl2? _functionElement;
  ClassElementImpl2? _futureElement;
  ClassElementImpl2? _futureOrElement;
  ClassElementImpl2? _intElement;
  ClassElementImpl2? _iterableElement;
  ClassElementImpl2? _listElement;
  ClassElementImpl2? _mapElement;
  ClassElementImpl2? _nullElement;
  ClassElementImpl2? _numElement;
  ClassElementImpl2? _objectElement;
  ClassElementImpl2? _recordElement;
  ClassElementImpl2? _setElement;
  ClassElementImpl2? _stackTraceElement;
  ClassElementImpl2? _streamElement;
  ClassElementImpl2? _stringElement;
  ClassElementImpl2? _symbolElement;
  ClassElementImpl2? _typeElement;

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
  })  : _coreLibrary = coreLibrary,
        _asyncLibrary = asyncLibrary;

  @override
  ClassElementImpl get boolElement {
    return boolElement2.asElement;
  }

  @override
  ClassElementImpl2 get boolElement2 {
    return _boolElement ??= _getClassElement(_coreLibrary, 'bool');
  }

  @override
  InterfaceTypeImpl get boolType {
    return _boolType ??= boolElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  TypeImpl get bottomType {
    return NeverTypeImpl.instance;
  }

  ClassElementImpl2 get deprecatedElement2 {
    return _deprecatedElement ??= _getClassElement(_coreLibrary, 'Deprecated');
  }

  @override
  InterfaceTypeImpl get deprecatedType {
    return _deprecatedType ??= deprecatedElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get doubleElement {
    return doubleElement2.asElement;
  }

  @override
  ClassElementImpl2 get doubleElement2 {
    return _doubleElement ??= _getClassElement(_coreLibrary, "double");
  }

  @override
  InterfaceTypeImpl get doubleType {
    return _doubleType ??= doubleElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get doubleTypeQuestion => _doubleTypeQuestion ??=
      doubleType.withNullability(NullabilitySuffix.question);

  @override
  TypeImpl get dynamicType => DynamicTypeImpl.instance;

  @override
  ClassElementImpl? get enumElement {
    return enumElement2?.asElement;
  }

  @override
  ClassElementImpl2? get enumElement2 {
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
        _enumType = element.instantiate(
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }
    return _enumType;
  }

  ClassElementImpl2 get functionElement2 {
    return _functionElement ??= _getClassElement(_coreLibrary, 'Function');
  }

  @override
  InterfaceTypeImpl get functionType {
    return _functionType ??= functionElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl get futureDynamicType {
    return _futureDynamicType ??= futureElement2.instantiate(
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get futureElement {
    return futureElement2.asElement;
  }

  @override
  ClassElementImpl2 get futureElement2 {
    return _futureElement ??= _getClassElement(_asyncLibrary, 'Future');
  }

  @override
  InterfaceTypeImpl get futureNullType {
    return _futureNullType ??= futureElement2.instantiate(
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get futureOrElement {
    return futureOrElement2.asElement;
  }

  @override
  ClassElementImpl2 get futureOrElement2 {
    return _futureOrElement ??= _getClassElement(_asyncLibrary, 'FutureOr');
  }

  @override
  InterfaceTypeImpl get futureOrNullType {
    return _futureOrNullType ??= futureOrElement2.instantiate(
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get intElement {
    return intElement2.asElement;
  }

  @override
  ClassElementImpl2 get intElement2 {
    return _intElement ??= _getClassElement(_coreLibrary, "int");
  }

  @override
  InterfaceTypeImpl get intType {
    return _intType ??= intElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get intTypeQuestion =>
      _intTypeQuestion ??= intType.withNullability(NullabilitySuffix.question);

  @override
  InterfaceTypeImpl get iterableDynamicType {
    return _iterableDynamicType ??= iterableElement2.instantiate(
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get iterableElement {
    return iterableElement2.asElement;
  }

  @override
  ClassElementImpl2 get iterableElement2 {
    return _iterableElement ??= _getClassElement(_coreLibrary, 'Iterable');
  }

  @override
  InterfaceTypeImpl get iterableObjectType {
    return _iterableObjectType ??= iterableElement2.instantiate(
      typeArguments: fixedTypeList(objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get listElement {
    return listElement2.asElement;
  }

  @override
  ClassElementImpl2 get listElement2 {
    return _listElement ??= _getClassElement(_coreLibrary, 'List');
  }

  @override
  ClassElementImpl get mapElement {
    return mapElement2.asElement;
  }

  @override
  ClassElementImpl2 get mapElement2 {
    return _mapElement ??= _getClassElement(_coreLibrary, 'Map');
  }

  @override
  InterfaceTypeImpl get mapObjectObjectType {
    return _mapObjectObjectType ??= mapElement2.instantiate(
      typeArguments: fixedTypeList(objectType, objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  NeverTypeImpl get neverType => NeverTypeImpl.instance;

  @override
  ClassElementImpl get nullElement {
    return nullElement2.asElement;
  }

  @override
  ClassElementImpl2 get nullElement2 {
    return _nullElement ??= _getClassElement(_coreLibrary, 'Null');
  }

  @override
  InterfaceTypeImpl get nullType {
    return _nullType ??= nullElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get numElement {
    return numElement2.asElement;
  }

  @override
  ClassElementImpl2 get numElement2 {
    return _numElement ??= _getClassElement(_coreLibrary, 'num');
  }

  @override
  InterfaceTypeImpl get numType {
    return _numType ??= numElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl get numTypeQuestion =>
      _numTypeQuestion ??= numType.withNullability(NullabilitySuffix.question);

  @override
  ClassElementImpl get objectElement {
    return objectElement2.asElement;
  }

  @override
  ClassElementImpl2 get objectElement2 {
    return _objectElement ??= _getClassElement(_coreLibrary, 'Object');
  }

  @override
  InterfaceTypeImpl get objectQuestionType {
    return _objectQuestionType ??= objectElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  @override
  InterfaceTypeImpl get objectType {
    return _objectType ??= objectElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get recordElement {
    return recordElement2.asElement;
  }

  @override
  ClassElementImpl2 get recordElement2 {
    return _recordElement ??= _getClassElement(_coreLibrary, 'Record');
  }

  @override
  InterfaceTypeImpl get recordType {
    return _recordType ??= recordElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get setElement {
    return setElement2.asElement;
  }

  @override
  ClassElementImpl2 get setElement2 {
    return _setElement ??= _getClassElement(_coreLibrary, 'Set');
  }

  ClassElementImpl2 get stackTraceElement2 {
    return _stackTraceElement ??= _getClassElement(_coreLibrary, 'StackTrace');
  }

  @override
  InterfaceTypeImpl get stackTraceType {
    return _stackTraceType ??= stackTraceElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl get streamDynamicType {
    return _streamDynamicType ??= streamElement2.instantiate(
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get streamElement {
    return streamElement2.asElement;
  }

  @override
  ClassElementImpl2 get streamElement2 {
    return _streamElement ??= _getClassElement(_asyncLibrary, 'Stream');
  }

  @override
  ClassElementImpl get stringElement {
    return stringElement2.asElement;
  }

  @override
  ClassElementImpl2 get stringElement2 {
    return _stringElement ??= _getClassElement(_coreLibrary, 'String');
  }

  @override
  InterfaceTypeImpl get stringType {
    return _stringType ??= stringElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get symbolElement {
    return symbolElement2.asElement;
  }

  @override
  ClassElementImpl2 get symbolElement2 {
    return _symbolElement ??= _getClassElement(_coreLibrary, 'Symbol');
  }

  @override
  InterfaceTypeImpl get symbolType {
    return _symbolType ??= symbolElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  ClassElementImpl2 get typeElement2 {
    return _typeElement ??= _getClassElement(_coreLibrary, 'Type');
  }

  @override
  InterfaceTypeImpl get typeType {
    return _typeType ??= typeElement2.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  VoidTypeImpl get voidType => VoidTypeImpl.instance;

  @override
  InterfaceTypeImpl futureOrType(DartType valueType) {
    return futureOrElement.instantiate(
      typeArguments: fixedTypeList(valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl futureType(DartType valueType) {
    return futureElement.instantiate(
      typeArguments: fixedTypeList(valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  bool isNonSubtypableClass(InterfaceElement element) {
    return isNonSubtypableClass2(element.asElement2);
  }

  @override
  bool isNonSubtypableClass2(InterfaceElement2 element) {
    var name = element.name3;
    if (_nonSubtypableClassNames.contains(name)) {
      var libraryUriStr = element.library2.uri.toString();
      var ofLibrary = _nonSubtypableClassMap[libraryUriStr];
      return ofLibrary != null && ofLibrary.contains(name);
    }
    return false;
  }

  @override
  InterfaceTypeImpl iterableType(DartType elementType) {
    return iterableElement.instantiate(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl listType(DartType elementType) {
    return listElement.instantiate(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl mapType(DartType keyType, DartType valueType) {
    return mapElement.instantiate(
      typeArguments: fixedTypeList(keyType, valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl setType(DartType elementType) {
    return setElement.instantiate(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceTypeImpl streamType(DartType elementType) {
    return streamElement.instantiate(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /// Return the class with the given [name] from the given [library], or
  /// throw a [StateError] if there is no class with the given name.
  ClassElementImpl2 _getClassElement(LibraryElementImpl library, String name) {
    var element = library.getClass2(name);
    if (element == null) {
      throw StateError('No definition of type $name');
    }
    return element;
  }
}
