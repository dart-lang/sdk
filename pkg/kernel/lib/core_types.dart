// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.core_types;

import 'ast.dart';
import 'library_index.dart';

/// Provides access to the classes and libraries in the core libraries.
class CoreTypes {
  static final Map<String, List<String>> requiredClasses = {
    'dart:core': [
      'Object',
      'Null',
      'bool',
      'int',
      'num',
      'double',
      'String',
      'List',
      'Map',
      'Iterable',
      'Iterator',
      'Symbol',
      'Type',
      'Function',
      'Invocation',
      'FallThroughError',
    ],
    'dart:_internal': [
      'Symbol',
    ],
    'dart:async': [
      'Future',
      'Stream',
    ]
  };

  final LibraryIndex index;

  Library _coreLibrary;
  Class _objectClass;
  Class _nullClass;
  Class _boolClass;
  Class _intClass;
  Class _numClass;
  Class _doubleClass;
  Class _stringClass;
  Class _listClass;
  Class _setClass;
  Class _mapClass;
  Class _iterableClass;
  Class _iteratorClass;
  Class _symbolClass;
  Class _typeClass;
  Class _functionClass;
  Class _invocationClass;
  Class _invocationMirrorClass;
  Constructor _invocationMirrorWithTypeConstructor;
  Constructor _noSuchMethodErrorDefaultConstructor;
  Procedure _listFromConstructor;
  Procedure _listUnmodifiableConstructor;
  Procedure _identicalProcedure;
  Constructor _fallThroughErrorUrlAndLineConstructor;
  Procedure _objectEquals;
  Procedure _mapUnmodifiable;

  Class _internalSymbolClass;

  Library _asyncLibrary;
  Class _futureClass;
  Class _stackTraceClass;
  Class _streamClass;
  Class _asyncAwaitCompleterClass;
  Class _futureOrClass;
  Constructor _asyncAwaitCompleterConstructor;
  Procedure _completeOnAsyncReturnProcedure;
  Procedure _completerCompleteError;
  Constructor _syncIterableDefaultConstructor;
  Constructor _streamIteratorDefaultConstructor;
  Constructor _asyncStarStreamControllerDefaultConstructor;
  Procedure _asyncStarListenHelperProcedure;
  Procedure _asyncStarMoveNextHelperProcedure;
  Procedure _asyncStackTraceHelperProcedure;
  Procedure _asyncThenWrapperHelperProcedure;
  Procedure _asyncErrorWrapperHelperProcedure;
  Procedure _awaitHelperProcedure;
  Procedure _boolFromEnvironment;

  /// The `dart:mirrors` library, or `null` if the component does not use it.
  Library _mirrorsLibrary;

  Class _pragmaClass;
  Field _pragmaName;
  Field _pragmaOptions;
  Constructor _pragmaConstructor;

