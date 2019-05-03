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
}
