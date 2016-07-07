dart_library.library('language/issue13179_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue13179_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue13179_test = Object.create(null);
  let __Tovoid = () => (__Tovoid = dart.constFn(dart.functionType(dart.void, [], [dart.dynamic])))();
  let __Tovoid$ = () => (__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [], [__Tovoid()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue13179_test.count = 0;
  issue13179_test.f = function(f) {
    if (f === void 0) f = issue13179_test.f;
    issue13179_test.count = dart.notNull(issue13179_test.count) + 1;
    if (f != null) {
      dart.dcall(f, null);
    }
  };
  dart.fn(issue13179_test.f, __Tovoid$());
  issue13179_test.main = function() {
    issue13179_test.f();
    expect$.Expect.equals(2, issue13179_test.count);
  };
  dart.fn(issue13179_test.main, VoidTodynamic());
  // Exports:
  exports.issue13179_test = issue13179_test;
});
