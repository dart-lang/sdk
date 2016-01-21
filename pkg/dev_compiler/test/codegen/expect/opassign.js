dart_library.library('opassign', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  dart.copyProperties(exports, {
    get index() {
      core.print('called "index" getter');
      return 0;
    }
  });
  dart.defineLazyProperties(exports, {
    get _foo() {
      return new Foo();
    }
  });
  dart.copyProperties(exports, {
    get foo() {
      core.print('called "foo" getter');
      return exports._foo;
    }
  });
  class Foo extends core.Object {
    Foo() {
      this.x = 100;
    }
  }
  function main() {
    let f = dart.map([0, 40]);
    core.print('should only call "index" 2 times:');
    let i = exports.index;
    f.set(i, dart.dsend(f.get(i), '+', 1));
    forcePostfix((() => {
      let i = exports.index, x = f.get(i);
      f.set(i, dart.dsend(x, '+', 1));
      return x;
    })());
    core.print('should only call "foo" 2 times:');
    let o = exports.foo;
    dart.dput(o, 'x', dart.dsend(dart.dload(o, 'x'), '+', 1));
    forcePostfix((() => {
      let o = exports.foo, x = dart.dload(o, 'x');
      dart.dput(o, 'x', dart.dsend(x, '+', 1));
      return x;
    })());
    core.print('op assign test, should only call "index" twice:');
    let i$ = exports.index;
    f.set(i$, dart.dsend(f.get(i$), '+', f.get(exports.index)));
  }
  dart.fn(main);
  function forcePostfix(x) {
  }
  dart.fn(forcePostfix);
  // Exports:
  exports.Foo = Foo;
  exports.main = main;
  exports.forcePostfix = forcePostfix;
});
