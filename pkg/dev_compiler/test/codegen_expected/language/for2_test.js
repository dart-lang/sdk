dart_library.library('language/for2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__for2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const for2_test = Object.create(null);
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  for2_test.f = null;
  for2_test.main = function() {
    for (let i = 0; i < 10; i++) {
      if (i == 7) {
        for2_test.f = dart.fn(() => dart.str`i = ${i}`, VoidToString());
      }
    }
    expect$.Expect.equals("i = 7", dart.dcall(for2_test.f));
    let k = null;
    for (k = 0; dart.notNull(k) < 10; k = dart.notNull(k) + 1) {
      if (k == 7) {
        for2_test.f = dart.fn(() => dart.str`k = ${k}`, VoidToString());
      }
    }
    expect$.Expect.equals("k = 10", dart.dcall(for2_test.f));
    for (let n = 0; n < 10; n++) {
      let l = n;
      if (l == 7) {
        for2_test.f = dart.fn(() => dart.str`l = ${l}, n = ${n}`, VoidToString());
      }
      l++;
    }
    expect$.Expect.equals("l = 8, n = 7", dart.dcall(for2_test.f));
    for (let i = 0; i < 10;) {
      if (i == 7) {
        for2_test.f = dart.fn(() => dart.str`i = ${i}`, VoidToString());
      }
      i++;
    }
    expect$.Expect.equals("i = 8", dart.dcall(for2_test.f));
    for (let i = 0; i < 10; i++) {
      if (i == 7) {
        for2_test.f = dart.fn(() => dart.str`i = ${i}`, VoidToString());
      }
      continue;
      i++;
    }
    expect$.Expect.equals("i = 7", dart.dcall(for2_test.f));
    for (let k = 0; k < 5; k++) {
      for (let i = 0; i < 10; i++) {
        if (k == 3 && i == 7) {
          for2_test.f = dart.fn(() => dart.str`k = ${k}, i = ${i}`, VoidToString());
        }
      }
    }
    expect$.Expect.equals("k = 3, i = 7", dart.dcall(for2_test.f));
  };
  dart.fn(for2_test.main, VoidTodynamic());
  // Exports:
  exports.for2_test = for2_test;
});
