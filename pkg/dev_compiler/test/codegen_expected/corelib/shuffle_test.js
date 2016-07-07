dart_library.library('corelib/shuffle_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__shuffle_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const typed_data = dart_sdk.typed_data;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const shuffle_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  shuffle_test.main = function() {
    for (let size of JSArrayOfint().of([0, 1, 2, 3, 7, 15, 99, 1023])) {
      let numbers = ListOfint().generate(size, dart.fn(x => x, intToint()));
      shuffle_test.testShuffle(numbers[dartx.toList]({growable: true}));
      shuffle_test.testShuffle(numbers[dartx.toList]({growable: false}));
      shuffle_test.testShuffle((() => {
        let _ = typed_data.Uint32List.new(size);
        _[dartx.setAll](0, numbers);
        return _;
      })());
      shuffle_test.testShuffle((() => {
        let _ = typed_data.Int32List.new(size);
        _[dartx.setAll](0, numbers);
        return _;
      })());
      shuffle_test.testShuffle((() => {
        let _ = typed_data.Uint16List.new(size);
        _[dartx.setAll](0, numbers);
        return _;
      })());
      shuffle_test.testShuffle((() => {
        let _ = typed_data.Int16List.new(size);
        _[dartx.setAll](0, numbers);
        return _;
      })());
      shuffle_test.testShuffle((() => {
        let _ = typed_data.Uint8List.new(size);
        _[dartx.setAll](0, numbers);
        return _;
      })());
      shuffle_test.testShuffle((() => {
        let _ = typed_data.Int8List.new(size);
        _[dartx.setAll](0, numbers);
        return _;
      })());
    }
    let l = JSArrayOfint().of([1, 2]);
    success: {
      for (let i = 0; i < 266; i++) {
        let first = core.int._check(l[dartx.first]);
        l[dartx.shuffle]();
        if (dart.equals(l[dartx.first], first)) break success;
      }
      expect$.Expect.fail("List changes every time.");
    }
    shuffle_test.testRandom();
  };
  dart.fn(shuffle_test.main, VoidTodynamic());
  shuffle_test.testShuffle = function(list) {
    let copy = core.List._check(dart.dsend(list, 'toList'));
    dart.dsend(list, 'shuffle');
    if (dart.test(dart.dsend(dart.dload(list, 'length'), '<', 2))) {
      expect$.Expect.listEquals(copy, core.List._check(list));
      return;
    }
    let seen = dart.map();
    for (let e of core.Iterable._check(list)) {
      seen[dartx.set](e, dart.dsend(seen[dartx.putIfAbsent](e, dart.fn(() => 0, VoidToint())), '+', 1));
    }
    for (let e of copy) {
      let remaining = core.int._check(seen[dartx.get](e));
      remaining = dart.notNull(remaining) - 1;
      if (remaining == 0) {
        seen[dartx.remove](e);
      } else {
        seen[dartx.set](e, remaining);
      }
    }
    expect$.Expect.isTrue(seen[dartx.isEmpty]);
    function listsDifferent() {
      for (let i = 0; i < dart.notNull(core.num._check(dart.dload(list, 'length'))); i++) {
        if (!dart.equals(dart.dindex(list, i), copy[dartx.get](i))) return true;
      }
      return false;
    }
    dart.fn(listsDifferent, VoidTobool());
    if (dart.test(dart.dsend(dart.dload(list, 'length'), '<', 59))) {
      let limit = 1e+80;
      let fact = 1.0;
      for (let i = 2; i < dart.notNull(core.num._check(dart.dload(list, 'length'))); i++) {
        fact = fact * i;
      }
      let combos = fact;
      while (!dart.test(listsDifferent()) && combos < limit) {
        dart.dsend(list, 'shuffle');
        combos = combos * fact;
      }
    }
    if (!dart.test(listsDifferent())) {
      expect$.Expect.fail(dart.str`Didn't shuffle at all, p < 1:1e80: ${list}`);
    }
  };
  dart.fn(shuffle_test.testShuffle, dynamicTovoid());
  shuffle_test.testRandom = function() {
    let randomNums = JSArrayOfint().of([37, 87, 42, 157, 252, 17]);
    let numbers = core.List.generate(25, dart.fn(x => x, intToint()));
    let l1 = numbers[dartx.toList]();
    l1[dartx.shuffle](new shuffle_test.MockRandom(ListOfint()._check(randomNums)));
    for (let i = 0; i < 50; i++) {
      let l2 = numbers[dartx.toList]();
      l2[dartx.shuffle](new shuffle_test.MockRandom(ListOfint()._check(randomNums)));
      expect$.Expect.listEquals(l1, l2);
    }
  };
  dart.fn(shuffle_test.testRandom, VoidTodynamic());
  const _values = Symbol('_values');
  const _next = Symbol('_next');
  shuffle_test.MockRandom = class MockRandom extends core.Object {
    new(values) {
      this[_values] = values;
      this.index = 0;
    }
    get [_next]() {
      let next = this[_values][dartx.get](this.index);
      this.index = (dart.notNull(this.index) + 1)[dartx['%']](this[_values][dartx.length]);
      return next;
    }
    nextInt(limit) {
      return this[_next][dartx['%']](limit);
    }
    nextDouble() {
      return dart.notNull(this[_next]) / 256.0;
    }
    nextBool() {
      return this[_next][dartx.isEven];
    }
  };
  shuffle_test.MockRandom[dart.implements] = () => [math.Random];
  dart.setSignature(shuffle_test.MockRandom, {
    constructors: () => ({new: dart.definiteFunctionType(shuffle_test.MockRandom, [core.List$(core.int)])}),
    methods: () => ({
      nextInt: dart.definiteFunctionType(core.int, [core.int]),
      nextDouble: dart.definiteFunctionType(core.double, []),
      nextBool: dart.definiteFunctionType(core.bool, [])
    })
  });
  // Exports:
  exports.shuffle_test = shuffle_test;
});