  InterfaceType _objectLegacyRawType;
  InterfaceType _objectNullableRawType;
  InterfaceType _objectNonNullableRawType;
  InterfaceType _nullType;
  InterfaceType _boolLegacyRawType;
  InterfaceType _boolNullableRawType;
  InterfaceType _boolNonNullableRawType;
  InterfaceType _intLegacyRawType;
  InterfaceType _intNullableRawType;
  InterfaceType _intNonNullableRawType;
  InterfaceType _numLegacyRawType;
  InterfaceType _numNullableRawType;
  InterfaceType _numNonNullableRawType;
  InterfaceType _doubleLegacyRawType;
  InterfaceType _doubleNullableRawType;
  InterfaceType _doubleNonNullableRawType;
  InterfaceType _stringLegacyRawType;
  InterfaceType _stringNullableRawType;
  InterfaceType _stringNonNullableRawType;
  InterfaceType _listLegacyRawType;
  InterfaceType _listNullableRawType;
  InterfaceType _listNonNullableRawType;
  InterfaceType _setLegacyRawType;
  InterfaceType _setNullableRawType;
  InterfaceType _setNonNullableRawType;
  InterfaceType _mapLegacyRawType;
  InterfaceType _mapNullableRawType;
  InterfaceType _mapNonNullableRawType;
  InterfaceType _iterableLegacyRawType;
  InterfaceType _iterableNullableRawType;
  InterfaceType _iterableNonNullableRawType;
  InterfaceType _iteratorLegacyRawType;
  InterfaceType _iteratorNullableRawType;
  InterfaceType _iteratorNonNullableRawType;
  InterfaceType _symbolLegacyRawType;
  InterfaceType _symbolNullableRawType;
  InterfaceType _symbolNonNullableRawType;
  InterfaceType _typeLegacyRawType;
  InterfaceType _typeNullableRawType;
  InterfaceType _typeNonNullableRawType;
  InterfaceType _functionLegacyRawType;
  InterfaceType _functionNullableRawType;
  InterfaceType _functionNonNullableRawType;
  InterfaceType _invocationLegacyRawType;
  InterfaceType _invocationNullableRawType;
  InterfaceType _invocationNonNullableRawType;
  InterfaceType _invocationMirrorLegacyRawType;
  InterfaceType _invocationMirrorNullableRawType;
  InterfaceType _invocationMirrorNonNullableRawType;
  InterfaceType _futureLegacyRawType;
  InterfaceType _futureNullableRawType;
  InterfaceType _futureNonNullableRawType;
  InterfaceType _stackTraceLegacyRawType;
  InterfaceType _stackTraceNullableRawType;
  InterfaceType _stackTraceNonNullableRawType;
  InterfaceType _streamLegacyRawType;
  InterfaceType _streamNullableRawType;
  InterfaceType _streamNonNullableRawType;
  InterfaceType _asyncAwaitCompleterLegacyRawType;
  InterfaceType _asyncAwaitCompleterNullableRawType;
  InterfaceType _asyncAwaitCompleterNonNullableRawType;
  InterfaceType _futureOrLegacyRawType;
  InterfaceType _futureOrNullableRawType;
  InterfaceType _futureOrNonNullableRawType;
  InterfaceType _pragmaLegacyRawType;
  InterfaceType _pragmaNullableRawType;
  InterfaceType _pragmaNonNullableRawType;
  final Map<Class, InterfaceType> _legacyRawTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<Class, InterfaceType> _nullableRawTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<Class, InterfaceType> _nonNullableRawTypes =
      new Map<Class, InterfaceType>.identity();

  CoreTypes(Component component)
      : index = new LibraryIndex.coreLibraries(component);

  Procedure get asyncErrorWrapperHelperProcedure {
    return _asyncErrorWrapperHelperProcedure ??=
        index.getTopLevelMember('dart:async', '_asyncErrorWrapperHelper');
  }

  Library get asyncLibrary {
    return _asyncLibrary ??= index.getLibrary('dart:async');
  }

  Member get asyncStarStreamControllerAdd {
    return index.getMember('dart:async', '_AsyncStarStreamController', 'add');
  }

  Member get asyncStarStreamControllerAddError {
    return index.getMember(
        'dart:async', '_AsyncStarStreamController', 'addError');
  }

  Member get asyncStarStreamControllerAddStream {
    return index.getMember(
        'dart:async', '_AsyncStarStreamController', 'addStream');
  }

  Class get asyncStarStreamControllerClass {
    return index.getClass('dart:async', '_AsyncStarStreamController');
  }

  Member get asyncStarStreamControllerClose {
    return index.getMember('dart:async', '_AsyncStarStreamController', 'close');
  }

  Constructor get asyncStarStreamControllerDefaultConstructor {
    return _asyncStarStreamControllerDefaultConstructor ??=
        index.getMember('dart:async', '_AsyncStarStreamController', '');
  }

  Member get asyncStarStreamControllerStream {
    return index.getMember(
        'dart:async', '_AsyncStarStreamController', 'get:stream');
  }

  Procedure get asyncStarListenHelper {
    return _asyncStarListenHelperProcedure ??=
        index.getTopLevelMember('dart:async', '_asyncStarListenHelper');
  }

  Procedure get asyncStarMoveNextHelper {
    return _asyncStarMoveNextHelperProcedure ??=
        index.getTopLevelMember('dart:async', '_asyncStarMoveNextHelper');
  }

  Procedure get asyncStackTraceHelperProcedure {
    return _asyncStackTraceHelperProcedure ??=
        index.getTopLevelMember('dart:async', '_asyncStackTraceHelper');
  }

  Procedure get asyncThenWrapperHelperProcedure {
    return _asyncThenWrapperHelperProcedure ??=
        index.getTopLevelMember('dart:async', '_asyncThenWrapperHelper');
  }

