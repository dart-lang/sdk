dart_library.library('language/getter_no_setter2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__getter_no_setter2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const getter_no_setter2_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  getter_no_setter2_test_none_multi.Example = class Example extends core.Object {
    static get nextVar() {
      return (() => {
        let x = getter_no_setter2_test_none_multi.Example._var;
        getter_no_setter2_test_none_multi.Example._var = dart.notNull(x) + 1;
        return x;
      })();
    }
    new() {
      {
        let flag_exception = false;
        try {
        } catch (excpt) {
          flag_exception = true;
        }

      }
      {
        let flag_exception = false;
        try {
        } catch (excpt) {
          flag_exception = true;
        }

      }
    }
    static test() {}
  };
  dart.setSignature(getter_no_setter2_test_none_multi.Example, {
    constructors: () => ({new: dart.definiteFunctionType(getter_no_setter2_test_none_multi.Example, [])}),
    statics: () => ({test: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['test']
  });
  getter_no_setter2_test_none_multi.Example._var = 1;
  getter_no_setter2_test_none_multi.Example1 = class Example1 extends core.Object {
    new(i) {
    }
  };
  dart.setSignature(getter_no_setter2_test_none_multi.Example1, {
    constructors: () => ({new: dart.definiteFunctionType(getter_no_setter2_test_none_multi.Example1, [core.int])})
  });
  getter_no_setter2_test_none_multi.Example2 = class Example2 extends getter_no_setter2_test_none_multi.Example1 {
    static get nextVar() {
      return (() => {
        let x = getter_no_setter2_test_none_multi.Example2._var;
        getter_no_setter2_test_none_multi.Example2._var = dart.notNull(x) + 1;
        return x;
      })();
    }
    new() {
      super.new(getter_no_setter2_test_none_multi.Example2.nextVar);
    }
  };
  dart.setSignature(getter_no_setter2_test_none_multi.Example2, {
    constructors: () => ({new: dart.definiteFunctionType(getter_no_setter2_test_none_multi.Example2, [])})
  });
  getter_no_setter2_test_none_multi.Example2._var = 1;
  getter_no_setter2_test_none_multi.main = function() {
    let x = new getter_no_setter2_test_none_multi.Example();
    getter_no_setter2_test_none_multi.Example.test();
    let x2 = new getter_no_setter2_test_none_multi.Example2();
  };
  dart.fn(getter_no_setter2_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.getter_no_setter2_test_none_multi = getter_no_setter2_test_none_multi;
});
