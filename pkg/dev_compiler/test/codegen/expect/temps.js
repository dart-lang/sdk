dart_library.library('temps', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  const _x = Symbol('_x');
  const __x = Symbol('__x');
  const _function = Symbol('_function');
  class FormalCollision extends core.Object {
    FormalCollision(x, _x$, func) {
      this[_x] = x;
      this[__x] = _x$;
      this[_function] = func;
    }
  }
  dart.setSignature(FormalCollision, {
    constructors: () => ({FormalCollision: [FormalCollision, [core.int, core.int, core.Function]]})
  });
  const _opt = Symbol('_opt');
  class OptionalArg extends core.Object {
    OptionalArg(opt) {
      if (opt === void 0) opt = 123;
      this[_opt] = opt;
      this.opt = null;
    }
    named(opts) {
      let opt = opts && 'opt' in opts ? opts.opt : 456;
      this.opt = opt;
      this[_opt] = null;
    }
  }
  dart.defineNamedConstructor(OptionalArg, 'named');
  dart.setSignature(OptionalArg, {
    constructors: () => ({
      OptionalArg: [OptionalArg, [], [core.int]],
      named: [OptionalArg, [], {opt: core.int}]
    })
  });
  function main() {
    core.print(new FormalCollision(1, 2, dart.fn(x => x)));
    core.print(new OptionalArg()[_opt]);
    core.print(new OptionalArg.named()[_opt]);
  }
  dart.fn(main);
  // Exports:
  exports.FormalCollision = FormalCollision;
  exports.OptionalArg = OptionalArg;
  exports.main = main;
});
