dart_library.library('language/named_parameter_regression_test', null, /* Imports */[
  'dart_sdk'
], function load__named_parameter_regression_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const named_parameter_regression_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameter_regression_test.Fisk = class Fisk extends core.Object {
    foo(opts) {
      let b = opts && 'b' in opts ? opts.b : null;
      let a = opts && 'a' in opts ? opts.a : true;
      if (b == null) return;
      dart.throw('broken');
    }
    bar(opts) {
      let a = opts && 'a' in opts ? opts.a : null;
      let b = opts && 'b' in opts ? opts.b : true;
      if (a == null) return;
      dart.throw('broken');
    }
  };
  dart.setSignature(named_parameter_regression_test.Fisk, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, [], {b: dart.dynamic, a: dart.dynamic}),
      bar: dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic})
    })
  });
  named_parameter_regression_test.main = function() {
    new named_parameter_regression_test.Fisk().foo({a: true});
    new named_parameter_regression_test.Fisk().bar({b: true});
  };
  dart.fn(named_parameter_regression_test.main, VoidTodynamic());
  // Exports:
  exports.named_parameter_regression_test = named_parameter_regression_test;
});
