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
  let _opt = Symbol('_opt');
  class OptionalArg extends core.Object {
    OptionalArg(opt) {
      if (opt === void 0)
        opt = 123;
      this[_opt] = opt;
    }
    named(opts) {
      let opt = opts && '_opt' in opts ? opts._opt : 456;
      this[_opt] = opt;
    }
  }
  dart.defineNamedConstructor(OptionalArg, 'named');
  // Function main: () → dynamic
  function main() {
    core.print(new FormalCollision(1, 2, x => x));
    core.print(new OptionalArg()[_opt]);
    core.print(new OptionalArg.named()[_opt]);
  }
  // Exports:
  exports.FormalCollision = FormalCollision;
  exports.OptionalArg = OptionalArg;
  exports.main = main;
})(temps || (temps = {}));
