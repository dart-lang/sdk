var html_input_d;
(function(exports) {
  'use strict';
  // Function fib: (int) → int
  function fib(n) {
    return _fib(n, new core.Map());
  }
  // Function _fib: (int, Map<int, int>) → int
  function _fib(n, seen) {
    if (n === 0 || n === 1)
      return 1;
    if (seen.get(n) !== null)
      return seen.get(n);
    seen.set(n, dart.notNull(_fib(dart.notNull(n) - 1, seen)) + dart.notNull(_fib(dart.notNull(n) - 2, seen)));
    return seen.get(n);
  }
  // Exports:
  exports.fib = fib;
})(html_input_d || (html_input_d = {}));
