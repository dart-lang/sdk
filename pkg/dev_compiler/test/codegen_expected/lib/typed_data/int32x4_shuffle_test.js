dart_library.library('lib/typed_data/int32x4_shuffle_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int32x4_shuffle_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_shuffle_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int32x4_shuffle_test.testShuffle = function() {
    let m = typed_data.Int32x4.new(1, 2, 3, 4);
    let c = null;
    c = m.shuffle(typed_data.Int32x4.WZYX);
    expect$.Expect.equals(4, dart.dload(c, 'x'));
    expect$.Expect.equals(3, dart.dload(c, 'y'));
    expect$.Expect.equals(2, dart.dload(c, 'z'));
    expect$.Expect.equals(1, dart.dload(c, 'w'));
  };
  dart.fn(int32x4_shuffle_test.testShuffle, VoidTovoid());
  int32x4_shuffle_test.testShuffleNonConstant = function(mask) {
    let m = typed_data.Int32x4.new(1, 2, 3, 4);
    let c = null;
    c = m.shuffle(core.int._check(mask));
    if (dart.equals(mask, 1)) {
      expect$.Expect.equals(2, dart.dload(c, 'x'));
      expect$.Expect.equals(1, dart.dload(c, 'y'));
      expect$.Expect.equals(1, dart.dload(c, 'z'));
      expect$.Expect.equals(1, dart.dload(c, 'w'));
    } else {
      expect$.Expect.equals(dart.notNull(typed_data.Int32x4.YYYY) + 1, mask);
      expect$.Expect.equals(3, dart.dload(c, 'x'));
      expect$.Expect.equals(2, dart.dload(c, 'y'));
      expect$.Expect.equals(2, dart.dload(c, 'z'));
      expect$.Expect.equals(2, dart.dload(c, 'w'));
    }
  };
  dart.fn(int32x4_shuffle_test.testShuffleNonConstant, dynamicTovoid());
  int32x4_shuffle_test.testShuffleMix = function() {
    let m = typed_data.Int32x4.new(1, 2, 3, 4);
    let n = typed_data.Int32x4.new(5, 6, 7, 8);
    let c = m.shuffleMix(n, typed_data.Int32x4.XYXY);
    expect$.Expect.equals(1, c.x);
    expect$.Expect.equals(2, c.y);
    expect$.Expect.equals(5, c.z);
    expect$.Expect.equals(6, c.w);
  };
  dart.fn(int32x4_shuffle_test.testShuffleMix, VoidTovoid());
  int32x4_shuffle_test.main = function() {
    let xxxx = dart.notNull(typed_data.Int32x4.XXXX) + 1;
    let yyyy = dart.notNull(typed_data.Int32x4.YYYY) + 1;
    for (let i = 0; i < 20; i++) {
      int32x4_shuffle_test.testShuffle();
      int32x4_shuffle_test.testShuffleNonConstant(xxxx);
      int32x4_shuffle_test.testShuffleNonConstant(yyyy);
      int32x4_shuffle_test.testShuffleMix();
    }
  };
  dart.fn(int32x4_shuffle_test.main, VoidTodynamic());
  // Exports:
  exports.int32x4_shuffle_test = int32x4_shuffle_test;
});
