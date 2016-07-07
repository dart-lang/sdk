dart_library.library('language/issue15720_test', null, /* Imports */[
  'dart_sdk'
], function load__issue15720_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue15720_test = Object.create(null);
  let SetOfB = () => (SetOfB = dart.constFn(core.Set$(issue15720_test.B)))();
  let JSArrayOfB = () => (JSArrayOfB = dart.constFn(_interceptors.JSArray$(issue15720_test.B)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue15720_test.B = class B extends core.Object {};
  issue15720_test.confuse = function(x) {
    if (dart.equals(new core.DateTime.now(), 42)) return issue15720_test.confuse(x);
    return x;
  };
  dart.fn(issue15720_test.confuse, dynamicTodynamic());
  issue15720_test.main = function() {
    let set = SetOfB().from(JSArrayOfB().of([]));
    issue15720_test.confuse(499);
    issue15720_test.confuse(set);
    let t1 = new issue15720_test.B();
    let t2 = new issue15720_test.B();
    let t3 = new issue15720_test.B();
    let t4 = new issue15720_test.B();
    set.addAll(JSArrayOfB().of([t1, t2, t3, t4]));
    issue15720_test.confuse(7);
    set.addAll(JSArrayOfB().of([t1, t2, t3, t4]));
  };
  dart.fn(issue15720_test.main, VoidTodynamic());
  // Exports:
  exports.issue15720_test = issue15720_test;
});
