dart_library.library('language/compile_time_constant_o_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_o_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_o_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_o_test_none_multi.str = "foo";
  compile_time_constant_o_test_none_multi.m1 = dart.const(dart.map({foo: 499}));
  compile_time_constant_o_test_none_multi.m2 = dart.const(dart.map({[dart.str`${compile_time_constant_o_test_none_multi.str}`]: 499}));
  compile_time_constant_o_test_none_multi.m3 = dart.const(dart.map({foo: 499}));
  compile_time_constant_o_test_none_multi.m4 = dart.const(dart.map({[dart.str`${compile_time_constant_o_test_none_multi.str}`]: 499}));
  compile_time_constant_o_test_none_multi.m5 = dart.const(dart.map({["f" + "o" + "o"]: 499}));
  compile_time_constant_o_test_none_multi.mm1 = dart.const(dart.map({"afoo#foo": 499}));
  compile_time_constant_o_test_none_multi.mm2 = dart.const(dart.map({[dart.str`a${compile_time_constant_o_test_none_multi.str}#${compile_time_constant_o_test_none_multi.str}`]: 499}));
  compile_time_constant_o_test_none_multi.mm3 = dart.const(dart.map({["a" + dart.str`${compile_time_constant_o_test_none_multi.str}` + "#" + "foo"]: 499}));
  compile_time_constant_o_test_none_multi.mm4 = dart.const(dart.map({[dart.str`a${compile_time_constant_o_test_none_multi.str}` + dart.str`#${compile_time_constant_o_test_none_multi.str}`]: 499}));
  compile_time_constant_o_test_none_multi.main = function() {
    expect$.Expect.equals(1, compile_time_constant_o_test_none_multi.m1[dartx.length]);
    expect$.Expect.equals(499, compile_time_constant_o_test_none_multi.m1[dartx.get]("foo"));
    expect$.Expect.identical(compile_time_constant_o_test_none_multi.m1, compile_time_constant_o_test_none_multi.m2);
    expect$.Expect.identical(compile_time_constant_o_test_none_multi.m1, compile_time_constant_o_test_none_multi.m3);
    expect$.Expect.identical(compile_time_constant_o_test_none_multi.m1, compile_time_constant_o_test_none_multi.m4);
    expect$.Expect.identical(compile_time_constant_o_test_none_multi.m1, compile_time_constant_o_test_none_multi.m5);
    expect$.Expect.equals(1, compile_time_constant_o_test_none_multi.mm1[dartx.length]);
    expect$.Expect.equals(499, compile_time_constant_o_test_none_multi.mm1[dartx.get]("afoo#foo"));
    expect$.Expect.identical(compile_time_constant_o_test_none_multi.mm1, compile_time_constant_o_test_none_multi.mm2);
    expect$.Expect.identical(compile_time_constant_o_test_none_multi.mm1, compile_time_constant_o_test_none_multi.mm3);
    expect$.Expect.identical(compile_time_constant_o_test_none_multi.mm1, compile_time_constant_o_test_none_multi.mm4);
  };
  dart.fn(compile_time_constant_o_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_o_test_none_multi = compile_time_constant_o_test_none_multi;
});
