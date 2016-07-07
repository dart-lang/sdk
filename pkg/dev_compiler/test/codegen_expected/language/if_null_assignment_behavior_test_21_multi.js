dart_library.library('language/if_null_assignment_behavior_test_21_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__if_null_assignment_behavior_test_21_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const if_null_assignment_behavior_test_21_multi = Object.create(null);
  const if_null_assignment_helper = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.functionType(dart.dynamic, [])))();
  let VoidTodynamic$ = () => (VoidTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAndFnAnddynamicTovoid = () => (dynamicAndFnAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, VoidTodynamic(), dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  if_null_assignment_behavior_test_21_multi.bad = function() {
    expect$.Expect.fail('Should not be executed');
  };
  dart.fn(if_null_assignment_behavior_test_21_multi.bad, VoidTodynamic$());
  if_null_assignment_behavior_test_21_multi.xGetValue = null;
  dart.copyProperties(if_null_assignment_behavior_test_21_multi, {
    get x() {
      if_null_assignment_helper.operations[dartx.add]('x');
      let tmp = if_null_assignment_behavior_test_21_multi.xGetValue;
      if_null_assignment_behavior_test_21_multi.xGetValue = null;
      return tmp;
    },
    set x(value) {
      if_null_assignment_helper.operations[dartx.add](dart.str`x=${value}`);
    }
  });
  if_null_assignment_behavior_test_21_multi.yGetValue = null;
  dart.copyProperties(if_null_assignment_behavior_test_21_multi, {
    get y() {
      if_null_assignment_helper.operations[dartx.add]('y');
      let tmp = if_null_assignment_behavior_test_21_multi.yGetValue;
      if_null_assignment_behavior_test_21_multi.yGetValue = null;
      return tmp;
    },
    set y(value) {
      if_null_assignment_helper.operations[dartx.add](dart.str`y=${value}`);
    }
  });
  if_null_assignment_behavior_test_21_multi.zGetValue = null;
  dart.copyProperties(if_null_assignment_behavior_test_21_multi, {
    get z() {
      if_null_assignment_helper.operations[dartx.add]('z');
      let tmp = if_null_assignment_behavior_test_21_multi.zGetValue;
      if_null_assignment_behavior_test_21_multi.zGetValue = null;
      return tmp;
    },
    set z(value) {
      if_null_assignment_helper.operations[dartx.add](dart.str`z=${value}`);
    }
  });
  if_null_assignment_behavior_test_21_multi.fValue = null;
  if_null_assignment_behavior_test_21_multi.f = function() {
    if_null_assignment_helper.operations[dartx.add]('f()');
    let tmp = if_null_assignment_behavior_test_21_multi.fValue;
    if_null_assignment_behavior_test_21_multi.fValue = null;
    return tmp;
  };
  dart.fn(if_null_assignment_behavior_test_21_multi.f, VoidTodynamic$());
  if_null_assignment_behavior_test_21_multi.check = function(expectedValue, f, expectedOperations) {
    expect$.Expect.equals(expectedValue, f());
    expect$.Expect.listEquals(core.List._check(expectedOperations), if_null_assignment_helper.operations);
    if_null_assignment_helper.operations = JSArrayOfString().of([]);
  };
  dart.fn(if_null_assignment_behavior_test_21_multi.check, dynamicAndFnAnddynamicTovoid());
  if_null_assignment_behavior_test_21_multi.checkThrows = function(expectedException, f, expectedOperations) {
    expect$.Expect.throws(f, expect$._CheckExceptionFn._check(expectedException));
    expect$.Expect.listEquals(core.List._check(expectedOperations), if_null_assignment_helper.operations);
    if_null_assignment_helper.operations = JSArrayOfString().of([]);
  };
  dart.fn(if_null_assignment_behavior_test_21_multi.checkThrows, dynamicAndFnAnddynamicTovoid());
  if_null_assignment_behavior_test_21_multi.noMethod = function(e) {
    return core.NoSuchMethodError.is(e);
  };
  dart.fn(if_null_assignment_behavior_test_21_multi.noMethod, dynamicTodynamic());
  if_null_assignment_behavior_test_21_multi.C = class C extends core.Object {
    new(s) {
      this.s = s;
      this.vGetValue = null;
      this.indexGetValue = null;
      this.finalOne = 1;
      this.finalNull = null;
    }
    toString() {
      return this.s;
    }
    static get x() {
      if_null_assignment_helper.operations[dartx.add]('C.x');
      let tmp = if_null_assignment_behavior_test_21_multi.C.xGetValue;
      if_null_assignment_behavior_test_21_multi.C.xGetValue = null;
      return tmp;
    }
    static set x(value) {
      if_null_assignment_helper.operations[dartx.add](dart.str`C.x=${value}`);
    }
    get v() {
      if_null_assignment_helper.operations[dartx.add](dart.str`${this.s}.v`);
      let tmp = this.vGetValue;
      this.vGetValue = null;
      return tmp;
    }
    set v(value) {
      if_null_assignment_helper.operations[dartx.add](dart.str`${this.s}.v=${value}`);
    }
    get(index) {
      if_null_assignment_helper.operations[dartx.add](dart.str`${this.s}[${index}]`);
      let tmp = this.indexGetValue;
      this.indexGetValue = null;
      return tmp;
    }
    set(index, value) {
      if_null_assignment_helper.operations[dartx.add](dart.str`${this.s}[${index}]=${value}`);
      return value;
    }
    instanceTest() {}
  };
  dart.setSignature(if_null_assignment_behavior_test_21_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(if_null_assignment_behavior_test_21_multi.C, [core.String])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      set: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic]),
      instanceTest: dart.definiteFunctionType(dart.void, [])
    })
  });
  if_null_assignment_behavior_test_21_multi.C.xGetValue = null;
  if_null_assignment_behavior_test_21_multi.D = class D extends if_null_assignment_behavior_test_21_multi.C {
    new(s) {
      super.new(s);
    }
    get v() {
      return if_null_assignment_behavior_test_21_multi.bad();
    }
    set v(value) {
      if_null_assignment_behavior_test_21_multi.bad();
    }
    derivedInstanceTest() {}
  };
  dart.setSignature(if_null_assignment_behavior_test_21_multi.D, {
    constructors: () => ({new: dart.definiteFunctionType(if_null_assignment_behavior_test_21_multi.D, [core.String])}),
    methods: () => ({derivedInstanceTest: dart.definiteFunctionType(dart.void, [])})
  });
  if_null_assignment_behavior_test_21_multi.main = function() {
    let _ = null;
    let t = _;
    t == null ? _ = null : t;
    new if_null_assignment_behavior_test_21_multi.C('c').instanceTest();
    new if_null_assignment_behavior_test_21_multi.D('d').derivedInstanceTest();
    if_null_assignment_behavior_test_21_multi.xGetValue = new if_null_assignment_behavior_test_21_multi.C('x');
    if_null_assignment_behavior_test_21_multi.yGetValue = 1;
    if_null_assignment_behavior_test_21_multi.check(1, dart.fn(() => (() => {
      let o = if_null_assignment_behavior_test_21_multi.x, t = dart.dload(o, 'v');
      return t == null ? dart.dput(o, 'v', if_null_assignment_behavior_test_21_multi.y) : t;
    })(), VoidTodynamic$()), JSArrayOfString().of(['x', 'x.v', 'y', 'x.v=1']));
  };
  dart.fn(if_null_assignment_behavior_test_21_multi.main, VoidTodynamic$());
  dart.defineLazy(if_null_assignment_helper, {
    get operations() {
      return JSArrayOfString().of([]);
    },
    set operations(_) {}
  });
  if_null_assignment_helper.xGetValue = null;
  dart.copyProperties(if_null_assignment_helper, {
    get x() {
      if_null_assignment_helper.operations[dartx.add]('h.x');
      let tmp = if_null_assignment_helper.xGetValue;
      if_null_assignment_helper.xGetValue = null;
      return tmp;
    },
    set x(value) {
      if_null_assignment_helper.operations[dartx.add](dart.str`h.x=${value}`);
    }
  });
  if_null_assignment_helper.C = class C extends core.Object {
    static get x() {
      if_null_assignment_helper.operations[dartx.add]('h.C.x');
      let tmp = if_null_assignment_helper.C.xGetValue;
      if_null_assignment_helper.C.xGetValue = null;
      return tmp;
    }
    static set x(value) {
      if_null_assignment_helper.operations[dartx.add](dart.str`h.C.x=${value}`);
    }
  };
  if_null_assignment_helper.C.xGetValue = null;
  // Exports:
  exports.if_null_assignment_behavior_test_21_multi = if_null_assignment_behavior_test_21_multi;
  exports.if_null_assignment_helper = if_null_assignment_helper;
});
