dart_library.library('lib/typed_data/setRange_1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setRange_1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setRange_1_test = Object.create(null);
  const setRange_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  setRange_1_test.sameTypeTest = function() {
    setRange_lib.checkSameSize(setRange_lib.makeInt16List, setRange_lib.makeInt16View, setRange_lib.makeInt16View);
    setRange_lib.checkSameSize(setRange_lib.makeUint16List, setRange_lib.makeUint16View, setRange_lib.makeUint16View);
  };
  dart.fn(setRange_1_test.sameTypeTest, VoidTodynamic());
  setRange_1_test.main = function() {
    setRange_1_test.sameTypeTest();
  };
  dart.fn(setRange_1_test.main, VoidTodynamic());
  setRange_lib.initialize = function(a) {
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(a, 'length'))); i++) {
      dart.dsetindex(a, i, i + 1);
    }
  };
  dart.fn(setRange_lib.initialize, dynamicTodynamic());
  setRange_lib.makeInt16View = function(buffer, byteOffset, length) {
    return typed_data.Int16List.view(typed_data.ByteBuffer._check(buffer), core.int._check(byteOffset), core.int._check(length));
  };
  dart.fn(setRange_lib.makeInt16View, dynamicAnddynamicAnddynamicTodynamic());
  setRange_lib.makeUint16View = function(buffer, byteOffset, length) {
    return typed_data.Uint16List.view(typed_data.ByteBuffer._check(buffer), core.int._check(byteOffset), core.int._check(length));
  };
  dart.fn(setRange_lib.makeUint16View, dynamicAnddynamicAnddynamicTodynamic());
  setRange_lib.makeInt16List = function(length) {
    return typed_data.Int16List.new(core.int._check(length));
  };
  dart.fn(setRange_lib.makeInt16List, dynamicTodynamic());
  setRange_lib.makeUint16List = function(length) {
    return typed_data.Uint16List.new(core.int._check(length));
  };
  dart.fn(setRange_lib.makeUint16List, dynamicTodynamic());
  setRange_lib.checkSameSize = function(constructor0, constructor1, constructor2) {
    let a0 = dart.dcall(constructor0, 9);
    let buffer = dart.dload(a0, 'buffer');
    let a1 = dart.dcall(constructor1, buffer, 0, 7);
    let a2 = dart.dcall(constructor2, buffer, 2 * dart.notNull(core.num._check(dart.dload(a0, 'elementSizeInBytes'))), 7);
    setRange_lib.initialize(a0);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9]', dart.str`${a0}`);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7]', dart.str`${a1}`);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9]', dart.str`${a2}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 7, a2);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9, 8, 9]', dart.str`${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 7, a1);
    expect$.Expect.equals('[1, 2, 1, 2, 3, 4, 5, 6, 7]', dart.str`${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 1, 7, a2);
    expect$.Expect.equals('[1, 3, 4, 5, 6, 7, 8, 8, 9]', dart.str`${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 1, 7, a1);
    expect$.Expect.equals('[1, 2, 3, 1, 2, 3, 4, 5, 6]', dart.str`${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 6, a2, 1);
    expect$.Expect.equals('[4, 5, 6, 7, 8, 9, 7, 8, 9]', dart.str`${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 6, a1, 1);
    expect$.Expect.equals('[1, 2, 2, 3, 4, 5, 6, 7, 9]', dart.str`${a0}`);
  };
  dart.fn(setRange_lib.checkSameSize, dynamicAnddynamicAnddynamicTodynamic());
  // Exports:
  exports.setRange_1_test = setRange_1_test;
  exports.setRange_lib = setRange_lib;
});
