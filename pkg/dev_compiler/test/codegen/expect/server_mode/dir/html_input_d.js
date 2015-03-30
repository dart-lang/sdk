var html_input_d;
(function(exports) {
  'use strict';
  // Function fib: (int) → int
  function fib(n) {
    return n == 0 || n == 1 ? 1 : dart.notNull(fib(dart.notNull(n) - 1)) + dart.notNull(fib(dart.notNull(n) - 2));
  }
  // Exports:
  exports.fib = fib;
})(html_input_d || (html_input_d = {}));
