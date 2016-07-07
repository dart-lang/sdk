dart_library.library('language/non_const_constructor_without_body_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__non_const_constructor_without_body_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const non_const_constructor_without_body_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest = class NonConstConstructorWithoutBodyTest extends core.Object {
    new() {
      this.x = null;
    }
    named() {
      this.x = null;
    }
    initializers() {
      this.x = 1;
    }
    parameters(x) {
      this.x = dart.notNull(x) + 1;
    }
    fieldParameter(x) {
      this.x = x;
    }
    redirection() {
      NonConstConstructorWithoutBodyTest.prototype.initializers.call(this);
    }
    static testMain() {
      expect$.Expect.equals(null, new non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest().x);
      expect$.Expect.equals(null, new non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest.named().x);
      expect$.Expect.equals(1, new non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest.initializers().x);
      expect$.Expect.equals(2, new non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest.parameters(1).x);
      expect$.Expect.equals(2, new non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest.fieldParameter(2).x);
      expect$.Expect.equals(1, new non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest.redirection().x);
    }
  };
  dart.defineNamedConstructor(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, 'named');
  dart.defineNamedConstructor(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, 'initializers');
  dart.defineNamedConstructor(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, 'parameters');
  dart.defineNamedConstructor(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, 'fieldParameter');
  dart.defineNamedConstructor(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, 'redirection');
  dart.setSignature(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, {
    constructors: () => ({
      new: dart.definiteFunctionType(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, []),
      named: dart.definiteFunctionType(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, []),
      initializers: dart.definiteFunctionType(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, []),
      parameters: dart.definiteFunctionType(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, [core.int]),
      fieldParameter: dart.definiteFunctionType(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, [core.int]),
      redirection: dart.definiteFunctionType(non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest, [])
    }),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  non_const_constructor_without_body_test.main = function() {
    non_const_constructor_without_body_test.NonConstConstructorWithoutBodyTest.testMain();
  };
  dart.fn(non_const_constructor_without_body_test.main, VoidTodynamic());
  // Exports:
  exports.non_const_constructor_without_body_test = non_const_constructor_without_body_test;
});
