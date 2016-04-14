dart_library.library('cascade', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const cascade = Object.create(null);
  cascade.A = class A extends core.Object {
    A() {
      this.x = null;
    }
  };
  cascade.test_closure_with_mutate = function() {
    let a = new cascade.A();
    a.x = dart.fn(() => {
      core.print("hi");
      a = null;
    });
    let _ = a;
    dart.dcall(_.x);
    dart.dcall(_.x);
    core.print(a);
  };
  dart.fn(cascade.test_closure_with_mutate, dart.void, []);
  cascade.test_closure_without_mutate = function() {
    let a = new cascade.A();
    a.x = dart.fn(() => {
      core.print(a);
    });
    dart.dcall(a.x);
    dart.dcall(a.x);
    core.print(a);
  };
  dart.fn(cascade.test_closure_without_mutate, dart.void, []);
  cascade.test_mutate_inside_cascade = function() {
    let a = null;
    let _ = new cascade.A();
    _.x = a = null;
    _.x = a = null;
    a = _;
    core.print(a);
  };
  dart.fn(cascade.test_mutate_inside_cascade, dart.void, []);
  cascade.test_mutate_outside_cascade = function() {
    let a = null, b = null;
    a = new cascade.A();
    a.x = b = null;
    a.x = b = null;
    a = null;
    core.print(a);
  };
  dart.fn(cascade.test_mutate_outside_cascade, dart.void, []);
  cascade.test_VariableDeclaration_single = function() {
    let a = [];
    a[dartx.length] = 2;
    a[dartx.add](42);
    core.print(a);
  };
  dart.fn(cascade.test_VariableDeclaration_single, dart.void, []);
  cascade.test_VariableDeclaration_last = function() {
    let a = 42, b = (() => {
      let _ = [];
      _[dartx.length] = 2;
      _[dartx.add](a);
      return _;
    })();
    core.print(b);
  };
  dart.fn(cascade.test_VariableDeclaration_last, dart.void, []);
  cascade.test_VariableDeclaration_first = function() {
    let a = (() => {
      let _ = [];
      _[dartx.length] = 2;
      _[dartx.add](3);
      return _;
    })(), b = 2;
    core.print(a);
  };
  dart.fn(cascade.test_VariableDeclaration_first, dart.void, []);
  cascade.test_increment = function() {
    let a = new cascade.A();
    let y = ((() => {
      a.x = dart.dsend(a.x, '+', 1);
      a.x = dart.dsend(a.x, '-', 1);
      return a;
    })());
  };
  dart.fn(cascade.test_increment, dart.void, []);
  cascade.Base$ = dart.generic(T => {
    class Base extends core.Object {
      Base() {
        this.x = dart.list([], T);
      }
    }
    return Base;
  });
  cascade.Base = cascade.Base$();
  cascade.Foo = class Foo extends cascade.Base$(core.int) {
    Foo() {
      super.Base();
    }
    test_final_field_generic(t) {
      this.x[dartx.add](1);
      this.x[dartx.add](2);
      this.x[dartx.add](3);
      this.x[dartx.add](4);
    }
  };
  dart.setSignature(cascade.Foo, {
    methods: () => ({test_final_field_generic: [dart.void, [dart.dynamic]]})
  });
  // Exports:
  exports.cascade = cascade;
});
