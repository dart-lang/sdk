// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.core_types;

import 'ast.dart';
import 'library_index.dart';
import 'type_algebra.dart';

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
      'Record',
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

  InterfaceType? _objectLegacyRawType;
  InterfaceType? _objectNullableRawType;
  InterfaceType? _objectNonNullableRawType;
  InterfaceType? _deprecatedNullType;
  InterfaceType? _boolLegacyRawType;
  InterfaceType? _boolNullableRawType;
  InterfaceType? _boolNonNullableRawType;
  InterfaceType? _intLegacyRawType;
  InterfaceType? _intNullableRawType;
  InterfaceType? _intNonNullableRawType;
  InterfaceType? _numLegacyRawType;
  InterfaceType? _numNullableRawType;
  InterfaceType? _numNonNullableRawType;
  InterfaceType? _doubleLegacyRawType;
  InterfaceType? _doubleNullableRawType;
  InterfaceType? _doubleNonNullableRawType;
  InterfaceType? _stringLegacyRawType;
  InterfaceType? _stringNullableRawType;
  InterfaceType? _stringNonNullableRawType;
  InterfaceType? _listLegacyRawType;
  InterfaceType? _listNullableRawType;
  InterfaceType? _listNonNullableRawType;
  InterfaceType? _setLegacyRawType;
  InterfaceType? _setNullableRawType;
  InterfaceType? _setNonNullableRawType;
  InterfaceType? _mapLegacyRawType;
  InterfaceType? _mapNullableRawType;
  InterfaceType? _mapNonNullableRawType;
  InterfaceType? _iterableLegacyRawType;
  InterfaceType? _iterableNullableRawType;
  InterfaceType? _iterableNonNullableRawType;
  InterfaceType? _iteratorLegacyRawType;
  InterfaceType? _iteratorNullableRawType;
  InterfaceType? _iteratorNonNullableRawType;
  InterfaceType? _symbolLegacyRawType;
  InterfaceType? _symbolNullableRawType;
  InterfaceType? _symbolNonNullableRawType;
  InterfaceType? _typeLegacyRawType;
  InterfaceType? _typeNullableRawType;
  InterfaceType? _typeNonNullableRawType;
  InterfaceType? _functionLegacyRawType;
  InterfaceType? _functionNullableRawType;
  InterfaceType? _functionNonNullableRawType;
  InterfaceType? _recordLegacyRawType;
  InterfaceType? _recordNullableRawType;
  InterfaceType? _recordNonNullableRawType;
  InterfaceType? _invocationLegacyRawType;
  InterfaceType? _invocationNullableRawType;
  InterfaceType? _invocationNonNullableRawType;
  InterfaceType? _invocationMirrorLegacyRawType;
  InterfaceType? _invocationMirrorNullableRawType;
  InterfaceType? _invocationMirrorNonNullableRawType;
  InterfaceType? _futureLegacyRawType;
  InterfaceType? _futureNullableRawType;
  InterfaceType? _futureNonNullableRawType;
  InterfaceType? _stackTraceLegacyRawType;
  InterfaceType? _stackTraceNullableRawType;
  InterfaceType? _stackTraceNonNullableRawType;
  InterfaceType? _streamLegacyRawType;
  InterfaceType? _streamNullableRawType;
  InterfaceType? _streamNonNullableRawType;
  InterfaceType? _pragmaLegacyRawType;
  InterfaceType? _pragmaNullableRawType;
  InterfaceType? _pragmaNonNullableRawType;
  final Map<Class, InterfaceType> _legacyRawTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<Class, InterfaceType> _nullableRawTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<Class, InterfaceType> _nonNullableRawTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<Class, InterfaceType> _thisInterfaceTypes =
      new Map<Class, InterfaceType>.identity();
  final Map<ExtensionTypeDeclaration, ExtensionType> _thisExtensionTypes =
      new Map<ExtensionTypeDeclaration, ExtensionType>.identity();
  final Map<Typedef, TypedefType> _thisTypedefTypes =
      new Map<Typedef, TypedefType>.identity();
  final Map<Class, InterfaceType> _bottomInterfaceTypes =
      new Map<Class, InterfaceType>.identity();

  CoreTypes(Component component)
      : index = new LibraryIndex.coreLibraries(component);

  late final Library asyncLibrary = index.getLibrary('dart:async');

  late final Procedure asyncStarMoveNextHelper =
      index.getTopLevelProcedure('dart:async', '_asyncStarMoveNextHelper');

  late final Class boolClass = index.getClass('dart:core', 'bool');

  late final Class futureImplClass = index.getClass('dart:async', '_Future');

  late final Library coreLibrary = index.getLibrary('dart:core');

  late final Class doubleClass = index.getClass('dart:core', 'double');

  late final Class functionClass = index.getClass('dart:core', 'Function');

  late final Class recordClass = index.getClass('dart:core', 'Record');

  late final Class futureClass = index.getClass('dart:core', 'Future');

  late final Procedure futureSyncFactory =
      index.getMember('dart:async', 'Future', 'sync') as Procedure;

  late final Procedure futureValueFactory =
      index.getMember('dart:async', 'Future', 'value') as Procedure;

  // TODO(cstefantsova): Remove it when FutureOrType is fully supported.
  late final Class deprecatedFutureOrClass =
      index.getClass('dart:async', 'FutureOr');

  late final Procedure identicalProcedure =
      index.getTopLevelProcedure('dart:core', 'identical');

  late final Procedure printProcedure =
      index.getTopLevelProcedure('dart:core', 'print');

  late final Class intClass = index.getClass('dart:core', 'int');

  late final Class internalSymbolClass =
      index.getClass('dart:_internal', 'Symbol');

  late final Class invocationClass = index.getClass('dart:core', 'Invocation');

  late final Class invocationMirrorClass =
      index.getClass('dart:core', '_InvocationMirror');

  late final Constructor invocationMirrorWithTypeConstructor =
      index.getConstructor('dart:core', '_InvocationMirror', '_withType');

  late final Class iterableClass = index.getClass('dart:core', 'Iterable');

  late final Procedure iterableGetIterator =
      index.getProcedure('dart:core', 'Iterable', 'get:iterator');

  late final Class iteratorClass = index.getClass('dart:core', 'Iterator');

  late final Procedure iteratorMoveNext =
      index.getProcedure('dart:core', 'Iterator', 'moveNext');

  late final Procedure iteratorGetCurrent =
      index.getProcedure('dart:core', 'Iterator', 'get:current');

  late final Class listClass = index.getClass('dart:core', 'List');

  late final Procedure listFromConstructor =
      index.getProcedure('dart:core', 'List', 'from');

  late final Procedure listUnmodifiableConstructor =
      index.getProcedure('dart:core', 'List', 'unmodifiable');

  late final Class setClass = index.getClass('dart:core', 'Set');

  late final Class mapClass = index.getClass('dart:core', 'Map');

  late final Procedure mapUnmodifiable =
      index.getProcedure('dart:core', 'Map', 'unmodifiable');

  /// The `dart:mirrors` library, or `null` if the component does not use it.
  late final Library? mirrorsLibrary = index.tryGetLibrary('dart:mirrors');

  late final Procedure noSuchMethodErrorDefaultConstructor =
      // TODO(regis): Replace 'withInvocation' with '' after dart2js is fixed.
      index.getProcedure('dart:core', 'NoSuchMethodError', 'withInvocation');

  late final Class deprecatedNullClass = index.getClass('dart:core', 'Null');

  late final Class numClass = index.getClass('dart:core', 'num');

  late final Class objectClass = index.getClass('dart:core', 'Object');

  late final Procedure objectEquals =
      index.getProcedure('dart:core', 'Object', '==');

  late final Class? platformClass = index.tryGetClass('dart:io', 'Platform');

  late final Class pragmaClass = index.getClass('dart:core', 'pragma');

  late final Field pragmaName = index.getField('dart:core', 'pragma', 'name');

  late final Field pragmaOptions =
      index.getField('dart:core', 'pragma', 'options');

  late final Constructor pragmaConstructor =
      index.getConstructor('dart:core', 'pragma', '_');

  late final Class stackTraceClass = index.getClass('dart:core', 'StackTrace');

  late final Class streamClass = index.getClass('dart:core', 'Stream');

  late final Member streamIteratorSubscription =
      index.getMember('dart:async', '_StreamIterator', '_subscription');

  late final Procedure streamIteratorCancel =
      index.getProcedure('dart:async', '_StreamIterator', 'cancel');

  late final Class streamIteratorClass =
      index.getClass('dart:async', '_StreamIterator');

  late final Constructor streamIteratorDefaultConstructor =
      index.getConstructor('dart:async', '_StreamIterator', '');

  late final Procedure streamIteratorMoveNext =
      index.getProcedure('dart:async', '_StreamIterator', 'moveNext');

  late final Member streamIteratorCurrent =
      index.getMember('dart:async', '_StreamIterator', 'get:current');

  late final Class stringClass = index.getClass('dart:core', 'String');

  late final Class symbolClass = index.getClass('dart:core', 'Symbol');

  late final Class typeClass = index.getClass('dart:core', 'Type');

  late final Procedure boolFromEnvironment =
      index.getProcedure('dart:core', 'bool', 'fromEnvironment');

  late final Procedure intUnaryMinus =
      index.getProcedure('dart:core', 'int', 'unary-');

  late final Procedure createSentinelMethod =
      index.getTopLevelProcedure('dart:_internal', 'createSentinel');

  late final Procedure isSentinelMethod =
      index.getTopLevelProcedure('dart:_internal', 'isSentinel');

  late final Constructor
      lateInitializationFieldAssignedDuringInitializationConstructor =
      index.getConstructor('dart:_internal', 'LateError', 'fieldADI');

  late final Constructor
      lateInitializationLocalAssignedDuringInitializationConstructor =
      index.getConstructor('dart:_internal', 'LateError', 'localADI');

  late final Constructor lateInitializationFieldNotInitializedConstructor =
      index.getConstructor('dart:_internal', 'LateError', 'fieldNI');

  late final Constructor lateInitializationLocalNotInitializedConstructor =
      index.getConstructor('dart:_internal', 'LateError', 'localNI');

  late final Constructor lateInitializationFieldAlreadyInitializedConstructor =
      index.getConstructor('dart:_internal', 'LateError', 'fieldAI');

  late final Constructor lateInitializationLocalAlreadyInitializedConstructor =
      index.getConstructor('dart:_internal', 'LateError', 'localAI');

  late final Constructor reachabilityErrorConstructor =
      index.getConstructor('dart:_internal', 'ReachabilityError', '');

  late final Constructor stateErrorConstructor =
      index.getConstructor('dart:core', 'StateError', '');

  late final Class cellClass = index.getClass('dart:_late_helper', '_Cell');

  late final Constructor cellConstructor =
      index.getMember('dart:_late_helper', '_Cell', '') as Constructor;

  late final Constructor cellNamedConstructor =
      index.getMember('dart:_late_helper', '_Cell', 'named') as Constructor;

  late final Class initializedCellClass =
      index.getClass('dart:_late_helper', '_InitializedCell');

  late final Constructor initializedCellConstructor = index.getMember(
      'dart:_late_helper', '_InitializedCell', '') as Constructor;

  late final Constructor initializedCellNamedConstructor = index.getMember(
      'dart:_late_helper', '_InitializedCell', 'named') as Constructor;

  late final Procedure cellReadLocal =
      index.getMember('dart:_late_helper', '_Cell', 'readLocal') as Procedure;

  late final Procedure cellReadField =
      index.getMember('dart:_late_helper', '_Cell', 'readField') as Procedure;

  late final Procedure initializedCellRead = index.getMember(
      'dart:_late_helper', '_InitializedCell', 'read') as Procedure;

  late final Procedure initializedCellReadFinal = index.getMember(
      'dart:_late_helper', '_InitializedCell', 'readFinal') as Procedure;

  late final Procedure cellValueSetter =
      index.getMember('dart:_late_helper', '_Cell', 'set:value') as Procedure;

  late final Procedure cellFinalLocalValueSetter = index.getMember(
      'dart:_late_helper', '_Cell', 'set:finalLocalValue') as Procedure;

  late final Procedure cellFinalFieldValueSetter = index.getMember(
      'dart:_late_helper', '_Cell', 'set:finalFieldValue') as Procedure;

  late final Procedure initializedCellValueSetter = index.getMember(
      'dart:_late_helper', '_InitializedCell', 'set:value') as Procedure;

  late final Procedure initializedCellFinalValueSetter = index.getMember(
      'dart:_late_helper', '_InitializedCell', 'set:finalValue') as Procedure;

  late final Procedure lateReadCheck =
      index.getTopLevelProcedure('dart:_late_helper', '_lateReadCheck');

  late final Procedure lateWriteOnceCheck =
      index.getTopLevelProcedure('dart:_late_helper', '_lateWriteOnceCheck');

  late final Procedure lateInitializeOnceCheck = index.getTopLevelProcedure(
      'dart:_late_helper', '_lateInitializeOnceCheck');

  late final Field enumNameField =
      index.getField('dart:core', '_Enum', '_name');

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

  InterfaceType get recordLegacyRawType {
    return _recordLegacyRawType ??= _legacyRawTypes[recordClass] ??=
        new InterfaceType(recordClass, Nullability.legacy, const <DartType>[]);
  }

  InterfaceType get recordNullableRawType {
    return _recordNullableRawType ??= _nullableRawTypes[recordClass] ??=
        new InterfaceType(
            recordClass, Nullability.nullable, const <DartType>[]);
  }

  InterfaceType get recordNonNullableRawType {
    return _recordNonNullableRawType ??= _nonNullableRawTypes[recordClass] ??=
        new InterfaceType(
            recordClass, Nullability.nonNullable, const <DartType>[]);
  }

  InterfaceType recordRawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return recordLegacyRawType;
      case Nullability.nullable:
        return recordNullableRawType;
      case Nullability.nonNullable:
        return recordNonNullableRawType;
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
    // TODO(cstefantsova): Consider using computeBounds instead of DynamicType
    // here.
    return _legacyRawTypes[klass] ??= new InterfaceType(
        klass,
        Nullability.legacy,
        new List<DartType>.filled(
            klass.typeParameters.length, const DynamicType()));
  }

  InterfaceType nullableRawType(Class klass) {
    // TODO(cstefantsova): Consider using computeBounds instead of DynamicType
    // here.
    return _nullableRawTypes[klass] ??= new InterfaceType(
        klass,
        Nullability.nullable,
        new List<DartType>.filled(
            klass.typeParameters.length, const DynamicType()));
  }

  InterfaceType nonNullableRawType(Class klass) {
    // TODO(cstefantsova): Consider using computeBounds instead of DynamicType
    // here.
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
    InterfaceType? result = _thisInterfaceTypes[klass];
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

  ExtensionType thisExtensionType(
      ExtensionTypeDeclaration klass, Nullability nullability) {
    ExtensionType? result = _thisExtensionTypes[klass];
    if (result == null) {
      return _thisExtensionTypes[klass] = new ExtensionType(klass, nullability,
          getAsTypeArguments(klass.typeParameters, klass.enclosingLibrary));
    }
    if (result.nullability != nullability) {
      return _thisExtensionTypes[klass] =
          result.withDeclaredNullability(nullability);
    }
    return result;
  }

  TypedefType thisTypedefType(Typedef typedef, Nullability nullability) {
    TypedefType? result = _thisTypedefTypes[typedef];
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

  InterfaceType bottomInterfaceType(Class klass, Nullability nullability) {
    InterfaceType? result = _bottomInterfaceTypes[klass];
    if (result == null) {
      return _bottomInterfaceTypes[klass] = new InterfaceType(
          klass,
          nullability,
          new List<DartType>.filled(
              klass.typeParameters.length, const NeverType.nonNullable()));
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

    // If the instantiated representation type, R, is a top type then the
    // extension type, V0, is a top type, otherwise V0 is a proper subtype of
    // Object?.
    // TODO(johnniwinther): Is this correct?
    if (type is ExtensionType) {
      return isTop(type.instantiatedRepresentationType);
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
  @pragma("vm:prefer-inline")
  bool isBottom(DartType type) {
    if (type is InterfaceType) return false;
    return _isBottom(type);
  }

  bool _isBottom(DartType type) {
    if (type is InvalidType) return false;

    // BOTTOM(Never) is true.
    if (type is NeverType && type.nullability == Nullability.nonNullable) {
      return true;
    }

    // BOTTOM(X&T) is true iff BOTTOM(T).
    if (type is IntersectionType && type.isPotentiallyNonNullable) {
      return isBottom(type.right);
    }

    // BOTTOM(X extends T) is true iff BOTTOM(T).
    if (type is TypeParameterType && type.isPotentiallyNonNullable) {
      return isBottom(type.parameter.bound);
    }

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