  Procedure get awaitHelperProcedure {
    return _awaitHelperProcedure ??=
        index.getTopLevelMember('dart:async', '_awaitHelper');
  }

  Class get boolClass {
    return _boolClass ??= index.getClass('dart:core', 'bool');
  }

  Class get asyncAwaitCompleterClass {
    return _asyncAwaitCompleterClass ??=
        index.getClass('dart:async', '_AsyncAwaitCompleter');
  }

  Constructor get asyncAwaitCompleterConstructor {
    return _asyncAwaitCompleterConstructor ??=
        index.getMember('dart:async', '_AsyncAwaitCompleter', '');
  }

  Member get completeOnAsyncReturn {
    return _completeOnAsyncReturnProcedure ??=
        index.getTopLevelMember('dart:async', '_completeOnAsyncReturn');
  }

  Procedure get completerCompleteError {
    return _completerCompleteError ??=
        index.getMember('dart:async', 'Completer', 'completeError');
  }

  Member get completerFuture {
    return index.getMember('dart:async', 'Completer', 'get:future');
  }

  Library get coreLibrary {
    return _coreLibrary ??= index.getLibrary('dart:core');
  }

  Class get doubleClass {
    return _doubleClass ??= index.getClass('dart:core', 'double');
  }

  Class get functionClass {
    return _functionClass ??= index.getClass('dart:core', 'Function');
  }

  Class get futureClass {
    return _futureClass ??= index.getClass('dart:core', 'Future');
  }

  Class get futureOrClass {
    return _futureOrClass ??= (index.tryGetClass('dart:core', 'FutureOr') ??
        index.getClass('dart:async', 'FutureOr'));
  }

  Procedure get identicalProcedure {
    return _identicalProcedure ??=
        index.getTopLevelMember('dart:core', 'identical');
  }

  Class get intClass {
    return _intClass ??= index.getClass('dart:core', 'int');
  }

  Class get internalSymbolClass {
    return _internalSymbolClass ??= index.getClass('dart:_internal', 'Symbol');
  }

  Class get invocationClass {
    return _invocationClass ??= index.getClass('dart:core', 'Invocation');
  }

  Class get invocationMirrorClass {
    return _invocationMirrorClass ??=
        index.getClass('dart:core', '_InvocationMirror');
  }

  Constructor get invocationMirrorWithTypeConstructor {
    return _invocationMirrorWithTypeConstructor ??=
        index.getMember('dart:core', '_InvocationMirror', '_withType');
  }

  Class get iterableClass {
    return _iterableClass ??= index.getClass('dart:core', 'Iterable');
  }

  Class get iteratorClass {
    return _iteratorClass ??= index.getClass('dart:core', 'Iterator');
  }

  Class get listClass {
    return _listClass ??= index.getClass('dart:core', 'List');
  }

  Procedure get listFromConstructor {
    return _listFromConstructor ??=
        index.getMember('dart:core', 'List', 'from');
  }

  Procedure get listUnmodifiableConstructor {
    return _listUnmodifiableConstructor ??=
        index.getMember('dart:core', 'List', 'unmodifiable');
  }

  Class get setClass {
    return _setClass ??= index.getClass('dart:core', 'Set');
  }

  Class get mapClass {
    return _mapClass ??= index.getClass('dart:core', 'Map');
  }

  Procedure get mapUnmodifiable {
    return _mapUnmodifiable ??=
        index.getMember('dart:core', 'Map', 'unmodifiable');
  }

  Library get mirrorsLibrary {
    return _mirrorsLibrary ??= index.tryGetLibrary('dart:mirrors');
  }

  Constructor get noSuchMethodErrorDefaultConstructor {
    return _noSuchMethodErrorDefaultConstructor ??=
        // TODO(regis): Replace 'withInvocation' with '' after dart2js is fixed.
        index.getMember('dart:core', 'NoSuchMethodError', 'withInvocation');
  }

  Class get nullClass {
    return _nullClass ??= index.getClass('dart:core', 'Null');
  }

  Class get numClass {
    return _numClass ??= index.getClass('dart:core', 'num');
  }

  Class get objectClass {
    return _objectClass ??= index.getClass('dart:core', 'Object');
  }

  Procedure get objectEquals {
    return _objectEquals ??= index.getMember('dart:core', 'Object', '==');
  }

