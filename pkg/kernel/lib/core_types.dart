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
  Class _noSuchMethodErrorClass;
  Constructor _noSuchMethodErrorImplementationConstructor;
  Procedure _listFromConstructor;
  Procedure _printProcedure;
  Procedure _identicalProcedure;
  Constructor _constantExpressionErrorDefaultConstructor;
  Constructor _compileTimeErrorDefaultConstructor;

  Class _internalSymbolClass;

  Library _asyncLibrary;
  Class _futureClass;
  Class _streamClass;
  Class _completerClass;
  Class _futureOrClass;
  Procedure _completerSyncConstructor;
  Procedure _futureMicrotaskConstructor;
  Constructor _syncIterableDefaultConstructor;
  Constructor _streamIteratorDefaultConstructor;
  Constructor _asyncStarStreamControllerDefaultConstructor;
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

  Constructor get asyncStarStreamControllerDefaultConstructor {
    return _asyncStarStreamControllerDefaultConstructor ??=
        _index.getMember('dart:async', '_AsyncStarStreamController', '');
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

  /// An implementation-specific constructor suitable for use by
  /// `Target.instantiateNoSuchMethodError`.
  Constructor get noSuchMethodErrorImplementationConstructor {
    return _noSuchMethodErrorImplementationConstructor ??=
        _index.getMember('dart:core', 'NoSuchMethodError', '_withType');
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

  Class get streamClass {
    return _streamClass ??= _index.getClass('dart:async', 'Stream');
  }

  Constructor get streamIteratorDefaultConstructor {
    return _streamIteratorDefaultConstructor ??=
        _index.getMember('dart:async', '_StreamIterator', '');
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

  Class get typeClass {
    return _typeClass ??= _index.getClass('dart:core', 'Type');
  }

  Constructor get constantExpressionErrorDefaultConstructor {
    return _constantExpressionErrorDefaultConstructor ??=
        _index.getMember('dart:core', '_ConstantExpressionError', '');
  }

  Constructor get compileTimeErrorDefaultConstructor {
    return _compileTimeErrorDefaultConstructor ??=
        _index.getMember('dart:core', '_CompileTimeError', '');
  }
}
