dart_library.library('language/deferred_type_dependency_test_is_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deferred_type_dependency_test_is_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deferred_type_dependency_test_is_multi = Object.create(null);
  const deferred_type_dependency_lib1 = Object.create(null);
  const deferred_type_dependency_lib3 = Object.create(null);
  const deferred_type_dependency_lib2 = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  deferred_type_dependency_test_is_multi.main = function() {
    return dart.async(function*() {
      yield loadLibrary();
      expect$.Expect.isFalse(deferred_type_dependency_lib1.fooIs("string"));
      yield loadLibrary();
      expect$.Expect.isTrue(deferred_type_dependency_lib1.fooIs(deferred_type_dependency_lib2.getInstance()));
    }, dart.dynamic);
  };
  dart.fn(deferred_type_dependency_test_is_multi.main, VoidTodynamic());
  deferred_type_dependency_lib1.fooIs = function(x) {
    return deferred_type_dependency_lib3.A.is(x);
  };
  dart.fn(deferred_type_dependency_lib1.fooIs, dynamicTobool());
  deferred_type_dependency_lib1.fooAs = function(x) {
    try {
      return deferred_type_dependency_lib3.A.as(x).p;
    } catch (e) {
      if (core.CastError.is(e)) {
        return false;
      } else
        throw e;
    }

  };
  dart.fn(deferred_type_dependency_lib1.fooAs, dynamicTobool());
  deferred_type_dependency_lib1.fooAnnotation = function(x) {
    try {
      let y = deferred_type_dependency_lib3.A._check(x);
      return !(typeof y == 'string');
    } catch (e) {
      if (core.TypeError.is(e)) {
        return false;
      } else
        throw e;
    }

  };
  dart.fn(deferred_type_dependency_lib1.fooAnnotation, dynamicTobool());
  deferred_type_dependency_lib3.A = class A extends core.Object {
    new() {
      this.p = true;
    }
  };
  deferred_type_dependency_lib2.getInstance = function() {
    return new deferred_type_dependency_lib3.A();
  };
  dart.fn(deferred_type_dependency_lib2.getInstance, VoidTodynamic());
  // Exports:
  exports.deferred_type_dependency_test_is_multi = deferred_type_dependency_test_is_multi;
  exports.deferred_type_dependency_lib1 = deferred_type_dependency_lib1;
  exports.deferred_type_dependency_lib3 = deferred_type_dependency_lib3;
  exports.deferred_type_dependency_lib2 = deferred_type_dependency_lib2;
});
