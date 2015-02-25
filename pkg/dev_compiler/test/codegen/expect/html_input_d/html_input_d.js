var html_input_d;
(function(html_input_d) {
  'use strict';
  // Function fib: (int) → int
  function fib(n) {
    return _fib(n, new core.Map());
  }
  // Function _fib: (int, Map<int, int>) → int
  function _fib(n, seen) {
    if (dart.notNull(n === 0) || dart.notNull(n === 1))
      return 1;
    if (seen.get(n) !== null)
      return seen.get(n);
    seen.set(n, _fib(n - 1, seen) + _fib(n - 2, seen));
    return seen.get(n);
  }
  // Exports:
  html_input_d.fib = fib;
})(html_input_d || (html_input_d = {}));