  Class get pragmaClass {
    return _pragmaClass ??= index.getClass('dart:core', 'pragma');
  }

  Field get pragmaName {
    return _pragmaName ??= index.getMember('dart:core', 'pragma', 'name');
  }

  Field get pragmaOptions {
    return _pragmaOptions ??= index.getMember('dart:core', 'pragma', 'options');
  }

  Constructor get pragmaConstructor {
    return _pragmaConstructor ??= index.getMember('dart:core', 'pragma', '_');
  }

  Class get stackTraceClass {
    return _stackTraceClass ??= index.getClass('dart:core', 'StackTrace');
  }

  Class get streamClass {
    return _streamClass ??= index.getClass('dart:core', 'Stream');
  }

  Member get streamIteratorSubscription {
    return index.getMember('dart:async', '_StreamIterator', '_subscription');
  }

  Member get streamIteratorCancel {
    return index.getMember('dart:async', '_StreamIterator', 'cancel');
  }

  Class get streamIteratorClass {
    return index.getClass('dart:async', '_StreamIterator');
  }

  Constructor get streamIteratorDefaultConstructor {
    return _streamIteratorDefaultConstructor ??=
        index.getMember('dart:async', '_StreamIterator', '');
  }

  Member get streamIteratorMoveNext {
    return index.getMember('dart:async', '_StreamIterator', 'moveNext');
  }

  Member get streamIteratorCurrent {
    return index.getMember('dart:async', '_StreamIterator', 'get:current');
  }

  Class get stringClass {
    return _stringClass ??= index.getClass('dart:core', 'String');
  }

  Class get symbolClass {
    return _symbolClass ??= index.getClass('dart:core', 'Symbol');
  }

  Constructor get syncIterableDefaultConstructor {
    return _syncIterableDefaultConstructor ??=
        index.getMember('dart:core', '_SyncIterable', '');
  }

  Class get syncIteratorClass {
    return index.getClass('dart:core', '_SyncIterator');
  }

  Member get syncIteratorCurrent {
    return index.getMember('dart:core', '_SyncIterator', '_current');
  }

  Member get syncIteratorYieldEachIterable {
    return index.getMember('dart:core', '_SyncIterator', '_yieldEachIterable');
  }

  Class get typeClass {
    return _typeClass ??= index.getClass('dart:core', 'Type');
  }

  Constructor get fallThroughErrorUrlAndLineConstructor {
    return _fallThroughErrorUrlAndLineConstructor ??=
        index.getMember('dart:core', 'FallThroughError', '_create');
  }

  Procedure get boolFromEnvironment {
    return _boolFromEnvironment ??=
        index.getMember('dart:core', 'bool', 'fromEnvironment');
  }

