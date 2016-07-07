dart_library.library('lib/math/random_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__random_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const random_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  random_test.main = function() {
    random_test.checkSequence();
    random_test.checkSeed();
  };
  dart.fn(random_test.main, VoidTodynamic());
  random_test.checkSequence = function() {
    let rnd = math.Random.new(20130307);
    let i = 1;
    expect$.Expect.equals(0, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(3, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(7, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(5, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(29, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(17, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(104, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(199, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(408, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(362, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(995, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(2561, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(2548, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(9553, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(2628, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(42376, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(101848, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(85153, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(495595, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(647122, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(793546, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(1073343, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(4479969, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(9680425, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(28460171, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(49481738, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(9878974, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(132552472, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(210267283, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(125422442, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(226275094, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(1639629168, rnd.nextInt((i = i * 2)));
    expect$.Expect.equals(4294967296, i);
    expect$.Expect.throws(dart.fn(() => rnd.nextInt(i + 1), VoidToint()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    rnd = math.Random.new(6790);
    expect$.Expect.approxEquals(0.1202733131, rnd.nextDouble());
    expect$.Expect.approxEquals(0.5554054805, rnd.nextDouble());
    expect$.Expect.approxEquals(0.0385160727, rnd.nextDouble());
    expect$.Expect.approxEquals(0.2836345217, rnd.nextDouble());
  };
  dart.fn(random_test.checkSequence, VoidTovoid());
  random_test.checkSeed = function() {
    let rawSeed = 7216285470301553;
    let expectations = JSArrayOfint().of([26007, 43006, 46458, 18610, 16413, 50455, 2164, 47399, 8859, 9732, 20367, 33935, 54549, 54913, 4819, 24198, 49353, 22277, 51852, 35959, 45347, 12100, 10136, 22372, 15293, 20066, 1351, 49030, 64845, 12793, 50916, 55784, 43170, 27653, 34696, 1492, 50255, 9597, 45929, 2874, 27629, 53084, 36064, 42140, 32016, 41751, 13967, 20516, 578, 16773, 53064, 14814, 22737, 48846, 45147, 10205, 56584, 63711, 44128, 21099, 47966, 35471, 39576, 1141, 45716, 54940, 57406, 15437, 31721, 35044, 28136, 39797, 50801, 22184, 58686]);
    let negative_seed_expectations = JSArrayOfint().of([12170, 42844, 39228, 64032, 29046, 57572, 8453, 52224, 27060, 28454, 20510, 28804, 59221, 53422, 11047, 50864, 33997, 19611, 1250, 65088, 19690, 11396, 20, 48867, 44862, 47129, 58724, 13325, 50005, 33320, 16523, 4740, 63721, 63272, 30545, 51403, 35845, 3943, 31850, 23148, 26307, 1724, 29281, 39988, 43653, 48012, 43810, 16755, 13105, 25325, 32648, 19958, 38838, 8322, 3421, 28624, 17269, 45385, 50680, 1696, 26088, 2787, 48566, 34357, 27731, 51764, 8455, 16498, 59721, 59568, 46333, 7935, 51459, 36766, 50711]);
    for (let i = 0, m = 1; i < 75; i++) {
      expect$.Expect.equals(expectations[dartx.get](i), math.Random.new(rawSeed * m).nextInt(65536));
      expect$.Expect.equals(negative_seed_expectations[dartx.get](i), math.Random.new(rawSeed * -m).nextInt(65536));
      m = m * 2;
    }
    expect$.Expect.equals(21391, math.Random.new(0).nextInt(65536));
  };
  dart.fn(random_test.checkSeed, VoidTovoid());
  // Exports:
  exports.random_test = random_test;
});
