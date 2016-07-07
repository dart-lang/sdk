dart_library.library('language/fixed_length_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__fixed_length_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const fixed_length_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  fixed_length_test.main = function() {
    expect$.Expect.equals(-1, fixed_length_test.foo());
  };
  dart.fn(fixed_length_test.main, VoidTovoid());
  fixed_length_test.foo = function() {
    let list = ListOfint().new(1024);
    for (let i = 0; i < dart.notNull(list[dartx.length]); i++)
      list[dartx.set](i, -i);
    for (let n = list[dartx.length]; dart.notNull(n) > 1; n = dart.notNull(n) - 1) {
      for (let i = 0; i < dart.notNull(n) - 1; i++) {
        if (dart.notNull(list[dartx.get](i)) > dart.notNull(list[dartx.get](i + 1))) {
          return list[dartx.get](i + 1);
        }
      }
    }
  };
  dart.fn(fixed_length_test.foo, VoidToint());
  // Exports:
  exports.fixed_length_test = fixed_length_test;
});
