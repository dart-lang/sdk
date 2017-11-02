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
      '_ConstantExpressionError',
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

  final LibraryIndex _index;

  Library _coreLibrary;
  Class _objectClass;
  Class _nullClass;
  Class _boolClass;
  Class _intClass;
  Class _numClass;
  Class _doubleClass;
  Class _stringClass;
  Class _listClass;
  Class _mapClass;
  Class _iterableClass;
  Class _iteratorClass;
  Class _symbolClass;
  Class _typeClass;
  Class _functionClass;
  Class _invocationClass;
  Constructor _externalNameDefaultConstructor;
  Class _invocationMirrorClass;
  Constructor _invocationMirrorDefaultConstructor;
  Constructor _invocationMirrorWithTypeConstructor;
  Class _noSuchMethodErrorClass;
  Constructor _noSuchMethodErrorDefaultConstructor;
  Procedure _listFromConstructor;
  Procedure _printProcedure;
  Procedure _identicalProcedure;
  Constructor _constantExpressionErrorDefaultConstructor;
  Constructor _fallThroughErrorUrlAndLineConstructor;
  Constructor _compileTimeErrorDefaultConstructor;

  Class _internalSymbolClass;

  Library _asyncLibrary;
  Class _futureClass;
  Class _stackTraceClass;
  Class _streamClass;
  Class _completerClass;
  Class _futureOrClass;
  Procedure _completerSyncConstructor;
  Procedure _completerComplete;
  Procedure _completerCompleteError;
  Procedure _futureMicrotaskConstructor;
  Constructor _syncIterableDefaultConstructor;
  Constructor _streamIteratorDefaultConstructor;
  Constructor _asyncStarStreamControllerDefaultConstructor;
  Procedure _asyncStackTraceHelperProcedure;
  Procedure _asyncThenWrapperHelperProcedure;
  Procedure _asyncErrorWrapperHelperProcedure;
  Procedure _awaitHelperProcedure;

  /// The `dart:mirrors` library, or `null` if the program does not use it.
  Library _mirrorsLibrary;

  CoreTypes(Program program) : _index = new LibraryIndex.coreLibraries(program);

  Procedure get asyncErrorWrapperHelperProcedure {
    return _asyncErrorWrapperHelperProcedure ??=
        _index.getTopLevelMember('dart:async', '_asyncErrorWrapperHelper');
  }

  Library get asyncLibrary {
    return _asyncLibrary ??= _index.getLibrary('dart:async');
  }

  Member get asyncStarStreamControllerAdd {
    return _index.getMember('dart:async', '_AsyncStarStreamController', 'add');
  }

  Member get asyncStarStreamControllerAddError {
    return _index.getMember(
        'dart:async', '_AsyncStarStreamController', 'addError');
  }

  Member get asyncStarStreamControllerAddStream {
    return _index.getMember(
        'dart:async', '_AsyncStarStreamController', 'addStream');
  }

  Class get asyncStarStreamControllerClass {
    return _index.getClass('dart:async', '_AsyncStarStreamController');
  }

  Member get asyncStarStreamControllerClose {
    return _index.getMember(
        'dart:async', '_AsyncStarStreamController', 'close');
  }

  Constructor get asyncStarStreamControllerDefaultConstructor {
    return _asyncStarStreamControllerDefaultConstructor ??=
        _index.getMember('dart:async', '_AsyncStarStreamController', '');
  }

  Member get asyncStarStreamControllerStream {
    return _index.getMember(
        'dart:async', '_AsyncStarStreamController', 'get:stream');
  }

  Procedure get asyncStackTraceHelperProcedure {
    return _asyncStackTraceHelperProcedure ??=
        _index.getTopLevelMember('dart:async', '_asyncStackTraceHelper');
  }

  Procedure get asyncThenWrapperHelperProcedure {
    return _asyncThenWrapperHelperProcedure ??=
        _index.getTopLevelMember('dart:async', '_asyncThenWrapperHelper');
  }

  Procedure get awaitHelperProcedure {
    return _awaitHelperProcedure ??=
        _index.getTopLevelMember('dart:async', '_awaitHelper');
  }

  Class get boolClass {
    return _boolClass ??= _index.getClass('dart:core', 'bool');
  }

  Class get completerClass {
    return _completerClass ??= _index.getClass('dart:async', 'Completer');
  }

  Procedure get completerSyncConstructor {
    return _completerSyncConstructor ??=
        _index.getMember('dart:async', 'Completer', 'sync');
  }

  Procedure get completerComplete {
    return _completerComplete ??=
        _index.getMember('dart:async', 'Completer', 'complete');
  }

  Procedure get completerCompleteError {
    return _completerCompleteError ??=
        _index.getMember('dart:async', 'Completer', 'completeError');
  }

  Member get completerFuture {
    return _index.getMember('dart:async', 'Completer', 'get:future');
  }

  Library get coreLibrary {
    return _coreLibrary ??= _index.getLibrary('dart:core');
  }

  Class get doubleClass {
    return _doubleClass ??= _index.getClass('dart:core', 'double');
  }

  Constructor get externalNameDefaultConstructor {
    return _externalNameDefaultConstructor ??=
        _index.getMember('dart:_internal', 'ExternalName', '');
  }

  Class get functionClass {
    return _functionClass ??= _index.getClass('dart:core', 'Function');
  }

  Class get futureClass {
    return _futureClass ??= _index.getClass('dart:async', 'Future');
  }

  Procedure get futureMicrotaskConstructor {
    return _futureMicrotaskConstructor ??=
        _index.getMember('dart:async', 'Future', 'microtask');
  }

  Class get futureOrClass {
    return _futureOrClass ??= _index.getClass('dart:async', 'FutureOr');
  }

  Procedure get identicalProcedure {
    return _identicalProcedure ??=
        _index.getTopLevelMember('dart:core', 'identical');
  }

  Class get intClass {
    return _intClass ??= _index.getClass('dart:core', 'int');
  }

  Class get internalSymbolClass {
    return _internalSymbolClass ??= _index.getClass('dart:_internal', 'Symbol');
  }

  Class get invocationClass {
    return _invocationClass ??= _index.getClass('dart:core', 'Invocation');
  }

  Class get invocationMirrorClass {
    return _invocationMirrorClass ??=
        _index.getClass('dart:core', '_InvocationMirror');
  }

  Constructor get invocationMirrorDefaultConstructor {
    return _invocationMirrorDefaultConstructor ??=
        _index.getMember('dart:core', '_InvocationMirror', '');
  }

  Constructor get invocationMirrorWithTypeConstructor {
    return _invocationMirrorWithTypeConstructor ??=
        _index.getMember('dart:core', '_InvocationMirror', '_withType');
  }

  Class get iterableClass {
    return _iterableClass ??= _index.getClass('dart:core', 'Iterable');
  }

  Class get iteratorClass {
    return _iteratorClass ??= _index.getClass('dart:core', 'Iterator');
  }

  Class get listClass {
    return _listClass ??= _index.getClass('dart:core', 'List');
  }

  Procedure get listFromConstructor {
    return _listFromConstructor ??=
        _index.getMember('dart:core', 'List', 'from');
  }

  Class get mapClass {
    return _mapClass ??= _index.getClass('dart:core', 'Map');
  }

  Library get mirrorsLibrary {
    return _mirrorsLibrary ??= _index.tryGetLibrary('dart:mirrors');
  }

  Class get noSuchMethodErrorClass {
    return _noSuchMethodErrorClass ??=
        _index.getClass('dart:core', 'NoSuchMethodError');
  }

  Constructor get noSuchMethodErrorDefaultConstructor {
    return _noSuchMethodErrorDefaultConstructor ??=
        // TODO(regis): Replace 'withInvocation' with '' after dart2js is fixed.
        _index.getMember('dart:core', 'NoSuchMethodError', 'withInvocation');
  }

  Class get nullClass {
    return _nullClass ??= _index.getClass('dart:core', 'Null');
  }

  Class get numClass {
    return _numClass ??= _index.getClass('dart:core', 'num');
  }

  Class get objectClass {
    return _objectClass ??= _index.getClass('dart:core', 'Object');
  }

  Procedure get printProcedure {
    return _printProcedure ??= _index.getTopLevelMember('dart:core', 'print');
  }

  Class get stackTraceClass {
    return _stackTraceClass ??= _index.getClass('dart:core', 'StackTrace');
  }

  Class get streamClass {
    return _streamClass ??= _index.getClass('dart:async', 'Stream');
  }

  Member get streamIteratorCancel {
    return _index.getMember('dart:async', '_StreamIterator', 'cancel');
  }

  Class get streamIteratorClass {
    return _index.getClass('dart:async', '_StreamIterator');
  }

  Constructor get streamIteratorDefaultConstructor {
    return _streamIteratorDefaultConstructor ??=
        _index.getMember('dart:async', '_StreamIterator', '');
  }

  Member get streamIteratorMoveNext {
    return _index.getMember('dart:async', '_StreamIterator', 'moveNext');
  }

  Member get streamIteratorCurrent {
    return _index.getMember('dart:async', '_StreamIterator', 'get:current');
  }

  Class get stringClass {
    return _stringClass ??= _index.getClass('dart:core', 'String');
  }

  Class get symbolClass {
    return _symbolClass ??= _index.getClass('dart:core', 'Symbol');
  }

  Constructor get syncIterableDefaultConstructor {
    return _syncIterableDefaultConstructor ??=
        _index.getMember('dart:core', '_SyncIterable', '');
  }

  Class get syncIteratorClass {
    return _index.getClass('dart:core', '_SyncIterator');
  }

  Member get syncIteratorCurrent {
    return _index.getMember('dart:core', '_SyncIterator', '_current');
  }

  Member get syncIteratorYieldEachIterable {
    return _index.getMember('dart:core', '_SyncIterator', '_yieldEachIterable');
  }

  Class get typeClass {
    return _typeClass ??= _index.getClass('dart:core', 'Type');
  }

  Constructor get constantExpressionErrorDefaultConstructor {
    return _constantExpressionErrorDefaultConstructor ??=
        _index.getMember('dart:core', '_ConstantExpressionError', '');
  }

  Constructor get fallThroughErrorUrlAndLineConstructor {
    return _fallThroughErrorUrlAndLineConstructor ??=
        _index.getMember('dart:core', 'FallThroughError', '_create');
  }

  Constructor get compileTimeErrorDefaultConstructor {
    return _compileTimeErrorDefaultConstructor ??=
        _index.getMember('dart:core', '_CompileTimeError', '');
  }
}
