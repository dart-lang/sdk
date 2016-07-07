dart_library.library('lib/typed_data/constructor_checks_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor_checks_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor_checks_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicToFloat32List = () => (dynamicToFloat32List = dart.constFn(dart.definiteFunctionType(typed_data.Float32List, [dart.dynamic])))();
  let dynamicToFloat64List = () => (dynamicToFloat64List = dart.constFn(dart.definiteFunctionType(typed_data.Float64List, [dart.dynamic])))();
  let dynamicToInt8List = () => (dynamicToInt8List = dart.constFn(dart.definiteFunctionType(typed_data.Int8List, [dart.dynamic])))();
  let dynamicToInt16List = () => (dynamicToInt16List = dart.constFn(dart.definiteFunctionType(typed_data.Int16List, [dart.dynamic])))();
  let dynamicToInt32List = () => (dynamicToInt32List = dart.constFn(dart.definiteFunctionType(typed_data.Int32List, [dart.dynamic])))();
  let dynamicToUint8List = () => (dynamicToUint8List = dart.constFn(dart.definiteFunctionType(typed_data.Uint8List, [dart.dynamic])))();
  let dynamicToUint16List = () => (dynamicToUint16List = dart.constFn(dart.definiteFunctionType(typed_data.Uint16List, [dart.dynamic])))();
  let dynamicToUint32List = () => (dynamicToUint32List = dart.constFn(dart.definiteFunctionType(typed_data.Uint32List, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicToFloat32List = () => (dynamicAnddynamicToFloat32List = dart.constFn(dart.definiteFunctionType(typed_data.Float32List, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicToFloat64List = () => (dynamicAnddynamicToFloat64List = dart.constFn(dart.definiteFunctionType(typed_data.Float64List, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicToInt8List = () => (dynamicAnddynamicToInt8List = dart.constFn(dart.definiteFunctionType(typed_data.Int8List, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicToInt16List = () => (dynamicAnddynamicToInt16List = dart.constFn(dart.definiteFunctionType(typed_data.Int16List, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicToInt32List = () => (dynamicAnddynamicToInt32List = dart.constFn(dart.definiteFunctionType(typed_data.Int32List, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicToUint8List = () => (dynamicAnddynamicToUint8List = dart.constFn(dart.definiteFunctionType(typed_data.Uint8List, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicToUint16List = () => (dynamicAnddynamicToUint16List = dart.constFn(dart.definiteFunctionType(typed_data.Uint16List, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicToUint32List = () => (dynamicAnddynamicToUint32List = dart.constFn(dart.definiteFunctionType(typed_data.Uint32List, [dart.dynamic, dart.dynamic])))();
  constructor_checks_test.checkLengthConstructors = function() {
    function check(creator) {
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, null), VoidTovoid()));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, 8.5), VoidTovoid()));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, '10'), VoidTovoid()));
      let a = dart.dcall(creator, 10);
      expect$.Expect.equals(10, dart.dload(a, 'length'));
    }
    dart.fn(check, dynamicTodynamic());
    check(dart.fn(a => typed_data.Float32List.new(core.int._check(a)), dynamicToFloat32List()));
    check(dart.fn(a => typed_data.Float64List.new(core.int._check(a)), dynamicToFloat64List()));
    check(dart.fn(a => typed_data.Int8List.new(core.int._check(a)), dynamicToInt8List()));
    check(dart.fn(a => typed_data.Int8List.new(core.int._check(a)), dynamicToInt8List()));
    check(dart.fn(a => typed_data.Int16List.new(core.int._check(a)), dynamicToInt16List()));
    check(dart.fn(a => typed_data.Int32List.new(core.int._check(a)), dynamicToInt32List()));
    check(dart.fn(a => typed_data.Uint8List.new(core.int._check(a)), dynamicToUint8List()));
    check(dart.fn(a => typed_data.Uint16List.new(core.int._check(a)), dynamicToUint16List()));
    check(dart.fn(a => typed_data.Uint32List.new(core.int._check(a)), dynamicToUint32List()));
  };
  dart.fn(constructor_checks_test.checkLengthConstructors, VoidTodynamic());
  constructor_checks_test.checkViewConstructors = function() {
    let buffer = typed_data.Int8List.new(256)[dartx.buffer];
    function check1(creator) {
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, 10), VoidTovoid()));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, null), VoidTovoid()));
      let a = dart.dcall(creator, buffer);
      expect$.Expect.equals(buffer, dart.dload(a, 'buffer'));
    }
    dart.fn(check1, dynamicTodynamic());
    function check2(creator) {
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, 10, 0), VoidTovoid()));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, null, 0), VoidTovoid()));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, buffer, null), VoidTovoid()));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, buffer, '8'), VoidTovoid()));
      let a = dart.dcall(creator, buffer, 8);
      expect$.Expect.equals(buffer, dart.dload(a, 'buffer'));
    }
    dart.fn(check2, dynamicTodynamic());
    check1(dart.fn(a => typed_data.Float32List.view(typed_data.ByteBuffer._check(a)), dynamicToFloat32List()));
    check1(dart.fn(a => typed_data.Float64List.view(typed_data.ByteBuffer._check(a)), dynamicToFloat64List()));
    check1(dart.fn(a => typed_data.Int8List.view(typed_data.ByteBuffer._check(a)), dynamicToInt8List()));
    check1(dart.fn(a => typed_data.Int8List.view(typed_data.ByteBuffer._check(a)), dynamicToInt8List()));
    check1(dart.fn(a => typed_data.Int16List.view(typed_data.ByteBuffer._check(a)), dynamicToInt16List()));
    check1(dart.fn(a => typed_data.Int32List.view(typed_data.ByteBuffer._check(a)), dynamicToInt32List()));
    check1(dart.fn(a => typed_data.Uint8List.view(typed_data.ByteBuffer._check(a)), dynamicToUint8List()));
    check1(dart.fn(a => typed_data.Uint16List.view(typed_data.ByteBuffer._check(a)), dynamicToUint16List()));
    check1(dart.fn(a => typed_data.Uint32List.view(typed_data.ByteBuffer._check(a)), dynamicToUint32List()));
    check2(dart.fn((a, b) => typed_data.Float32List.view(typed_data.ByteBuffer._check(a), core.int._check(b)), dynamicAnddynamicToFloat32List()));
    check2(dart.fn((a, b) => typed_data.Float64List.view(typed_data.ByteBuffer._check(a), core.int._check(b)), dynamicAnddynamicToFloat64List()));
    check2(dart.fn((a, b) => typed_data.Int8List.view(typed_data.ByteBuffer._check(a), core.int._check(b)), dynamicAnddynamicToInt8List()));
    check2(dart.fn((a, b) => typed_data.Int8List.view(typed_data.ByteBuffer._check(a), core.int._check(b)), dynamicAnddynamicToInt8List()));
    check2(dart.fn((a, b) => typed_data.Int16List.view(typed_data.ByteBuffer._check(a), core.int._check(b)), dynamicAnddynamicToInt16List()));
    check2(dart.fn((a, b) => typed_data.Int32List.view(typed_data.ByteBuffer._check(a), core.int._check(b)), dynamicAnddynamicToInt32List()));
    check2(dart.fn((a, b) => typed_data.Uint8List.view(typed_data.ByteBuffer._check(a), core.int._check(b)), dynamicAnddynamicToUint8List()));
    check2(dart.fn((a, b) => typed_data.Uint16List.view(typed_data.ByteBuffer._check(a), core.int._check(b)), dynamicAnddynamicToUint16List()));
    check2(dart.fn((a, b) => typed_data.Uint32List.view(typed_data.ByteBuffer._check(a), core.int._check(b)), dynamicAnddynamicToUint32List()));
  };
  dart.fn(constructor_checks_test.checkViewConstructors, VoidTodynamic());
  constructor_checks_test.main = function() {
    constructor_checks_test.checkLengthConstructors();
    constructor_checks_test.checkViewConstructors();
  };
  dart.fn(constructor_checks_test.main, VoidTodynamic());
  // Exports:
  exports.constructor_checks_test = constructor_checks_test;
});
