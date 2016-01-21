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
  // Exports:
  exports.Pair$ = Pair$;
  exports.Pair = Pair;
});
