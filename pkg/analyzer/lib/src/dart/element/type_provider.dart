// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
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
  final LibraryElement _coreLibrary;
  final LibraryElement _asyncLibrary;

  bool _hasEnumElement = false;
  bool _hasEnumType = false;

  ClassElement? _boolElement;
  ClassElement? _doubleElement;
  ClassElement? _enumElement;
  ClassElement? _futureElement;
  ClassElement? _futureOrElement;
  ClassElement? _intElement;
  ClassElement? _iterableElement;
  ClassElement? _listElement;
  ClassElement? _mapElement;
  ClassElement? _nullElement;
  ClassElement? _numElement;
  ClassElement? _objectElement;
  ClassElement? _recordElement;
  ClassElement? _setElement;
  ClassElement? _streamElement;
  ClassElement? _stringElement;
  ClassElement? _symbolElement;

  InterfaceType? _boolType;
  InterfaceType? _deprecatedType;
  InterfaceType? _doubleType;
  InterfaceType? _doubleTypeQuestion;
  InterfaceType? _enumType;
  InterfaceType? _functionType;
  InterfaceType? _futureDynamicType;
  InterfaceType? _futureNullType;
  InterfaceType? _futureOrNullType;
  InterfaceType? _intType;
  InterfaceType? _intTypeQuestion;
  InterfaceType? _iterableDynamicType;
  InterfaceType? _iterableObjectType;
  InterfaceType? _mapObjectObjectType;
  InterfaceType? _nullType;
  InterfaceType? _numType;
  InterfaceType? _numTypeQuestion;
  InterfaceType? _objectType;
  InterfaceType? _objectQuestionType;
  InterfaceType? _recordType;
  InterfaceType? _stackTraceType;
  InterfaceType? _streamDynamicType;
  InterfaceType? _stringType;
  InterfaceType? _symbolType;
  InterfaceType? _typeType;

  /// Initialize a newly created type provider to provide the types defined in
  /// the given [coreLibrary] and [asyncLibrary].
  TypeProviderImpl({
    required LibraryElement coreLibrary,
    required LibraryElement asyncLibrary,
  })  : _coreLibrary = coreLibrary,
        _asyncLibrary = asyncLibrary;

  @override
  ClassElement get boolElement {
    return _boolElement ??= _getClassElement(_coreLibrary, 'bool');
  }

  @override
  ClassElement2 get boolElement2 {
    return boolElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get boolType {
    return _boolType ??= _getType(_coreLibrary, "bool");
  }

  @override
  DartType get bottomType {
    return NeverTypeImpl.instance;
  }

  @override
  InterfaceType get deprecatedType {
    return _deprecatedType ??= _getType(_coreLibrary, "Deprecated");
  }

  @override
  ClassElement get doubleElement {
    return _doubleElement ??= _getClassElement(_coreLibrary, "double");
  }

  @override
  ClassElement2 get doubleElement2 {
    return doubleElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get doubleType {
    return _doubleType ??= _getType(_coreLibrary, "double");
  }

  InterfaceType get doubleTypeQuestion =>
      _doubleTypeQuestion ??= (doubleType as InterfaceTypeImpl)
          .withNullability(NullabilitySuffix.question);

  @override
  DartType get dynamicType => DynamicTypeImpl.instance;

  @override
  ClassElement? get enumElement {
    if (!_hasEnumElement) {
      _hasEnumElement = true;
      _enumElement = _coreLibrary.getClass('Enum');
    }
    return _enumElement;
  }

  @override
  ClassElement2? get enumElement2 {
    return enumElement?.asElement2 as ClassElement2?;
  }

  @override
  InterfaceType? get enumType {
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
  InterfaceType get functionType {
    return _functionType ??= _getType(_coreLibrary, "Function");
  }

  @override
  InterfaceType get futureDynamicType {
    return _futureDynamicType ??= InterfaceTypeImpl(
      element: futureElement,
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElement get futureElement {
    return _futureElement ??= _getClassElement(_asyncLibrary, 'Future');
  }

  @override
  ClassElement2 get futureElement2 {
    return futureElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get futureNullType {
    return _futureNullType ??= InterfaceTypeImpl(
      element: futureElement,
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElement get futureOrElement {
    return _futureOrElement ??= _getClassElement(_asyncLibrary, 'FutureOr');
  }

  @override
  ClassElement2 get futureOrElement2 {
    return futureOrElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get futureOrNullType {
    return _futureOrNullType ??= InterfaceTypeImpl(
      element: futureOrElement,
      typeArguments: fixedTypeList(nullType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElement get intElement {
    return _intElement ??= _getClassElement(_coreLibrary, "int");
  }

  @override
  ClassElement2 get intElement2 {
    return intElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get intType {
    return _intType ??= _getType(_coreLibrary, "int");
  }

  InterfaceType get intTypeQuestion =>
      _intTypeQuestion ??= (intType as InterfaceTypeImpl)
          .withNullability(NullabilitySuffix.question);

  @override
  InterfaceType get iterableDynamicType {
    return _iterableDynamicType ??= InterfaceTypeImpl(
      element: iterableElement,
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElement get iterableElement {
    return _iterableElement ??= _getClassElement(_coreLibrary, 'Iterable');
  }

  @override
  ClassElement2 get iterableElement2 {
    return iterableElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get iterableObjectType {
    return _iterableObjectType ??= InterfaceTypeImpl(
      element: iterableElement,
      typeArguments: fixedTypeList(objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElement get listElement {
    return _listElement ??= _getClassElement(_coreLibrary, 'List');
  }

  @override
  ClassElement2 get listElement2 {
    return listElement.asElement2 as ClassElement2;
  }

  @override
  ClassElement get mapElement {
    return _mapElement ??= _getClassElement(_coreLibrary, 'Map');
  }

  @override
  ClassElement2 get mapElement2 {
    return mapElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get mapObjectObjectType {
    return _mapObjectObjectType ??= InterfaceTypeImpl(
      element: mapElement,
      typeArguments: fixedTypeList(objectType, objectType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  NeverType get neverType => NeverTypeImpl.instance;

  @override
  ClassElement get nullElement {
    return _nullElement ??= _getClassElement(_coreLibrary, 'Null');
  }

  @override
  ClassElement2 get nullElement2 {
    return nullElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get nullType {
    return _nullType ??= _getType(_coreLibrary, "Null");
  }

  @override
  ClassElement get numElement {
    return _numElement ??= _getClassElement(_coreLibrary, 'num');
  }

  @override
  ClassElement2 get numElement2 {
    return numElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get numType {
    return _numType ??= _getType(_coreLibrary, "num");
  }

  InterfaceType get numTypeQuestion =>
      _numTypeQuestion ??= (numType as InterfaceTypeImpl)
          .withNullability(NullabilitySuffix.question);

  @override
  ClassElement get objectElement {
    return _objectElement ??= _getClassElement(_coreLibrary, 'Object');
  }

  @override
  ClassElement2 get objectElement2 {
    return objectElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get objectQuestionType {
    return _objectQuestionType ??= objectElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  @override
  InterfaceType get objectType {
    return _objectType ??= objectElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElement get recordElement {
    return _recordElement ??= _getClassElement(_coreLibrary, 'Record');
  }

  @override
  ClassElement2 get recordElement2 {
    return recordElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get recordType {
    return _recordType ??= recordElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElement get setElement {
    return _setElement ??= _getClassElement(_coreLibrary, 'Set');
  }

  @override
  ClassElement2 get setElement2 {
    return setElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get stackTraceType {
    return _stackTraceType ??= _getType(_coreLibrary, "StackTrace");
  }

  @override
  InterfaceType get streamDynamicType {
    return _streamDynamicType ??= InterfaceTypeImpl(
      element: streamElement,
      typeArguments: fixedTypeList(dynamicType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  ClassElement get streamElement {
    return _streamElement ??= _getClassElement(_asyncLibrary, 'Stream');
  }

  @override
  ClassElement2 get streamElement2 {
    return streamElement.asElement2 as ClassElement2;
  }

  @override
  ClassElement get stringElement {
    return _stringElement ??= _getClassElement(_coreLibrary, 'String');
  }

  @override
  ClassElement2 get stringElement2 {
    return stringElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get stringType {
    return _stringType ??= _getType(_coreLibrary, "String");
  }

  @override
  ClassElement get symbolElement {
    return _symbolElement ??= _getClassElement(_coreLibrary, 'Symbol');
  }

  @override
  ClassElement2 get symbolElement2 {
    return symbolElement.asElement2 as ClassElement2;
  }

  @override
  InterfaceType get symbolType {
    return _symbolType ??= _getType(_coreLibrary, "Symbol");
  }

  @override
  InterfaceType get typeType {
    return _typeType ??= _getType(_coreLibrary, "Type");
  }

  @override
  VoidType get voidType => VoidTypeImpl.instance;

  @override
  InterfaceType futureOrType(DartType valueType) {
    return futureOrElement.instantiate(
      typeArguments: fixedTypeList(valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceType futureType(DartType valueType) {
    return futureElement.instantiate(
      typeArguments: fixedTypeList(valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  bool isNonSubtypableClass(InterfaceElement element) {
    var name = element.name;
    if (_nonSubtypableClassNames.contains(name)) {
      var libraryUriStr = element.library.source.uri.toString();
      var ofLibrary = _nonSubtypableClassMap[libraryUriStr];
      return ofLibrary != null && ofLibrary.contains(name);
    }
    return false;
  }

  @override
  InterfaceType iterableType(DartType elementType) {
    return iterableElement.instantiate(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceType listType(DartType elementType) {
    return listElement.instantiate(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceType mapType(DartType keyType, DartType valueType) {
    return mapElement.instantiate(
      typeArguments: fixedTypeList(keyType, valueType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceType setType(DartType elementType) {
    return setElement.instantiate(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  InterfaceType streamType(DartType elementType) {
    return streamElement.instantiate(
      typeArguments: fixedTypeList(elementType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /// Return the class with the given [name] from the given [library], or
  /// throw a [StateError] if there is no class with the given name.
  ClassElement _getClassElement(LibraryElement library, String name) {
    var element = library.getClass(name);
    if (element == null) {
      throw StateError('No definition of type $name');
    }
    return element;
  }

  /// Return the type with the given [name] from the given [library], or
  /// throw a [StateError] if there is no class with the given name.
  InterfaceType _getType(LibraryElement library, String name) {
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
