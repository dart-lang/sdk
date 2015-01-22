var fieldtest;
(function (fieldtest) {
  'use strict';
  class A {
    constructor() {
      this.x = 42;
      super();
    }
  }

  // Function foo: (A) → int
  function foo(a) {
    dart_core.print(a.x);
    return a.x;
  }


  // Function bar: (dynamic) → int
  function bar(a) {
    dart_core.print(dart_runtime.dload(a, "x"));
    return /* Unimplemented: DownCast: dynamic to int */ dart_runtime.dload(a, "x");
  }


  // Function baz: (A) → dynamic
  function baz(a) { return a.x; }

  // Function main: () → void
  function main() {
    let a = new A();
    foo(a);
    bar(a);
    dart_core.print(baz(a));
  }


  // Exports:
  fieldtest.A = A;
  fieldtest.foo = foo;
  fieldtest.bar = bar;
  fieldtest.baz = baz;
  fieldtest.main = main;
})(fieldtest || (fieldtest = {}));
