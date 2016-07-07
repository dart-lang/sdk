dart_library.library('language/deferred_shared_and_unshared_classes_test', null, /* Imports */[
  'dart_sdk',
  'async_helper'
], function load__deferred_shared_and_unshared_classes_test(exports, dart_sdk, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const deferred_shared_and_unshared_classes_test = Object.create(null);
  const deferred_shared_and_unshared_classes_lib1 = Object.create(null);
  const deferred_shared_and_unshared_classes_lib_shared = Object.create(null);
  const deferred_shared_and_unshared_classes_lib2 = Object.create(null);
  let JSArrayOfFuture = () => (JSArrayOfFuture = dart.constFn(_interceptors.JSArray$(async.Future)))();
  let FutureOfList = () => (FutureOfList = dart.constFn(async.Future$(core.List)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToFutureOfList = () => (VoidToFutureOfList = dart.constFn(dart.definiteFunctionType(FutureOfList(), [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_shared_and_unshared_classes_test.main = function() {
    async_helper$.asyncTest(dart.fn(() => async.Future.wait(dart.dynamic)(JSArrayOfFuture().of([loadLibrary().then(dart.dynamic)(dart.fn(_ => {
        deferred_shared_and_unshared_classes_lib1.foo();
      }, dynamicTodynamic())), loadLibrary().then(dart.dynamic)(dart.fn(_ => {
        deferred_shared_and_unshared_classes_lib2.foo();
      }, dynamicTodynamic()))])), VoidToFutureOfList()));
  };
  dart.fn(deferred_shared_and_unshared_classes_test.main, VoidTovoid());
  deferred_shared_and_unshared_classes_lib1.foo = function() {
    core.print(new deferred_shared_and_unshared_classes_lib_shared.C1());
    core.print(new deferred_shared_and_unshared_classes_lib_shared.CShared());
  };
  dart.fn(deferred_shared_and_unshared_classes_lib1.foo, VoidTodynamic());
  deferred_shared_and_unshared_classes_lib_shared.CShared = class CShared extends core.Object {
    toString() {
      return "shared";
    }
  };
  deferred_shared_and_unshared_classes_lib_shared.C1 = class C1 extends core.Object {
    toString() {
      return "C1";
    }
  };
  deferred_shared_and_unshared_classes_lib_shared.C2 = class C2 extends core.Object {
    toString() {
      return "C2";
    }
  };
  deferred_shared_and_unshared_classes_lib2.foo = function() {
    core.print(new deferred_shared_and_unshared_classes_lib_shared.C2());
    core.print(new deferred_shared_and_unshared_classes_lib_shared.CShared());
  };
  dart.fn(deferred_shared_and_unshared_classes_lib2.foo, VoidTodynamic());
  // Exports:
  exports.deferred_shared_and_unshared_classes_test = deferred_shared_and_unshared_classes_test;
  exports.deferred_shared_and_unshared_classes_lib1 = deferred_shared_and_unshared_classes_lib1;
  exports.deferred_shared_and_unshared_classes_lib_shared = deferred_shared_and_unshared_classes_lib_shared;
  exports.deferred_shared_and_unshared_classes_lib2 = deferred_shared_and_unshared_classes_lib2;
});
