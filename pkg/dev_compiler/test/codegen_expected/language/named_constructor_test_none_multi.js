dart_library.library('language/named_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_constructor_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_constructor_test_none_multi = Object.create(null);
  const named_constructor_lib = Object.create(null);
  let Class = () => (Class = dart.constFn(named_constructor_test_none_multi.Class$()))();
  let ClassOfint = () => (ClassOfint = dart.constFn(named_constructor_test_none_multi.Class$(core.int)))();
  let ClassOfint$ = () => (ClassOfint$ = dart.constFn(named_constructor_lib.Class$(core.int)))();
  let Class$ = () => (Class$ = dart.constFn(named_constructor_lib.Class$()))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  named_constructor_test_none_multi.Class$ = dart.generic(T => {
    class Class extends core.Object {
      new() {
        this.value = 0;
      }
      named() {
        this.value = 1;
      }
    }
    dart.addTypeTests(Class);
    dart.defineNamedConstructor(Class, 'named');
    dart.setSignature(Class, {
      constructors: () => ({
        new: dart.definiteFunctionType(named_constructor_test_none_multi.Class$(T), []),
        named: dart.definiteFunctionType(named_constructor_test_none_multi.Class$(T), [])
      })
    });
    return Class;
  });
  named_constructor_test_none_multi.Class = Class();
  named_constructor_test_none_multi.main = function() {
    expect$.Expect.equals(0, new named_constructor_test_none_multi.Class().value);
    expect$.Expect.equals(0, new (ClassOfint())().value);
    expect$.Expect.equals(1, new named_constructor_test_none_multi.Class.named().value);
    expect$.Expect.equals(1, new (ClassOfint()).named().value);
    expect$.Expect.equals(2, new named_constructor_lib.Class().value);
    expect$.Expect.equals(2, new (ClassOfint$())().value);
    expect$.Expect.equals(3, new named_constructor_lib.Class.named().value);
    expect$.Expect.equals(3, new (ClassOfint$()).named().value);
  };
  dart.fn(named_constructor_test_none_multi.main, VoidTovoid());
  named_constructor_lib.Class$ = dart.generic(T => {
    class Class extends core.Object {
      new() {
        this.value = 2;
      }
      named() {
        this.value = 3;
      }
    }
    dart.addTypeTests(Class);
    dart.defineNamedConstructor(Class, 'named');
    dart.setSignature(Class, {
      constructors: () => ({
        new: dart.definiteFunctionType(named_constructor_lib.Class$(T), []),
        named: dart.definiteFunctionType(named_constructor_lib.Class$(T), [])
      })
    });
    return Class;
  });
  named_constructor_lib.Class = Class$();
  // Exports:
  exports.named_constructor_test_none_multi = named_constructor_test_none_multi;
  exports.named_constructor_lib = named_constructor_lib;
});
