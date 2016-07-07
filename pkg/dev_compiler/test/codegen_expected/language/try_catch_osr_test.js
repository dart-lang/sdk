dart_library.library('language/try_catch_osr_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch_osr_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch_osr_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])))();
  try_catch_osr_test.maythrow = function(x) {
    try {
      if (x == null) dart.throw(42);
      return 99;
    } finally {
    }
  };
  dart.fn(try_catch_osr_test.maythrow, dynamicTodynamic());
  try_catch_osr_test.f1 = function() {
    let s = 0, t = "abc";
    for (let i = 0; i < 21; ++i) {
      s = s + i;
    }
    try {
      try_catch_osr_test.maythrow(null);
    } catch (e) {
      expect$.Expect.equals("abc", t);
      expect$.Expect.equals(42, e);
      s++;
    }

    return s;
  };
  dart.fn(try_catch_osr_test.f1, VoidTodynamic());
  try_catch_osr_test.f2 = function(x) {
    if (x === void 0) x = 1;
    let s = 0, t = "abc";
    try {
      try {
        for (let i = 0; i < 20; ++i) {
          if (i == 18) try_catch_osr_test.maythrow(null);
          s = dart.notNull(s) + dart.notNull(core.int._check(x));
        }
      } catch (e) {
        expect$.Expect.equals(1, x);
        expect$.Expect.equals("abc", t);
        expect$.Expect.equals(42, e);
        s = dart.notNull(s) + 1;
      }

    } catch (e) {
    }

    return s;
  };
  dart.fn(try_catch_osr_test.f2, __Todynamic());
  try_catch_osr_test.f3 = function() {
    let s = 0, t = "abc";
    try {
      try_catch_osr_test.maythrow(null);
    } catch (e) {
      expect$.Expect.equals("abc", t);
      for (let i = 0; i < 21; ++i) {
        s = s + i;
      }
      expect$.Expect.equals("abc", t);
      expect$.Expect.equals(42, e);
      return s;
    }

  };
  dart.fn(try_catch_osr_test.f3, VoidTodynamic());
  try_catch_osr_test.f4 = function() {
    let s = 0, t = "abc";
    try {
      for (let i = 0; i < 21; ++i) {
        if (i == 18) try_catch_osr_test.maythrow(null);
        s = s + i;
      }
    } catch (e) {
      expect$.Expect.equals("abc", t);
      expect$.Expect.equals(42, e);
      s++;
    }

    return s;
  };
  dart.fn(try_catch_osr_test.f4, VoidTodynamic());
  try_catch_osr_test.f5 = function() {
    let s = null, t = "abc";
    try {
      try_catch_osr_test.maythrow(null);
    } catch (e) {
      expect$.Expect.equals("abc", t);
      expect$.Expect.equals(42, e);
      s = 0;
    }

    for (let i = 0; i < 21; ++i) {
      s = dart.dsend(s, '+', i);
    }
    expect$.Expect.equals("abc", t);
    return s;
  };
  dart.fn(try_catch_osr_test.f5, VoidTodynamic());
  try_catch_osr_test.main = function() {
    expect$.Expect.equals(211, try_catch_osr_test.f1());
    expect$.Expect.equals(19, try_catch_osr_test.f2());
    expect$.Expect.equals(210, try_catch_osr_test.f3());
    expect$.Expect.equals(9 * 17 + 1, try_catch_osr_test.f4());
    expect$.Expect.equals(210, try_catch_osr_test.f5());
  };
  dart.fn(try_catch_osr_test.main, VoidTodynamic());
  // Exports:
  exports.try_catch_osr_test = try_catch_osr_test;
});
