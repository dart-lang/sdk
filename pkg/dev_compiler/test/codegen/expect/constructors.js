dart_library.library('constructors', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  class A extends core.Object {}
  class B extends core.Object {
    B() {
    }
  }
  dart.setSignature(B, {
    constructors: () => ({B: [B, []]})
  });
  class C extends core.Object {
    named() {
    }
  }
  dart.defineNamedConstructor(C, 'named');
  dart.setSignature(C, {
    constructors: () => ({named: [C, []]})
  });
  class C2 extends C {
    named() {
      super.named();
    }
  }
  dart.defineNamedConstructor(C2, 'named');
  dart.setSignature(C2, {
    constructors: () => ({named: [C2, []]})
  });
  class D extends core.Object {
    D() {
    }
    named() {
    }
  }
  dart.defineNamedConstructor(D, 'named');
  dart.setSignature(D, {
    constructors: () => ({
      D: [D, []],
      named: [D, []]
    })
  });
  class E extends core.Object {
    E(name) {
      this.name = name;
    }
  }
  dart.setSignature(E, {
    constructors: () => ({E: [E, [core.String]]})
  });
  class F extends E {
    F(name) {
      super.E(name);
    }
  }
  dart.setSignature(F, {
    constructors: () => ({F: [F, [core.String]]})
  });
  class G extends core.Object {
    G(p1) {
      if (p1 === void 0) p1 = null;
    }
  }
  dart.setSignature(G, {
    constructors: () => ({G: [G, [], [core.String]]})
  });
  class H extends core.Object {
    H(opts) {
      let p1 = opts && 'p1' in opts ? opts.p1 : null;
    }
  }
  dart.setSignature(H, {
    constructors: () => ({H: [H, [], {p1: core.String}]})
  });
  class I extends core.Object {
    I() {
      this.name = 'default';
    }
    named(name) {
      this.name = name;
    }
  }
  dart.defineNamedConstructor(I, 'named');
  dart.setSignature(I, {
    constructors: () => ({
      I: [I, []],
      named: [I, [core.String]]
    })
  });
  class J extends core.Object {
    J() {
      this.initialized = true;
      this.nonInitialized = null;
    }
  }
  dart.setSignature(J, {
    constructors: () => ({J: [J, []]})
  });
  class K extends core.Object {
    K() {
      this.s = 'a';
    }
    withS(s) {
      this.s = s;
    }
  }
  dart.defineNamedConstructor(K, 'withS');
  dart.setSignature(K, {
    constructors: () => ({
      K: [K, []],
      withS: [K, [core.String]]
    })
  });
  class L extends core.Object {
    L(foo) {
      this.foo = foo;
    }
  }
  dart.setSignature(L, {
    constructors: () => ({L: [L, [dart.dynamic]]})
  });
  class M extends L {
    named(x) {
      super.L(dart.notNull(x) + 42);
    }
  }
  dart.defineNamedConstructor(M, 'named');
  dart.setSignature(M, {
    constructors: () => ({named: [M, [core.int]]})
  });
  class N extends M {
    named(y) {
      super.named(dart.notNull(y) + 100);
    }
  }
  dart.defineNamedConstructor(N, 'named');
  dart.setSignature(N, {
    constructors: () => ({named: [N, [core.int]]})
  });
  class P extends N {
    P(z) {
      super.named(dart.notNull(z) + 9000);
    }
    foo(x) {
      this.P(dart.notNull(x) + 42);
    }
    bar() {
      this.foo(1);
    }
  }
  dart.defineNamedConstructor(P, 'foo');
  dart.defineNamedConstructor(P, 'bar');
  dart.setSignature(P, {
    constructors: () => ({
      P: [P, [core.int]],
      foo: [P, [core.int]],
      bar: [P, []]
    })
  });
  const Q$ = dart.generic(function(T) {
    class Q extends core.Object {
      Q(y) {
        this.x = dart.as(y, T);
      }
      static foo() {
        return new (Q$())("hello");
      }
      bar() {
        let q = Q$().foo();
        return dart.as(q.x, core.String);
      }
      bar2() {
        let q = new (Q$())("world");
        return dart.as(q.x, core.String);
      }
      static baz() {
        let q = new (Q$(core.int))(42);
        return dart.notNull(q.bar()) + dart.notNull(q.bar2());
      }
    }
    dart.setSignature(Q, {
      constructors: () => ({Q: [Q$(T), [dart.dynamic]]}),
      methods: () => ({
        bar: [core.String, []],
        bar2: [core.String, []]
      }),
      statics: () => ({
        foo: [Q$(), []],
        baz: [core.String, []]
      }),
      names: ['foo', 'baz']
    });
    return Q;
  });
  let Q = Q$();
  // Exports:
  exports.A = A;
  exports.B = B;
  exports.C = C;
  exports.C2 = C2;
  exports.D = D;
  exports.E = E;
  exports.F = F;
  exports.G = G;
  exports.H = H;
  exports.I = I;
  exports.J = J;
  exports.K = K;
  exports.L = L;
  exports.M = M;
  exports.N = N;
  exports.P = P;
  exports.Q$ = Q$;
  exports.Q = Q;
});
