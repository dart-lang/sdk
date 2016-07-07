dart_library.library('language/issue12023_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue12023_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue12023_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  issue12023_test.main = function() {
    let test = JSArrayOfString().of(["f", "5", "s", "6"]);
    let length = test[dartx.length];
    for (let i = 0; i < dart.notNull(length);) {
      let action = test[dartx.get](i++);
      switch (action) {
        case "f":
        case "s":
        {
          action = test[dartx.get](i - 1);
          let value = core.int.parse(core.String._check(test[dartx.get](i++)));
          if (dart.equals(action, "f")) {
            expect$.Expect.equals(5, value);
          } else {
            expect$.Expect.equals(6, value);
          }
          break;
        }
      }
    }
  };
  dart.fn(issue12023_test.main, VoidTovoid());
  // Exports:
  exports.issue12023_test = issue12023_test;
});
