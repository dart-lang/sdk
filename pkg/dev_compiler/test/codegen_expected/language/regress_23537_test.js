dart_library.library('language/regress_23537_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_23537_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_23537_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTonum = () => (VoidTonum = dart.constFn(dart.definiteFunctionType(core.num, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  regress_23537_test.d = null;
  regress_23537_test.test = function(a) {
    while (true) {
      try {
        let b = null;
        try {
          for (let i = 0; i < 10; i++) {
            return dart.fn(() => i + dart.notNull(core.num._check(a)) + dart.notNull(core.num._check(b)), VoidTonum());
          }
        } finally {
          b = 10;
          while (true) {
            let c = 5;
            regress_23537_test.d = dart.fn(() => dart.dsend(dart.dsend(a, '+', b), '+', c), VoidTodynamic());
            break;
          }
        }
      } finally {
        a = 1;
      }
      break;
    }
  };
  dart.fn(regress_23537_test.test, dynamicTodynamic());
  regress_23537_test.main = function() {
    let c = regress_23537_test.test(0);
    expect$.Expect.equals(11, dart.dcall(c));
    expect$.Expect.equals(16, dart.dcall(regress_23537_test.d));
  };
  dart.fn(regress_23537_test.main, VoidTodynamic());
  // Exports:
  exports.regress_23537_test = regress_23537_test;
});
