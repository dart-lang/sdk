dart_library.library('language/no_such_method_subtype_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__no_such_method_subtype_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const no_such_method_subtype_test = Object.create(null);
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(no_such_method_subtype_test.A)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  no_such_method_subtype_test.A = class A extends core.Object {
    foo() {
      return 42;
    }
  };
  dart.setSignature(no_such_method_subtype_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  no_such_method_subtype_test.B = class B extends core.Object {
    noSuchMethod(im) {
      return 84;
    }
    foo(...args) {
      return this.noSuchMethod(new dart.InvocationImpl('foo', args, {isMethod: true}));
    }
  };
  no_such_method_subtype_test.B[dart.implements] = () => [no_such_method_subtype_test.A];
  no_such_method_subtype_test.main = function() {
    let a = JSArrayOfA().of([new no_such_method_subtype_test.A(), new no_such_method_subtype_test.B()]);
    let b = a[dartx.get](1);
    if (no_such_method_subtype_test.A.is(b)) {
      expect$.Expect.equals(84, b.foo());
      return;
    }
    expect$.Expect.fail('Should not be here');
  };
  dart.fn(no_such_method_subtype_test.main, VoidTodynamic());
  // Exports:
  exports.no_such_method_subtype_test = no_such_method_subtype_test;
});
