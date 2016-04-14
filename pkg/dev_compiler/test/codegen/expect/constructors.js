dart_library.library('constructors', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constructors = Object.create(null);
  constructors.A = class A extends core.Object {};
  constructors.B = class B extends core.Object {
    B() {
    }
  };
  dart.setSignature(constructors.B, {
    constructors: () => ({B: [constructors.B, []]})
  });
  constructors.C = class C extends core.Object {
    named() {
    }
  };
  dart.defineNamedConstructor(constructors.C, 'named');
  dart.setSignature(constructors.C, {
    constructors: () => ({named: [constructors.C, []]})
  });
  constructors.C2 = class C2 extends constructors.C {
    named() {
      super.named();
    }
  };
  dart.defineNamedConstructor(constructors.C2, 'named');
  dart.setSignature(constructors.C2, {
    constructors: () => ({named: [constructors.C2, []]})
  });
  constructors.D = class D extends core.Object {
    D() {
    }
    named() {
    }
  };
  dart.defineNamedConstructor(constructors.D, 'named');
  dart.setSignature(constructors.D, {
    constructors: () => ({
      D: [constructors.D, []],
      named: [constructors.D, []]
    })
  });
  constructors.E = class E extends core.Object {
    E(name) {
      this.name = name;
    }
  };
  dart.setSignature(constructors.E, {
    constructors: () => ({E: [constructors.E, [core.String]]})
  });
  constructors.F = class F extends constructors.E {
    F(name) {
      super.E(name);
    }
  };
  dart.setSignature(constructors.F, {
    constructors: () => ({F: [constructors.F, [core.String]]})
  });
  constructors.G = class G extends core.Object {
    G(p1) {
      if (p1 === void 0) p1 = null;
    }
  };
  dart.setSignature(constructors.G, {
    constructors: () => ({G: [constructors.G, [], [core.String]]})
  });
  constructors.H = class H extends core.Object {
    H(opts) {
      let p1 = opts && 'p1' in opts ? opts.p1 : null;
    }
  };
  dart.setSignature(constructors.H, {
    constructors: () => ({H: [constructors.H, [], {p1: core.String}]})
  });
  constructors.I = class I extends core.Object {
    I() {
      this.name = 'default';
    }
    named(name) {
      this.name = name;
    }
  };
  dart.defineNamedConstructor(constructors.I, 'named');
  dart.setSignature(constructors.I, {
    constructors: () => ({
      I: [constructors.I, []],
      named: [constructors.I, [core.String]]
    })
  });
  constructors.J = class J extends core.Object {
    J() {
      this.initialized = true;
      this.nonInitialized = null;
    }
  };
  dart.setSignature(constructors.J, {
    constructors: () => ({J: [constructors.J, []]})
  });
  constructors.K = class K extends core.Object {
    K() {
      this.s = 'a';
    }
    withS(s) {
      this.s = s;
    }
  };
  dart.defineNamedConstructor(constructors.K, 'withS');
  dart.setSignature(constructors.K, {
    constructors: () => ({
      K: [constructors.K, []],
      withS: [constructors.K, [core.String]]
    })
  });
  constructors.L = class L extends core.Object {
    L(foo) {
      this.foo = foo;
    }
  };
  dart.setSignature(constructors.L, {
    constructors: () => ({L: [constructors.L, [dart.dynamic]]})
  });
  constructors.M = class M extends constructors.L {
    named(x) {
      super.L(dart.notNull(x) + 42);
    }
  };
  dart.defineNamedConstructor(constructors.M, 'named');
  dart.setSignature(constructors.M, {
    constructors: () => ({named: [constructors.M, [core.int]]})
  });
  constructors.N = class N extends constructors.M {
    named(y) {
      super.named(dart.notNull(y) + 100);
    }
  };
  dart.defineNamedConstructor(constructors.N, 'named');
  dart.setSignature(constructors.N, {
    constructors: () => ({named: [constructors.N, [core.int]]})
  });
  constructors.P = class P extends constructors.N {
    P(z) {
      super.named(dart.notNull(z) + 9000);
    }
    foo(x) {
      this.P(dart.notNull(x) + 42);
    }
    bar() {
      this.foo(1);
    }
  };
  dart.defineNamedConstructor(constructors.P, 'foo');
  dart.defineNamedConstructor(constructors.P, 'bar');
  dart.setSignature(constructors.P, {
    constructors: () => ({
      P: [constructors.P, [core.int]],
      foo: [constructors.P, [core.int]],
      bar: [constructors.P, []]
    })
  });
  constructors.Q$ = dart.generic(T => {
    class Q extends core.Object {
      Q(y) {
        this.x = dart.as(y, T);
      }
      static foo() {
        return new constructors.Q("hello");
      }
      bar() {
        let q = constructors.Q.foo();
        return dart.as(q.x, core.String);
      }
      bar2() {
        let q = new constructors.Q("world");
        return dart.as(q.x, core.String);
      }
      static baz() {
        let q = new (constructors.Q$(core.int))(42);
        return dart.notNull(q.bar()) + dart.notNull(q.bar2());
      }
    }
    dart.setSignature(Q, {
      constructors: () => ({Q: [constructors.Q$(T), [dart.dynamic]]}),
      methods: () => ({
        bar: [core.String, []],
        bar2: [core.String, []]
      }),
      statics: () => ({
        foo: [constructors.Q, []],
        baz: [core.String, []]
      }),
      names: ['foo', 'baz']
    });
    return Q;
  });
  constructors.Q = constructors.Q$();
  // Exports:
  exports.constructors = constructors;
});
