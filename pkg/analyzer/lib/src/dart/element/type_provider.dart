// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:meta/meta.dart';

/// Provide common functionality shared by the various TypeProvider
/// implementations.
abstract class TypeProviderBase implements TypeProvider {
  @override
  List<InterfaceType> get nonSubtypableTypes => <InterfaceType>[
        boolType,
        doubleType,
        intType,
        nullType,
        numType,
        stringType
      ];

  @override
  bool isObjectGetter(String id) {
    PropertyAccessorElement element = objectType.element.getGetter(id);
    return element != null && !element.isStatic;
  }

  @override
  bool isObjectMember(String id) {
    return isObjectGetter(id) || isObjectMethod(id);
  }

  @override
  bool isObjectMethod(String id) {
    MethodElement element = objectType.element.getMethod(id);
    return element != null && !element.isStatic;
  }
}

class TypeProviderImpl extends TypeProviderBase {
  final LibraryElement _coreLibrary;
  final LibraryElement _asyncLibrary;

  /// If `true`, then NNBD types are returned.
  /// If `false`, then legacy types are returned.
  final bool isNonNullableByDefault;

  ClassElement _boolElement;
  ClassElement _doubleElement;
  ClassElement _futureElement;
  ClassElement _futureOrElement;
  ClassElement _intElement;
  ClassElement _iterableElement;
  ClassElement _listElement;
  ClassElement _mapElement;
  ClassElement _nullElement;
  ClassElement _numElement;
  ClassElement _objectElement;
  ClassElement _setElement;
  ClassElement _streamElement;
  ClassElement _stringElement;
  ClassElement _symbolElement;

  InterfaceType _boolType;
  InterfaceType _deprecatedType;
  InterfaceType _doubleType;
  InterfaceType _functionType;
  InterfaceType _futureDynamicType;
  InterfaceType _futureNullType;
  InterfaceType _futureOrNullType;
  InterfaceType _futureOrType;
  InterfaceType _futureType;
  InterfaceType _intType;
  InterfaceType _iterableDynamicType;
  InterfaceType _iterableObjectType;
  InterfaceType _iterableType;
  InterfaceType _listType;
  InterfaceType _mapType;
  InterfaceType _mapObjectObjectType;
  DartObjectImpl _nullObject;
  InterfaceType _nullType;
  InterfaceType _numType;
  InterfaceType _objectType;
  InterfaceType _setType;
  InterfaceType _stackTraceType;
  InterfaceType _streamDynamicType;
  InterfaceType _streamType;
  InterfaceType _stringType;
  InterfaceType _symbolType;
  InterfaceType _typeType;

  InterfaceTypeImpl _nullStar;

  InterfaceType _iterableForSetMapDisambiguation;
  InterfaceType _mapForSetMapDisambiguation;

  Set<ClassElement> _nonSubtypableClasses;

  /// Initialize a newly created type provider to provide the types defined in
  /// the given [coreLibrary] and [asyncLibrary].
  TypeProviderImpl({
    @required LibraryElement coreLibrary,
    @required LibraryElement asyncLibrary,
    @required bool isNonNullableByDefault,
  })  : _coreLibrary = coreLibrary,
        _asyncLibrary = asyncLibrary,
        isNonNullableByDefault = isNonNullableByDefault;

  TypeProviderImpl get asLegacy {
    if (isNonNullableByDefault) {
      return TypeProviderImpl(
        coreLibrary: _coreLibrary,
        asyncLibrary: _asyncLibrary,
        isNonNullableByDefault: false,
      );
    } else {
      return this;
    }
  }

  TypeProviderImpl get asNonNullableByDefault {
    if (isNonNullableByDefault) {
      return this;
    } else {
      return TypeProviderImpl(
        coreLibrary: _coreLibrary,
        asyncLibrary: _asyncLibrary,
        isNonNullableByDefault: true,
      );
    }
  }

  @override
  ClassElement get boolElement {
    return _boolElement ??= _getClassElement(_coreLibrary, 'bool');
  }

  @override
  InterfaceType get boolType {
    _boolType ??= _getType(_coreLibrary, "bool");
    return _boolType;
  }

  @override
  DartType get bottomType {
    if (isNonNullableByDefault) {
      return NeverTypeImpl.instance;
    }
    return NeverTypeImpl.instanceLegacy;
  }

  @override
  InterfaceType get deprecatedType {
    _deprecatedType ??= _getType(_coreLibrary, "Deprecated");
    return _deprecatedType;
  }

  @override
  ClassElement get doubleElement {
    return _doubleElement ??= _getClassElement(_coreLibrary, "double");
  }

  @override
  InterfaceType get doubleType {
    _doubleType ??= _getType(_coreLibrary, "double");
    return _doubleType;
  }

  @override
  DartType get dynamicType => DynamicTypeImpl.instance;

  @override
  InterfaceType get functionType {
    _functionType ??= _getType(_coreLibrary, "Function");
    return _functionType;
  }

