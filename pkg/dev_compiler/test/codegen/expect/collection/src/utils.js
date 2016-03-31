dart_library.library('collection/src/utils', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  const Pair$ = dart.generic(function(E, F) {
    class Pair extends core.Object {
      Pair(first, last) {
        this.first = first;
        this.last = last;
      }
    }
    dart.setSignature(Pair, {
      constructors: () => ({Pair: [Pair$(E, F), [E, F]]})
    });
    return Pair;
  });
  let Pair = Pair$();
  function defaultCompare() {
    return dart.fn((value1, value2) => dart.as(value1, core.Comparable)[dartx.compareTo](value2), core.int, [dart.dynamic, dart.dynamic]);
  }
  dart.fn(defaultCompare, () => dart.definiteFunctionType(core.Comparator, []));
  // Exports:
  exports.Pair$ = Pair$;
  exports.Pair = Pair;
  exports.defaultCompare = defaultCompare;
});
