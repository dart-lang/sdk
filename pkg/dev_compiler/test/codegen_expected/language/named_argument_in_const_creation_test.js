dart_library.library('language/named_argument_in_const_creation_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_argument_in_const_creation_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_argument_in_const_creation_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_argument_in_const_creation_test.A = class A extends core.Object {
    new(a, opts) {
      let b = opts && 'b' in opts ? opts.b : null;
      this.x = a;
      this.y = b;
    }
  };
  dart.setSignature(named_argument_in_const_creation_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(named_argument_in_const_creation_test.A, [dart.dynamic], {b: dart.dynamic})})
  });
  dart.defineLazy(named_argument_in_const_creation_test.A, {
    get test() {
      return dart.const(new named_argument_in_const_creation_test.A(1, {b: 2}));
    }
  });
  named_argument_in_const_creation_test.main = function() {
    let a = named_argument_in_const_creation_test.A.test;
    expect$.Expect.equals(1, a.x);
    expect$.Expect.equals(2, a.y);
  };
  dart.fn(named_argument_in_const_creation_test.main, VoidTodynamic());
  // Exports:
  exports.named_argument_in_const_creation_test = named_argument_in_const_creation_test;
});
