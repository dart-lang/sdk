// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Native testing library. Provides support for mock @Native classes and
// collects common imports.

import "package:expect/expect.dart";
import 'dart:_js_helper' show Native;
import 'dart:_foreign_helper' show JS;

export "package:expect/expect.dart";
export 'dart:_js_helper' show Creates, Native, JSName, Returns;
export 'dart:_foreign_helper' show JS;

void nativeTesting() {
  JS('', r'''
((function() {
  var toStringResultProperty = "_toStringResult";
  var objectToStringMethod = Object.prototype.toString;

  Object.prototype.toString = function() {
    if (this != null) {
      var constructor = this.constructor;
      if (constructor != null) {
        var result = constructor[toStringResultProperty];
        if (typeof result == "string") return result;
      }
    }
    return objectToStringMethod.call(this);
  };

  // To mock a @Native class with JavaScript constructor `Foo`, add
  //
  //     self.nativeConstructor(Foo);
  //
  // to the JavaScript code.
  self.nativeConstructor = function(constructor, opt_name) {
    var toStringResult = "[object " + (opt_name || constructor.name) + "]";
    constructor[toStringResultProperty] = toStringResult;
  };
})())
''');
}

@NoInline()
@AssumeDynamic()
confuse(x) => x;
