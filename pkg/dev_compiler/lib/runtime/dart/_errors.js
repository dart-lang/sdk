// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
 * This library encapsulates the core sdk errors that the runtime knows about.
 *
 */

dart_library.library('dart/_errors', null, /* Imports */[
], /* Lazy Imports */[
  'dart/_operations',
  'dart/core',
  'dart/_js_helper'
], function(exports, operations, core, _js_helper) {
  'use strict';

  function throwNoSuchMethod(obj, name, pArgs, nArgs, extras) {
    operations.throw(new core.NoSuchMethodError(obj, name, pArgs, nArgs, extras));
  }
  exports.throwNoSuchMethod = throwNoSuchMethod;

  function throwCastError(actual, type) {
    operations.throw(new _js_helper.CastErrorImplementation(actual, type));
  }
  exports.throwCastError = throwCastError;

  function throwAssertionError() {
    operations.throw(new core.AssertionError());
  }
  exports.throwAssertionError = throwAssertionError;

  function throwNullValueError() {
    // TODO(vsm): Per spec, we should throw an NSM here.  Technically, we ought
    // to thread through method info, but that uglifies the code and can't
    // actually be queried ... it only affects how the error is printed.
    operations.throw(new core.NoSuchMethodError(null,
      new core.Symbol('<Unexpected Null Value>'), null, null, null));
  }
  exports.throwNullValueError = throwNullValueError;
});