  @override
  InterfaceType get futureDynamicType {
    _futureDynamicType ??= InterfaceTypeImpl(
      element: futureElement,
      typeArguments: [dynamicType],
      nullabilitySuffix: _nullabilitySuffix,
    );
    return _futureDynamicType;
  }

  @override
  ClassElement get futureElement {
    return _futureElement ??= _getClassElement(_asyncLibrary, 'Future');
  }

  @override
  InterfaceType get futureNullType {
    _futureNullType ??= InterfaceTypeImpl(
      element: futureElement,
      typeArguments: [nullType],
      nullabilitySuffix: _nullabilitySuffix,
    );
    return _futureNullType;
  }

  @override
  ClassElement get futureOrElement {
    return _futureOrElement ??= _getClassElement(_asyncLibrary, 'FutureOr');
  }

  @override
  InterfaceType get futureOrNullType {
    _futureOrNullType ??= InterfaceTypeImpl(
      element: futureOrElement,
      typeArguments: [nullType],
      nullabilitySuffix: _nullabilitySuffix,
    );
    return _futureOrNullType;
  }

  @override
  InterfaceType get futureOrType {
    _futureOrType ??= _getType(_asyncLibrary, "FutureOr");
    return _futureOrType;
  }

  @override
  InterfaceType get futureType {
    _futureType ??= _getType(_asyncLibrary, "Future");
    return _futureType;
  }

  @override
  ClassElement get intElement {
    return _intElement ??= _getClassElement(_coreLibrary, "int");
  }

  @override
  InterfaceType get intType {
    _intType ??= _getType(_coreLibrary, "int");
    return _intType;
  }

  @override
  InterfaceType get iterableDynamicType {
    _iterableDynamicType ??= InterfaceTypeImpl(
      element: iterableElement,
      typeArguments: [dynamicType],
      nullabilitySuffix: _nullabilitySuffix,
    );
    return _iterableDynamicType;
  }

  @override
  ClassElement get iterableElement {
    return _iterableElement ??= _getClassElement(_coreLibrary, 'Iterable');
  }

  /// Return the type that should be used during disambiguation between `Set`
  /// and `Map` literals. If NNBD enabled, use `Iterable<Object?, Object?>`,
  /// otherwise use `Iterable<Object*, Object*>*`.
  InterfaceType get iterableForSetMapDisambiguation {
    if (_iterableForSetMapDisambiguation == null) {
      var objectType = objectElement.instantiate(
        typeArguments: const [],
        nullabilitySuffix: _questionOrStarSuffix,
      );
      _iterableForSetMapDisambiguation = iterableElement.instantiate(
        typeArguments: [
          objectType,
        ],
        nullabilitySuffix: _questionOrStarSuffix,
      );
    }
    return _iterableForSetMapDisambiguation;
  }

  @override
  InterfaceType get iterableObjectType {
    _iterableObjectType ??= InterfaceTypeImpl(
      element: iterableElement,
      typeArguments: [objectType],
      nullabilitySuffix: _nullabilitySuffix,
    );
    return _iterableObjectType;
  }

  @override
  InterfaceType get iterableType {
    _iterableType ??= _getType(_coreLibrary, "Iterable");
    return _iterableType;
  }

  @override
  ClassElement get listElement {
    return _listElement ??= _getClassElement(_coreLibrary, 'List');
  }

  @override
  InterfaceType get listType {
    _listType ??= _getType(_coreLibrary, "List");
    return _listType;
  }

  @override
  ClassElement get mapElement {
    return _mapElement ??= _getClassElement(_coreLibrary, 'Map');
  }

  /// Return the type that should be used during disambiguation between `Set`
  /// and `Map` literals. If NNBD enabled, use `Map<Object?, Object?>`,
  /// otherwise use `Map<Object*, Object*>*`.
  InterfaceType get mapForSetMapDisambiguation {
    if (_mapForSetMapDisambiguation == null) {
      var objectType = objectElement.instantiate(
        typeArguments: const [],
        nullabilitySuffix: _questionOrStarSuffix,
      );
      _mapForSetMapDisambiguation = mapElement.instantiate(
        typeArguments: [
          objectType,
          objectType,
        ],
        nullabilitySuffix: _questionOrStarSuffix,
      );
    }
    return _mapForSetMapDisambiguation;
  }

  @override
  InterfaceType get mapObjectObjectType {
    _mapObjectObjectType ??= InterfaceTypeImpl(
      element: mapElement,
      typeArguments: [objectType, objectType],
      nullabilitySuffix: _nullabilitySuffix,
    );
    return _mapObjectObjectType;
  }

  @override
  InterfaceType get mapType {
    _mapType ??= _getType(_coreLibrary, "Map");
    return _mapType;
  }

  @override
  DartType get neverType => isNonNullableByDefault
      ? NeverTypeImpl.instance
      : NeverTypeImpl.instanceLegacy;

  @override
  Set<ClassElement> get nonSubtypableClasses => _nonSubtypableClasses ??= {
        boolElement,
        doubleElement,
        futureOrElement,
        intElement,
        nullElement,
        numElement,
        stringElement,
      };

  @override
  ClassElement get nullElement {
    return _nullElement ??= _getClassElement(_coreLibrary, 'Null');
  }

