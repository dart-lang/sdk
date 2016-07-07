dart_library.library('language/const_conditional_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_conditional_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_conditional_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const_conditional_test_none_multi.Marker = class Marker extends core.Object {
    new(field) {
      this.field = field;
    }
  };
  dart.setSignature(const_conditional_test_none_multi.Marker, {
    constructors: () => ({new: dart.definiteFunctionType(const_conditional_test_none_multi.Marker, [dart.dynamic])})
  });
  const_conditional_test_none_multi.var0 = dart.const(new const_conditional_test_none_multi.Marker(0));
  const_conditional_test_none_multi.var1 = dart.const(new const_conditional_test_none_multi.Marker(1));
  const_conditional_test_none_multi.const0 = dart.const(new const_conditional_test_none_multi.Marker(0));
  const_conditional_test_none_multi.const1 = dart.const(new const_conditional_test_none_multi.Marker(1));
  const_conditional_test_none_multi.trueConst = true;
  const_conditional_test_none_multi.falseConst = false;
  const_conditional_test_none_multi.nonConst = true;
  const_conditional_test_none_multi.zeroConst = 0;
  const_conditional_test_none_multi.cond1 = const_conditional_test_none_multi.trueConst ? const_conditional_test_none_multi.const0 : const_conditional_test_none_multi.const1;
  const_conditional_test_none_multi.cond2 = const_conditional_test_none_multi.falseConst ? const_conditional_test_none_multi.const0 : const_conditional_test_none_multi.const1;
  const_conditional_test_none_multi.main = function() {
    expect$.Expect.identical(const_conditional_test_none_multi.var0, const_conditional_test_none_multi.cond1);
    expect$.Expect.identical(const_conditional_test_none_multi.var1, const_conditional_test_none_multi.cond2);
  };
  dart.fn(const_conditional_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.const_conditional_test_none_multi = const_conditional_test_none_multi;
});
