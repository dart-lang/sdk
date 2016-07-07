dart_library.library('language/issue15702_test', null, /* Imports */[
  'dart_sdk'
], function load__issue15702_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue15702_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue15702_test.main = function() {
    let stake = new issue15702_test.Amount(2.5);
    if ((dart.notNull(stake.value) * 10)[dartx.toInt]() != 25) {
      dart.throw('Test failed');
    }
  };
  dart.fn(issue15702_test.main, VoidTodynamic());
  issue15702_test.Amount = class Amount extends core.Object {
    new(value) {
      this.value = value;
    }
  };
  dart.setSignature(issue15702_test.Amount, {
    constructors: () => ({new: dart.definiteFunctionType(issue15702_test.Amount, [core.num])})
  });
  // Exports:
  exports.issue15702_test = issue15702_test;
});
