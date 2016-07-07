dart_library.library('language/function_type_alias6_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_type_alias6_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_type_alias6_test_none_multi = Object.create(null);
  let ListOfF = () => (ListOfF = dart.constFn(core.List$(function_type_alias6_test_none_multi.F)))();
  let ListTodynamic = () => (ListTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List])))();
  let ListOfFTodynamic = () => (ListOfFTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [ListOfF()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_alias6_test_none_multi.F = dart.typedef('F', () => dart.functionType(dart.dynamic, [core.List]));
  function_type_alias6_test_none_multi.C = dart.typedef('C', () => dart.functionType(function_type_alias6_test_none_multi.D, []));
  function_type_alias6_test_none_multi.D = class D extends core.Object {
    foo() {}
    bar() {}
  };
  dart.setSignature(function_type_alias6_test_none_multi.D, {
    methods: () => ({
      foo: dart.definiteFunctionType(function_type_alias6_test_none_multi.C, []),
      bar: dart.definiteFunctionType(function_type_alias6_test_none_multi.D, [])
    })
  });
  function_type_alias6_test_none_multi.main = function() {
    let f = dart.fn(x => {
    }, ListTodynamic());
    expect$.Expect.isTrue(function_type_alias6_test_none_multi.F.is(f));
    let g = dart.fn(x => {
    }, ListOfFTodynamic());
    expect$.Expect.isTrue(function_type_alias6_test_none_multi.F.is(g));
    let d = new function_type_alias6_test_none_multi.D();
    expect$.Expect.isTrue(!function_type_alias6_test_none_multi.C.is(dart.bind(d, 'foo')));
    expect$.Expect.isTrue(function_type_alias6_test_none_multi.C.is(dart.bind(d, 'bar')));
  };
  dart.fn(function_type_alias6_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.function_type_alias6_test_none_multi = function_type_alias6_test_none_multi;
});
