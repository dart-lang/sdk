var constructors;
(function (constructors) {
  'use strict';
  class A {
  }

  class B {
    constructor() {
    }
  }

  class C {
    __init_named() {
    }
  }
  C.named = function() { this.__init_named() };
  C.named.prototype = C.prototype;

  class C2 extends C {
    __init_named() {
      super.__init_named();
    }
  }
  C2.named = function() { this.__init_named() };
  C2.named.prototype = C2.prototype;

  class D {
    constructor() {
    }
    __init_named() {
    }
  }
  D.named = function() { this.__init_named() };
  D.named.prototype = D.prototype;

  class E {
    constructor(name) {
      this.name = name;
    }
  }

  class F extends E {
    constructor(name) {
      super(name);
    }
  }

  class G {
    constructor(p1) {
      if (p1 === undefined) p1 = null;
    }
  }

  class H {
    constructor(opt$) {
      let p1 = opt$.p1 === undefined ? null : opt$.p1;
    }
  }

  class I {
    constructor() {
      this.name = "default";
    }
    __init_named(name) {
      this.name = name;
    }
  }
  I.named = function(name) { this.__init_named(name) };
  I.named.prototype = I.prototype;

  class J {
    constructor() {
      this.initialized = true;
      this.nonInitialized = null;
    }
  }

  class K {
    constructor() {
      this.s = "a";
    }
    __init_withS(s) {
      this.s = s;
    }
  }
  K.withS = function(s) { this.__init_withS(s) };
  K.withS.prototype = K.prototype;

  class L {
    constructor(foo) {
      this.foo = foo;
    }
  }

  class M extends L {
    __init_named(x) {
      L.call(this, x + 42);
    }
  }
  M.named = function(x) { this.__init_named(x) };
  M.named.prototype = M.prototype;

  class N extends M {
    __init_named(y) {
      super.__init_named(y + 100);
    }
  }
  N.named = function(y) { this.__init_named(y) };
  N.named.prototype = N.prototype;

  class P extends N {
    constructor(z) {
      super.__init_named(z + 9000);
    }
  }

  // Exports:
  constructors.A = A;
  constructors.B = B;
  constructors.C = C;
  constructors.C2 = C2;
  constructors.D = D;
  constructors.E = E;
  constructors.F = F;
  constructors.G = G;
  constructors.H = H;
  constructors.I = I;
  constructors.J = J;
  constructors.K = K;
  constructors.L = L;
  constructors.M = M;
  constructors.N = N;
  constructors.P = P;
})(constructors || (constructors = {}));
