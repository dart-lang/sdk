var html_input_d = dart.defineLibrary(html_input_d, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  function fib(n) {
    return n == 0 || n == 1 ? 1 : dart.notNull(fib(dart.notNull(n) - 1)) + dart.notNull(fib(dart.notNull(n) - 2));
  }
  dart.fn(fib, core.int, [core.int]);
  // Exports:
  exports.fib = fib;
})(html_input_d, core);
