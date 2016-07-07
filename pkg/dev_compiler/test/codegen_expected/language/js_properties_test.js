dart_library.library('language/js_properties_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__js_properties_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const js_properties_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  js_properties_test.main = function() {
    expect$.Expect.equals(42, new js_properties_test.__defineGetter__().hello());
    expect$.Expect.equals(42, new js_properties_test.__defineSetter__().hello());
    expect$.Expect.equals(42, new js_properties_test.__lookupGetter__().hello());
    expect$.Expect.equals(42, new js_properties_test.__lookupSetter__().hello());
    expect$.Expect.equals(42, new js_properties_test.constructor().hello());
    expect$.Expect.equals(42, new js_properties_test.hasOwnProperty().hello());
    expect$.Expect.equals(42, new js_properties_test.isPrototypeOf().hello());
    expect$.Expect.equals(42, new js_properties_test.propertyIsEnumerable().hello());
    expect$.Expect.equals(42, new js_properties_test.toLocaleString().hello());
    expect$.Expect.equals(42, new js_properties_test.toString().hello());
    expect$.Expect.equals(42, new js_properties_test.valueOf().hello());
  };
  dart.fn(js_properties_test.main, VoidTovoid());
  js_properties_test.Hello = class Hello extends core.Object {
    hello() {
      return 42;
    }
  };
  dart.setSignature(js_properties_test.Hello, {
    methods: () => ({hello: dart.definiteFunctionType(core.int, [])})
  });
  js_properties_test.__defineGetter__ = class __defineGetter__ extends js_properties_test.Hello {};
  js_properties_test.__defineSetter__ = class __defineSetter__ extends js_properties_test.Hello {};
  js_properties_test.__lookupGetter__ = class __lookupGetter__ extends js_properties_test.Hello {};
  js_properties_test.__lookupSetter__ = class __lookupSetter__ extends js_properties_test.Hello {};
  js_properties_test.constructor = class constructor extends js_properties_test.Hello {};
  js_properties_test.hasOwnProperty = class hasOwnProperty extends js_properties_test.Hello {};
  js_properties_test.isPrototypeOf = class isPrototypeOf extends js_properties_test.Hello {};
  js_properties_test.propertyIsEnumerable = class propertyIsEnumerable extends js_properties_test.Hello {};
  js_properties_test.toLocaleString = class toLocaleString extends js_properties_test.Hello {};
  js_properties_test.toString = class toString extends js_properties_test.Hello {};
  js_properties_test.valueOf = class valueOf extends js_properties_test.Hello {};
  // Exports:
  exports.js_properties_test = js_properties_test;
});
