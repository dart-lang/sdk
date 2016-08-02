dart_library.library('language/call_with_no_such_method_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__call_with_no_such_method_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const call_with_no_such_method_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  call_with_no_such_method_test.F = dart.callableClass(function F(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class F extends core.Object {
    call() {
      return null;
    }
    noSuchMethod(i) {
      if (dart.equals(i.memberName, const$ || (const$ = dart.const(core.Symbol.new('call')))) && dart.test(i.isMethod)) {
        return i.positionalArguments[dartx.get](0);
      }
      return super.noSuchMethod(i);
    }
  });
  dart.setSignature(call_with_no_such_method_test.F, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [])})
  });
  call_with_no_such_method_test.main = function() {
    let result = core.Function.apply(new call_with_no_such_method_test.F(), JSArrayOfString().of(['a', 'b', 'c', 'd']));
    expect$.Expect.equals('a', result);
  };
  dart.fn(call_with_no_such_method_test.main, VoidTodynamic());
  // Exports:
  exports.call_with_no_such_method_test = call_with_no_such_method_test;
});
