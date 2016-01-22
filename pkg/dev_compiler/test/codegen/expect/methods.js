dart_library.library('methods', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  const _c = Symbol('_c');
  class A extends core.Object {
    A() {
      this[_c] = 3;
    }
    x() {
      return 42;
    }
    y(a) {
      return a;
    }
    z(b) {
      if (b === void 0) b = null;
      return dart.asInt(b);
    }
    zz(b) {
      if (b === void 0) b = 0;
      return b;
    }
    w(a, opts) {
      let b = opts && 'b' in opts ? opts.b : null;
      return dart.asInt(dart.notNull(a) + dart.notNull(b));
    }
    ww(a, opts) {
      let b = opts && 'b' in opts ? opts.b : 0;
      return dart.notNull(a) + dart.notNull(b);
    }
    clashWithObjectProperty(opts) {
      let constructor = opts && 'constructor' in opts ? opts.constructor : null;
      return constructor;
    }
    clashWithJsReservedName(opts) {
      let func = opts && 'function' in opts ? opts.function : null;
      return func;
    }
    get a() {
      return this.x();
    }
    set b(b) {}
    get c() {
      return this[_c];
    }
    set c(c) {
      this[_c] = c;
    }
  }
  dart.setSignature(A, {
    methods: () => ({
      x: [core.int, []],
      y: [core.int, [core.int]],
      z: [core.int, [], [core.num]],
      zz: [core.int, [], [core.int]],
      w: [core.int, [core.int], {b: core.num}],
      ww: [core.int, [core.int], {b: core.int}],
      clashWithObjectProperty: [dart.dynamic, [], {constructor: dart.dynamic}],
      clashWithJsReservedName: [dart.dynamic, [], {function: dart.dynamic}]
    })
  });
  class Bar extends core.Object {
    call(x) {
      return core.print(`hello from ${x}`);
    }
  }
  dart.setSignature(Bar, {
    methods: () => ({call: [dart.dynamic, [dart.dynamic]]})
  });
  class Foo extends core.Object {
    Foo() {
      this.bar = new Bar();
    }
  }
  function test() {
    let f = new Foo();
    dart.dcall(f.bar, "Bar's call method!");
    let a = new A();
    let g = dart.bind(a, 'x');
    let aa = new A();
    let h = dart.dload(aa, 'x');
    let ts = dart.fn(dart.toString.bind(a), core.String, []);
    let nsm = dart.fn(dart.noSuchMethod.bind(a), dart.dynamic, [core.Invocation]);
    let c = dart.bind("", dartx.padLeft);
    let r = dart.bind(3.0, dartx.floor);
  }
  dart.fn(test);
  // Exports:
  exports.A = A;
  exports.Bar = Bar;
  exports.Foo = Foo;
  exports.test = test;
});
