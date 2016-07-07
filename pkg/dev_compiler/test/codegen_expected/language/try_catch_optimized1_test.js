dart_library.library('language/try_catch_optimized1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch_optimized1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch_optimized1_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicAnddynamic__Todynamic$ = () => (dynamicAnddynamicAnddynamic__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  try_catch_optimized1_test.maythrow = function(x) {
    if (x == null) dart.throw(42);
    return 99;
  };
  dart.fn(try_catch_optimized1_test.maythrow, dynamicTodynamic());
  try_catch_optimized1_test.f1 = function(x) {
    let result = 123;
    try {
      result = core.int._check(try_catch_optimized1_test.maythrow(x));
      if (dart.notNull(result) > 100) dart.throw(42);
    } catch (e) {
      expect$.Expect.equals(result, 123);
      expect$.Expect.equals(42, e);
      result = 0;
    }

    return result;
  };
  dart.fn(try_catch_optimized1_test.f1, dynamicTodynamic());
  try_catch_optimized1_test.A = class A extends core.Object {
    maythrow(x) {
      if (x == null) dart.throw(42);
      return 99;
    }
  };
  dart.setSignature(try_catch_optimized1_test.A, {
    methods: () => ({maythrow: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  try_catch_optimized1_test.f2 = function(x) {
    let result = 123;
    let a = new try_catch_optimized1_test.A();
    try {
      result = dart.notNull(result) + 1;
      result = core.int._check(a.maythrow(x));
    } catch (e) {
      expect$.Expect.equals(124, result);
      result = core.int._check(x);
    }

    return result;
  };
  dart.fn(try_catch_optimized1_test.f2, dynamicTodynamic());
  try_catch_optimized1_test.f3 = function(x, y) {
    let result = 123;
    let a = new try_catch_optimized1_test.A();
    try {
      result = dart.notNull(result) + 1;
      result = core.int._check(a.maythrow(x));
    } catch (e) {
      result = core.int._check(dart.dsend(y, '+', 1));
    }

    return result;
  };
  dart.fn(try_catch_optimized1_test.f3, dynamicAnddynamicTodynamic());
  try_catch_optimized1_test.f4 = function(x) {
    try {
      try_catch_optimized1_test.maythrow(x);
    } catch (e) {
      try_catch_optimized1_test.check_f4(e, "abc");
    }

  };
  dart.fn(try_catch_optimized1_test.f4, dynamicTodynamic());
  try_catch_optimized1_test.check_f4 = function(e, s) {
    if (!dart.equals(e, 42)) dart.throw("ERROR");
    if (!dart.equals(s, "abc")) dart.throw("ERROR");
  };
  dart.fn(try_catch_optimized1_test.check_f4, dynamicAnddynamicTodynamic());
  try_catch_optimized1_test.f5 = function(x) {
    try {
      try_catch_optimized1_test.maythrow(x);
    } catch (e) {
      try_catch_optimized1_test.check_f5(e, "abc");
    }

    try {
      try_catch_optimized1_test.maythrow(x);
    } catch (e) {
      try_catch_optimized1_test.check_f5(e, "abc");
    }

  };
  dart.fn(try_catch_optimized1_test.f5, dynamicTodynamic());
  try_catch_optimized1_test.check_f5 = function(e, s) {
    if (!dart.equals(e, 42)) dart.throw("ERROR");
    if (!dart.equals(s, "abc")) dart.throw("ERROR");
  };
  dart.fn(try_catch_optimized1_test.check_f5, dynamicAnddynamicTodynamic());
  try_catch_optimized1_test.f6 = function(x, y) {
    let a = x;
    let b = y;
    let c = 123;
    try_catch_optimized1_test.check_f6(42, null, 1, 123, null, 1);
    try {
      try_catch_optimized1_test.maythrow(x);
    } catch (e) {
      try_catch_optimized1_test.check_f6(e, a, b, c, x, y);
    }

  };
  dart.fn(try_catch_optimized1_test.f6, dynamicAnddynamicTodynamic());
  try_catch_optimized1_test.check_f6 = function(e, a, b, c, x, y) {
    if (!dart.equals(e, 42)) dart.throw("ERROR");
    if (a != null) dart.throw("ERROR");
    if (!dart.equals(b, 1)) dart.throw("ERROR");
    if (!dart.equals(c, 123)) dart.throw("ERROR");
    if (x != null) dart.throw("ERROR");
    if (!dart.equals(y, 1)) dart.throw("ERROR");
  };
  dart.fn(try_catch_optimized1_test.check_f6, dynamicAnddynamicAnddynamic__Todynamic());
  try_catch_optimized1_test.f7 = function(str) {
    let d = core.double.parse(str);
    let t = d;
    try {
      let a = d[dartx.toInt]();
      return false;
    } catch (e) {
      if (core.UnsupportedError.is(e)) {
        expect$.Expect.equals(true, core.identical(t, d));
        return true;
      } else
        throw e;
    }

  };
  dart.fn(try_catch_optimized1_test.f7, StringTobool());
  try_catch_optimized1_test.f8 = function(x, a, b) {
    if (a === void 0) a = 3;
    if (b === void 0) b = 4;
    let c = 123;
    let y = a;
    try {
      try_catch_optimized1_test.maythrow(x);
    } catch (e) {
      let s = dart.stackTrace(e);
      try_catch_optimized1_test.check_f8(e, s, a, b, c, x, y);
    }

  };
  dart.fn(try_catch_optimized1_test.f8, dynamic__Todynamic());
  try_catch_optimized1_test.check_f8 = function(e, s, a, b, c, x, y) {
    if (!dart.equals(e, 42)) dart.throw("ERROR");
    if (!core.StackTrace.is(s)) dart.throw("ERROR");
    if (!dart.equals(a, 3)) {
      core.print(a);
      dart.throw("ERROR");
    }
    if (!dart.equals(b, 4)) dart.throw("ERROR");
    if (!dart.equals(c, 123)) dart.throw("ERROR");
    if (x != null) dart.throw("ERROR");
    if (!dart.equals(y, a)) dart.throw("ERROR");
  };
  dart.fn(try_catch_optimized1_test.check_f8, dynamicAnddynamicAnddynamic__Todynamic$());
  try_catch_optimized1_test.f9 = function(x, a, b) {
    if (a === void 0) a = 3;
    if (b === void 0) b = 4;
    let c = 123;
    let y = a;
    try {
      if (dart.test(dart.dsend(x, '<', a))) try_catch_optimized1_test.maythrow(null);
      try_catch_optimized1_test.maythrow(x);
    } catch (e) {
      let s = dart.stackTrace(e);
      try_catch_optimized1_test.check_f9(e, s, a, b, c, x, y);
    }

  };
  dart.fn(try_catch_optimized1_test.f9, dynamic__Todynamic());
  try_catch_optimized1_test.check_f9 = function(e, s, a, b, c, x, y) {
    if (!dart.equals(e, 42)) dart.throw("ERROR");
    if (!core.StackTrace.is(s)) dart.throw("ERROR");
    if (!dart.equals(a, 3)) {
      core.print(a);
      dart.throw("ERROR");
    }
    if (!dart.equals(b, 4)) dart.throw("ERROR");
    if (!dart.equals(c, 123)) dart.throw("ERROR");
    if (x != null) dart.throw("ERROR");
    if (!dart.equals(y, a)) dart.throw("ERROR");
  };
  dart.fn(try_catch_optimized1_test.check_f9, dynamicAnddynamicAnddynamic__Todynamic$());
  try_catch_optimized1_test.f10 = function(x, y) {
    let result = 123;
    try {
      result = core.int._check(try_catch_optimized1_test.maythrow(x));
    } catch (e) {
      expect$.Expect.equals(123, result);
      expect$.Expect.equals(0.5, dart.dsend(y, '/', 2.0));
      result = 0;
    }

    return result;
  };
  dart.fn(try_catch_optimized1_test.f10, dynamicAnddynamicTodynamic());
  try_catch_optimized1_test.f11 = function(x) {
    let result = 123;
    let tmp = x;
    try {
      result = core.int._check(try_catch_optimized1_test.maythrow(x));
      if (dart.notNull(result) > 100) dart.throw(42);
    } catch (e) {
      let s = dart.stackTrace(e);
      expect$.Expect.equals(123, result);
      expect$.Expect.equals(true, core.identical(tmp, x));
      expect$.Expect.equals(true, core.StackTrace.is(s));
      result = 0;
    }

    return result;
  };
  dart.fn(try_catch_optimized1_test.f11, dynamicTodynamic());
  try_catch_optimized1_test.f12 = function(x) {
    if (x === void 0) x = null;
    try {
      try_catch_optimized1_test.maythrow(x);
    } catch (e) {
      try_catch_optimized1_test.check_f12(e, x);
    }

  };
  dart.fn(try_catch_optimized1_test.f12, __Todynamic());
  try_catch_optimized1_test.check_f12 = function(e, x) {
    if (!dart.equals(e, 42)) dart.throw("ERROR");
    if (x != null) dart.throw("ERROR");
  };
  dart.fn(try_catch_optimized1_test.check_f12, dynamicAnddynamicTodynamic());
  try_catch_optimized1_test.f13 = function(x) {
    let result = 123;
    try {
      try {
        result = core.int._check(try_catch_optimized1_test.maythrow(x));
        if (dart.notNull(result) > 100) dart.throw(42);
      } catch (e) {
        expect$.Expect.equals(123, result);
        result = 0;
      }

      try_catch_optimized1_test.maythrow(x);
    } catch (e) {
      result = dart.notNull(result) + 1;
    }

    return result;
  };
  dart.fn(try_catch_optimized1_test.f13, dynamicTodynamic());
  try_catch_optimized1_test.main = function() {
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f1("abc");
    expect$.Expect.equals(99, try_catch_optimized1_test.f1("abc"));
    expect$.Expect.equals(0, try_catch_optimized1_test.f1(null));
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f2("abc");
    expect$.Expect.equals(99, try_catch_optimized1_test.f2("abc"));
    expect$.Expect.equals(null, try_catch_optimized1_test.f2(null));
    try_catch_optimized1_test.f3("123", 0);
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f3(null, 0);
    expect$.Expect.equals(99, try_catch_optimized1_test.f3("123", 0));
    expect$.Expect.equals(1073741824, try_catch_optimized1_test.f3(null, 1073741823));
    try_catch_optimized1_test.f4(null);
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f4(123);
    try_catch_optimized1_test.f4(null);
    try_catch_optimized1_test.f5(null);
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f5(123);
    try_catch_optimized1_test.f5(null);
    try_catch_optimized1_test.f6(null, 1);
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f6(123, 1);
    try_catch_optimized1_test.f6(null, 1);
    try_catch_optimized1_test.f7("1.2");
    try_catch_optimized1_test.f7("Infinity");
    try_catch_optimized1_test.f7("-Infinity");
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f7("1.2");
    expect$.Expect.equals(false, try_catch_optimized1_test.f7("1.2"));
    expect$.Expect.equals(true, try_catch_optimized1_test.f7("Infinity"));
    expect$.Expect.equals(true, try_catch_optimized1_test.f7("-Infinity"));
    expect$.Expect.equals(false, try_catch_optimized1_test.f7("123456789012345"));
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f7("123456789012345");
    expect$.Expect.equals(true, try_catch_optimized1_test.f7("Infinity"));
    expect$.Expect.equals(true, try_catch_optimized1_test.f7("-Infinity"));
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f8(null);
    try_catch_optimized1_test.f8(null);
    try_catch_optimized1_test.f9(5);
    try_catch_optimized1_test.f9(5.0);
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f9(3);
    try_catch_optimized1_test.f9(3);
    let y = 1.0;
    expect$.Expect.equals(0, try_catch_optimized1_test.f10(null, y));
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f10("abc", y);
    expect$.Expect.equals(99, try_catch_optimized1_test.f10("abc", y));
    expect$.Expect.equals(0, try_catch_optimized1_test.f10(null, y));
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f11("abc");
    expect$.Expect.equals(99, try_catch_optimized1_test.f11("abc"));
    expect$.Expect.equals(0, try_catch_optimized1_test.f11(null));
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f12(null);
    try_catch_optimized1_test.f12(null);
    try_catch_optimized1_test.f13(null);
    for (let i = 0; i < 20; i++)
      try_catch_optimized1_test.f13("abc");
    expect$.Expect.equals(99, try_catch_optimized1_test.f13("abc"));
    expect$.Expect.equals(1, try_catch_optimized1_test.f13(null));
  };
  dart.fn(try_catch_optimized1_test.main, VoidTodynamic());
  // Exports:
  exports.try_catch_optimized1_test = try_catch_optimized1_test;
});
