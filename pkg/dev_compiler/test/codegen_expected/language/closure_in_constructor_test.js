dart_library.library('language/closure_in_constructor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_in_constructor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_in_constructor_test = Object.create(null);
  let A = () => (A = dart.constFn(closure_in_constructor_test.A$()))();
  let AOfint = () => (AOfint = dart.constFn(closure_in_constructor_test.A$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_in_constructor_test.A$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(closure_in_constructor_test.A$(T)))();
    let ListOfT = () => (ListOfT = dart.constFn(core.List$(T)))();
    let VoidToListOfT = () => (VoidToListOfT = dart.constFn(dart.definiteFunctionType(ListOfT(), [])))();
    class A extends core.Object {
      static factory() {
        return new (AOfT())(dart.fn(() => ListOfT().new(), VoidToListOfT()));
      }
      new(closure) {
        if (closure === void 0) closure = null;
        this.closure = closure;
        if (this.closure == null) {
          this.closure = dart.fn(() => ListOfT().new(), VoidToListOfT());
        }
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({
        factory: dart.definiteFunctionType(closure_in_constructor_test.A$(T), []),
        new: dart.definiteFunctionType(closure_in_constructor_test.A$(T), [], [dart.dynamic])
      })
    });
    return A;
  });
  closure_in_constructor_test.A = A();
  closure_in_constructor_test.main = function() {
    expect$.Expect.isTrue(core.List.is(dart.dsend(closure_in_constructor_test.A.factory(), 'closure')));
    expect$.Expect.isTrue(core.List.is(dart.dsend(new closure_in_constructor_test.A(), 'closure')));
    expect$.Expect.isTrue(ListOfint().is(dart.dsend(AOfint().factory(), 'closure')));
    expect$.Expect.isTrue(ListOfint().is(dart.dsend(new (AOfint())(), 'closure')));
    expect$.Expect.isFalse(ListOfString().is(dart.dsend(AOfint().factory(), 'closure')));
    expect$.Expect.isFalse(ListOfString().is(dart.dsend(new (AOfint())(), 'closure')));
  };
  dart.fn(closure_in_constructor_test.main, VoidTodynamic());
  // Exports:
  exports.closure_in_constructor_test = closure_in_constructor_test;
});
