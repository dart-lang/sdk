var fieldtest;
(function(exports) {
  'use strict';
  class A extends core.Object {
    A() {
      this.x = 42;
    }
  }
  let B$ = dart.generic(function(T) {
    class B extends core.Object {
      B() {
        this.x = null;
        this.y = null;
        this.z = null;
      }
    }
    return B;
  });
  let B = B$(dart.dynamic);
  // Function foo: (A) → int
  function foo(a) {
    core.print(a.x);
    return a.x;
  }
  // Function bar: (dynamic) → int
  function bar(a) {
    core.print(dart.dload(a, 'x'));
    return dart.as(dart.dload(a, 'x'), core.int);
  }
  // Function baz: (A) → dynamic
  function baz(a) {
    return a.x;
  }
  // Function compute: () → int
  function compute() {
    return 123;
  }
  dart.defineLazyProperties(exports, {
    get y() {
      return dart.notNull(compute()) + 444;
    },
    set y(_) {}
  });
  dart.copyProperties(exports, {
    get q() {
      return core.String['+'](core.String['+']('life, ', 'the universe '), 'and everything');
    },
    get z() {
      return 42;
    },
    set z(value) {
      exports.y = dart.as(value, core.int);
    }
  });
  // Function main: () → void
  function main() {
    let a = new A();
    foo(a);
    bar(a);
    core.print(baz(a));
  }
  // Exports:
  exports.A = A;
  exports.B = B;
  exports.B$ = B$;
  exports.foo = foo;
  exports.bar = bar;
  exports.baz = baz;
  exports.compute = compute;
  exports.main = main;
})(fieldtest || (fieldtest = {}));
