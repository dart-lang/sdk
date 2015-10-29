// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dart_library.library('dart/_runtime', null, /* Imports */[
  'dart/_classes',
  'dart/_errors',
  'dart/_generators',
  'dart/_operations',
  'dart/_rtti',
  'dart/_types',
], /* Lazy Imports */[
  'dart/_js_helper'
], function(exports, classes, errors, generators, operations, rtti, types,
    _js_helper) {
  'use strict';

  function _export(value) {
    if (value) return value;
    console.log("Re-exporting null field: " + name);
    throw "Bad export";
  }

  function exportFrom(value, names) {
    for (let name of names) {
      exports[name] = _export(value[name]);
    }
  }

  exports.global = typeof window == "undefined" ? global : window;
  exports.JsSymbol = _export(Symbol);

  // TODO(vsm): This is referenced (as init.globalState) from
  // isolate_helper.dart.  Where should it go?
  // See: https://github.com/dart-lang/dev_compiler/issues/164
  exports.globalState = null;
  _js_helper.checkNum = operations.notNull;

  // Re-exports

  // From classes
  exportFrom(classes, [
    'bind',
    'classGetConstructorType',
    'dartx',
    'defineNamedConstructor',
    'defineExtensionNames',
    'defineExtensionMembers',
    'generic',
    'implements',
    'list',
    'metadata',
    'mixin',
    'registerExtension',
    'setBaseClass',
    'setSignature',
    'virtualField'
  ]);

  exportFrom(generators, [
    'syncStar',
    'async',
    'asyncStar'
  ]);

  // From dart_utils
  exportFrom(dart_utils, ['copyProperties', 'export']);
  // Renames
  exports.defineLazyClass = _export(dart_utils.defineLazy);
  exports.defineLazyProperties = _export(dart_utils.defineLazy);
  exports.defineLazyClassGeneric = _export(dart_utils.defineLazyProperty);

  // From operations
  exportFrom(operations, [
    'JsIterator',
    'arity',
    'asInt',
    'assert',
    'const',
    'dcall',
    'dindex',
    'dload',
    'dput',
    'dsend',
    'dsetindex',
    'equals',
    'hashCode',
    'map',
    'noSuchMethod',
    'notNull',
    'nullSafe',
    'stackPrint',
    'stackTrace',
    'strongInstanceOf',
    'throw',
    'toString',
  ])
  // Renames
  exports.as = _export(operations.cast);
  exports.is = _export(operations.instanceOf);

  // From types
  exportFrom(types, [
    'bottom',
    'definiteFunctionType',
    'dynamic',
    'functionType',
    'jsobject',
    'typedef',
    'typeName',
    'void',
  ]);

  // From rtti
  exportFrom(rtti, [
    'fn',
    'realRuntimeType',
    'runtimeType',
  ]);

});
