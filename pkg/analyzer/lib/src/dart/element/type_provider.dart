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
  ClassElementImpl? _doubleElement;
  ClassElementImpl? _enumElement;
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
  ClassElementImpl? _streamElement;
  ClassElementImpl? _stringElement;
  ClassElementImpl? _symbolElement;

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
    return _boolElement ??= _getClassElement(_coreLibrary, 'bool');
  }

  @override
  ClassElementImpl2 get boolElement2 {
    return boolElement.element;
  }

  @override
  InterfaceTypeImpl get boolType {
    return _boolType ??= _getType(_coreLibrary, "bool");
  }

  @override
  TypeImpl get bottomType {
    return NeverTypeImpl.instance;
  }

  @override
  InterfaceTypeImpl get deprecatedType {
    return _deprecatedType ??= _getType(_coreLibrary, "Deprecated");
  }

  @override
  ClassElementImpl get doubleElement {
    return _doubleElement ??= _getClassElement(_coreLibrary, "double");
  }

  @override
  ClassElementImpl2 get doubleElement2 {
    return doubleElement.element;
  }

  @override
  InterfaceTypeImpl get doubleType {
    return _doubleType ??= _getType(_coreLibrary, "double");
  }

  InterfaceTypeImpl get doubleTypeQuestion => _doubleTypeQuestion ??=
      doubleType.withNullability(NullabilitySuffix.question);

  @override
  TypeImpl get dynamicType => DynamicTypeImpl.instance;

  @override
  ClassElementImpl? get enumElement {
    if (!_hasEnumElement) {
      _hasEnumElement = true;
      _enumElement = _coreLibrary.getClass('Enum');
    }
    return _enumElement;
  }

  @override
  ClassElementImpl2? get enumElement2 {
    return enumElement?.element;
  }

  @override
  InterfaceTypeImpl? get enumType {
    if (!_hasEnumType) {
      _hasEnumType = true;
      var element = enumElement;
      if (element != null) {
        _enumType = InterfaceTypeImpl(
          element: element,
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }
    return _enumType;
  }

  @override
  InterfaceTypeImpl get functionType {
    return _functionType ??= _getType(_coreLibrary, "Function");
  }

  @override
  InterfaceTypeImpl get futureDynamicType {
    return _futureDynamicType ??= InterfaceTypeImpl(
      element: futureElement,
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get futureElement {
    return _futureElement ??= _getClassElement(_asyncLibrary, 'Future');
  }

  @override
  ClassElementImpl2 get futureElement2 {
    return futureElement.element;
  }

  @override
  InterfaceTypeImpl get futureNullType {
    return _futureNullType ??= InterfaceTypeImpl(
      element: futureElement,
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get futureOrElement {
    return _futureOrElement ??= _getClassElement(_asyncLibrary, 'FutureOr');
  }

  @override
  ClassElementImpl2 get futureOrElement2 {
    return futureOrElement.element;
  }

  @override
  InterfaceTypeImpl get futureOrNullType {
    return _futureOrNullType ??= InterfaceTypeImpl(
      element: futureOrElement,
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get intElement {
    return _intElement ??= _getClassElement(_coreLibrary, "int");
  }

  @override
  ClassElementImpl2 get intElement2 {
    return intElement.element;
  }

  @override
  InterfaceTypeImpl get intType {
    return _intType ??= _getType(_coreLibrary, "int");
  }

  InterfaceTypeImpl get intTypeQuestion =>
      _intTypeQuestion ??= intType.withNullability(NullabilitySuffix.question);

  @override
  InterfaceTypeImpl get iterableDynamicType {
    return _iterableDynamicType ??= InterfaceTypeImpl(
      element: iterableElement,
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get iterableElement {
    return _iterableElement ??= _getClassElement(_coreLibrary, 'Iterable');
  }

  @override
  ClassElementImpl2 get iterableElement2 {
    return iterableElement.element;
  }

  @override
  InterfaceTypeImpl get iterableObjectType {
    return _iterableObjectType ??= InterfaceTypeImpl(
      element: iterableElement,
      typeArguments: fixedTypeList(objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get listElement {
    return _listElement ??= _getClassElement(_coreLibrary, 'List');
  }

  @override
  ClassElementImpl2 get listElement2 {
    return listElement.element;
  }

  @override
  ClassElementImpl get mapElement {
    return _mapElement ??= _getClassElement(_coreLibrary, 'Map');
  }

  @override
  ClassElementImpl2 get mapElement2 {
    return mapElement.element;
  }

  @override
  InterfaceTypeImpl get mapObjectObjectType {
    return _mapObjectObjectType ??= InterfaceTypeImpl(
      element: mapElement,
      typeArguments: fixedTypeList(objectType, objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  NeverTypeImpl get neverType => NeverTypeImpl.instance;

  @override
  ClassElementImpl get nullElement {
    return _nullElement ??= _getClassElement(_coreLibrary, 'Null');
  }

  @override
  ClassElementImpl2 get nullElement2 {
    return nullElement.element;
  }

  @override
  InterfaceTypeImpl get nullType {
    return _nullType ??= _getType(_coreLibrary, "Null");
  }

  @override
  ClassElementImpl get numElement {
    return _numElement ??= _getClassElement(_coreLibrary, 'num');
  }

  @override
  ClassElementImpl2 get numElement2 {
    return numElement.element;
  }

  @override
  InterfaceTypeImpl get numType {
    return _numType ??= _getType(_coreLibrary, "num");
  }

  InterfaceTypeImpl get numTypeQuestion =>
      _numTypeQuestion ??= numType.withNullability(NullabilitySuffix.question);

  @override
  ClassElementImpl get objectElement {
    return _objectElement ??= _getClassElement(_coreLibrary, 'Object');
  }

  @override
  ClassElementImpl2 get objectElement2 {
    return objectElement.element;
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
    return _recordElement ??= _getClassElement(_coreLibrary, 'Record');
  }

  @override
  ClassElementImpl2 get recordElement2 {
    return recordElement.element;
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
    return _setElement ??= _getClassElement(_coreLibrary, 'Set');
  }

  @override
  ClassElementImpl2 get setElement2 {
    return setElement.element;
  }

  @override
  InterfaceTypeImpl get stackTraceType {
    return _stackTraceType ??= _getType(_coreLibrary, "StackTrace");
  }

  @override
  InterfaceTypeImpl get streamDynamicType {
    return _streamDynamicType ??= InterfaceTypeImpl(
      element: streamElement,
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElementImpl get streamElement {
    return _streamElement ??= _getClassElement(_asyncLibrary, 'Stream');
  }

  @override
  ClassElementImpl2 get streamElement2 {
    return streamElement.element;
  }

  @override
  ClassElementImpl get stringElement {
    return _stringElement ??= _getClassElement(_coreLibrary, 'String');
  }

  @override
  ClassElementImpl2 get stringElement2 {
    return stringElement.element;
  }

  @override
  InterfaceTypeImpl get stringType {
    return _stringType ??= _getType(_coreLibrary, "String");
  }

  @override
  ClassElementImpl get symbolElement {
    return _symbolElement ??= _getClassElement(_coreLibrary, 'Symbol');
  }

  @override
  ClassElementImpl2 get symbolElement2 {
    return symbolElement.element;
  }

  @override
  InterfaceTypeImpl get symbolType {
    return _symbolType ??= _getType(_coreLibrary, "Symbol");
  }

  @override
  InterfaceTypeImpl get typeType {
    return _typeType ??= _getType(_coreLibrary, "Type");
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
  ClassElementImpl _getClassElement(LibraryElementImpl library, String name) {
    var element = library.getClass(name);
    if (element == null) {
      throw StateError('No definition of type $name');
    }
    return element;
  }

  /// Return the type with the given [name] from the given [library], or
  /// throw a [StateError] if there is no class with the given name.
  InterfaceTypeImpl _getType(LibraryElementImpl library, String name) {
    var element = _getClassElement(library, name);

    var typeArguments = const <DartType>[];
    var typeParameters = element.typeParameters;
    if (typeParameters.isNotEmpty) {
      typeArguments = typeParameters.map((e) {
        return TypeParameterTypeImpl(
          element: e,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }).toList(growable: false);
    }

    return InterfaceTypeImpl(
      element: element,
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}
