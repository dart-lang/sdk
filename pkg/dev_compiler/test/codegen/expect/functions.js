dart_library.library('functions', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const functions = Object.create(null);
  functions.bootstrap = function() {
    return dart.list([new functions.Foo()], functions.Foo);
  };
  dart.lazyFn(functions.bootstrap, () => [core.List$(functions.Foo), []]);
  functions.A2B$ = dart.generic((A, B) => {
    const A2B = dart.typedef('A2B', () => dart.functionType(B, [A]));
    return A2B;
  });
  functions.A2B = functions.A2B$();
  functions.id = function(f) {
    return f;
  };
  dart.lazyFn(functions.id, () => [functions.A2B$(functions.Foo, functions.Foo), [functions.A2B$(functions.Foo, functions.Foo)]]);
  functions.Foo = class Foo extends core.Object {};
  functions.main = function() {
    core.print(functions.bootstrap()[dartx.get](0));
  };
  dart.fn(functions.main, dart.void, []);
  // Exports:
  exports.functions = functions;
});
