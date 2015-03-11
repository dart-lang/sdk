// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var dart_core;
(function (dart_core) {
  var Object = (function () {
    var constructor = function Object() {};

    constructor.prototype.toString = function toString() {
      return 'Instance of ' + this.constructor.name;
    };

    constructor.prototype.noSuchMethod = function noSuchMethod(invocation) {
      // TODO: add arguments when Invocation is defined
      throw new NoSuchMethodError();
    };

    // TODO: implement ==

    // TODO: implement hashCode

    // TODO: implement runtimeType

    return constructor;
  })();
  dart_core.Object = Object;

  // Function print: (Object) → void
  function print(obj) {
    console.log(obj.toString());
  }
  dart_core.print = print;

  // Class NoSuchMethodError
  var NoSuchMethodError = (function () {
    // TODO(vsm): Implement.
    function NoSuchMethodError(f, args) {
    }
    return NoSuchMethodError;
  })();
  dart_core.NoSuchMethodError = NoSuchMethodError;

  // Class UnimplementedError
  var UnimplementedError = (function () {
    // TODO(vsm): Implement.
    function UnimplementedError(message) {
      this.message = (message != void 0) ? message : null;
    }
    return UnimplementedError;
  })();
  dart_core.UnimplementedError = UnimplementedError;
})(dart_core || (dart_core = {}));
