var fieldtest;
(function(fieldtest) {
  'use strict';
  class A extends dart.Object {
    A() {
      this.x = 42;
    }
  }
  let B$ = dart.generic(function(T) {
    class B extends dart.Object {
      B() {
        this.x = dart.as(null, core.int);
        this.y = null;
        this.z = dart.as(null, T);
      }
    }
    return B;
  });
  let B = B$(dynamic);
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
  dart.defineLazyProperties(fieldtest, {
    get y() {
      return compute() + 444;
    },
    set y() {}
  });
  dart.copyProperties(fieldtest, {
    get q() {
      return core.String['+'](core.String['+']('life, ', 'the universe '), 'and everything');
    },
    get z() {
      return 42;
    },
    set z(value) {
      fieldtest.y = dart.as(value, core.int);
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
  fieldtest.A = A;
  fieldtest.B = B;
  fieldtest.B$ = B$;
  fieldtest.foo = foo;
  fieldtest.bar = bar;
  fieldtest.baz = baz;
  fieldtest.compute = compute;
  fieldtest.q = q;
  fieldtest.z = z;
  fieldtest.z = z;
  fieldtest.main = main;
})(fieldtest || (fieldtest = {}));
