var methods;
(function(exports) {
  'use strict';
  let _c = Symbol('_c');
  class A extends dart.Object {
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
      if (b === void 0)
        b = null;
      return b;
    }
    zz(b) {
      if (b === void 0)
        b = 0;
      return b;
    }
    w(a, opt$) {
      let b = opt$.b === void 0 ? null : opt$.b;
      return dart.notNull(a) + dart.notNull(b);
    }
    ww(a, opt$) {
      let b = opt$.b === void 0 ? 0 : opt$.b;
      return dart.notNull(a) + dart.notNull(b);
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
  class Bar extends dart.Object {
    call(x) {
      return core.print(`hello from ${x}`);
    }
  }
  class Foo extends dart.Object {
    Foo() {
      this.bar = new Bar();
    }
  }
  // Function test: () → dynamic
  function test() {
    let f = new Foo();
    dart.dinvoke(f, 'bar', "Bar's call method!");
  }
  // Exports:
  exports.A = A;
  exports.Bar = Bar;
  exports.Foo = Foo;
  exports.test = test;
})(methods || (methods = {}));
