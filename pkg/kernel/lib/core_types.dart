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
  Class _mapClass;
  Class _iterableClass;
  Class _iteratorClass;
  Class _symbolClass;
  Class _typeClass;
  Class _functionClass;
  Class _invocationClass;
  Constructor _externalNameDefaultConstructor;
  Class _invocationMirrorClass;
  Constructor _invocationMirrorWithTypeConstructor;
  Constructor _invocationMirrorWithoutTypeConstructor;
  Class _noSuchMethodErrorClass;
  Constructor _noSuchMethodErrorDefaultConstructor;
  Procedure _listFromConstructor;
  Procedure _printProcedure;
  Procedure _identicalProcedure;
  Constructor _constantExpressionErrorDefaultConstructor;
  Procedure _constantExpressionErrorThrow;
  Constructor _duplicatedFieldInitializerErrorDefaultConstructor;
  Constructor _fallThroughErrorUrlAndLineConstructor;
  Constructor _compileTimeErrorDefaultConstructor;
  Procedure _objectEquals;
  Procedure _mapUnmodifiable;

  Class _internalSymbolClass;

  Library _asyncLibrary;
  Class _futureClass;
  Class _stackTraceClass;
  Class _streamClass;
  Class _completerClass;
  Class _asyncAwaitCompleterClass;
  Class _futureOrClass;
  Constructor _asyncAwaitCompleterConstructor;
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

  /// The `dart:mirrors` library, or `null` if the component does not use it.
  Library _mirrorsLibrary;

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

  Class get completerClass {
    return _completerClass ??= index.getClass('dart:async', 'Completer');
  }

  Class get asyncAwaitCompleterClass {
    return _asyncAwaitCompleterClass ??=
        index.getClass('dart:async', '_AsyncAwaitCompleter');
  }

  Procedure get completerSyncConstructor {
    return _completerSyncConstructor ??=
        index.getMember('dart:async', 'Completer', 'sync');
  }

  Constructor get asyncAwaitCompleterConstructor {
    return _asyncAwaitCompleterConstructor ??=
        index.getMember('dart:async', '_AsyncAwaitCompleter', '');
  }

  Procedure get completerComplete {
    return _completerComplete ??=
        index.getMember('dart:async', 'Completer', 'complete');
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

  Constructor get externalNameDefaultConstructor {
    return _externalNameDefaultConstructor ??=
        index.getMember('dart:_internal', 'ExternalName', '');
  }

  Class get functionClass {
    return _functionClass ??= index.getClass('dart:core', 'Function');
  }

  Class get futureClass {
    return _futureClass ??= index.getClass('dart:async', 'Future');
  }

  Procedure get futureMicrotaskConstructor {
    return _futureMicrotaskConstructor ??=
        index.getMember('dart:async', 'Future', 'microtask');
  }

  Class get futureOrClass {
    return _futureOrClass ??= index.getClass('dart:async', 'FutureOr');
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

  Constructor get invocationMirrorWithoutTypeConstructor {
    return _invocationMirrorWithoutTypeConstructor ??=
        index.getMember('dart:core', '_InvocationMirror', '_withoutType');
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

  Class get noSuchMethodErrorClass {
    return _noSuchMethodErrorClass ??=
        index.getClass('dart:core', 'NoSuchMethodError');
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

  Procedure get printProcedure {
    return _printProcedure ??= index.getTopLevelMember('dart:core', 'print');
  }

  Class get stackTraceClass {
    return _stackTraceClass ??= index.getClass('dart:core', 'StackTrace');
  }

  Class get streamClass {
    return _streamClass ??= index.getClass('dart:async', 'Stream');
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

  Constructor get constantExpressionErrorDefaultConstructor {
    return _constantExpressionErrorDefaultConstructor ??=
        index.getMember('dart:core', '_ConstantExpressionError', '');
  }

  Member get constantExpressionErrorThrow {
    return _constantExpressionErrorThrow ??=
        index.getMember('dart:core', '_ConstantExpressionError', '_throw');
  }

  Constructor get duplicatedFieldInitializerErrorDefaultConstructor {
    return _duplicatedFieldInitializerErrorDefaultConstructor ??=
        index.getMember('dart:core', '_DuplicatedFieldInitializerError', '');
  }

  Constructor get fallThroughErrorUrlAndLineConstructor {
    return _fallThroughErrorUrlAndLineConstructor ??=
        index.getMember('dart:core', 'FallThroughError', '_create');
  }

  Constructor get compileTimeErrorDefaultConstructor {
    return _compileTimeErrorDefaultConstructor ??=
        index.getMember('dart:core', '_CompileTimeError', '');
  }
}
