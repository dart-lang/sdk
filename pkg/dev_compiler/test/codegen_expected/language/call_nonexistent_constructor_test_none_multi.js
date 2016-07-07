dart_library.library('language/call_nonexistent_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__call_nonexistent_constructor_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const call_nonexistent_constructor_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  call_nonexistent_constructor_test_none_multi.foo = function() {
    dart.throw('hest');
  };
  dart.fn(call_nonexistent_constructor_test_none_multi.foo, VoidTodynamic());
  call_nonexistent_constructor_test_none_multi.A = class A extends core.Object {
    foo(x) {
    }
  };
  dart.defineNamedConstructor(call_nonexistent_constructor_test_none_multi.A, 'foo');
  dart.setSignature(call_nonexistent_constructor_test_none_multi.A, {
    constructors: () => ({foo: dart.definiteFunctionType(call_nonexistent_constructor_test_none_multi.A, [dart.dynamic])})
  });
  call_nonexistent_constructor_test_none_multi.main = function() {
    let i = 0;
    new call_nonexistent_constructor_test_none_multi.A.foo(42);
    try {
    } catch (e$) {
      if (core.NoSuchMethodError.is(e$)) {
        let e = e$;
        i = -1;
      } else if (core.String.is(e$)) {
        let e = e$;
        i = 1;
      } else
        throw e$;
    }

    try {
    } catch (e) {
      if (core.NoSuchMethodError.is(e)) {
        i = 2;
      } else
        throw e;
    }

  };
  dart.fn(call_nonexistent_constructor_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.call_nonexistent_constructor_test_none_multi = call_nonexistent_constructor_test_none_multi;
});
