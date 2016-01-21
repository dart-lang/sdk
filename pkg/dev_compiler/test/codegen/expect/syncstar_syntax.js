dart_library.library('syncstar_syntax', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, core, expect) {
  'use strict';
  let dartx = dart.dartx;
  function foo() {
    return dart.syncStar(function*() {
      yield 1;
      yield* dart.list([2, 3], core.int);
    }, core.int);
  }
  dart.fn(foo, core.Iterable$(core.int), []);
  class Class extends core.Object {
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
  }
  dart.setSignature(Class, {
    methods: () => ({bar: [core.Iterable$(core.int), []]}),
    statics: () => ({baz: [core.Iterable$(core.int), []]}),
    names: ['baz']
  });
  function main() {
    function qux() {
      return dart.syncStar(function*() {
        yield 1;
        yield* dart.list([2, 3], core.int);
      }, core.int);
    }
    dart.fn(qux, core.Iterable$(core.int), []);
    expect.Expect.listEquals([1, 2, 3], foo()[dartx.toList]());
    expect.Expect.listEquals([1, 2, 3], new Class().bar()[dartx.toList]());
    expect.Expect.listEquals([1, 2, 3], Class.baz()[dartx.toList]());
    expect.Expect.listEquals([1, 2, 3], qux()[dartx.toList]());
  }
  dart.fn(main);
  // Exports:
  exports.foo = foo;
  exports.Class = Class;
  exports.main = main;
});
