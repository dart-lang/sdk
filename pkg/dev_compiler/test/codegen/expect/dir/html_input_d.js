dart_library.library('dir/html_input_d', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  function fib(n) {
    return n == 0 || n == 1 ? 1 : dart.notNull(fib(dart.notNull(n) - 1)) + dart.notNull(fib(dart.notNull(n) - 2));
  }
  dart.fn(fib, core.int, [core.int]);
  // Exports:
  exports.fib = fib;
});
