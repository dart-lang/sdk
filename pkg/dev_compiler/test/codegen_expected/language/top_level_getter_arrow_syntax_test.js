dart_library.library('language/top_level_getter_arrow_syntax_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__top_level_getter_arrow_syntax_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const top_level_getter_arrow_syntax_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.copyProperties(top_level_getter_arrow_syntax_test, {
    get getter() {
      return 42;
    }
  });
  dart.copyProperties(top_level_getter_arrow_syntax_test, {
    get lgetter() {
      return null;
    }
  });
  dart.copyProperties(top_level_getter_arrow_syntax_test, {
    get two_wrongs() {
      return !true;
    }
  });
  top_level_getter_arrow_syntax_test.main = function() {
    expect$.Expect.equals(42, top_level_getter_arrow_syntax_test.getter);
    expect$.Expect.equals(null, top_level_getter_arrow_syntax_test.lgetter);
    expect$.Expect.equals(false, top_level_getter_arrow_syntax_test.two_wrongs);
  };
  dart.fn(top_level_getter_arrow_syntax_test.main, VoidTodynamic());
  // Exports:
  exports.top_level_getter_arrow_syntax_test = top_level_getter_arrow_syntax_test;
});
