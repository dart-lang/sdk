dart_library.library('syncstar_syntax', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const syncstar_syntax = Object.create(null);
  syncstar_syntax.foo = function() {
    return dart.syncStar(function*() {
      yield 1;
      yield* dart.list([2, 3], core.int);
    }, core.int);
  };
  dart.fn(syncstar_syntax.foo, core.Iterable$(core.int), []);
  syncstar_syntax.Class = class Class extends core.Object {
    bar() {
      return dart.syncStar(function*() {
        yield 1;
        yield* dart.list([2, 3], core.int);
      }, core.int);
    }
    static baz() {
      return dart.syncStar(function*() {
        yield 1;
        yield* dart.list([2, 3], core.int);
      }, core.int);
    }
  };
  dart.setSignature(syncstar_syntax.Class, {
    methods: () => ({bar: [core.Iterable$(core.int), []]}),
    statics: () => ({baz: [core.Iterable$(core.int), []]}),
    names: ['baz']
  });
  syncstar_syntax.main = function() {
    function qux() {
      return dart.syncStar(function*() {
        yield 1;
        yield* dart.list([2, 3], core.int);
      }, core.int);
    }
    dart.fn(qux, core.Iterable$(core.int), []);
    expect$.Expect.listEquals(dart.list([1, 2, 3], core.int), syncstar_syntax.foo()[dartx.toList]());
    expect$.Expect.listEquals(dart.list([1, 2, 3], core.int), new syncstar_syntax.Class().bar()[dartx.toList]());
    expect$.Expect.listEquals(dart.list([1, 2, 3], core.int), syncstar_syntax.Class.baz()[dartx.toList]());
    expect$.Expect.listEquals(dart.list([1, 2, 3], core.int), qux()[dartx.toList]());
  };
  dart.fn(syncstar_syntax.main);
  // Exports:
  exports.syncstar_syntax = syncstar_syntax;
});
