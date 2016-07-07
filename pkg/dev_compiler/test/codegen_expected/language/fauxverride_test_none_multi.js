dart_library.library('language/fauxverride_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__fauxverride_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const fauxverride_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  fauxverride_test_none_multi.m = function() {
    return 'top level';
  };
  dart.fn(fauxverride_test_none_multi.m, VoidTodynamic());
  fauxverride_test_none_multi.Super = class Super extends core.Object {
    static m() {
      return 'super';
    }
    instanceMethod() {
      return fauxverride_test_none_multi.Super.m();
    }
    instanceMethod2() {
      return fauxverride_test_none_multi.Super.m();
    }
  };
  dart.setSignature(fauxverride_test_none_multi.Super, {
    methods: () => ({
      instanceMethod: dart.definiteFunctionType(dart.dynamic, []),
      instanceMethod2: dart.definiteFunctionType(dart.dynamic, [])
    }),
    statics: () => ({m: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['m']
  });
  fauxverride_test_none_multi.Super.i = 'super';
  fauxverride_test_none_multi.Super.i2 = 'super';
  fauxverride_test_none_multi.Sub = class Sub extends fauxverride_test_none_multi.Super {
    static m() {
      return 'sub';
    }
    instanceMethod() {
      return fauxverride_test_none_multi.Sub.m();
    }
    static i2() {
      return fauxverride_test_none_multi.Sub.m();
    }
    foo() {
      return 'foo';
    }
  };
  dart.setSignature(fauxverride_test_none_multi.Sub, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])}),
    statics: () => ({i2: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['i2']
  });
  dart.defineLazy(fauxverride_test_none_multi.Sub, {
    get i() {
      return 'sub';
    },
    set i(_) {}
  });
  fauxverride_test_none_multi.main = function() {
    expect$.Expect.equals('foo', new fauxverride_test_none_multi.Sub().foo());
    expect$.Expect.equals('top level', fauxverride_test_none_multi.m());
    expect$.Expect.equals('super', fauxverride_test_none_multi.Super.m());
    expect$.Expect.equals('sub', fauxverride_test_none_multi.Sub.m());
    expect$.Expect.equals('super', fauxverride_test_none_multi.Super.i);
    expect$.Expect.equals('sub', fauxverride_test_none_multi.Sub.i);
    expect$.Expect.equals('super', fauxverride_test_none_multi.Super.i2);
    expect$.Expect.equals('sub', fauxverride_test_none_multi.Sub.i2());
    expect$.Expect.equals('super', new fauxverride_test_none_multi.Super().instanceMethod());
    expect$.Expect.equals('sub', new fauxverride_test_none_multi.Sub().instanceMethod());
    expect$.Expect.equals('super', new fauxverride_test_none_multi.Super().instanceMethod2());
    expect$.Expect.equals('super', new fauxverride_test_none_multi.Sub().instanceMethod2());
  };
  dart.fn(fauxverride_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.fauxverride_test_none_multi = fauxverride_test_none_multi;
});
