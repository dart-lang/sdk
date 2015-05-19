var fieldtest = dart.defineLibrary(fieldtest, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  class A extends core.Object {
    A() {
      this.x = 42;
    }
  }
  dart.setSignature(A, {});
  let B$ = dart.generic(function(T) {
    class B extends core.Object {
      B() {
        this.x = null;
        this.y = null;
        this.z = null;
      }
    }
    dart.setSignature(B, {});
    return B;
  });
  let B = B$();
  function foo(a) {
    core.print(a.x);
    return a.x;
  }
  dart.fn(foo, core.int, [A]);
  function bar(a) {
    core.print(dart.dload(a, 'x'));
    return dart.as(dart.dload(a, 'x'), core.int);
  }
  dart.fn(bar, core.int, [dart.dynamic]);
  function baz(a) {
    return a.x;
  }
  dart.fn(baz, dart.dynamic, [A]);
  function compute() {
    return 123;
  }
  dart.fn(compute, core.int, []);
  dart.defineLazyProperties(exports, {
    get y() {
      return dart.notNull(compute()) + 444;
    },
    set y(_) {}
  });
  dart.copyProperties(exports, {
    get q() {
      return 'life, ' + 'the universe ' + 'and everything';
    },
    get z() {
      return 42;
    },
    set z(value) {
      exports.y = dart.as(value, core.int);
    }
  });
  class BaseWithGetter extends core.Object {
    get foo() {
      return 1;
    }
  }
  dart.setSignature(BaseWithGetter, {});
  class Derived extends BaseWithGetter {
    Derived() {
      this.foo = 2;
      this.bar = 3;
    }
  }
  dart.virtualField(Derived, 'foo');
  dart.setSignature(Derived, {});
  let Generic$ = dart.generic(function(T) {
    class Generic extends core.Object {
      foo(t) {
        dart.as(t, T);
        return core.print(dart.notNull(Generic$().bar) + dart.notNull(t));
      }
    }
    dart.setSignature(Generic, {
      methods: () => ({foo: dart.functionType(dart.dynamic, [T])})
    });
    return Generic;
  });
  let Generic = Generic$();
  Generic.bar = 'hello';
  function main() {
    let a = new A();
    foo(a);
    bar(a);
    core.print(baz(a));
    core.print(new (Generic$(core.String))().foo(' world'));
  }
  dart.fn(main, dart.void, []);
  // Exports:
  exports.A = A;
  exports.B$ = B$;
  exports.B = B;
  exports.foo = foo;
  exports.bar = bar;
  exports.baz = baz;
  exports.compute = compute;
  exports.BaseWithGetter = BaseWithGetter;
  exports.Derived = Derived;
  exports.Generic$ = Generic$;
  exports.Generic = Generic;
  exports.main = main;
})(fieldtest, core);
