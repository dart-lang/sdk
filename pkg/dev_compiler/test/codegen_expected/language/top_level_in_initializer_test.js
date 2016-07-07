dart_library.library('language/top_level_in_initializer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__top_level_in_initializer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const top_level_in_initializer_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  top_level_in_initializer_test.topLevelField = 1;
  top_level_in_initializer_test.topLevelMethod = function() {
    return 1;
  };
  dart.fn(top_level_in_initializer_test.topLevelMethod, VoidTodynamic());
  dart.copyProperties(top_level_in_initializer_test, {
    get topLevelGetter() {
      return 1;
    }
  });
  top_level_in_initializer_test.Foo = class Foo extends core.Object {
    one() {
      this.x = top_level_in_initializer_test.topLevelField;
    }
    second() {
      this.x = top_level_in_initializer_test.topLevelMethod;
    }
    third() {
      this.x = top_level_in_initializer_test.topLevelGetter;
    }
  };
  dart.defineNamedConstructor(top_level_in_initializer_test.Foo, 'one');
  dart.defineNamedConstructor(top_level_in_initializer_test.Foo, 'second');
  dart.defineNamedConstructor(top_level_in_initializer_test.Foo, 'third');
  dart.setSignature(top_level_in_initializer_test.Foo, {
    constructors: () => ({
      one: dart.definiteFunctionType(top_level_in_initializer_test.Foo, []),
      second: dart.definiteFunctionType(top_level_in_initializer_test.Foo, []),
      third: dart.definiteFunctionType(top_level_in_initializer_test.Foo, [])
    })
  });
  top_level_in_initializer_test.main = function() {
    expect$.Expect.equals(top_level_in_initializer_test.topLevelField, new top_level_in_initializer_test.Foo.one().x);
    expect$.Expect.equals(top_level_in_initializer_test.topLevelMethod(), dart.dsend(new top_level_in_initializer_test.Foo.second(), 'x'));
    expect$.Expect.equals(top_level_in_initializer_test.topLevelGetter, new top_level_in_initializer_test.Foo.third().x);
  };
  dart.fn(top_level_in_initializer_test.main, VoidTodynamic());
  // Exports:
  exports.top_level_in_initializer_test = top_level_in_initializer_test;
});
