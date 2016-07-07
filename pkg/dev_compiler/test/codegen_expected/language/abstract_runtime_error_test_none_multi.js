dart_library.library('language/abstract_runtime_error_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__abstract_runtime_error_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const abstract_runtime_error_test_none_multi = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  abstract_runtime_error_test_none_multi.Interface = class Interface extends core.Object {};
  abstract_runtime_error_test_none_multi.AbstractClass = class AbstractClass extends core.Object {
    toString() {
      return 'AbstractClass';
    }
  };
  abstract_runtime_error_test_none_multi.ConcreteSubclass = class ConcreteSubclass extends abstract_runtime_error_test_none_multi.AbstractClass {
    toString() {
      return 'ConcreteSubclass';
    }
  };
  abstract_runtime_error_test_none_multi.NonAbstractClass = class NonAbstractClass extends core.Object {
    toString() {
      return 'NonAbstractClass';
    }
  };
  abstract_runtime_error_test_none_multi.NonAbstractClass[dart.implements] = () => [abstract_runtime_error_test_none_multi.Interface];
  abstract_runtime_error_test_none_multi.isAbstractClassInstantiationError = function(e) {
    return core.AbstractClassInstantiationError.is(e);
  };
  dart.fn(abstract_runtime_error_test_none_multi.isAbstractClassInstantiationError, dynamicTobool());
  abstract_runtime_error_test_none_multi.main = function() {
    expect$.Expect.stringEquals('ConcreteSubclass', dart.str`${new abstract_runtime_error_test_none_multi.ConcreteSubclass()}`);
    expect$.Expect.stringEquals('NonAbstractClass', dart.str`${new abstract_runtime_error_test_none_multi.NonAbstractClass()}`);
  };
  dart.fn(abstract_runtime_error_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.abstract_runtime_error_test_none_multi = abstract_runtime_error_test_none_multi;
});
