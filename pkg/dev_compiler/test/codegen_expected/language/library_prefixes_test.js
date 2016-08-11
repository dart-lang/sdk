dart_library.library('language/library_prefixes_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__library_prefixes_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const library_prefixes_test = Object.create(null);
  const library_prefixes = Object.create(null);
  const library_prefixes_test1 = Object.create(null);
  const library_prefixes_test2 = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  library_prefixes_test.LibraryPrefixesTest = class LibraryPrefixesTest extends core.Object {
    static testMain() {
      library_prefixes.LibraryPrefixes.main(dart.fn((a, b) => {
        expect$.Expect.equals(a, b);
      }, dynamicAnddynamicTodynamic()));
    }
  };
  dart.setSignature(library_prefixes_test.LibraryPrefixesTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  library_prefixes_test.main = function() {
    library_prefixes_test.LibraryPrefixesTest.testMain();
  };
  dart.fn(library_prefixes_test.main, VoidTodynamic());
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  let const$6;
  library_prefixes.LibraryPrefixes = class LibraryPrefixes extends core.Object {
    static main(expectEquals) {
      let a = library_prefixes_test1.Constants.PI;
      let b = library_prefixes_test2.Constants.PI;
      dart.dcall(expectEquals, 3.14, a);
      dart.dcall(expectEquals, 3.14, b);
      dart.dcall(expectEquals, 1, library_prefixes_test1.Constants.foo);
      dart.dcall(expectEquals, 2, library_prefixes_test2.Constants.foo);
      dart.dcall(expectEquals, -1, library_prefixes_test1.A.y);
      dart.dcall(expectEquals, 0, library_prefixes_test2.A.y);
      dart.dcall(expectEquals, 1, new library_prefixes_test1.A().x);
      dart.dcall(expectEquals, 2, new library_prefixes_test2.A().x);
      dart.dcall(expectEquals, 3, new library_prefixes_test1.A.named().x);
      dart.dcall(expectEquals, 4, new library_prefixes_test2.A.named().x);
      dart.dcall(expectEquals, 3, library_prefixes_test1.A.fac().x);
      dart.dcall(expectEquals, 4, library_prefixes_test2.A.fac().x);
      dart.dcall(expectEquals, 1, new library_prefixes_test1.B().x);
      dart.dcall(expectEquals, 2, new library_prefixes_test2.B().x);
      dart.dcall(expectEquals, 8, new library_prefixes_test1.B.named().x);
      dart.dcall(expectEquals, 13, new library_prefixes_test2.B.named().x);
      dart.dcall(expectEquals, 8, library_prefixes_test1.B.fac().x);
      dart.dcall(expectEquals, 13, library_prefixes_test2.B.fac().x);
      dart.dcall(expectEquals, 1, (const$ || (const$ = dart.const(new library_prefixes_test1.C()))).x);
      dart.dcall(expectEquals, 2, (const$0 || (const$0 = dart.const(new library_prefixes_test2.C()))).x);
      dart.dcall(expectEquals, 3, (const$1 || (const$1 = dart.const(new library_prefixes_test1.C.named()))).x);
      dart.dcall(expectEquals, 4, (const$2 || (const$2 = dart.const(new library_prefixes_test2.C.named()))).x);
      dart.dcall(expectEquals, 3, library_prefixes_test1.C.fac().x);
      dart.dcall(expectEquals, 4, library_prefixes_test2.C.fac().x);
      dart.dcall(expectEquals, 1, (const$3 || (const$3 = dart.const(new library_prefixes_test1.D()))).x);
      dart.dcall(expectEquals, 2, (const$4 || (const$4 = dart.const(new library_prefixes_test2.D()))).x);
      dart.dcall(expectEquals, 8, (const$5 || (const$5 = dart.const(new library_prefixes_test1.D.named()))).x);
      dart.dcall(expectEquals, 13, (const$6 || (const$6 = dart.const(new library_prefixes_test2.D.named()))).x);
      dart.dcall(expectEquals, 8, library_prefixes_test1.D.fac().x);
      dart.dcall(expectEquals, 13, library_prefixes_test2.D.fac().x);
      dart.dcall(expectEquals, 0, library_prefixes_test1.E.foo());
      dart.dcall(expectEquals, 3, library_prefixes_test2.E.foo());
      dart.dcall(expectEquals, 1, new library_prefixes_test1.E().bar());
      dart.dcall(expectEquals, 4, new library_prefixes_test2.E().bar());
      dart.dcall(expectEquals, 9, dart.dcall(new library_prefixes_test1.E().toto(7)));
      dart.dcall(expectEquals, 16, dart.dcall(new library_prefixes_test2.E().toto(11)));
      dart.dcall(expectEquals, 111, dart.dcall(new library_prefixes_test1.E.fun(100).f));
      dart.dcall(expectEquals, 1313, dart.dcall(new library_prefixes_test2.E.fun(1300).f));
      dart.dcall(expectEquals, 999, dart.dcall(library_prefixes_test1.E.fooo(900)));
      dart.dcall(expectEquals, 2048, dart.dcall(library_prefixes_test2.E.fooo(1024)));
    }
  };
  dart.setSignature(library_prefixes.LibraryPrefixes, {
    statics: () => ({main: dart.definiteFunctionType(dart.void, [dart.dynamic])}),
    names: ['main']
  });
  library_prefixes_test1.Constants = class Constants extends core.Object {};
  library_prefixes_test1.Constants.PI = 3.14;
  library_prefixes_test1.Constants.foo = 1;
  library_prefixes_test1.A = class A extends core.Object {
    new() {
      this.x = 1;
    }
    named() {
      this.x = 3;
    }
    superC(x) {
      this.x = core.int._check(dart.dsend(x, '+', 7));
    }
    static fac() {
      return new library_prefixes_test1.A.named();
    }
  };
  dart.defineNamedConstructor(library_prefixes_test1.A, 'named');
  dart.defineNamedConstructor(library_prefixes_test1.A, 'superC');
  dart.setSignature(library_prefixes_test1.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test1.A, []),
      named: dart.definiteFunctionType(library_prefixes_test1.A, []),
      superC: dart.definiteFunctionType(library_prefixes_test1.A, [dart.dynamic]),
      fac: dart.definiteFunctionType(library_prefixes_test1.A, [])
    })
  });
  library_prefixes_test1.A.y = -1;
  library_prefixes_test1.B = class B extends library_prefixes_test1.A {
    new() {
      super.new();
    }
    named() {
      super.superC(1);
    }
    static fac() {
      return new library_prefixes_test1.B.named();
    }
  };
  dart.defineNamedConstructor(library_prefixes_test1.B, 'named');
  dart.setSignature(library_prefixes_test1.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test1.B, []),
      named: dart.definiteFunctionType(library_prefixes_test1.B, []),
      fac: dart.definiteFunctionType(library_prefixes_test1.B, [])
    })
  });
  let const$7;
  library_prefixes_test1.C = class C extends core.Object {
    new() {
      this.x = 1;
    }
    named() {
      this.x = 3;
    }
    superC(x) {
      this.x = core.int._check(dart.dsend(x, '+', 7));
    }
    static fac() {
      return const$7 || (const$7 = dart.const(new library_prefixes_test1.C.named()));
    }
  };
  dart.defineNamedConstructor(library_prefixes_test1.C, 'named');
  dart.defineNamedConstructor(library_prefixes_test1.C, 'superC');
  dart.setSignature(library_prefixes_test1.C, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test1.C, []),
      named: dart.definiteFunctionType(library_prefixes_test1.C, []),
      superC: dart.definiteFunctionType(library_prefixes_test1.C, [dart.dynamic]),
      fac: dart.definiteFunctionType(library_prefixes_test1.C, [])
    })
  });
  let const$8;
  library_prefixes_test1.D = class D extends library_prefixes_test1.C {
    new() {
      super.new();
    }
    named() {
      super.superC(1);
    }
    static fac() {
      return const$8 || (const$8 = dart.const(new library_prefixes_test1.D.named()));
    }
  };
  dart.defineNamedConstructor(library_prefixes_test1.D, 'named');
  dart.setSignature(library_prefixes_test1.D, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test1.D, []),
      named: dart.definiteFunctionType(library_prefixes_test1.D, []),
      fac: dart.definiteFunctionType(library_prefixes_test1.D, [])
    })
  });
  library_prefixes_test1.E = class E extends core.Object {
    new() {
      this.f = null;
    }
    fun(x) {
      this.f = dart.fn(() => dart.dsend(x, '+', 11), VoidTodynamic());
    }
    static foo() {
      return 0;
    }
    static fooo(x) {
      return dart.fn(() => dart.dsend(x, '+', 99), VoidTodynamic());
    }
    bar() {
      return 1;
    }
    toto(x) {
      return dart.fn(() => dart.dsend(x, '+', 2), VoidTodynamic());
    }
  };
  dart.defineNamedConstructor(library_prefixes_test1.E, 'fun');
  dart.setSignature(library_prefixes_test1.E, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test1.E, []),
      fun: dart.definiteFunctionType(library_prefixes_test1.E, [dart.dynamic])
    }),
    methods: () => ({
      bar: dart.definiteFunctionType(dart.dynamic, []),
      toto: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    }),
    statics: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      fooo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    }),
    names: ['foo', 'fooo']
  });
  library_prefixes_test2.Constants = class Constants extends core.Object {};
  library_prefixes_test2.Constants.PI = 3.14;
  library_prefixes_test2.Constants.foo = 2;
  library_prefixes_test2.A = class A extends core.Object {
    new() {
      this.x = 2;
    }
    named() {
      this.x = 4;
    }
    superC(x) {
      this.x = core.int._check(dart.dsend(x, '+', 11));
    }
    static fac() {
      return new library_prefixes_test2.A.named();
    }
  };
  dart.defineNamedConstructor(library_prefixes_test2.A, 'named');
  dart.defineNamedConstructor(library_prefixes_test2.A, 'superC');
  dart.setSignature(library_prefixes_test2.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test2.A, []),
      named: dart.definiteFunctionType(library_prefixes_test2.A, []),
      superC: dart.definiteFunctionType(library_prefixes_test2.A, [dart.dynamic]),
      fac: dart.definiteFunctionType(library_prefixes_test2.A, [])
    })
  });
  library_prefixes_test2.A.y = 0;
  library_prefixes_test2.B = class B extends library_prefixes_test2.A {
    new() {
      super.new();
    }
    named() {
      super.superC(2);
    }
    static fac() {
      return new library_prefixes_test2.B.named();
    }
  };
  dart.defineNamedConstructor(library_prefixes_test2.B, 'named');
  dart.setSignature(library_prefixes_test2.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test2.B, []),
      named: dart.definiteFunctionType(library_prefixes_test2.B, []),
      fac: dart.definiteFunctionType(library_prefixes_test2.B, [])
    })
  });
  let const$9;
  library_prefixes_test2.C = class C extends core.Object {
    new() {
      this.x = 2;
    }
    named() {
      this.x = 4;
    }
    superC(x) {
      this.x = core.int._check(dart.dsend(x, '+', 11));
    }
    static fac() {
      return const$9 || (const$9 = dart.const(new library_prefixes_test2.C.named()));
    }
  };
  dart.defineNamedConstructor(library_prefixes_test2.C, 'named');
  dart.defineNamedConstructor(library_prefixes_test2.C, 'superC');
  dart.setSignature(library_prefixes_test2.C, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test2.C, []),
      named: dart.definiteFunctionType(library_prefixes_test2.C, []),
      superC: dart.definiteFunctionType(library_prefixes_test2.C, [dart.dynamic]),
      fac: dart.definiteFunctionType(library_prefixes_test2.C, [])
    })
  });
  let const$10;
  library_prefixes_test2.D = class D extends library_prefixes_test2.C {
    new() {
      super.new();
    }
    named() {
      super.superC(2);
    }
    static fac() {
      return const$10 || (const$10 = dart.const(new library_prefixes_test2.D.named()));
    }
  };
  dart.defineNamedConstructor(library_prefixes_test2.D, 'named');
  dart.setSignature(library_prefixes_test2.D, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test2.D, []),
      named: dart.definiteFunctionType(library_prefixes_test2.D, []),
      fac: dart.definiteFunctionType(library_prefixes_test2.D, [])
    })
  });
  library_prefixes_test2.E = class E extends core.Object {
    new() {
      this.f = null;
    }
    fun(x) {
      this.f = dart.fn(() => dart.dsend(x, '+', 13), VoidTodynamic());
    }
    static foo() {
      return 3;
    }
    static fooo(x) {
      return dart.fn(() => dart.dsend(x, '+', 1024), VoidTodynamic());
    }
    bar() {
      return 4;
    }
    toto(x) {
      return dart.fn(() => dart.dsend(x, '+', 5), VoidTodynamic());
    }
  };
  dart.defineNamedConstructor(library_prefixes_test2.E, 'fun');
  dart.setSignature(library_prefixes_test2.E, {
    constructors: () => ({
      new: dart.definiteFunctionType(library_prefixes_test2.E, []),
      fun: dart.definiteFunctionType(library_prefixes_test2.E, [dart.dynamic])
    }),
    methods: () => ({
      bar: dart.definiteFunctionType(dart.dynamic, []),
      toto: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    }),
    statics: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      fooo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    }),
    names: ['foo', 'fooo']
  });
  // Exports:
  exports.library_prefixes_test = library_prefixes_test;
  exports.library_prefixes = library_prefixes;
  exports.library_prefixes_test1 = library_prefixes_test1;
  exports.library_prefixes_test2 = library_prefixes_test2;
});
