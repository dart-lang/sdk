dart_library.library('syncstar_yield_test', null, /* Imports */[
  "dart_runtime/dart",
  'dart/core',
  'expect'
], /* Lazy imports */[
], function(exports, dart, core, expect) {
  'use strict';
  let dartx = dart.dartx;
  function* foo1() {
    yield 1;
  }
  dart.fn(foo1, core.Iterable$(core.int), []);
  function* foo2(p) {
    let t = false;
    yield null;
    while (true) {
      a:
        for (let i = 0; dart.notNull(i) < dart.notNull(dart.as(p, core.num)); i = dart.notNull(i) + 1) {
          if (!dart.notNull(t)) {
            for (let j = 0; dart.notNull(j) < 3; j = dart.notNull(j) + 1) {
              yield -1;
              t = true;
              break a;
            }
          }
          yield i;
        }
    }
  }
  dart.fn(foo2, core.Iterable$(core.int), [dart.dynamic]);
  function* foo3(p) {
    let i = 0;
    i = dart.notNull(i) + 1;
    p = dart.notNull(p) + 1;
    yield dart.notNull(p) + dart.notNull(i);
  }
  dart.fn(foo3, core.Iterable$(core.int), [core.int]);
  function main() {
    expect.Expect.listEquals([1], foo1()[dartx.toList]());
    expect.Expect.listEquals([null, -1, 0, 1, 2, 3, 0, 1, 2, 3], foo2(4)[dartx.take](10)[dartx.toList]());
    let t = foo3(0);
    let it1 = t[dartx.iterator];
    let it2 = t[dartx.iterator];
    it1.moveNext();
    it2.moveNext();
    expect.Expect.equals(2, it1.current);
    expect.Expect.equals(2, it2.current);
    expect.Expect.isFalse(it1.moveNext());
    expect.Expect.isFalse(it1.moveNext());
    expect.Expect.isFalse(it2.moveNext());
    expect.Expect.isFalse(it2.moveNext());
  }
  dart.fn(main);
  // Exports:
  exports.foo1 = foo1;
  exports.foo2 = foo2;
  exports.foo3 = foo3;
  exports.main = main;
});
