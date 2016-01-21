dart_library.library('cascade', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  class A extends core.Object {
    A() {
      this.x = null;
    }
  }
  function test_closure_with_mutate() {
    let a = new A();
    a.x = dart.fn(() => {
      core.print("hi");
      a = null;
    });
    let _ = a;
    dart.dcall(_.x);
    dart.dcall(_.x);
    core.print(a);
  }
  dart.fn(test_closure_with_mutate, dart.void, []);
  function test_closure_without_mutate() {
    let a = new A();
    a.x = dart.fn(() => {
      core.print(a);
    });
    dart.dcall(a.x);
    dart.dcall(a.x);
    core.print(a);
  }
  dart.fn(test_closure_without_mutate, dart.void, []);
  function test_mutate_inside_cascade() {
    let a = null;
    let _ = new A();
    _.x = a = null;
    _.x = a = null;
    a = _;
    core.print(a);
  }
  dart.fn(test_mutate_inside_cascade, dart.void, []);
  function test_mutate_outside_cascade() {
    let a = null, b = null;
    a = new A();
    a.x = b = null;
    a.x = b = null;
    a = null;
    core.print(a);
  }
  dart.fn(test_mutate_outside_cascade, dart.void, []);
  function test_VariableDeclaration_single() {
    let a = [];
    a[dartx.length] = 2;
    a[dartx.add](42);
    core.print(a);
  }
  dart.fn(test_VariableDeclaration_single, dart.void, []);
  function test_VariableDeclaration_last() {
    let a = 42, b = (() => {
      let _ = [];
      _[dartx.length] = 2;
      _[dartx.add](a);
      return _;
    })();
    core.print(b);
  }
  dart.fn(test_VariableDeclaration_last, dart.void, []);
  function test_VariableDeclaration_first() {
    let a = (() => {
      let _ = [];
      _[dartx.length] = 2;
      _[dartx.add](3);
      return _;
    })(), b = 2;
    core.print(a);
  }
  dart.fn(test_VariableDeclaration_first, dart.void, []);
  function test_increment() {
    let a = new A();
    let y = ((() => {
      a.x = dart.dsend(a.x, '+', 1);
      a.x = dart.dsend(a.x, '-', 1);
      return a;
    })());
  }
  dart.fn(test_increment, dart.void, []);
  const Base$ = dart.generic(function(T) {
    class Base extends core.Object {
      Base() {
        this.x = dart.list([], T);
      }
    }
    return Base;
  });
  let Base = Base$();
  class Foo extends Base$(core.int) {
    Foo() {
      super.Base();
    }
    test_final_field_generic(t) {
      this.x[dartx.add](1);
      this.x[dartx.add](2);
      this.x[dartx.add](3);
      this.x[dartx.add](4);
    }
  }
  dart.setSignature(Foo, {
    methods: () => ({test_final_field_generic: [dart.void, [dart.dynamic]]})
  });
  // Exports:
  exports.A = A;
  exports.test_closure_with_mutate = test_closure_with_mutate;
  exports.test_closure_without_mutate = test_closure_without_mutate;
  exports.test_mutate_inside_cascade = test_mutate_inside_cascade;
  exports.test_mutate_outside_cascade = test_mutate_outside_cascade;
  exports.test_VariableDeclaration_single = test_VariableDeclaration_single;
  exports.test_VariableDeclaration_last = test_VariableDeclaration_last;
  exports.test_VariableDeclaration_first = test_VariableDeclaration_first;
  exports.test_increment = test_increment;
  exports.Base$ = Base$;
  exports.Base = Base;
  exports.Foo = Foo;
});
