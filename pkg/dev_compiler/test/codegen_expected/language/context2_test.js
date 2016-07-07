dart_library.library('language/context2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__context2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const context2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  context2_test.V = class V extends core.Object {
    notCalled(x) {
      return dart.dcall(x);
    }
    foofoo(x) {
      return x;
    }
    hoop(input, n) {
      while (dart.test(dart.dsend((() => {
        let x = n;
        n = dart.dsend(x, '-', 1);
        return x;
      })(), '>', 0))) {
        expect$.Expect.equals(5, input);
        continue;
        switch (input) {
          case 3:
          {
            let values = dart.bind(this, 'foofoo');
            this.notCalled(dart.fn(() => dart.dcall(values, input), VoidTodynamic()));
          }
        }
      }
    }
  };
  dart.setSignature(context2_test.V, {
    methods: () => ({
      notCalled: dart.definiteFunctionType(dart.dynamic, [core.Function]),
      foofoo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      hoop: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])
    })
  });
  context2_test.main = function() {
    new context2_test.V().hoop(5, 3);
  };
  dart.fn(context2_test.main, VoidTodynamic());
  // Exports:
  exports.context2_test = context2_test;
});
