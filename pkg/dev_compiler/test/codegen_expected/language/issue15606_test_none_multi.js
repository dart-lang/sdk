dart_library.library('language/issue15606_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__issue15606_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue15606_test_none_multi = Object.create(null);
  let Foo = () => (Foo = dart.constFn(issue15606_test_none_multi.Foo$()))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue15606_test_none_multi.Foo$ = dart.generic(T => {
    class Foo extends core.Object {}
    dart.addTypeTests(Foo);
    return Foo;
  });
  issue15606_test_none_multi.Foo = Foo();
  dart.defineLazy(issue15606_test_none_multi, {
    get a() {
      return JSArrayOfObject().of([new core.Object(), 42]);
    },
    set a(_) {}
  });
  issue15606_test_none_multi.main = function() {
    while (false) {
    }
  };
  dart.fn(issue15606_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.issue15606_test_none_multi = issue15606_test_none_multi;
});
