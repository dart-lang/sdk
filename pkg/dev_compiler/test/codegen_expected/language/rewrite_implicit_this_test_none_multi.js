dart_library.library('language/rewrite_implicit_this_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__rewrite_implicit_this_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const rewrite_implicit_this_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  rewrite_implicit_this_test_none_multi.toplevel = 'A';
  rewrite_implicit_this_test_none_multi.Foo = class Foo extends core.Object {
    new() {
      this.x = 'x';
    }
    easy(z) {}
    shadow_y_parameter(y) {}
    shadow_y_local(z) {
      let y = z;
    }
    shadow_y_capturedLocal(z) {
      let y = z;
      function foo() {
      }
      dart.fn(foo, VoidTodynamic());
      return foo();
    }
    shadow_y_closureParam(z) {
      function foo(y) {
      }
      dart.fn(foo, dynamicTodynamic());
      return foo(z);
    }
    shadow_y_localInsideClosure(z) {
      function foo() {
        let y = z;
      }
      dart.fn(foo, VoidTodynamic());
      return foo();
    }
    shadow_x_parameter(x) {}
    shadow_x_local(z) {
      let x = z;
    }
    shadow_x_capturedLocal(z) {
      let x = z;
      function foo() {
      }
      dart.fn(foo, VoidTodynamic());
      return foo();
    }
    shadow_x_closureParam(z) {
      function foo(x) {
      }
      dart.fn(foo, dynamicTodynamic());
      return foo(z);
    }
    shadow_x_localInsideClosure(z) {
      function foo() {
        let x = z;
      }
      dart.fn(foo, VoidTodynamic());
      return foo();
    }
    shadow_x_toplevel() {}
  };
  dart.setSignature(rewrite_implicit_this_test_none_multi.Foo, {
    methods: () => ({
      easy: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_y_parameter: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_y_local: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_y_capturedLocal: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_y_closureParam: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_y_localInsideClosure: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_x_parameter: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_x_local: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_x_capturedLocal: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_x_closureParam: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_x_localInsideClosure: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      shadow_x_toplevel: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  rewrite_implicit_this_test_none_multi.Sub = class Sub extends rewrite_implicit_this_test_none_multi.Foo {
    new() {
      this.y = 'y';
      this.toplevel = 'B';
      super.new();
    }
  };
  rewrite_implicit_this_test_none_multi.main = function() {
  };
  dart.fn(rewrite_implicit_this_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.rewrite_implicit_this_test_none_multi = rewrite_implicit_this_test_none_multi;
});
