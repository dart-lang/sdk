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
  }

  C.named = function() {
  };
  C.named.prototype = C.prototype;

  class C2 extends C {
  }

  C2.named = function() {
    C.named.call(this);
  };
  C2.named.prototype = C2.prototype;

  class D {
    constructor() {
    }
  }

  D.named = function() {
  };
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
  }

  I.named = function(name) {
    this.name = name;
  };
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
  }

  K.withS = function(s) {
    this.s = s;
  };
  K.withS.prototype = K.prototype;

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
})(constructors || (constructors = {}));
