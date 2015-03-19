// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var core;
(function (core) {
  'use strict';

  // TODO(jmesserly): for now this is copy+paste from dart/core.js
  class Object {
    constructor() {
      var name = this.constructor.name;
      var init = this[name];
      var result = void 0;
      if (init)
        result = init.apply(this, arguments);
      return result === void 0 ? this : result;
    }
    ['=='](other) {
      return identical(this, other);
    }
    get hashCode() {
      return _js_helper.Primitives.objectHashCode(this);
    }
    toString() {
      return _js_helper.Primitives.objectToString(this);
    }
    noSuchMethod(invocation) {
      throw new NoSuchMethodError(this, invocation.memberName, invocation.positionalArguments, invocation.namedArguments);
    }
    get runtimeType() {
      return _js_helper.getRuntimeType(this);
    }
  }
  core.Object = Object;

  // Function identical: (Object, Object) → bool
  function identical(a, b) {
    return _js_helper.Primitives.identicalImplementation(a, b);
  }
  core.identical = identical;

  // Function print: (Object) → void
  function print(obj) {
    console.log(obj.toString());
  }
  core.print = print;

  // Class NoSuchMethodError
  var NoSuchMethodError = (function () {
    // TODO(vsm): Implement.
    function NoSuchMethodError(f, args) {
    }
    return NoSuchMethodError;
  })();
  core.NoSuchMethodError = NoSuchMethodError;

  // Class UnimplementedError
  var UnimplementedError = (function () {
    // TODO(vsm): Implement.
    function UnimplementedError(message) {
      this.message = (message != void 0) ? message : null;
    }
    return UnimplementedError;
  })();
  core.UnimplementedError = UnimplementedError;
})(core || (core = {}));
