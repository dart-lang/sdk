dart_library.library('language/number_identity2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__number_identity2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const number_identity2_test = Object.create(null);
  let intTodouble = () => (intTodouble = dart.constFn(dart.definiteFunctionType(core.double, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  number_identity2_test.uint64toDouble = function(i) {
    let buffer = typed_data.Uint8List.new(8)[dartx.buffer];
    let bdata = typed_data.ByteData.view(buffer);
    bdata[dartx.setUint64](0, i);
    return bdata[dartx.getFloat64](0);
  };
  dart.fn(number_identity2_test.uint64toDouble, intTodouble());
  number_identity2_test.testNumberIdentity = function() {
    let a = core.double.NAN;
    let b = dart.notNull(a) + 0.0;
    expect$.Expect.isTrue(core.identical(a, b));
    a = number_identity2_test.uint64toDouble((1)[dartx['<<']](64) - 1);
    b = number_identity2_test.uint64toDouble((1)[dartx['<<']](64) - 2);
    expect$.Expect.isFalse(core.identical(a, b));
    a = 0.0 / 0.0;
    b = 1.0 / 0.0;
    expect$.Expect.isFalse(core.identical(a, b));
  };
  dart.fn(number_identity2_test.testNumberIdentity, VoidTodynamic());
  number_identity2_test.main = function() {
    for (let i = 0; i < 20; i++) {
      number_identity2_test.testNumberIdentity();
    }
  };
  dart.fn(number_identity2_test.main, VoidTodynamic());
  // Exports:
  exports.number_identity2_test = number_identity2_test;
});
