dart_library.library('language/no_such_method_native_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__no_such_method_native_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const no_such_method_native_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ObjectTodynamic = () => (ObjectTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.Object])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  no_such_method_native_test.invocation = null;
  no_such_method_native_test.C = class C extends core.Object {
    noSuchMethod(i) {
      no_such_method_native_test.invocation = i;
      return 42;
    }
  };
  no_such_method_native_test.expectNSME = function(d) {
    try {
      dart.noSuchMethod(d, no_such_method_native_test.invocation);
    } catch (e) {
      if (core.NoSuchMethodError.is(e)) {
        expect$.Expect.isTrue(dart.toString(e)[dartx.contains]('foobar'));
      } else
        throw e;
    }

  };
  dart.fn(no_such_method_native_test.expectNSME, ObjectTodynamic());
  let const$;
  no_such_method_native_test.main = function() {
    let c = new no_such_method_native_test.C();
    expect$.Expect.equals(42, dart.dsend(c, 'foobar', 123));
    expect$.Expect.equals(no_such_method_native_test.invocation.memberName, const$ || (const$ = dart.const(core.Symbol.new('foobar'))));
    expect$.Expect.listEquals(no_such_method_native_test.invocation.positionalArguments, JSArrayOfint().of([123]));
    no_such_method_native_test.expectNSME(null);
    no_such_method_native_test.expectNSME(777);
    no_such_method_native_test.expectNSME('hello');
  };
  dart.fn(no_such_method_native_test.main, VoidTodynamic());
  // Exports:
  exports.no_such_method_native_test = no_such_method_native_test;
});
