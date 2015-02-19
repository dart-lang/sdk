var methods;
(function (methods) {
  'use strict';
  class A extends dart.Object {
    A() {
      this._c = 3;
    }
    x() { return 42; }
    y(a) {
      return a;
    }
    z(b) {
      if (b === undefined) b = null;
      return dart.notNull(b)
    }
    zz(b) {
      if (b === undefined) b = 0;
      return b
    }
    w(a, opt$) {
      let b = opt$.b === undefined ? null : opt$.b;
      return dart.notNull(a + dart.notNull(b));
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

  class Bar extends dart.Object {
    call(x) { return core.print(`hello from ${x}`); }
  }

  class Foo extends dart.Object {
    Foo() {
      this.bar = new Bar();
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
