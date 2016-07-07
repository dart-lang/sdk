dart_library.library('language/instance_field_initializer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__instance_field_initializer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const instance_field_initializer_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  instance_field_initializer_test.A = class A extends core.Object {
    new() {
      this.x = 1;
    }
    reassign() {
      this.x = 2;
    }
    reassign2(x) {
      this.x = x;
    }
  };
  dart.defineNamedConstructor(instance_field_initializer_test.A, 'reassign');
  dart.defineNamedConstructor(instance_field_initializer_test.A, 'reassign2');
  dart.setSignature(instance_field_initializer_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(instance_field_initializer_test.A, []),
      reassign: dart.definiteFunctionType(instance_field_initializer_test.A, []),
      reassign2: dart.definiteFunctionType(instance_field_initializer_test.A, [core.int])
    })
  });
  instance_field_initializer_test.B = class B extends instance_field_initializer_test.A {
    new() {
      super.new();
    }
    reassign() {
      super.reassign();
    }
    reassign2() {
      super.reassign2(3);
    }
  };
  dart.defineNamedConstructor(instance_field_initializer_test.B, 'reassign');
  dart.defineNamedConstructor(instance_field_initializer_test.B, 'reassign2');
  dart.setSignature(instance_field_initializer_test.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(instance_field_initializer_test.B, []),
      reassign: dart.definiteFunctionType(instance_field_initializer_test.B, []),
      reassign2: dart.definiteFunctionType(instance_field_initializer_test.B, [])
    })
  });
  instance_field_initializer_test.InstanceFieldInitializerTest = class InstanceFieldInitializerTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(1, new instance_field_initializer_test.A().x);
      expect$.Expect.equals(2, new instance_field_initializer_test.A.reassign().x);
      expect$.Expect.equals(3, new instance_field_initializer_test.A.reassign2(3).x);
      expect$.Expect.equals(1, new instance_field_initializer_test.B().x);
      expect$.Expect.equals(2, new instance_field_initializer_test.B.reassign().x);
      expect$.Expect.equals(3, new instance_field_initializer_test.B.reassign2().x);
    }
  };
  dart.setSignature(instance_field_initializer_test.InstanceFieldInitializerTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  instance_field_initializer_test.main = function() {
    instance_field_initializer_test.InstanceFieldInitializerTest.testMain();
  };
  dart.fn(instance_field_initializer_test.main, VoidTodynamic());
  // Exports:
  exports.instance_field_initializer_test = instance_field_initializer_test;
});
