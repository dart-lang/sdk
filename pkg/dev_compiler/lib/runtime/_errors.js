// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
 * This library encapsulates the core sdk errors that the runtime knows about.
 *
 */

dart_library.library('dart_runtime/_errors', null, /* Imports */[
], /* Lazy Imports */[
  'dart/core',
  'dart/_js_helper'
], function(exports, core, _js_helper) {
  'use strict';

  function throwNoSuchMethod(obj, name, pArgs, nArgs, extras) {
    throw new core.NoSuchMethodError(obj, name, pArgs, nArgs, extras);
  }
  exports.throwNoSuchMethod = throwNoSuchMethod;

  function throwCastError(actual, type) {
    throw new _js_helper.CastErrorImplementation(actual, type);
  }
  exports.throwCastError = throwCastError;

  function throwAssertionError() {
    throw new core.AssertionError();
  }
  exports.throwAssertionError = throwAssertionError;
});
