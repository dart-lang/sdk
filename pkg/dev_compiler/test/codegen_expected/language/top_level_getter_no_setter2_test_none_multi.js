dart_library.library('language/top_level_getter_no_setter2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__top_level_getter_no_setter2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const top_level_getter_no_setter2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  top_level_getter_no_setter2_test_none_multi.getter_visited = false;
  dart.defineLazy(top_level_getter_no_setter2_test_none_multi, {
    get getter() {
      return core.int._check(dart.fn(() => {
        top_level_getter_no_setter2_test_none_multi.getter_visited = true;
      }, VoidTodynamic())());
    }
  });
  top_level_getter_no_setter2_test_none_multi.Class = class Class extends core.Object {
    method() {
      try {
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          return;
        } else
          throw e;
      }

    }
  };
  dart.setSignature(top_level_getter_no_setter2_test_none_multi.Class, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [])})
  });
  top_level_getter_no_setter2_test_none_multi.main = function() {
    new top_level_getter_no_setter2_test_none_multi.Class().method();
  };
  dart.fn(top_level_getter_no_setter2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.top_level_getter_no_setter2_test_none_multi = top_level_getter_no_setter2_test_none_multi;
});
