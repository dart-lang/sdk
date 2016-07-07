dart_library.library('language/list_literal_syntax_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_literal_syntax_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_literal_syntax_test_none_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  list_literal_syntax_test_none_multi.I = class I extends core.Object {};
  list_literal_syntax_test_none_multi.main = function() {
    let list = null;
    list = JSArrayOfint().of([0]);
    expect$.Expect.equals(1, dart.dload(list, 'length'));
    list = JSArrayOfint().of([0]);
    expect$.Expect.equals(1, dart.dload(list, 'length'));
    list = JSArrayOfint().of([0]);
    expect$.Expect.equals(1, dart.dload(list, 'length'));
    list = JSArrayOfint().of([0]);
    expect$.Expect.equals(1, dart.dload(list, 'length'));
    list = JSArrayOfint().of([0]);
    expect$.Expect.equals(1, dart.dload(list, 'length'));
    list = JSArrayOfint().of([0]);
    expect$.Expect.equals(1, dart.dload(list, 'length'));
    list = JSArrayOfint().of([0]);
    expect$.Expect.equals(1, dart.dload(list, 'length'));
    list = JSArrayOfint().of([JSArrayOfint().of([JSArrayOfint().of([1])[dartx.get](0)])[dartx.get](0)]);
    expect$.Expect.equals(1, dart.dload(list, 'length'));
    expect$.Expect.equals(1, dart.dindex(list, 0));
    list = JSArrayOfint().of([JSArrayOfListOfint().of([JSArrayOfint().of([1])])[dartx.get](0)[dartx.get](0)]);
    expect$.Expect.equals(1, dart.dload(list, 'length'));
    expect$.Expect.equals(1, dart.dindex(list, 0));
  };
  dart.fn(list_literal_syntax_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.list_literal_syntax_test_none_multi = list_literal_syntax_test_none_multi;
});
