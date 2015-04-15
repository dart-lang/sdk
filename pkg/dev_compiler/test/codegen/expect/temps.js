var temps;
(function(exports) {
  'use strict';
  let _x = Symbol('_x');
  let __x = Symbol('__x');
  let _function = Symbol('_function');
  class FormalCollision extends core.Object {
    FormalCollision(x, _x$, func) {
      this[_x] = x;
      this[__x] = _x$;
      this[_function] = func;
    }
  }
  // Function main: () → dynamic
  function main() {
    core.print(new FormalCollision(1, 2, x => x));
  }
  // Exports:
  exports.FormalCollision = FormalCollision;
  exports.main = main;
})(temps || (temps = {}));
