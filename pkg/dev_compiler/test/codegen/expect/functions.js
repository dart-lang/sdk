var functions = dart.defineLibrary(functions, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  function bootstrap() {
    return dart.setType([new Foo()], core.List$(Foo));
  }
  dart.fn(bootstrap, () => dart.functionType(core.List$(Foo), []));
  class Foo extends core.Object {}
  dart.setSignature(Foo, {});
  function main() {
    core.print(bootstrap()[core.$get](0));
  }
  dart.fn(main, dart.void, []);
  // Exports:
  exports.bootstrap = bootstrap;
  exports.Foo = Foo;
  exports.main = main;
})(functions, core);
