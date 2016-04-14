dart_library.library('opassign', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const opassign = Object.create(null);
  dart.copyProperties(opassign, {
    get index() {
      core.print('called "index" getter');
      return 0;
    }
  });
  dart.defineLazy(opassign, {
    get _foo() {
      return new opassign.Foo();
    }
  });
  dart.copyProperties(opassign, {
    get foo() {
      core.print('called "foo" getter');
      return opassign._foo;
    }
  });
  opassign.Foo = class Foo extends core.Object {
    Foo() {
      this.x = 100;
    }
  };
  opassign.main = function() {
    let f = dart.map([0, 40]);
    core.print('should only call "index" 2 times:');
    let i = dart.as(opassign.index, core.int);
    f[dartx.set](i, dart.notNull(f[dartx.get](i)) + 1);
    opassign.forcePostfix((() => {
      let i = dart.as(opassign.index, core.int), x = f[dartx.get](i);
      f[dartx.set](i, dart.notNull(x) + 1);
      return x;
    })());
    core.print('should only call "foo" 2 times:');
    let o = opassign.foo;
    dart.dput(o, 'x', dart.dsend(dart.dload(o, 'x'), '+', 1));
    opassign.forcePostfix((() => {
      let o = opassign.foo, x = dart.dload(o, 'x');
      dart.dput(o, 'x', dart.dsend(x, '+', 1));
      return x;
    })());
    core.print('op assign test, should only call "index" twice:');
    let i$ = dart.as(opassign.index, core.int);
    f[dartx.set](i$, dart.notNull(f[dartx.get](i$)) + dart.notNull(f[dartx.get](opassign.index)));
  };
  dart.fn(opassign.main);
  opassign.forcePostfix = function(x) {
  };
  dart.fn(opassign.forcePostfix);
  // Exports:
  exports.opassign = opassign;
});
