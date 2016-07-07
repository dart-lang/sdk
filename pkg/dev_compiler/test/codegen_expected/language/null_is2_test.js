dart_library.library('language/null_is2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_is2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_is2_test = Object.create(null);
  let Test = () => (Test = dart.constFn(null_is2_test.Test$()))();
  let TestOfObject = () => (TestOfObject = dart.constFn(null_is2_test.Test$(core.Object)))();
  let TestOfint = () => (TestOfint = dart.constFn(null_is2_test.Test$(core.int)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  null_is2_test.Test$ = dart.generic(T => {
    class Test extends core.Object {
      foo(a) {
        return T.is(a);
      }
    }
    dart.addTypeTests(Test);
    dart.setSignature(Test, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return Test;
  });
  null_is2_test.Test = Test();
  null_is2_test.main = function() {
    expect$.Expect.isTrue(new (TestOfObject())().foo(null));
    expect$.Expect.isTrue(new null_is2_test.Test().foo(null));
    expect$.Expect.isFalse(new (TestOfint())().foo(null));
    expect$.Expect.isFalse(ListOfObject().is(null));
  };
  dart.fn(null_is2_test.main, VoidTodynamic());
  // Exports:
  exports.null_is2_test = null_is2_test;
});