  @deprecated
  @override
  DartObjectImpl get nullObject {
    return _nullObject ??= DartObjectImpl(
      TypeSystemImpl(
        implicitCasts: false,
        isNonNullableByDefault: false,
        strictInference: false,
        typeProvider: this,
      ),
      nullType,
      NullState.NULL_STATE,
    );
  }

  InterfaceTypeImpl get nullStar {
    return _nullStar ??= nullElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  @override
  InterfaceType get nullType {
    _nullType ??= _getType(_coreLibrary, "Null");
    return _nullType;
  }

  @override
  ClassElement get numElement {
    return _numElement ??= _getClassElement(_coreLibrary, 'num');
  }

  @override
  InterfaceType get numType {
    _numType ??= _getType(_coreLibrary, "num");
    return _numType;
  }

  ClassElement get objectElement {
    return _objectElement ??= _getClassElement(_coreLibrary, 'Object');
  }

  @override
  InterfaceType get objectType {
    _objectType ??= _getType(_coreLibrary, "Object");
    return _objectType;
  }

  @override
  ClassElement get setElement {
    return _setElement ??= _getClassElement(_coreLibrary, 'Set');
  }

  @override
  InterfaceType get setType {
    return _setType ??= _getType(_coreLibrary, "Set");
  }

  @override
  InterfaceType get stackTraceType {
    _stackTraceType ??= _getType(_coreLibrary, "StackTrace");
    return _stackTraceType;
  }

  @override
  InterfaceType get streamDynamicType {
    _streamDynamicType ??= InterfaceTypeImpl(
      element: streamElement,
      typeArguments: [dynamicType],
      nullabilitySuffix: _nullabilitySuffix,
    );
    return _streamDynamicType;
  }

  @override
  ClassElement get streamElement {
    return _streamElement ??= _getClassElement(_asyncLibrary, 'Stream');
  }

  @override
  InterfaceType get streamType {
    _streamType ??= _getType(_asyncLibrary, "Stream");
    return _streamType;
  }

  @override
  ClassElement get stringElement {
    return _stringElement ??= _getClassElement(_coreLibrary, 'String');
  }

  @override
  InterfaceType get stringType {
    _stringType ??= _getType(_coreLibrary, "String");
    return _stringType;
  }

  @override
  ClassElement get symbolElement {
    return _symbolElement ??= _getClassElement(_coreLibrary, 'Symbol');
  }

  @override
  InterfaceType get symbolType {
    _symbolType ??= _getType(_coreLibrary, "Symbol");
    return _symbolType;
  }

  @override
  InterfaceType get typeType {
    _typeType ??= _getType(_coreLibrary, "Type");
    return _typeType;
  }

  @override
  VoidType get voidType => VoidTypeImpl.instance;

  NullabilitySuffix get _nullabilitySuffix {
    if (isNonNullableByDefault) {
      return NullabilitySuffix.none;
    } else {
      return NullabilitySuffix.star;
    }
  }

  NullabilitySuffix get _questionOrStarSuffix {
    return isNonNullableByDefault
        ? NullabilitySuffix.question
        : NullabilitySuffix.star;
  }

  @override
  InterfaceType futureOrType2(DartType valueType) {
    return futureOrElement.instantiate(
      typeArguments: [valueType],
      nullabilitySuffix: _nullabilitySuffix,
    );
  }

  @override
  InterfaceType futureType2(DartType valueType) {
    return futureElement.instantiate(
      typeArguments: [valueType],
      nullabilitySuffix: _nullabilitySuffix,
    );
  }

  @override
  InterfaceType iterableType2(DartType elementType) {
    return iterableElement.instantiate(
      typeArguments: [elementType],
      nullabilitySuffix: _nullabilitySuffix,
    );
  }

  @override
  InterfaceType listType2(DartType elementType) {
    return listElement.instantiate(
      typeArguments: [elementType],
      nullabilitySuffix: _nullabilitySuffix,
    );
  }

  @override
  InterfaceType mapType2(DartType keyType, DartType valueType) {
    return mapElement.instantiate(
      typeArguments: [keyType, valueType],
      nullabilitySuffix: _nullabilitySuffix,
    );
  }

  @override
  InterfaceType setType2(DartType elementType) {
    return setElement.instantiate(
      typeArguments: [elementType],
      nullabilitySuffix: _nullabilitySuffix,
    );
  }

  @override
  InterfaceType streamType2(DartType elementType) {
    return streamElement.instantiate(
      typeArguments: [elementType],
      nullabilitySuffix: _nullabilitySuffix,
    );
  }

  /// Return the class with the given [name] from the given [library], or
  /// throw a [StateError] if there is no class with the given name.
  ClassElement _getClassElement(LibraryElement library, String name) {
    var element = library.getType(name);
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
          nullabilitySuffix: _nullabilitySuffix,
        );
      }).toList(growable: false);
    }

    return InterfaceTypeImpl(
      element: element,
      typeArguments: typeArguments,
      nullabilitySuffix: _nullabilitySuffix,
    );
  }
}
