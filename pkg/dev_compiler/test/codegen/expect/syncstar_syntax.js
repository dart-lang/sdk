dart_library.library('syncstar_syntax', null, /* Imports */[
  "dart_runtime/dart",
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  function* foo() {
    yield 1;
    yield* dart.list([2, 3], core.int);
  }
  dart.fn(foo, core.Iterable$(core.int), []);
  class Class extends core.Object {
    *bar() {
      yield 1;
      yield* dart.list([2, 3], core.int);
    }
    static *baz() {
      yield 1;
      yield* dart.list([2, 3], core.int);
    }
  }
  dart.setSignature(Class, {
    methods: () => ({bar: [core.Iterable$(core.int), []]}),
    statics: () => ({baz: [core.Iterable$(core.int), []]}),
    names: ['baz']
  });
  function main() {
    function* qux() {
      yield 1;
      yield* dart.list([2, 3], core.int);
    }
    dart.fn(qux, core.Iterable$(core.int), []);
    foo()[dartx.forEach](core.print);
    new Class().bar()[dartx.forEach](core.print);
    Class.baz()[dartx.forEach](core.print);
    qux()[dartx.forEach](core.print);
  }
  dart.fn(main);
  // Exports:
  exports.foo = foo;
  exports.Class = Class;
  exports.main = main;
});