  InterfaceType get objectLegacyRawType {
    return _objectLegacyRawType ??= _legacyRawTypes[objectClass] ??=
        new InterfaceType(objectClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get objectNullableRawType {
    return _objectNullableRawType ??= _nullableRawTypes[objectClass] ??=
        new InterfaceType(
            objectClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get objectNonNullableRawType {
    return _objectNonNullableRawType ??= _nonNullableRawTypes[objectClass] ??=
        new InterfaceType(
            objectClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType objectRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return objectLegacyRawType;
      case Nullability.nullable:
        return objectNullableRawType;
      case Nullability.nonNullable:
        return objectNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  /// Null is always nullable, so there's only one raw type for that class.
  InterfaceType get nullType {
    return _nullType ??= _nullableRawTypes[nullClass] ??=
        new InterfaceType(nullClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get boolLegacyRawType {
    return _boolLegacyRawType ??= _legacyRawTypes[boolClass] ??=
        new InterfaceType(boolClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get boolNullableRawType {
    return _boolNullableRawType ??= _nullableRawTypes[boolClass] ??=
        new InterfaceType(boolClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get boolNonNullableRawType {
    return _boolNonNullableRawType ??= _nonNullableRawTypes[boolClass] ??=
        new InterfaceType(
            boolClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType boolRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return boolLegacyRawType;
      case Nullability.nullable:
        return boolNullableRawType;
      case Nullability.nonNullable:
        return boolNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get intLegacyRawType {
    return _intLegacyRawType ??= _legacyRawTypes[intClass] ??=
        new InterfaceType(intClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get intNullableRawType {
    return _intNullableRawType ??= _nullableRawTypes[intClass] ??=
        new InterfaceType(intClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get intNonNullableRawType {
    return _intNonNullableRawType ??= _nonNullableRawTypes[intClass] ??=
        new InterfaceType(
            intClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType intRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return intLegacyRawType;
      case Nullability.nullable:
        return intNullableRawType;
      case Nullability.nonNullable:
        return intNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get numLegacyRawType {
    return _numLegacyRawType ??= _legacyRawTypes[numClass] ??=
        new InterfaceType(numClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get numNullableRawType {
    return _numNullableRawType ??= _nullableRawTypes[numClass] ??=
        new InterfaceType(numClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get numNonNullableRawType {
    return _numNonNullableRawType ??= _nonNullableRawTypes[numClass] ??=
        new InterfaceType(
            numClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType numRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return numLegacyRawType;
      case Nullability.nullable:
        return numNullableRawType;
      case Nullability.nonNullable:
        return numNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get doubleLegacyRawType {
    return _doubleLegacyRawType ??= _legacyRawTypes[doubleClass] ??=
        new InterfaceType(doubleClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get doubleNullableRawType {
    return _doubleNullableRawType ??= _nullableRawTypes[doubleClass] ??=
        new InterfaceType(
            doubleClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get doubleNonNullableRawType {
    return _doubleNonNullableRawType ??= _nonNullableRawTypes[doubleClass] ??=
        new InterfaceType(
            doubleClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType doubleRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return doubleLegacyRawType;
      case Nullability.nullable:
        return doubleNullableRawType;
      case Nullability.nonNullable:
        return doubleNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get stringLegacyRawType {
    return _stringLegacyRawType ??= _legacyRawTypes[stringClass] ??=
        new InterfaceType(stringClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get stringNullableRawType {
    return _stringNullableRawType ??= _nullableRawTypes[stringClass] ??=
        new InterfaceType(
            stringClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get stringNonNullableRawType {
    return _stringNonNullableRawType ??= _nonNullableRawTypes[stringClass] ??=
        new InterfaceType(
            stringClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType stringRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return stringLegacyRawType;
      case Nullability.nullable:
        return stringNullableRawType;
      case Nullability.nonNullable:
        return stringNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get listLegacyRawType {
    return _listLegacyRawType ??= _legacyRawTypes[listClass] ??=
        new InterfaceType(listClass, const <DartType>[const DynamicType()],
            Nullability.legacy);
  }

  InterfaceType get listNullableRawType {
    return _listNullableRawType ??= _nullableRawTypes[listClass] ??=
        new InterfaceType(listClass, const <DartType>[const DynamicType()],
            Nullability.nullable);
  }

  InterfaceType get listNonNullableRawType {
    return _listNonNullableRawType ??= _nonNullableRawTypes[listClass] ??=
        new InterfaceType(listClass, const <DartType>[const DynamicType()],
            Nullability.nonNullable);
  }

  InterfaceType listRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return listLegacyRawType;
      case Nullability.nullable:
        return listNullableRawType;
      case Nullability.nonNullable:
        return listNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get setLegacyRawType {
    return _setLegacyRawType ??= _legacyRawTypes[setClass] ??=
        new InterfaceType(setClass, const <DartType>[const DynamicType()],
            Nullability.legacy);
  }

  InterfaceType get setNullableRawType {
    return _setNullableRawType ??= _nullableRawTypes[setClass] ??=
        new InterfaceType(setClass, const <DartType>[const DynamicType()],
            Nullability.nullable);
  }

  InterfaceType get setNonNullableRawType {
    return _setNonNullableRawType ??= _nonNullableRawTypes[setClass] ??=
        new InterfaceType(setClass, const <DartType>[const DynamicType()],
            Nullability.nonNullable);
  }

  InterfaceType setRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return setLegacyRawType;
      case Nullability.nullable:
        return setNullableRawType;
      case Nullability.nonNullable:
        return setNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get mapLegacyRawType {
    return _mapLegacyRawType ??= _legacyRawTypes[mapClass] ??=
        new InterfaceType(
            mapClass,
            const <DartType>[const DynamicType(), const DynamicType()],
            Nullability.legacy);
  }

  InterfaceType get mapNullableRawType {
    return _mapNullableRawType ??= _nullableRawTypes[mapClass] ??=
        new InterfaceType(
            mapClass,
            const <DartType>[const DynamicType(), const DynamicType()],
            Nullability.nullable);
  }

  InterfaceType get mapNonNullableRawType {
    return _mapNonNullableRawType ??= _nonNullableRawTypes[mapClass] ??=
        new InterfaceType(
            mapClass,
            const <DartType>[const DynamicType(), const DynamicType()],
            Nullability.nonNullable);
  }

  InterfaceType mapRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return mapLegacyRawType;
      case Nullability.nullable:
        return mapNullableRawType;
      case Nullability.nonNullable:
        return mapNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get iterableLegacyRawType {
    return _iterableLegacyRawType ??= _legacyRawTypes[iterableClass] ??=
        new InterfaceType(iterableClass, const <DartType>[const DynamicType()],
            Nullability.legacy);
  }

  InterfaceType get iterableNullableRawType {
    return _iterableNullableRawType ??= _nullableRawTypes[iterableClass] ??=
        new InterfaceType(iterableClass, const <DartType>[const DynamicType()],
            Nullability.nullable);
  }

  InterfaceType get iterableNonNullableRawType {
    return _iterableNonNullableRawType ??=
        _nonNullableRawTypes[iterableClass] ??= new InterfaceType(iterableClass,
            const <DartType>[const DynamicType()], Nullability.nonNullable);
  }

  InterfaceType iterableRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return iterableLegacyRawType;
      case Nullability.nullable:
        return iterableNullableRawType;
      case Nullability.nonNullable:
        return iterableNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get iteratorLegacyRawType {
    return _iteratorLegacyRawType ??= _legacyRawTypes[iteratorClass] ??=
        new InterfaceType(iteratorClass, const <DartType>[const DynamicType()],
            Nullability.legacy);
  }

  InterfaceType get iteratorNullableRawType {
    return _iteratorNullableRawType ??= _nullableRawTypes[iteratorClass] ??=
        new InterfaceType(iteratorClass, const <DartType>[const DynamicType()],
            Nullability.nullable);
  }

  InterfaceType get iteratorNonNullableRawType {
    return _iteratorNonNullableRawType ??=
        _nonNullableRawTypes[iteratorClass] ??= new InterfaceType(iteratorClass,
            const <DartType>[const DynamicType()], Nullability.nonNullable);
  }

  InterfaceType iteratorRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return iteratorLegacyRawType;
      case Nullability.nullable:
        return iteratorNullableRawType;
      case Nullability.nonNullable:
        return iteratorNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get symbolLegacyRawType {
    return _symbolLegacyRawType ??= _legacyRawTypes[symbolClass] ??=
        new InterfaceType(symbolClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get symbolNullableRawType {
    return _symbolNullableRawType ??= _nullableRawTypes[symbolClass] ??=
        new InterfaceType(
            symbolClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get symbolNonNullableRawType {
    return _symbolNonNullableRawType ??= _nonNullableRawTypes[symbolClass] ??=
        new InterfaceType(
            symbolClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType symbolRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return symbolLegacyRawType;
      case Nullability.nullable:
        return symbolNullableRawType;
      case Nullability.nonNullable:
        return symbolNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get typeLegacyRawType {
    return _typeLegacyRawType ??= _legacyRawTypes[typeClass] ??=
        new InterfaceType(typeClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get typeNullableRawType {
    return _typeNullableRawType ??= _nullableRawTypes[typeClass] ??=
        new InterfaceType(typeClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get typeNonNullableRawType {
    return _typeNonNullableRawType ??= _nonNullableRawTypes[typeClass] ??=
        new InterfaceType(
            typeClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType typeRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return typeLegacyRawType;
      case Nullability.nullable:
        return typeNullableRawType;
      case Nullability.nonNullable:
        return typeNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get functionLegacyRawType {
    return _functionLegacyRawType ??= _legacyRawTypes[functionClass] ??=
        new InterfaceType(
            functionClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get functionNullableRawType {
    return _functionNullableRawType ??= _nullableRawTypes[functionClass] ??=
        new InterfaceType(
            functionClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get functionNonNullableRawType {
    return _functionNonNullableRawType ??=
        _nonNullableRawTypes[functionClass] ??= new InterfaceType(
            functionClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType functionRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return functionLegacyRawType;
      case Nullability.nullable:
        return functionNullableRawType;
      case Nullability.nonNullable:
        return functionNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get invocationLegacyRawType {
    return _invocationLegacyRawType ??= _legacyRawTypes[invocationClass] ??=
        new InterfaceType(
            invocationClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get invocationNullableRawType {
    return _invocationNullableRawType ??= _nullableRawTypes[invocationClass] ??=
        new InterfaceType(
            invocationClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get invocationNonNullableRawType {
    return _invocationNonNullableRawType ??=
        _nonNullableRawTypes[invocationClass] ??= new InterfaceType(
            invocationClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType invocationRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return invocationLegacyRawType;
      case Nullability.nullable:
        return invocationNullableRawType;
      case Nullability.nonNullable:
        return invocationNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get invocationMirrorLegacyRawType {
    return _invocationMirrorLegacyRawType ??=
        _legacyRawTypes[invocationMirrorClass] ??= new InterfaceType(
            invocationMirrorClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get invocationMirrorNullableRawType {
    return _invocationMirrorNullableRawType ??=
        _nullableRawTypes[invocationMirrorClass] ??= new InterfaceType(
            invocationMirrorClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get invocationMirrorNonNullableRawType {
    return _invocationMirrorNonNullableRawType ??=
        _nonNullableRawTypes[invocationMirrorClass] ??= new InterfaceType(
            invocationMirrorClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType invocationMirrorRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return invocationMirrorLegacyRawType;
      case Nullability.nullable:
        return invocationMirrorNullableRawType;
      case Nullability.nonNullable:
        return invocationMirrorNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get futureLegacyRawType {
    return _futureLegacyRawType ??= _legacyRawTypes[futureClass] ??=
        new InterfaceType(futureClass, const <DartType>[const DynamicType()],
            Nullability.legacy);
  }

  InterfaceType get futureNullableRawType {
    return _futureNullableRawType ??= _nullableRawTypes[futureClass] ??=
        new InterfaceType(futureClass, const <DartType>[const DynamicType()],
            Nullability.nullable);
  }

  InterfaceType get futureNonNullableRawType {
    return _futureNonNullableRawType ??= _nonNullableRawTypes[futureClass] ??=
        new InterfaceType(futureClass, const <DartType>[const DynamicType()],
            Nullability.nonNullable);
  }

  InterfaceType futureRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return futureLegacyRawType;
      case Nullability.nullable:
        return futureNullableRawType;
      case Nullability.nonNullable:
        return futureNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get stackTraceLegacyRawType {
    return _stackTraceLegacyRawType ??= _legacyRawTypes[stackTraceClass] ??=
        new InterfaceType(
            stackTraceClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get stackTraceNullableRawType {
    return _stackTraceNullableRawType ??= _nullableRawTypes[stackTraceClass] ??=
        new InterfaceType(
            stackTraceClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get stackTraceNonNullableRawType {
    return _stackTraceNonNullableRawType ??=
        _nonNullableRawTypes[stackTraceClass] ??= new InterfaceType(
            stackTraceClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType stackTraceRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return stackTraceLegacyRawType;
      case Nullability.nullable:
        return stackTraceNullableRawType;
      case Nullability.nonNullable:
        return stackTraceNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get streamLegacyRawType {
    return _streamLegacyRawType ??= _legacyRawTypes[streamClass] ??=
        new InterfaceType(streamClass, const <DartType>[const DynamicType()],
            Nullability.legacy);
  }

  InterfaceType get streamNullableRawType {
    return _streamNullableRawType ??= _nullableRawTypes[streamClass] ??=
        new InterfaceType(streamClass, const <DartType>[const DynamicType()],
            Nullability.nullable);
  }

  InterfaceType get streamNonNullableRawType {
    return _streamNonNullableRawType ??= _nonNullableRawTypes[streamClass] ??=
        new InterfaceType(streamClass, const <DartType>[const DynamicType()],
            Nullability.nonNullable);
  }

  InterfaceType streamRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return streamLegacyRawType;
      case Nullability.nullable:
        return streamNullableRawType;
      case Nullability.nonNullable:
        return streamNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get asyncAwaitCompleterLegacyRawType {
    return _asyncAwaitCompleterLegacyRawType ??=
        _legacyRawTypes[asyncAwaitCompleterClass] ??= new InterfaceType(
            asyncAwaitCompleterClass,
            const <DartType>[const DynamicType()],
            Nullability.legacy);
  }

  InterfaceType get asyncAwaitCompleterNullableRawType {
    return _asyncAwaitCompleterNullableRawType ??=
        _nullableRawTypes[asyncAwaitCompleterClass] ??= new InterfaceType(
            asyncAwaitCompleterClass,
            const <DartType>[const DynamicType()],
            Nullability.nullable);
  }

  InterfaceType get asyncAwaitCompleterNonNullableRawType {
    return _asyncAwaitCompleterNonNullableRawType ??=
        _nonNullableRawTypes[asyncAwaitCompleterClass] ??= new InterfaceType(
            asyncAwaitCompleterClass,
            const <DartType>[const DynamicType()],
            Nullability.nonNullable);
  }

  InterfaceType asyncAwaitCompleterRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return asyncAwaitCompleterLegacyRawType;
      case Nullability.nullable:
        return asyncAwaitCompleterNullableRawType;
      case Nullability.nonNullable:
        return asyncAwaitCompleterNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get futureOrLegacyRawType {
    return _futureOrLegacyRawType ??= _legacyRawTypes[futureOrClass] ??=
        new InterfaceType(futureOrClass, const <DartType>[const DynamicType()],
            Nullability.legacy);
  }

  InterfaceType get futureOrNullableRawType {
    return _futureOrNullableRawType ??= _nullableRawTypes[futureOrClass] ??=
        new InterfaceType(futureOrClass, const <DartType>[const DynamicType()],
            Nullability.nullable);
  }

  InterfaceType get futureOrNonNullableRawType {
    return _futureOrNonNullableRawType ??=
        _nonNullableRawTypes[futureOrClass] ??= new InterfaceType(futureOrClass,
            const <DartType>[const DynamicType()], Nullability.nonNullable);
  }

  InterfaceType futureOrRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return futureOrLegacyRawType;
      case Nullability.nullable:
        return futureOrNullableRawType;
      case Nullability.nonNullable:
        return futureOrNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get pragmaLegacyRawType {
    return _pragmaLegacyRawType ??= _legacyRawTypes[pragmaClass] ??=
        new InterfaceType(pragmaClass, const <DartType>[], Nullability.legacy);
  }

  InterfaceType get pragmaNullableRawType {
    return _pragmaNullableRawType ??= _nullableRawTypes[pragmaClass] ??=
        new InterfaceType(
            pragmaClass, const <DartType>[], Nullability.nullable);
  }

  InterfaceType get pragmaNonNullableRawType {
    return _pragmaNonNullableRawType ??= _nonNullableRawTypes[pragmaClass] ??=
        new InterfaceType(
            pragmaClass, const <DartType>[], Nullability.nonNullable);
  }

  InterfaceType pragmaRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return pragmaLegacyRawType;
      case Nullability.nullable:
        return pragmaNullableRawType;
      case Nullability.nonNullable:
        return pragmaNonNullableRawType;
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType legacyRawType(Class klass) {
    // TODO(dmitryas): Consider using computeBounds instead of DynamicType here.
    return _legacyRawTypes[klass] ??= new InterfaceType(
        klass,
        new List<DartType>.filled(
            klass.typeParameters.length, const DynamicType()),
        Nullability.legacy);
  }

  InterfaceType nullableRawType(Class klass) {
    // TODO(dmitryas): Consider using computeBounds instead of DynamicType here.
    return _nullableRawTypes[klass] ??= new InterfaceType(
        klass,
        new List<DartType>.filled(
            klass.typeParameters.length, const DynamicType()),
        Nullability.nullable);
  }

  InterfaceType nonNullableRawType(Class klass) {
    // TODO(dmitryas): Consider using computeBounds instead of DynamicType here.
    return _nonNullableRawTypes[klass] ??= new InterfaceType(
        klass,
        new List<DartType>.filled(
            klass.typeParameters.length, const DynamicType()),
        Nullability.nonNullable);
  }

  InterfaceType rawType(Class klass, Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return legacyRawType(klass);
      case Nullability.nullable:
        return nullableRawType(klass);
      case Nullability.nonNullable:
        return nonNullableRawType(klass);
      case Nullability.neither:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }
}
