dart_library.library('functions', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  function bootstrap() {
    return dart.list([new Foo()], Foo);
  }
  dart.fn(bootstrap, () => dart.definiteFunctionType(core.List$(Foo), []));
  const A2B$ = dart.generic(function(A, B) {
    const A2B = dart.typedef('A2B', () => dart.functionType(B, [A]));
    return A2B;
  });
  let A2B = A2B$();
  function id(f) {
    return f;
  }
  dart.fn(id, () => dart.definiteFunctionType(A2B$(Foo, Foo), [A2B$(Foo, Foo)]));
  class Foo extends core.Object {}
  function main() {
    core.print(bootstrap()[dartx.get](0));
  }
  dart.fn(main, dart.void, []);
  // Exports:
  exports.bootstrap = bootstrap;
  exports.A2B$ = A2B$;
  exports.A2B = A2B;
  exports.id = id;
  exports.Foo = Foo;
  exports.main = main;
});
