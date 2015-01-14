var methods;
(function (methods) {
  'use strict';
  class A {
    constructor() {
      this._c = 3;
      super();
    }
    x() {
      return 42;
    }
    y(a) {
      return a;
    }
    z(b) {
      if (b === undefined) b = null;
      return b;
    }
    zz(b) {
      if (b === undefined) b = 0;
      return b;
    }
    w(a, opt$) {
      let b = opt$.b === undefined ? null : opt$.b;
      return a + b;
    }
    ww(a, opt$) {
      let b = opt$.b === undefined ? 0 : opt$.b;
      return a + b;
    }
    get a() {
      return this.x();
    }
    set b(b) {
    }
    get c() {
      return this._c;
    }
    set c(c) {
      this._c = c;
    }
  }

  // Exports:
  methods.A = A;
})(methods || (methods = {}));
