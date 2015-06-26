dart_library.library('syncstar_yieldstar_test', null, /* Imports */[
  "dart_runtime/dart",
  'dart/core',
  'expect'
], /* Lazy imports */[
], function(exports, dart, core, expect) {
  'use strict';
  let dartx = dart.dartx;
  function* bar() {
    let i = 1;
    let j = 1;
    while (true) {
      yield i;
      j = dart.notNull(i) + dart.notNull(j);
      i = dart.notNull(j) - dart.notNull(i);
    }
  }
  dart.fn(bar);
  function* foo() {
    yield* [1, 2, 3];
    yield null;
    yield* dart.as(bar(), core.Iterable);
  }
  dart.fn(foo);
  function main() {
    expect.Expect.listEquals([1, 2, 3, null, 1, 1, 2, 3, 5], dart.as(dart.dsend(dart.dsend(foo(), 'take', 9), 'toList'), core.List));
  }
  dart.fn(main);
  // Exports:
  exports.bar = bar;
  exports.foo = foo;
  exports.main = main;
});
