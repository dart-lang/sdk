dart_library.library('temps', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const temps = Object.create(null);
  const _x = Symbol('_x');
  const __x = Symbol('__x');
  const _function = Symbol('_function');
  temps.FormalCollision = class FormalCollision extends core.Object {
    FormalCollision(x, _x$, func) {
      this[_x] = x;
      this[__x] = _x$;
      this[_function] = func;
    }
  };
  dart.setSignature(temps.FormalCollision, {
    constructors: () => ({FormalCollision: [temps.FormalCollision, [core.int, core.int, core.Function]]})
  });
  const _opt = Symbol('_opt');
  temps.OptionalArg = class OptionalArg extends core.Object {
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
  };
  dart.defineNamedConstructor(temps.OptionalArg, 'named');
  dart.setSignature(temps.OptionalArg, {
    constructors: () => ({
      OptionalArg: [temps.OptionalArg, [], [core.int]],
      named: [temps.OptionalArg, [], {opt: core.int}]
    })
  });
  temps.main = function() {
    core.print(new temps.FormalCollision(1, 2, dart.fn(x => x)));
    core.print(new temps.OptionalArg()[_opt]);
    core.print(new temps.OptionalArg.named()[_opt]);
  };
  dart.fn(temps.main);
  // Exports:
  exports.temps = temps;
});
