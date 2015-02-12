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
    /*constructor*/ named() {
    }
  }
  dart.defineNamedConstructor(C, "named");

  class C2 extends C {
    /*constructor*/ named() {
      super.named();
    }
  }
  dart.defineNamedConstructor(C2, "named");

  class D {
    constructor() {
    }
    /*constructor*/ named() {
    }
  }
  dart.defineNamedConstructor(D, "named");

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
      this.name = 'default';
    }
    /*constructor*/ named(name) {
      this.name = name;
    }
  }
  dart.defineNamedConstructor(I, "named");

  class J {
    constructor() {
      this.initialized = true;
      this.nonInitialized = null;
    }
  }

  class K {
    constructor() {
      this.s = 'a';
    }
    /*constructor*/ withS(s) {
      this.s = s;
    }
  }
  dart.defineNamedConstructor(K, "withS");

  class L {
    constructor(foo) {
      this.foo = foo;
    }
  }

  class M extends L {
    /*constructor*/ named(x) {
      L.call(this, x + 42);
    }
  }
  dart.defineNamedConstructor(M, "named");

  class N extends M {
    /*constructor*/ named(y) {
      super.named(y + 100);
    }
  }
  dart.defineNamedConstructor(N, "named");

  class P extends N {
    constructor(z) {
      super.named(z + 9000);
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
