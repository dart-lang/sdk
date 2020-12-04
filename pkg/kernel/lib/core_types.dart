// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.core_types;

import 'package:kernel/type_algebra.dart';

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
      'LateInitializationErrorImpl',
      'ReachabilityError',
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
  Class _deprecatedNullClass;
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
  Procedure _listDefaultConstructor;
  Procedure _listFromConstructor;
  Procedure _listUnmodifiableConstructor;
  Procedure _identicalProcedure;
  Constructor _fallThroughErrorUrlAndLineConstructor;
  Procedure _objectEquals;
  Procedure _mapUnmodifiable;
  Procedure _iterableGetIterator;
  Procedure _iteratorMoveNext;
  Procedure _iteratorGetCurrent;
  Procedure _isSentinelMethod;
  Procedure _createSentinelMethod;

  Class _internalSymbolClass;

  Library _asyncLibrary;
  Class _futureClass;
  Class _deprecatedFutureOrClass;
  Class _stackTraceClass;
  Class _streamClass;
  Class _futureImplClass;
  Constructor _futureImplConstructor;
  Procedure _completeOnAsyncErrorProcedure;
  Procedure _completeOnAsyncReturnProcedure;
  Constructor _syncIterableDefaultConstructor;
  Constructor _streamIteratorDefaultConstructor;
  Constructor _asyncStarStreamControllerDefaultConstructor;
  Procedure _asyncStarMoveNextHelperProcedure;
  Procedure _asyncThenWrapperHelperProcedure;
  Procedure _asyncErrorWrapperHelperProcedure;
  Procedure _awaitHelperProcedure;
  Procedure _boolFromEnvironment;
  Constructor _lateInitializationFieldAssignedDuringInitializationConstructor;
  Constructor _lateInitializationLocalAssignedDuringInitializationConstructor;
  Constructor _lateInitializationFieldNotInitializedConstructor;
  Constructor _lateInitializationLocalNotInitializedConstructor;
  Constructor _lateInitializationFieldAlreadyInitializedConstructor;
  Constructor _lateInitializationLocalAlreadyInitializedConstructor;
  Constructor _reachabilityErrorConstructor;

  /// The `dart:mirrors` library, or `null` if the component does not use it.
  Library _mirrorsLibrary;

  Class _pragmaClass;
  Field _pragmaName;
  Field _pragmaOptions;
  Constructor _pragmaConstructor;

  InterfaceType _objectLegacyRawType;
  InterfaceType _objectNullableRawType;
  InterfaceType _objectNonNullableRawType;
  InterfaceType _deprecatedNullType;
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
  InterfaceType _pragmaLegacyRawType;
  InterfaceType _pragmaNullableRawType;
  InterfaceType _pragmaNonNullableRawType;
  final Map<Class, InterfaceType> _legacyRawTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<Class, InterfaceType> _nullableRawTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<Class, InterfaceType> _nonNullableRawTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<Class, InterfaceType> _thisInterfaceTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<Typedef, TypedefType> _thisTypedefTypes =
      new Map<Typedef, TypedefType>.identity();
  final Map<Class, InterfaceType> _bottomInterfaceTypes =
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

  Procedure get asyncStarMoveNextHelper {
    return _asyncStarMoveNextHelperProcedure ??=
        index.getTopLevelMember('dart:async', '_asyncStarMoveNextHelper');
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

  Class get futureImplClass {
    return _futureImplClass ??= index.getClass('dart:async', '_Future');
  }

  Constructor get futureImplConstructor {
    return _futureImplConstructor ??=
        index.getMember('dart:async', '_Future', '');
  }

  Member get completeOnAsyncReturn {
    return _completeOnAsyncReturnProcedure ??=
        index.getTopLevelMember('dart:async', '_completeOnAsyncReturn');
  }

  Member get completeOnAsyncError {
    return _completeOnAsyncErrorProcedure ??=
        index.getTopLevelMember('dart:async', '_completeOnAsyncError');
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

  // TODO(dmitryas): Remove it when FutureOrType is fully supported.
  Class get deprecatedFutureOrClass {
    return _deprecatedFutureOrClass ??=
        index.getClass('dart:async', 'FutureOr');
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

  Procedure get iterableGetIterator {
    return _iterableGetIterator ??=
        index.getMember('dart:core', 'Iterable', 'get:iterator');
  }

  Class get iteratorClass {
    return _iteratorClass ??= index.getClass('dart:core', 'Iterator');
  }

  Procedure get iteratorMoveNext {
    return _iteratorMoveNext ??=
        index.getMember('dart:core', 'Iterator', 'moveNext');
  }

  Procedure get iteratorGetCurrent {
    return _iteratorGetCurrent ??=
        index.getMember('dart:core', 'Iterator', 'get:current');
  }

  Class get listClass {
    return _listClass ??= index.getClass('dart:core', 'List');
  }

  Procedure get listDefaultConstructor {
    return _listDefaultConstructor ??= index.getMember('dart:core', 'List', '');
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

  Class get deprecatedNullClass {
    return _deprecatedNullClass ??= index.getClass('dart:core', 'Null');
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

  Procedure get createSentinelMethod {
    return _createSentinelMethod ??=
        index.getTopLevelMember('dart:_internal', 'createSentinel');
  }

  Procedure get isSentinelMethod {
    return _isSentinelMethod ??=
        index.getTopLevelMember('dart:_internal', 'isSentinel');
  }

  InterfaceType get objectLegacyRawType {
    return _objectLegacyRawType ??= _legacyRawTypes[objectClass] ??=
        new InterfaceType(objectClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get objectNullableRawType {
    return _objectNullableRawType ??= _nullableRawTypes[objectClass] ??=
        new InterfaceType(
            objectClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get objectNonNullableRawType {
    return _objectNonNullableRawType ??= _nonNullableRawTypes[objectClass] ??=
        new InterfaceType(
            objectClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType objectRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return objectLegacyRawType;
      case Nullability.nullable:
        return objectNullableRawType;
      case Nullability.nonNullable:
        return objectNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  /// Null is always nullable, so there's only one raw type for that class.
  InterfaceType get deprecatedNullType {
    return _deprecatedNullType ??= _nullableRawTypes[deprecatedNullClass] ??=
        new InterfaceType(
            deprecatedNullClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get boolLegacyRawType {
    return _boolLegacyRawType ??= _legacyRawTypes[boolClass] ??=
        new InterfaceType(boolClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get boolNullableRawType {
    return _boolNullableRawType ??= _nullableRawTypes[boolClass] ??=
        new InterfaceType(boolClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get boolNonNullableRawType {
    return _boolNonNullableRawType ??= _nonNullableRawTypes[boolClass] ??=
        new InterfaceType(
            boolClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType boolRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return boolLegacyRawType;
      case Nullability.nullable:
        return boolNullableRawType;
      case Nullability.nonNullable:
        return boolNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get intLegacyRawType {
    return _intLegacyRawType ??= _legacyRawTypes[intClass] ??=
        new InterfaceType(intClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get intNullableRawType {
    return _intNullableRawType ??= _nullableRawTypes[intClass] ??=
        new InterfaceType(intClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get intNonNullableRawType {
    return _intNonNullableRawType ??= _nonNullableRawTypes[intClass] ??=
        new InterfaceType(
            intClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType intRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return intLegacyRawType;
      case Nullability.nullable:
        return intNullableRawType;
      case Nullability.nonNullable:
        return intNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get numLegacyRawType {
    return _numLegacyRawType ??= _legacyRawTypes[numClass] ??=
        new InterfaceType(numClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get numNullableRawType {
    return _numNullableRawType ??= _nullableRawTypes[numClass] ??=
        new InterfaceType(numClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get numNonNullableRawType {
    return _numNonNullableRawType ??= _nonNullableRawTypes[numClass] ??=
        new InterfaceType(
            numClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType numRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return numLegacyRawType;
      case Nullability.nullable:
        return numNullableRawType;
      case Nullability.nonNullable:
        return numNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get doubleLegacyRawType {
    return _doubleLegacyRawType ??= _legacyRawTypes[doubleClass] ??=
        new InterfaceType(doubleClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get doubleNullableRawType {
    return _doubleNullableRawType ??= _nullableRawTypes[doubleClass] ??=
        new InterfaceType(
            doubleClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get doubleNonNullableRawType {
    return _doubleNonNullableRawType ??= _nonNullableRawTypes[doubleClass] ??=
        new InterfaceType(
            doubleClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType doubleRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return doubleLegacyRawType;
      case Nullability.nullable:
        return doubleNullableRawType;
      case Nullability.nonNullable:
        return doubleNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get stringLegacyRawType {
    return _stringLegacyRawType ??= _legacyRawTypes[stringClass] ??=
        new InterfaceType(stringClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get stringNullableRawType {
    return _stringNullableRawType ??= _nullableRawTypes[stringClass] ??=
        new InterfaceType(
            stringClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get stringNonNullableRawType {
    return _stringNonNullableRawType ??= _nonNullableRawTypes[stringClass] ??=
        new InterfaceType(
            stringClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType stringRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return stringLegacyRawType;
      case Nullability.nullable:
        return stringNullableRawType;
      case Nullability.nonNullable:
        return stringNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get listLegacyRawType {
    return _listLegacyRawType ??= _legacyRawTypes[listClass] ??=
        new InterfaceType(listClass, Nullability.legacy,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get listNullableRawType {
    return _listNullableRawType ??= _nullableRawTypes[listClass] ??=
        new InterfaceType(listClass, Nullability.nullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get listNonNullableRawType {
    return _listNonNullableRawType ??= _nonNullableRawTypes[listClass] ??=
        new InterfaceType(listClass, Nullability.nonNullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType listRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return listLegacyRawType;
      case Nullability.nullable:
        return listNullableRawType;
      case Nullability.nonNullable:
        return listNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get setLegacyRawType {
    return _setLegacyRawType ??= _legacyRawTypes[setClass] ??=
        new InterfaceType(setClass, Nullability.legacy,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get setNullableRawType {
    return _setNullableRawType ??= _nullableRawTypes[setClass] ??=
        new InterfaceType(setClass, Nullability.nullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get setNonNullableRawType {
    return _setNonNullableRawType ??= _nonNullableRawTypes[setClass] ??=
        new InterfaceType(setClass, Nullability.nonNullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType setRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return setLegacyRawType;
      case Nullability.nullable:
        return setNullableRawType;
      case Nullability.nonNullable:
        return setNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get mapLegacyRawType {
    return _mapLegacyRawType ??= _legacyRawTypes[mapClass] ??=
        new InterfaceType(mapClass, Nullability.legacy,
            const <DartType>[const DynamicType(), const DynamicType()]);
  }

  InterfaceType get mapNullableRawType {
    return _mapNullableRawType ??= _nullableRawTypes[mapClass] ??=
        new InterfaceType(mapClass, Nullability.nullable,
            const <DartType>[const DynamicType(), const DynamicType()]);
  }

  InterfaceType get mapNonNullableRawType {
    return _mapNonNullableRawType ??= _nonNullableRawTypes[mapClass] ??=
        new InterfaceType(mapClass, Nullability.nonNullable,
            const <DartType>[const DynamicType(), const DynamicType()]);
  }

  InterfaceType mapRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return mapLegacyRawType;
      case Nullability.nullable:
        return mapNullableRawType;
      case Nullability.nonNullable:
        return mapNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get iterableLegacyRawType {
    return _iterableLegacyRawType ??= _legacyRawTypes[iterableClass] ??=
        new InterfaceType(iterableClass, Nullability.legacy,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get iterableNullableRawType {
    return _iterableNullableRawType ??= _nullableRawTypes[iterableClass] ??=
        new InterfaceType(iterableClass, Nullability.nullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get iterableNonNullableRawType {
    return _iterableNonNullableRawType ??=
        _nonNullableRawTypes[iterableClass] ??= new InterfaceType(iterableClass,
            Nullability.nonNullable, const <DartType>[const DynamicType()]);
  }

  InterfaceType iterableRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return iterableLegacyRawType;
      case Nullability.nullable:
        return iterableNullableRawType;
      case Nullability.nonNullable:
        return iterableNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get iteratorLegacyRawType {
    return _iteratorLegacyRawType ??= _legacyRawTypes[iteratorClass] ??=
        new InterfaceType(iteratorClass, Nullability.legacy,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get iteratorNullableRawType {
    return _iteratorNullableRawType ??= _nullableRawTypes[iteratorClass] ??=
        new InterfaceType(iteratorClass, Nullability.nullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get iteratorNonNullableRawType {
    return _iteratorNonNullableRawType ??=
        _nonNullableRawTypes[iteratorClass] ??= new InterfaceType(iteratorClass,
            Nullability.nonNullable, const <DartType>[const DynamicType()]);
  }

  InterfaceType iteratorRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return iteratorLegacyRawType;
      case Nullability.nullable:
        return iteratorNullableRawType;
      case Nullability.nonNullable:
        return iteratorNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get symbolLegacyRawType {
    return _symbolLegacyRawType ??= _legacyRawTypes[symbolClass] ??=
        new InterfaceType(symbolClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get symbolNullableRawType {
    return _symbolNullableRawType ??= _nullableRawTypes[symbolClass] ??=
        new InterfaceType(
            symbolClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get symbolNonNullableRawType {
    return _symbolNonNullableRawType ??= _nonNullableRawTypes[symbolClass] ??=
        new InterfaceType(
            symbolClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType symbolRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return symbolLegacyRawType;
      case Nullability.nullable:
        return symbolNullableRawType;
      case Nullability.nonNullable:
        return symbolNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get typeLegacyRawType {
    return _typeLegacyRawType ??= _legacyRawTypes[typeClass] ??=
        new InterfaceType(typeClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get typeNullableRawType {
    return _typeNullableRawType ??= _nullableRawTypes[typeClass] ??=
        new InterfaceType(typeClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get typeNonNullableRawType {
    return _typeNonNullableRawType ??= _nonNullableRawTypes[typeClass] ??=
        new InterfaceType(
            typeClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType typeRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return typeLegacyRawType;
      case Nullability.nullable:
        return typeNullableRawType;
      case Nullability.nonNullable:
        return typeNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get functionLegacyRawType {
    return _functionLegacyRawType ??= _legacyRawTypes[functionClass] ??=
        new InterfaceType(
            functionClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get functionNullableRawType {
    return _functionNullableRawType ??= _nullableRawTypes[functionClass] ??=
        new InterfaceType(
            functionClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get functionNonNullableRawType {
    return _functionNonNullableRawType ??=
        _nonNullableRawTypes[functionClass] ??= new InterfaceType(
            functionClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType functionRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return functionLegacyRawType;
      case Nullability.nullable:
        return functionNullableRawType;
      case Nullability.nonNullable:
        return functionNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get invocationLegacyRawType {
    return _invocationLegacyRawType ??= _legacyRawTypes[invocationClass] ??=
        new InterfaceType(
            invocationClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get invocationNullableRawType {
    return _invocationNullableRawType ??= _nullableRawTypes[invocationClass] ??=
        new InterfaceType(
            invocationClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get invocationNonNullableRawType {
    return _invocationNonNullableRawType ??=
        _nonNullableRawTypes[invocationClass] ??= new InterfaceType(
            invocationClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType invocationRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return invocationLegacyRawType;
      case Nullability.nullable:
        return invocationNullableRawType;
      case Nullability.nonNullable:
        return invocationNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get invocationMirrorLegacyRawType {
    return _invocationMirrorLegacyRawType ??=
        _legacyRawTypes[invocationMirrorClass] ??= new InterfaceType(
            invocationMirrorClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get invocationMirrorNullableRawType {
    return _invocationMirrorNullableRawType ??=
        _nullableRawTypes[invocationMirrorClass] ??= new InterfaceType(
            invocationMirrorClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get invocationMirrorNonNullableRawType {
    return _invocationMirrorNonNullableRawType ??=
        _nonNullableRawTypes[invocationMirrorClass] ??= new InterfaceType(
            invocationMirrorClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType invocationMirrorRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return invocationMirrorLegacyRawType;
      case Nullability.nullable:
        return invocationMirrorNullableRawType;
      case Nullability.nonNullable:
        return invocationMirrorNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get futureLegacyRawType {
    return _futureLegacyRawType ??= _legacyRawTypes[futureClass] ??=
        new InterfaceType(futureClass, Nullability.legacy,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get futureNullableRawType {
    return _futureNullableRawType ??= _nullableRawTypes[futureClass] ??=
        new InterfaceType(futureClass, Nullability.nullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get futureNonNullableRawType {
    return _futureNonNullableRawType ??= _nonNullableRawTypes[futureClass] ??=
        new InterfaceType(futureClass, Nullability.nonNullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType futureRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return futureLegacyRawType;
      case Nullability.nullable:
        return futureNullableRawType;
      case Nullability.nonNullable:
        return futureNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get stackTraceLegacyRawType {
    return _stackTraceLegacyRawType ??= _legacyRawTypes[stackTraceClass] ??=
        new InterfaceType(
            stackTraceClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get stackTraceNullableRawType {
    return _stackTraceNullableRawType ??= _nullableRawTypes[stackTraceClass] ??=
        new InterfaceType(
            stackTraceClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get stackTraceNonNullableRawType {
    return _stackTraceNonNullableRawType ??=
        _nonNullableRawTypes[stackTraceClass] ??= new InterfaceType(
            stackTraceClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType stackTraceRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return stackTraceLegacyRawType;
      case Nullability.nullable:
        return stackTraceNullableRawType;
      case Nullability.nonNullable:
        return stackTraceNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get streamLegacyRawType {
    return _streamLegacyRawType ??= _legacyRawTypes[streamClass] ??=
        new InterfaceType(streamClass, Nullability.legacy,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get streamNullableRawType {
    return _streamNullableRawType ??= _nullableRawTypes[streamClass] ??=
        new InterfaceType(streamClass, Nullability.nullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType get streamNonNullableRawType {
    return _streamNonNullableRawType ??= _nonNullableRawTypes[streamClass] ??=
        new InterfaceType(streamClass, Nullability.nonNullable,
            const <DartType>[const DynamicType()]);
  }

  InterfaceType streamRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return streamLegacyRawType;
      case Nullability.nullable:
        return streamNullableRawType;
      case Nullability.nonNullable:
        return streamNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType get pragmaLegacyRawType {
    return _pragmaLegacyRawType ??= _legacyRawTypes[pragmaClass] ??=
        new InterfaceType(pragmaClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get pragmaNullableRawType {
    return _pragmaNullableRawType ??= _nullableRawTypes[pragmaClass] ??=
        new InterfaceType(
            pragmaClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get pragmaNonNullableRawType {
    return _pragmaNonNullableRawType ??= _nonNullableRawTypes[pragmaClass] ??=
        new InterfaceType(
            pragmaClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType pragmaRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return pragmaLegacyRawType;
      case Nullability.nullable:
        return pragmaNullableRawType;
      case Nullability.nonNullable:
        return pragmaNonNullableRawType;
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType legacyRawType(Class klass) {
    // TODO(dmitryas): Consider using computeBounds instead of DynamicType here.
    return _legacyRawTypes[klass] ??= new InterfaceType(
        klass,
        Nullability.legacy,
        new List<DartType>.filled(
            klass.typeParameters.length, const DynamicType()));
  }

  InterfaceType nullableRawType(Class klass) {
    // TODO(dmitryas): Consider using computeBounds instead of DynamicType here.
    return _nullableRawTypes[klass] ??= new InterfaceType(
        klass,
        Nullability.nullable,
        new List<DartType>.filled(
            klass.typeParameters.length, const DynamicType()));
  }

  InterfaceType nonNullableRawType(Class klass) {
    // TODO(dmitryas): Consider using computeBounds instead of DynamicType here.
    return _nonNullableRawTypes[klass] ??= new InterfaceType(
        klass,
        Nullability.nonNullable,
        new List<DartType>.filled(
            klass.typeParameters.length, const DynamicType()));
  }

  InterfaceType rawType(Class klass, Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return legacyRawType(klass);
      case Nullability.nullable:
        return nullableRawType(klass);
      case Nullability.nonNullable:
        return nonNullableRawType(klass);
      case Nullability.undetermined:
      default:
        throw new StateError(
            "Unsupported nullability $nullability on an InterfaceType.");
    }
  }

  InterfaceType thisInterfaceType(Class klass, Nullability nullability) {
    InterfaceType result = _thisInterfaceTypes[klass];
    if (result == null) {
      return _thisInterfaceTypes[klass] = new InterfaceType(klass, nullability,
          getAsTypeArguments(klass.typeParameters, klass.enclosingLibrary));
    }
    if (result.nullability != nullability) {
      return _thisInterfaceTypes[klass] =
          result.withDeclaredNullability(nullability);
    }
    return result;
  }

  TypedefType thisTypedefType(Typedef typedef, Nullability nullability) {
    TypedefType result = _thisTypedefTypes[typedef];
    if (result == null) {
      return _thisTypedefTypes[typedef] = new TypedefType(typedef, nullability,
          getAsTypeArguments(typedef.typeParameters, typedef.enclosingLibrary));
    }
    if (result.nullability != nullability) {
      return _thisTypedefTypes[typedef] =
          result.withDeclaredNullability(nullability);
    }
    return result;
  }

  Constructor
      get lateInitializationFieldAssignedDuringInitializationConstructor {
    return _lateInitializationFieldAssignedDuringInitializationConstructor ??=
        index.getMember('dart:_internal', 'LateError', 'fieldADI');
  }

  Constructor
      get lateInitializationLocalAssignedDuringInitializationConstructor {
    return _lateInitializationLocalAssignedDuringInitializationConstructor ??=
        index.getMember('dart:_internal', 'LateError', 'localADI');
  }

  Constructor get lateInitializationFieldNotInitializedConstructor {
    return _lateInitializationFieldNotInitializedConstructor ??=
        index.getMember('dart:_internal', 'LateError', 'fieldNI');
  }

  Constructor get lateInitializationLocalNotInitializedConstructor {
    return _lateInitializationLocalNotInitializedConstructor ??=
        index.getMember('dart:_internal', 'LateError', 'localNI');
  }

  Constructor get lateInitializationFieldAlreadyInitializedConstructor {
    return _lateInitializationFieldAlreadyInitializedConstructor ??=
        index.getMember('dart:_internal', 'LateError', 'fieldAI');
  }

  Constructor get lateInitializationLocalAlreadyInitializedConstructor {
    return _lateInitializationLocalAlreadyInitializedConstructor ??=
        index.getMember('dart:_internal', 'LateError', 'localAI');
  }

  Constructor get reachabilityErrorConstructor {
    return _reachabilityErrorConstructor ??=
        index.getMember('dart:_internal', 'ReachabilityError', '');
  }

  InterfaceType bottomInterfaceType(Class klass, Nullability nullability) {
    InterfaceType result = _bottomInterfaceTypes[klass];
    if (result == null) {
      return _bottomInterfaceTypes[klass] = new InterfaceType(
          klass,
          nullability,
          new List<DartType>.filled(
              klass.typeParameters.length, const BottomType()));
    }
    if (result.nullability != nullability) {
      return _bottomInterfaceTypes[klass] =
          result.withDeclaredNullability(nullability);
    }
    return result;
  }

  /// Checks if [type] satisfies the TOP predicate.
  ///
  /// For the definition of TOP see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  bool isTop(DartType type) {
    if (type is InvalidType) return false;

    // TOP(dynamic) is true.
    if (type is DynamicType) return true;

    // TOP(void) is true.
    if (type is VoidType) return true;

    // TOP(T?) is true iff TOP(T) or OBJECT(T).
    // TOP(T*) is true iff TOP(T) or OBJECT(T).
    if (type.declaredNullability == Nullability.nullable ||
        type.declaredNullability == Nullability.legacy) {
      DartType nonNullableType = unwrapNullabilityConstructor(type, this);
      if (!identical(type, nonNullableType)) {
        return isTop(nonNullableType) || isObject(nonNullableType);
      }
    }

    // TOP(FutureOr<T>) is TOP(T).
    if (type is FutureOrType) {
      return isTop(type.typeArgument);
    }

    return false;
  }

  /// Checks if [type] satisfies the OBJECT predicate.
  ///
  /// For the definition of OBJECT see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  bool isObject(DartType type) {
    if (type is InvalidType) return false;

    // OBJECT(Object) is true.
    if (type is InterfaceType &&
        type.classNode == objectClass &&
        type.nullability == Nullability.nonNullable) {
      return true;
    }

    // OBJECT(FutureOr<T>) is OBJECT(T).
    if (type is FutureOrType && type.nullability == Nullability.nonNullable) {
      return isObject(type.typeArgument);
    }

    return false;
  }

  /// Checks if [type] satisfies the BOTTOM predicate.
  ///
  /// For the definition of BOTTOM see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  bool isBottom(DartType type) {
    if (type is InvalidType) return false;

    // BOTTOM(Never) is true.
    if (type is NeverType && type.nullability == Nullability.nonNullable) {
      return true;
    }

    // BOTTOM(X&T) is true iff BOTTOM(T).
    if (type is TypeParameterType &&
        type.promotedBound != null &&
        type.isPotentiallyNonNullable) {
      return isBottom(type.promotedBound);
    }

    // BOTTOM(X extends T) is true iff BOTTOM(T).
    if (type is TypeParameterType && type.isPotentiallyNonNullable) {
      assert(type.promotedBound == null);
      return isBottom(type.parameter.bound);
    }

    if (type is BottomType) return true;

    return false;
  }

  /// Checks if [type] satisfies the NULL predicate.
  ///
  /// For the definition of NULL see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  bool isNull(DartType type) {
    if (type is InvalidType) return false;

    // NULL(Null) is true.
    if (type is NullType) return true;

    // NULL(T?) is true iff NULL(T) or BOTTOM(T).
    // NULL(T*) is true iff NULL(T) or BOTTOM(T).
    if (type.nullability == Nullability.nullable ||
        type.nullability == Nullability.legacy) {
      DartType nonNullableType =
          type.withDeclaredNullability(Nullability.nonNullable);
      return isBottom(nonNullableType);
    }

    return false;
  }
}
