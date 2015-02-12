var methods;
(function (methods) {
  'use strict';
  class A {
    constructor() {
      this._c = 3;
      super();
    }
    x() { return 42; }
    y(a) {
      return a;
    }
    z(b) {
      if (b === undefined) b = null;
      return b
    }
    zz(b) {
      if (b === undefined) b = 0;
      return b
    }
    w(a, opt$) {
      let b = opt$.b === undefined ? null : opt$.b;
      return a + b;
    }
    ww(a, opt$) {
      let b = opt$.b === undefined ? 0 : opt$.b;
      return a + b;
    }
    get a() { return this.x(); }
    set b(b) {
    }
    get c() { return this._c; }
    set c(c) {
      this._c = c;
    }
  }

  class Bar {
    call(x) { return core.print(`hello from ${x}`); }
  }

  class Foo {
    constructor() {
      this.bar = new Bar();
      super();
    }
  }

  // Function test: () → dynamic
  function test() {
    let f = new Foo();
    dart.dinvoke(f, "bar", "Bar's call method!");
  }

  // Exports:
  methods.A = A;
  methods.Bar = Bar;
  methods.Foo = Foo;
  methods.test = test;
})(methods || (methods = {}));
