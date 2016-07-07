dart_library.library('language/map_literal_syntax_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_literal_syntax_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_literal_syntax_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  map_literal_syntax_test.Foo = class Foo extends core.Object {
    new() {
      this.x = dart.map();
      this.y = dart.map({}, core.String, core.int);
      this.z = const$ || (const$ = dart.const(dart.map()));
      this.v = const$0 || (const$0 = dart.const(dart.map({}, core.String, core.int)));
    }
  };
  dart.setSignature(map_literal_syntax_test.Foo, {
    constructors: () => ({new: dart.definiteFunctionType(map_literal_syntax_test.Foo, [])})
  });
  map_literal_syntax_test.main = function() {
    expect$.Expect.equals("{}", dart.toString(new map_literal_syntax_test.Foo().x));
    expect$.Expect.equals("{}", dart.toString(new map_literal_syntax_test.Foo().y));
    expect$.Expect.equals("{}", dart.toString(new map_literal_syntax_test.Foo().z));
    expect$.Expect.equals("{}", dart.toString(new map_literal_syntax_test.Foo().v));
  };
  dart.fn(map_literal_syntax_test.main, VoidTodynamic());
  // Exports:
  exports.map_literal_syntax_test = map_literal_syntax_test;
});
