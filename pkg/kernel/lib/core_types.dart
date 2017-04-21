// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.core_types;

import 'ast.dart';
import 'library_index.dart';

/// Provides access to the classes and libraries in the core libraries.
class CoreTypes extends LibraryIndex {
  Class objectClass;
  Class nullClass;
  Class boolClass;
  Class intClass;
  Class numClass;
  Class doubleClass;
  Class stringClass;
  Class listClass;
  Class mapClass;
  Class iterableClass;
  Class iteratorClass;
  Class futureClass;
  Class streamClass;
  Class symbolClass;
  Class internalSymbolClass;
  Class typeClass;
  Class functionClass;
  Class invocationClass;

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
    ],
    'dart:_internal': [
      'Symbol',
    ],
    'dart:async': [
      'Future',
      'Stream',
    ]
  };

  CoreTypes(Program program) : super.coreLibraries(program) {
    objectClass = getClass('dart:core', 'Object');
    nullClass = getClass('dart:core', 'Null');
    boolClass = getClass('dart:core', 'bool');
    intClass = getClass('dart:core', 'int');
    numClass = getClass('dart:core', 'num');
    doubleClass = getClass('dart:core', 'double');
    stringClass = getClass('dart:core', 'String');
    listClass = getClass('dart:core', 'List');
    mapClass = getClass('dart:core', 'Map');
    iterableClass = getClass('dart:core', 'Iterable');
    iteratorClass = getClass('dart:core', 'Iterator');
    symbolClass = getClass('dart:core', 'Symbol');
    typeClass = getClass('dart:core', 'Type');
    functionClass = getClass('dart:core', 'Function');
    invocationClass = getClass('dart:core', 'Invocation');
    futureClass = getClass('dart:async', 'Future');
    streamClass = getClass('dart:async', 'Stream');
    internalSymbolClass = getClass('dart:_internal', 'Symbol');
  }
}
