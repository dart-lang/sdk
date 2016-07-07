dart_library.library('language/inline_test', null, /* Imports */[
  'dart_sdk'
], function load__inline_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const inline_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inline_test.X = class X extends core.Object {
    x(a, b) {
      do {
        if (core.identical(a, b)) {
          break;
        }
      } while (dart.test(this.p(a, b)));
    }
    p(a, b) {
      return core.identical(a, b);
    }
  };
  dart.setSignature(inline_test.X, {
    methods: () => ({
      x: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic]),
      p: dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])
    })
  });
  inline_test.main = function() {
    let x = new inline_test.X();
    x.x(1, 2);
  };
  dart.fn(inline_test.main, VoidTodynamic());
  // Exports:
  exports.inline_test = inline_test;
});
