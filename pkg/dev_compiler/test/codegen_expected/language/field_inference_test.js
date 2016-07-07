dart_library.library('language/field_inference_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field_inference_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field_inference_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _field = Symbol('_field');
  field_inference_test.A = class A extends core.Object {
    get field() {
      return this[_field];
    }
    new(field) {
      this[_field] = field;
      this.other = null;
    }
    fromOther(other) {
      this.other = other;
      this[_field] = null;
      this[_field] = dart.dload(this.other, 'field');
    }
  };
  dart.defineNamedConstructor(field_inference_test.A, 'fromOther');
  dart.setSignature(field_inference_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(field_inference_test.A, [dart.dynamic]),
      fromOther: dart.definiteFunctionType(field_inference_test.A, [dart.dynamic])
    })
  });
  field_inference_test.B = class B extends core.Object {
    new() {
      this.a = null;
      try {
        this.a = new field_inference_test.A(42);
      } catch (e) {
        throw e;
      }

    }
  };
  dart.setSignature(field_inference_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(field_inference_test.B, [])})
  });
  dart.defineLazy(field_inference_test, {
    get array() {
      return JSArrayOfObject().of([new field_inference_test.A(42), new field_inference_test.B()]);
    },
    set array(_) {}
  });
  field_inference_test.main = function() {
    new field_inference_test.B();
    let a = field_inference_test.analyzeAfterB();
    new field_inference_test.B();
    expect$.Expect.equals(42, dart.dload(a, _field));
  };
  dart.fn(field_inference_test.main, VoidTodynamic());
  field_inference_test.analyzeAfterB = function() {
    try {
      return new field_inference_test.A.fromOther(field_inference_test.array[dartx.get](0));
    } catch (e) {
      throw e;
    }

  };
  dart.fn(field_inference_test.analyzeAfterB, VoidTodynamic());
  // Exports:
  exports.field_inference_test = field_inference_test;
});
