dart_library.library('language/cascade_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cascade_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cascade_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cascade_test_none_multi.A = class A extends core.Object {
    new(x, y) {
      this.x = x;
      this.y = y;
    }
    setX(x) {
      this.x = x;
      return this;
    }
    setY(y) {
      this.y = y;
    }
    swap() {
      let tmp = this.x;
      this.x = this.y;
      this.y = tmp;
      return dart.bind(this, 'swap');
    }
    check(x, y) {
      expect$.Expect.equals(x, this.x);
      expect$.Expect.equals(y, this.y);
    }
    get(i) {
      if (dart.equals(i, 0)) return this.x;
      if (dart.equals(i, 1)) return this.y;
      if (dart.equals(i, "swap")) return dart.bind(this, 'swap');
      return null;
    }
    set(i, value) {
      if (i == 0) {
        this.x = value;
      } else if (i == 1) {
        this.y = value;
      }
      return value;
    }
    import() {
      this.x = dart.notNull(this.x) + 1;
    }
  };
  dart.setSignature(cascade_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(cascade_test_none_multi.A, [core.int, core.int])}),
    methods: () => ({
      setX: dart.definiteFunctionType(cascade_test_none_multi.A, [core.int]),
      setY: dart.definiteFunctionType(dart.void, [core.int]),
      swap: dart.definiteFunctionType(core.Function, []),
      check: dart.definiteFunctionType(dart.void, [core.int, core.int]),
      get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      set: dart.definiteFunctionType(core.int, [core.int, core.int]),
      import: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  cascade_test_none_multi.main = function() {
    let a = new cascade_test_none_multi.A(1, 2);
    a.check(1, 2);
    a.swap();
    a.check(2, 1);
    a.x = 4;
    a.y = 9;
    a.check(4, 9);
    a.setX(10);
    a.check(10, 9);
    a.y = 5;
    a.check(10, 5);
    dart.dcall(dart.dcall(a.swap()));
    a.check(5, 10);
    a.set(0, 2);
    a.check(2, 10);
    a.setX(10).setY(3);
    a.check(10, 3);
    dart.dcall(a.setX(7).get("swap"));
    a.check(3, 7);
    a.import();
    a.check(4, 7);
    dart.dcall(dart.dcall(dart.dcall(a.get("swap"))));
    a.check(7, 4);
    a.check(7, 4);
  };
  dart.fn(cascade_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.cascade_test_none_multi = cascade_test_none_multi;
});
