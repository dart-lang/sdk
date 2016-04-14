dart_library.library('byte_data_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const byte_data_test = Object.create(null);
  byte_data_test.main = function() {
    byte_data_test.testRegress10898();
  };
  dart.fn(byte_data_test.main);
  byte_data_test.testRegress10898 = function() {
    let data = typed_data.ByteData.new(16);
    expect$.Expect.equals(16, data[dartx.lengthInBytes]);
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i++) {
      expect$.Expect.equals(0, data[dartx.getInt8](i));
      data[dartx.setInt8](i, 42 + i);
      expect$.Expect.equals(42 + i, data[dartx.getInt8](i));
    }
    let backing = typed_data.ByteData.new(16);
    let view = typed_data.ByteData.view(backing[dartx.buffer]);
    for (let i = 0; i < dart.notNull(view[dartx.lengthInBytes]); i++) {
      expect$.Expect.equals(0, view[dartx.getInt8](i));
      view[dartx.setInt8](i, 87 + i);
      expect$.Expect.equals(87 + i, view[dartx.getInt8](i));
    }
    view = typed_data.ByteData.view(backing[dartx.buffer], 4);
    expect$.Expect.equals(12, view[dartx.lengthInBytes]);
    for (let i = 0; i < dart.notNull(view[dartx.lengthInBytes]); i++) {
      expect$.Expect.equals(87 + i + 4, view[dartx.getInt8](i));
    }
    view = typed_data.ByteData.view(backing[dartx.buffer], 8, 4);
    expect$.Expect.equals(4, view[dartx.lengthInBytes]);
    for (let i = 0; i < dart.notNull(view[dartx.lengthInBytes]); i++) {
      expect$.Expect.equals(87 + i + 8, view[dartx.getInt8](i));
    }
  };
  dart.fn(byte_data_test.testRegress10898);
  // Exports:
  exports.byte_data_test = byte_data_test;
});
dart_library.library('constructor_checks_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor_checks_test = Object.create(null);
  constructor_checks_test.checkLengthConstructors = function() {
    function check(creator) {
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, null), dart.void, []));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, 8.5), dart.void, []));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, '10'), dart.void, []));
      let a = dart.dcall(creator, 10);
      expect$.Expect.equals(10, dart.dload(a, 'length'));
    }
    dart.fn(check);
    check(dart.fn(a => typed_data.Float32List.new(dart.as(a, core.int)), typed_data.Float32List, [dart.dynamic]));
    check(dart.fn(a => typed_data.Float64List.new(dart.as(a, core.int)), typed_data.Float64List, [dart.dynamic]));
    check(dart.fn(a => typed_data.Int8List.new(dart.as(a, core.int)), typed_data.Int8List, [dart.dynamic]));
    check(dart.fn(a => typed_data.Int8List.new(dart.as(a, core.int)), typed_data.Int8List, [dart.dynamic]));
    check(dart.fn(a => typed_data.Int16List.new(dart.as(a, core.int)), typed_data.Int16List, [dart.dynamic]));
    check(dart.fn(a => typed_data.Int32List.new(dart.as(a, core.int)), typed_data.Int32List, [dart.dynamic]));
    check(dart.fn(a => typed_data.Uint8List.new(dart.as(a, core.int)), typed_data.Uint8List, [dart.dynamic]));
    check(dart.fn(a => typed_data.Uint16List.new(dart.as(a, core.int)), typed_data.Uint16List, [dart.dynamic]));
    check(dart.fn(a => typed_data.Uint32List.new(dart.as(a, core.int)), typed_data.Uint32List, [dart.dynamic]));
  };
  dart.fn(constructor_checks_test.checkLengthConstructors);
  constructor_checks_test.checkViewConstructors = function() {
    let buffer = typed_data.Int8List.new(256)[dartx.buffer];
    function check1(creator) {
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, 10), dart.void, []));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, null), dart.void, []));
      let a = dart.dcall(creator, buffer);
      expect$.Expect.equals(buffer, dart.dload(a, 'buffer'));
    }
    dart.fn(check1);
    function check2(creator) {
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, 10, 0), dart.void, []));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, null, 0), dart.void, []));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, buffer, null), dart.void, []));
      expect$.Expect.throws(dart.fn(() => dart.dcall(creator, buffer, '8'), dart.void, []));
      let a = dart.dcall(creator, buffer, 8);
      expect$.Expect.equals(buffer, dart.dload(a, 'buffer'));
    }
    dart.fn(check2);
    check1(dart.fn(a => typed_data.Float32List.view(dart.as(a, typed_data.ByteBuffer)), typed_data.Float32List, [dart.dynamic]));
    check1(dart.fn(a => typed_data.Float64List.view(dart.as(a, typed_data.ByteBuffer)), typed_data.Float64List, [dart.dynamic]));
    check1(dart.fn(a => typed_data.Int8List.view(dart.as(a, typed_data.ByteBuffer)), typed_data.Int8List, [dart.dynamic]));
    check1(dart.fn(a => typed_data.Int8List.view(dart.as(a, typed_data.ByteBuffer)), typed_data.Int8List, [dart.dynamic]));
    check1(dart.fn(a => typed_data.Int16List.view(dart.as(a, typed_data.ByteBuffer)), typed_data.Int16List, [dart.dynamic]));
    check1(dart.fn(a => typed_data.Int32List.view(dart.as(a, typed_data.ByteBuffer)), typed_data.Int32List, [dart.dynamic]));
    check1(dart.fn(a => typed_data.Uint8List.view(dart.as(a, typed_data.ByteBuffer)), typed_data.Uint8List, [dart.dynamic]));
    check1(dart.fn(a => typed_data.Uint16List.view(dart.as(a, typed_data.ByteBuffer)), typed_data.Uint16List, [dart.dynamic]));
    check1(dart.fn(a => typed_data.Uint32List.view(dart.as(a, typed_data.ByteBuffer)), typed_data.Uint32List, [dart.dynamic]));
    check2(dart.fn((a, b) => typed_data.Float32List.view(dart.as(a, typed_data.ByteBuffer), dart.as(b, core.int)), typed_data.Float32List, [dart.dynamic, dart.dynamic]));
    check2(dart.fn((a, b) => typed_data.Float64List.view(dart.as(a, typed_data.ByteBuffer), dart.as(b, core.int)), typed_data.Float64List, [dart.dynamic, dart.dynamic]));
    check2(dart.fn((a, b) => typed_data.Int8List.view(dart.as(a, typed_data.ByteBuffer), dart.as(b, core.int)), typed_data.Int8List, [dart.dynamic, dart.dynamic]));
    check2(dart.fn((a, b) => typed_data.Int8List.view(dart.as(a, typed_data.ByteBuffer), dart.as(b, core.int)), typed_data.Int8List, [dart.dynamic, dart.dynamic]));
    check2(dart.fn((a, b) => typed_data.Int16List.view(dart.as(a, typed_data.ByteBuffer), dart.as(b, core.int)), typed_data.Int16List, [dart.dynamic, dart.dynamic]));
    check2(dart.fn((a, b) => typed_data.Int32List.view(dart.as(a, typed_data.ByteBuffer), dart.as(b, core.int)), typed_data.Int32List, [dart.dynamic, dart.dynamic]));
    check2(dart.fn((a, b) => typed_data.Uint8List.view(dart.as(a, typed_data.ByteBuffer), dart.as(b, core.int)), typed_data.Uint8List, [dart.dynamic, dart.dynamic]));
    check2(dart.fn((a, b) => typed_data.Uint16List.view(dart.as(a, typed_data.ByteBuffer), dart.as(b, core.int)), typed_data.Uint16List, [dart.dynamic, dart.dynamic]));
    check2(dart.fn((a, b) => typed_data.Uint32List.view(dart.as(a, typed_data.ByteBuffer), dart.as(b, core.int)), typed_data.Uint32List, [dart.dynamic, dart.dynamic]));
  };
  dart.fn(constructor_checks_test.checkViewConstructors);
  constructor_checks_test.main = function() {
    constructor_checks_test.checkLengthConstructors();
    constructor_checks_test.checkViewConstructors();
  };
  dart.fn(constructor_checks_test.main);
  // Exports:
  exports.constructor_checks_test = constructor_checks_test;
});
dart_library.library('endianness_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const endianness_test = Object.create(null);
  endianness_test.main = function() {
    endianness_test.swapTest();
    endianness_test.swapTestVar(typed_data.Endianness.LITTLE_ENDIAN, typed_data.Endianness.BIG_ENDIAN);
    endianness_test.swapTestVar(typed_data.Endianness.BIG_ENDIAN, typed_data.Endianness.LITTLE_ENDIAN);
  };
  dart.fn(endianness_test.main);
  endianness_test.swapTest = function() {
    let data = typed_data.ByteData.new(16);
    expect$.Expect.equals(16, data[dartx.lengthInBytes]);
    for (let i = 0; i < 4; i++) {
      data[dartx.setInt32](i * 4, i);
    }
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getInt32](i, typed_data.Endianness.BIG_ENDIAN);
      data[dartx.setInt32](i, e, typed_data.Endianness.LITTLE_ENDIAN);
    }
    expect$.Expect.equals(33554432, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getInt16](i, typed_data.Endianness.BIG_ENDIAN);
      data[dartx.setInt16](i, e, typed_data.Endianness.LITTLE_ENDIAN);
    }
    expect$.Expect.equals(131072, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getUint32](i, typed_data.Endianness.LITTLE_ENDIAN);
      data[dartx.setUint32](i, e, typed_data.Endianness.BIG_ENDIAN);
    }
    expect$.Expect.equals(512, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getUint16](i, typed_data.Endianness.LITTLE_ENDIAN);
      data[dartx.setUint16](i, e, typed_data.Endianness.BIG_ENDIAN);
    }
    expect$.Expect.equals(2, data[dartx.getInt32](8));
  };
  dart.fn(endianness_test.swapTest);
  endianness_test.swapTestVar = function(read, write) {
    let data = typed_data.ByteData.new(16);
    expect$.Expect.equals(16, data[dartx.lengthInBytes]);
    for (let i = 0; i < 4; i++) {
      data[dartx.setInt32](i * 4, i);
    }
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getInt32](i, dart.as(read, typed_data.Endianness));
      data[dartx.setInt32](i, e, dart.as(write, typed_data.Endianness));
    }
    expect$.Expect.equals(33554432, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getInt16](i, dart.as(read, typed_data.Endianness));
      data[dartx.setInt16](i, e, dart.as(write, typed_data.Endianness));
    }
    expect$.Expect.equals(131072, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getUint32](i, dart.as(read, typed_data.Endianness));
      data[dartx.setUint32](i, e, dart.as(write, typed_data.Endianness));
    }
    expect$.Expect.equals(512, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getUint16](i, dart.as(read, typed_data.Endianness));
      data[dartx.setUint16](i, e, dart.as(write, typed_data.Endianness));
    }
    expect$.Expect.equals(2, data[dartx.getInt32](8));
  };
  dart.fn(endianness_test.swapTestVar);
  // Exports:
  exports.endianness_test = endianness_test;
});
dart_library.library('float32x4_clamp_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_clamp_test = Object.create(null);
  float32x4_clamp_test.testClampLowerGreaterThanUpper = function() {
    let l = typed_data.Float32x4.new(1.0, 1.0, 1.0, 1.0);
    let u = typed_data.Float32x4.new(-1.0, -1.0, -1.0, -1.0);
    let z = typed_data.Float32x4.zero();
    let a = z.clamp(l, u);
    expect$.Expect.equals(a.x, 1.0);
    expect$.Expect.equals(a.y, 1.0);
    expect$.Expect.equals(a.z, 1.0);
    expect$.Expect.equals(a.w, 1.0);
  };
  dart.fn(float32x4_clamp_test.testClampLowerGreaterThanUpper, dart.void, []);
  float32x4_clamp_test.testClamp = function() {
    let l = typed_data.Float32x4.new(-1.0, -1.0, -1.0, -1.0);
    let u = typed_data.Float32x4.new(1.0, 1.0, 1.0, 1.0);
    let z = typed_data.Float32x4.zero();
    let a = z.clamp(l, u);
    expect$.Expect.equals(a.x, 0.0);
    expect$.Expect.equals(a.y, 0.0);
    expect$.Expect.equals(a.z, 0.0);
    expect$.Expect.equals(a.w, 0.0);
  };
  dart.fn(float32x4_clamp_test.testClamp, dart.void, []);
  float32x4_clamp_test.main = function() {
    for (let i = 0; i < 2000; i++) {
      float32x4_clamp_test.testClampLowerGreaterThanUpper();
      float32x4_clamp_test.testClamp();
    }
  };
  dart.fn(float32x4_clamp_test.main);
  // Exports:
  exports.float32x4_clamp_test = float32x4_clamp_test;
});
dart_library.library('float32x4_cross_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_cross_test = Object.create(null);
  float32x4_cross_test.cross = function(a, b) {
    let t0 = a.shuffle(typed_data.Float32x4.YZXW);
    let t1 = b.shuffle(typed_data.Float32x4.ZXYW);
    let l = t0['*'](t1);
    t0 = a.shuffle(typed_data.Float32x4.ZXYW);
    t1 = b.shuffle(typed_data.Float32x4.YZXW);
    let r = t0['*'](t1);
    return l['-'](r);
  };
  dart.fn(float32x4_cross_test.cross, typed_data.Float32x4, [typed_data.Float32x4, typed_data.Float32x4]);
  float32x4_cross_test.testCross = function(a, b, r) {
    let x = float32x4_cross_test.cross(a, b);
    expect$.Expect.equals(r.x, x.x);
    expect$.Expect.equals(r.y, x.y);
    expect$.Expect.equals(r.z, x.z);
    expect$.Expect.equals(r.w, x.w);
  };
  dart.fn(float32x4_cross_test.testCross, dart.void, [typed_data.Float32x4, typed_data.Float32x4, typed_data.Float32x4]);
  float32x4_cross_test.main = function() {
    let x = typed_data.Float32x4.new(1.0, 0.0, 0.0, 0.0);
    let y = typed_data.Float32x4.new(0.0, 1.0, 0.0, 0.0);
    let z = typed_data.Float32x4.new(0.0, 0.0, 1.0, 0.0);
    let zero = typed_data.Float32x4.zero();
    for (let i = 0; i < 20; i++) {
      float32x4_cross_test.testCross(x, y, z);
      float32x4_cross_test.testCross(z, x, y);
      float32x4_cross_test.testCross(y, z, x);
      float32x4_cross_test.testCross(z, y, x['unary-']());
      float32x4_cross_test.testCross(x, z, y['unary-']());
      float32x4_cross_test.testCross(y, x, z['unary-']());
      float32x4_cross_test.testCross(x, x, zero);
      float32x4_cross_test.testCross(y, y, zero);
      float32x4_cross_test.testCross(z, z, zero);
      float32x4_cross_test.testCross(x, y, float32x4_cross_test.cross(y['unary-'](), x));
      float32x4_cross_test.testCross(x, y['+'](z), float32x4_cross_test.cross(x, y)['+'](float32x4_cross_test.cross(x, z)));
    }
  };
  dart.fn(float32x4_cross_test.main);
  // Exports:
  exports.float32x4_cross_test = float32x4_cross_test;
});
dart_library.library('float32x4_list_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_list_test = Object.create(null);
  float32x4_list_test.testLoadStore = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(dart.is(array, core.List$(typed_data.Float32x4)));
    dart.dsetindex(array, 0, typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0));
    expect$.Expect.equals(1.0, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(array, 0), 'w'));
    dart.dsetindex(array, 1, dart.dindex(array, 0));
    dart.dsetindex(array, 0, dart.dsend(dart.dindex(array, 0), 'withX', 9.0));
    expect$.Expect.equals(9.0, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(array, 0), 'w'));
    expect$.Expect.equals(1.0, dart.dload(dart.dindex(array, 1), 'x'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(array, 1), 'y'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(array, 1), 'z'));
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(array, 1), 'w'));
  };
  dart.fn(float32x4_list_test.testLoadStore);
  float32x4_list_test.testLoadStoreDeopt = function(array, index, value) {
    dart.dsetindex(array, index, value);
    expect$.Expect.equals(dart.dload(value, 'x'), dart.dload(dart.dindex(array, index), 'x'));
    expect$.Expect.equals(dart.dload(value, 'y'), dart.dload(dart.dindex(array, index), 'y'));
    expect$.Expect.equals(dart.dload(value, 'z'), dart.dload(dart.dindex(array, index), 'z'));
    expect$.Expect.equals(dart.dload(value, 'w'), dart.dload(dart.dindex(array, index), 'w'));
  };
  dart.fn(float32x4_list_test.testLoadStoreDeopt);
  float32x4_list_test.testLoadStoreDeoptDriver = function() {
    let list = typed_data.Float32x4List.new(4);
    let value = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(list, 5, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(null, 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(list, 0, null);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(list, 3.14159, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(list, 0, (4)[dartx.toDouble]());
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(dart.list([typed_data.Float32x4.new(2.0, 3.0, 4.0, 5.0)], typed_data.Float32x4), 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
  };
  dart.fn(float32x4_list_test.testLoadStoreDeoptDriver);
  float32x4_list_test.testListZero = function() {
    let list = typed_data.Float32x4List.new(1);
    expect$.Expect.equals(0.0, list.get(0).x);
    expect$.Expect.equals(0.0, list.get(0).y);
    expect$.Expect.equals(0.0, list.get(0).z);
    expect$.Expect.equals(0.0, list.get(0).w);
  };
  dart.fn(float32x4_list_test.testListZero);
  float32x4_list_test.testView = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(dart.is(array, core.List$(typed_data.Float32x4)));
    expect$.Expect.equals(0.0, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(1.0, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(array, 0), 'w'));
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(array, 1), 'x'));
    expect$.Expect.equals(5.0, dart.dload(dart.dindex(array, 1), 'y'));
    expect$.Expect.equals(6.0, dart.dload(dart.dindex(array, 1), 'z'));
    expect$.Expect.equals(7.0, dart.dload(dart.dindex(array, 1), 'w'));
  };
  dart.fn(float32x4_list_test.testView);
  float32x4_list_test.testSublist = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(dart.is(array, typed_data.Float32x4List));
    let a = dart.dsend(array, 'sublist', 0, 1);
    expect$.Expect.equals(1, dart.dload(a, 'length'));
    expect$.Expect.equals(0.0, dart.dload(dart.dindex(a, 0), 'x'));
    expect$.Expect.equals(1.0, dart.dload(dart.dindex(a, 0), 'y'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(a, 0), 'z'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 1, 2);
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(a, 0), 'x'));
    expect$.Expect.equals(5.0, dart.dload(dart.dindex(a, 0), 'y'));
    expect$.Expect.equals(6.0, dart.dload(dart.dindex(a, 0), 'z'));
    expect$.Expect.equals(7.0, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 0);
    expect$.Expect.equals(dart.dload(a, 'length'), dart.dload(array, 'length'));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(array, 'length'), core.num)); i++) {
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'x'), dart.dload(dart.dindex(a, i), 'x'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'y'), dart.dload(dart.dindex(a, i), 'y'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'z'), dart.dload(dart.dindex(a, i), 'z'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'w'), dart.dload(dart.dindex(a, i), 'w'));
    }
  };
  dart.fn(float32x4_list_test.testSublist);
  float32x4_list_test.testSpecialValues = function(array) {
    function checkEquals(expected, actual) {
      if (dart.notNull(dart.as(dart.dload(expected, 'isNaN'), core.bool))) {
        expect$.Expect.isTrue(dart.dload(actual, 'isNaN'));
      } else if (dart.equals(expected, 0.0) && dart.notNull(dart.as(dart.dload(expected, 'isNegative'), core.bool))) {
        expect$.Expect.isTrue(dart.equals(actual, 0.0) && dart.notNull(dart.as(dart.dload(actual, 'isNegative'), core.bool)));
      } else {
        expect$.Expect.equals(expected, actual);
      }
    }
    dart.fn(checkEquals, dart.void, [dart.dynamic, dart.dynamic]);
    let pairs = dart.list([dart.list([0.0, 0.0], core.double), dart.list([5e-324, 0.0], core.double), dart.list([2.225073858507201e-308, 0.0], core.double), dart.list([2.2250738585072014e-308, 0.0], core.double), dart.list([0.9999999999999999, 1.0], core.double), dart.list([1.0, 1.0], core.double), dart.list([1.0000000000000002, 1.0], core.double), dart.list([4294967295.0, 4294967296.0], core.double), dart.list([4294967296.0, 4294967296.0], core.double), dart.list([4503599627370495.5, 4503599627370496.0], core.double), dart.list([9007199254740992.0, 9007199254740992.0], core.double), dart.list([1.7976931348623157e+308, core.double.INFINITY], core.double), dart.list([0.49999999999999994, 0.5], core.double), dart.list([4503599627370497.0, 4503599627370496.0], core.double), dart.list([9007199254740991.0, 9007199254740992.0], core.double), dart.list([core.double.INFINITY, core.double.INFINITY], core.double), dart.list([core.double.NAN, core.double.NAN], core.double)], core.List$(core.double));
    let conserved = dart.list([1.401298464324817e-45, 1.1754942106924411e-38, 1.1754943508222875e-38, 0.9999999403953552, 1.0000001192092896, 8388607.5, 8388608.0, 3.4028234663852886e+38, 8388609.0, 16777215.0], core.double);
    let minusPairs = pairs[dartx.map](dart.fn(pair => dart.list([-dart.notNull(pair[dartx.get](0)), -dart.notNull(pair[dartx.get](1))], core.double), core.List$(core.double), [core.List$(core.double)]));
    let conservedPairs = conserved[dartx.map](dart.fn(value => dart.list([value, value], core.double), core.List$(core.double), [core.double]));
    let allTests = dart.list([pairs, minusPairs, conservedPairs], core.Iterable$(core.List$(core.double)))[dartx.expand](dart.fn(x => x, core.Iterable$(core.List$(core.double)), [core.Iterable$(core.List$(core.double))]));
    for (let pair of allTests) {
      let input = pair[dartx.get](0);
      let expected = pair[dartx.get](1);
      let f = null;
      f = typed_data.Float32x4.new(input, 2.0, 3.0, 4.0);
      dart.dsetindex(array, 0, f);
      f = dart.dindex(array, 0);
      checkEquals(expected, dart.dload(f, 'x'));
      expect$.Expect.equals(2.0, dart.dload(f, 'y'));
      expect$.Expect.equals(3.0, dart.dload(f, 'z'));
      expect$.Expect.equals(4.0, dart.dload(f, 'w'));
      f = typed_data.Float32x4.new(1.0, input, 3.0, 4.0);
      dart.dsetindex(array, 1, f);
      f = dart.dindex(array, 1);
      expect$.Expect.equals(1.0, dart.dload(f, 'x'));
      checkEquals(expected, dart.dload(f, 'y'));
      expect$.Expect.equals(3.0, dart.dload(f, 'z'));
      expect$.Expect.equals(4.0, dart.dload(f, 'w'));
      f = typed_data.Float32x4.new(1.0, 2.0, input, 4.0);
      dart.dsetindex(array, 2, f);
      f = dart.dindex(array, 2);
      expect$.Expect.equals(1.0, dart.dload(f, 'x'));
      expect$.Expect.equals(2.0, dart.dload(f, 'y'));
      checkEquals(expected, dart.dload(f, 'z'));
      expect$.Expect.equals(4.0, dart.dload(f, 'w'));
      f = typed_data.Float32x4.new(1.0, 2.0, 3.0, input);
      dart.dsetindex(array, 3, f);
      f = dart.dindex(array, 3);
      expect$.Expect.equals(1.0, dart.dload(f, 'x'));
      expect$.Expect.equals(2.0, dart.dload(f, 'y'));
      expect$.Expect.equals(3.0, dart.dload(f, 'z'));
      checkEquals(expected, dart.dload(f, 'w'));
    }
  };
  dart.fn(float32x4_list_test.testSpecialValues, dart.void, [dart.dynamic]);
  float32x4_list_test.main = function() {
    let list = null;
    list = typed_data.Float32x4List.new(8);
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStore(list);
    }
    let floatList = typed_data.Float32List.new(32);
    for (let i = 0; i < dart.notNull(floatList[dartx.length]); i++) {
      floatList[dartx.set](i, i[dartx.toDouble]());
    }
    list = typed_data.Float32x4List.view(floatList[dartx.buffer]);
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testView(list);
    }
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testSublist(list);
    }
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStore(list);
    }
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testListZero();
    }
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testSpecialValues(list);
    }
    float32x4_list_test.testLoadStoreDeoptDriver();
  };
  dart.fn(float32x4_list_test.main);
  // Exports:
  exports.float32x4_list_test = float32x4_list_test;
});
dart_library.library('float32x4_shuffle_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_shuffle_test = Object.create(null);
  float32x4_shuffle_test.testShuffle00 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.XXXX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXXY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXXZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXXW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXYX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXYY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXYZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXYW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXZX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXZY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXZZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXZW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXWX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXWY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXWZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXWW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle00, dart.void, []);
  float32x4_shuffle_test.testShuffle01 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.XYXX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYXY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYXZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYXW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYYX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYYY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYYZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYYW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYZX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYZY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYZZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYZW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYWX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYWY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYWZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYWW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle01, dart.void, []);
  float32x4_shuffle_test.testShuffle02 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.XZXX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZXY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZXZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZXW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZYX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZYY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZYZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZYW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZZX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZZY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZZZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZZW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZWX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZWY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZWZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZWW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle02, dart.void, []);
  float32x4_shuffle_test.testShuffle03 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.XWXX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWXY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWXZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWXW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWYX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWYY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWYZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWYW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWZX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWZY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWZZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWZW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWWX);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWWY);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWWZ);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWWW);
    expect$.Expect.equals(1.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle03, dart.void, []);
  float32x4_shuffle_test.testShuffle10 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.YXXX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXXY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXXZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXXW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXYX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXYY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXYZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXYW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXZX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXZY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXZZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXZW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXWX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXWY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXWZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXWW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle10, dart.void, []);
  float32x4_shuffle_test.testShuffle11 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.YYXX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYXY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYXZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYXW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYYX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYYY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYYZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYYW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYZX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYZY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYZZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYZW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYWX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYWY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYWZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYWW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle11, dart.void, []);
  float32x4_shuffle_test.testShuffle12 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.YZXX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZXY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZXZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZXW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZYX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZYY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZYZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZYW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZZX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZZY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZZZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZZW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZWX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZWY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZWZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZWW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle12, dart.void, []);
  float32x4_shuffle_test.testShuffle13 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.YWXX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWXY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWXZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWXW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWYX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWYY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWYZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWYW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWZX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWZY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWZZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWZW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWWX);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWWY);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWWZ);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWWW);
    expect$.Expect.equals(2.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle13, dart.void, []);
  float32x4_shuffle_test.testShuffle20 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.ZXXX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXXY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXXZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXXW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXYX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXYY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXYZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXYW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXZX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXZY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXZZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXZW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXWX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXWY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXWZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXWW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle20, dart.void, []);
  float32x4_shuffle_test.testShuffle21 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.ZYXX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYXY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYXZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYXW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYYX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYYY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYYZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYYW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYZX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYZY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYZZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYZW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYWX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYWY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYWZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYWW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle21, dart.void, []);
  float32x4_shuffle_test.testShuffle22 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.ZZXX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZXY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZXZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZXW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZYX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZYY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZYZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZYW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZZX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZZY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZZZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZZW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZWX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZWY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZWZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZWW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle22, dart.void, []);
  float32x4_shuffle_test.testShuffle23 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.ZWXX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWXY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWXZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWXW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWYX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWYY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWYZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWYW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWZX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWZY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWZZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWZW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWWX);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWWY);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWWZ);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWWW);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle23, dart.void, []);
  float32x4_shuffle_test.testShuffle30 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WXXX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXXY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXXZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXXW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXYX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXYY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXYZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXYW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXZX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXZY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXZZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXZW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXWX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXWY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXWZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXWW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(1.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle30, dart.void, []);
  float32x4_shuffle_test.testShuffle31 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WYXX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYXY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYXZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYXW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYYX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYYY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYYZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYYW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYZX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYZY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYZZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYZW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYWX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYWY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYWZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYWW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(2.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle31, dart.void, []);
  float32x4_shuffle_test.testShuffle32 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WZXX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZXY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZXZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZXW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZYX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZYY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZYZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZYW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZZX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZZY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZZZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZZW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZWX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZWY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZWZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZWW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle32, dart.void, []);
  float32x4_shuffle_test.testShuffle33 = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WWXX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWXY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWXZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWXW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(1.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWYX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWYY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWYZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWYW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWZX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWZY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWZZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWZW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(3.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWWX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWWY);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWWZ);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWWW);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(4.0, dart.dload(c, 'y'));
    expect$.Expect.equals(4.0, dart.dload(c, 'z'));
    expect$.Expect.equals(4.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle33, dart.void, []);
  float32x4_shuffle_test.testShuffleNonConstant = function(mask) {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(dart.as(mask, core.int));
    if (dart.equals(mask, 1)) {
      expect$.Expect.equals(2.0, dart.dload(c, 'x'));
      expect$.Expect.equals(1.0, dart.dload(c, 'y'));
      expect$.Expect.equals(1.0, dart.dload(c, 'z'));
      expect$.Expect.equals(1.0, dart.dload(c, 'w'));
    } else {
      expect$.Expect.equals(dart.notNull(typed_data.Float32x4.YYYY) + 1, mask);
      expect$.Expect.equals(3.0, dart.dload(c, 'x'));
      expect$.Expect.equals(2.0, dart.dload(c, 'y'));
      expect$.Expect.equals(2.0, dart.dload(c, 'z'));
      expect$.Expect.equals(2.0, dart.dload(c, 'w'));
    }
  };
  dart.fn(float32x4_shuffle_test.testShuffleNonConstant, dart.void, [dart.dynamic]);
  float32x4_shuffle_test.testInvalidShuffle = function(mask) {
    expect$.Expect.isFalse(dart.notNull(dart.as(dart.dsend(mask, '<=', 255), core.bool)) && dart.notNull(dart.as(dart.dsend(mask, '>=', 0), core.bool)));
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    expect$.Expect.throws(dart.fn(() => {
      c = m.shuffle(dart.as(mask, core.int));
    }, dart.void, []));
  };
  dart.fn(float32x4_shuffle_test.testInvalidShuffle, dart.void, [dart.dynamic]);
  float32x4_shuffle_test.testShuffle = function() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WZYX);
    expect$.Expect.equals(4.0, dart.dload(c, 'x'));
    expect$.Expect.equals(3.0, dart.dload(c, 'y'));
    expect$.Expect.equals(2.0, dart.dload(c, 'z'));
    expect$.Expect.equals(1.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_shuffle_test.testShuffle, dart.void, []);
  float32x4_shuffle_test.main = function() {
    let xxxx = dart.notNull(typed_data.Float32x4.XXXX) + 1;
    let yyyy = dart.notNull(typed_data.Float32x4.YYYY) + 1;
    for (let i = 0; i < 20; i++) {
      float32x4_shuffle_test.testShuffle();
      float32x4_shuffle_test.testShuffle00();
      float32x4_shuffle_test.testShuffle01();
      float32x4_shuffle_test.testShuffle02();
      float32x4_shuffle_test.testShuffle03();
      float32x4_shuffle_test.testShuffle10();
      float32x4_shuffle_test.testShuffle11();
      float32x4_shuffle_test.testShuffle12();
      float32x4_shuffle_test.testShuffle13();
      float32x4_shuffle_test.testShuffle20();
      float32x4_shuffle_test.testShuffle21();
      float32x4_shuffle_test.testShuffle22();
      float32x4_shuffle_test.testShuffle23();
      float32x4_shuffle_test.testShuffle30();
      float32x4_shuffle_test.testShuffle31();
      float32x4_shuffle_test.testShuffle32();
      float32x4_shuffle_test.testShuffle33();
      float32x4_shuffle_test.testShuffleNonConstant(xxxx);
      float32x4_shuffle_test.testShuffleNonConstant(yyyy);
      float32x4_shuffle_test.testInvalidShuffle(256);
      float32x4_shuffle_test.testInvalidShuffle(-1);
    }
  };
  dart.fn(float32x4_shuffle_test.main);
  // Exports:
  exports.float32x4_shuffle_test = float32x4_shuffle_test;
});
dart_library.library('float32x4_sign_mask_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_sign_mask_test = Object.create(null);
  float32x4_sign_mask_test.testImmediates = function() {
    let f = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let m = f.signMask;
    expect$.Expect.equals(0, m);
    f = typed_data.Float32x4.new(-1.0, -2.0, -3.0, -0.0);
    m = f.signMask;
    expect$.Expect.equals(15, m);
    f = typed_data.Float32x4.new(-1.0, 2.0, 3.0, 4.0);
    m = f.signMask;
    expect$.Expect.equals(1, m);
    f = typed_data.Float32x4.new(1.0, -2.0, 3.0, 4.0);
    m = f.signMask;
    expect$.Expect.equals(2, m);
    f = typed_data.Float32x4.new(1.0, 2.0, -3.0, 4.0);
    m = f.signMask;
    expect$.Expect.equals(4, m);
    f = typed_data.Float32x4.new(1.0, 2.0, 3.0, -4.0);
    m = f.signMask;
    expect$.Expect.equals(8, m);
  };
  dart.fn(float32x4_sign_mask_test.testImmediates, dart.void, []);
  float32x4_sign_mask_test.testZero = function() {
    let f = typed_data.Float32x4.new(0.0, 0.0, 0.0, 0.0);
    let m = f.signMask;
    expect$.Expect.equals(0, m);
    f = typed_data.Float32x4.new(-0.0, -0.0, -0.0, -0.0);
    m = f.signMask;
    expect$.Expect.equals(15, m);
  };
  dart.fn(float32x4_sign_mask_test.testZero, dart.void, []);
  float32x4_sign_mask_test.testArithmetic = function() {
    let a = typed_data.Float32x4.new(1.0, 1.0, 1.0, 1.0);
    let b = typed_data.Float32x4.new(2.0, 2.0, 2.0, 2.0);
    let c = typed_data.Float32x4.new(-1.0, -1.0, -1.0, -1.0);
    let m1 = a['-'](b).signMask;
    expect$.Expect.equals(15, m1);
    let m2 = b['-'](a).signMask;
    expect$.Expect.equals(0, m2);
    let m3 = c['*'](c).signMask;
    expect$.Expect.equals(0, m3);
    let m4 = a['*'](c).signMask;
    expect$.Expect.equals(15, m4);
  };
  dart.fn(float32x4_sign_mask_test.testArithmetic, dart.void, []);
  float32x4_sign_mask_test.main = function() {
    for (let i = 0; i < 2000; i++) {
      float32x4_sign_mask_test.testImmediates();
      float32x4_sign_mask_test.testZero();
      float32x4_sign_mask_test.testArithmetic();
    }
  };
  dart.fn(float32x4_sign_mask_test.main);
  // Exports:
  exports.float32x4_sign_mask_test = float32x4_sign_mask_test;
});
dart_library.library('float32x4_transpose_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_transpose_test = Object.create(null);
  float32x4_transpose_test.transpose = function(m) {
    expect$.Expect.equals(4, m.length);
    let m0 = m.get(0);
    let m1 = m.get(1);
    let m2 = m.get(2);
    let m3 = m.get(3);
    let t0 = m0.shuffleMix(m1, typed_data.Float32x4.XYXY);
    let t1 = m2.shuffleMix(m3, typed_data.Float32x4.XYXY);
    m.set(0, t0.shuffleMix(t1, typed_data.Float32x4.XZXZ));
    m.set(1, t0.shuffleMix(t1, typed_data.Float32x4.YWYW));
    let t2 = m0.shuffleMix(m1, typed_data.Float32x4.ZWZW);
    let t3 = m2.shuffleMix(m3, typed_data.Float32x4.ZWZW);
    m.set(2, t2.shuffleMix(t3, typed_data.Float32x4.XZXZ));
    m.set(3, t2.shuffleMix(t3, typed_data.Float32x4.YWYW));
  };
  dart.fn(float32x4_transpose_test.transpose, dart.void, [typed_data.Float32x4List]);
  float32x4_transpose_test.testTranspose = function(m, r) {
    float32x4_transpose_test.transpose(m);
    for (let i = 0; i < 4; i++) {
      let a = m.get(i);
      let b = r.get(i);
      expect$.Expect.equals(b.x, a.x);
      expect$.Expect.equals(b.y, a.y);
      expect$.Expect.equals(b.z, a.z);
      expect$.Expect.equals(b.w, a.w);
    }
  };
  dart.fn(float32x4_transpose_test.testTranspose, dart.void, [typed_data.Float32x4List, typed_data.Float32x4List]);
  float32x4_transpose_test.main = function() {
    let A = typed_data.Float32x4List.new(4);
    A.set(0, typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0));
    A.set(1, typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0));
    A.set(2, typed_data.Float32x4.new(9.0, 10.0, 11.0, 12.0));
    A.set(3, typed_data.Float32x4.new(13.0, 14.0, 15.0, 16.0));
    let B = typed_data.Float32x4List.new(4);
    B.set(0, typed_data.Float32x4.new(1.0, 5.0, 9.0, 13.0));
    B.set(1, typed_data.Float32x4.new(2.0, 6.0, 10.0, 14.0));
    B.set(2, typed_data.Float32x4.new(3.0, 7.0, 11.0, 15.0));
    B.set(3, typed_data.Float32x4.new(4.0, 8.0, 12.0, 16.0));
    let I = typed_data.Float32x4List.new(4);
    I.set(0, typed_data.Float32x4.new(1.0, 0.0, 0.0, 0.0));
    I.set(1, typed_data.Float32x4.new(0.0, 1.0, 0.0, 0.0));
    I.set(2, typed_data.Float32x4.new(0.0, 0.0, 1.0, 0.0));
    I.set(3, typed_data.Float32x4.new(0.0, 0.0, 0.0, 1.0));
    for (let i = 0; i < 20; i++) {
      let m = typed_data.Float32x4List.fromList(I);
      float32x4_transpose_test.testTranspose(m, I);
      m = typed_data.Float32x4List.fromList(A);
      float32x4_transpose_test.testTranspose(m, B);
    }
  };
  dart.fn(float32x4_transpose_test.main);
  // Exports:
  exports.float32x4_transpose_test = float32x4_transpose_test;
});
dart_library.library('float32x4_two_arg_shuffle_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_two_arg_shuffle_test = Object.create(null);
  float32x4_two_arg_shuffle_test.testWithZWInXY = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = b.shuffleMix(a, typed_data.Float32x4.ZWZW);
    expect$.Expect.equals(7.0, c.x);
    expect$.Expect.equals(8.0, c.y);
    expect$.Expect.equals(3.0, c.z);
    expect$.Expect.equals(4.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testWithZWInXY);
  float32x4_two_arg_shuffle_test.testInterleaveXY = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.XYXY).shuffle(typed_data.Float32x4.XZYW);
    expect$.Expect.equals(1.0, c.x);
    expect$.Expect.equals(5.0, c.y);
    expect$.Expect.equals(2.0, c.z);
    expect$.Expect.equals(6.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testInterleaveXY);
  float32x4_two_arg_shuffle_test.testInterleaveZW = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.ZWZW).shuffle(typed_data.Float32x4.XZYW);
    expect$.Expect.equals(3.0, c.x);
    expect$.Expect.equals(7.0, c.y);
    expect$.Expect.equals(4.0, c.z);
    expect$.Expect.equals(8.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testInterleaveZW);
  float32x4_two_arg_shuffle_test.testInterleaveXYPairs = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.XYXY);
    expect$.Expect.equals(1.0, c.x);
    expect$.Expect.equals(2.0, c.y);
    expect$.Expect.equals(5.0, c.z);
    expect$.Expect.equals(6.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testInterleaveXYPairs);
  float32x4_two_arg_shuffle_test.testInterleaveZWPairs = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.ZWZW);
    expect$.Expect.equals(3.0, c.x);
    expect$.Expect.equals(4.0, c.y);
    expect$.Expect.equals(7.0, c.z);
    expect$.Expect.equals(8.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testInterleaveZWPairs);
  float32x4_two_arg_shuffle_test.main = function() {
    for (let i = 0; i < 20; i++) {
      float32x4_two_arg_shuffle_test.testWithZWInXY();
      float32x4_two_arg_shuffle_test.testInterleaveXY();
      float32x4_two_arg_shuffle_test.testInterleaveZW();
      float32x4_two_arg_shuffle_test.testInterleaveXYPairs();
      float32x4_two_arg_shuffle_test.testInterleaveZWPairs();
    }
  };
  dart.fn(float32x4_two_arg_shuffle_test.main);
  // Exports:
  exports.float32x4_two_arg_shuffle_test = float32x4_two_arg_shuffle_test;
});
dart_library.library('float32x4_unbox_phi_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_unbox_phi_test = Object.create(null);
  float32x4_unbox_phi_test.testUnboxPhi = function(data) {
    let res = typed_data.Float32x4.zero();
    for (let i = 0; i < dart.notNull(data.length); i++) {
      res = res['+'](data.get(i));
    }
    return dart.notNull(res.x) + dart.notNull(res.y) + dart.notNull(res.z) + dart.notNull(res.w);
  };
  dart.fn(float32x4_unbox_phi_test.testUnboxPhi, core.double, [typed_data.Float32x4List]);
  float32x4_unbox_phi_test.main = function() {
    let list = typed_data.Float32x4List.new(10);
    let floatList = typed_data.Float32List.view(list.buffer);
    for (let i = 0; i < dart.notNull(floatList[dartx.length]); i++) {
      floatList[dartx.set](i, i[dartx.toDouble]());
    }
    for (let i = 0; i < 20; i++) {
      let r = float32x4_unbox_phi_test.testUnboxPhi(list);
      expect$.Expect.equals(780.0, r);
    }
  };
  dart.fn(float32x4_unbox_phi_test.main);
  // Exports:
  exports.float32x4_unbox_phi_test = float32x4_unbox_phi_test;
});
dart_library.library('float32x4_unbox_regress_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_unbox_regress_test = Object.create(null);
  float32x4_unbox_regress_test.testListStore = function(array, index, value) {
    dart.dsetindex(array, index, value);
  };
  dart.fn(float32x4_unbox_regress_test.testListStore);
  float32x4_unbox_regress_test.testListStoreDeopt = function() {
    let list = null;
    let value = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let smi = 12;
    list = typed_data.Float32x4List.new(8);
    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testListStore(list, 0, value);
    }
    try {
      float32x4_unbox_regress_test.testListStore(list, 0, smi);
    } catch (_) {
    }

  };
  dart.fn(float32x4_unbox_regress_test.testListStoreDeopt, dart.void, []);
  float32x4_unbox_regress_test.testAdd = function(a, b) {
    let c = dart.dsend(a, '+', b);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(5.0, dart.dload(c, 'y'));
    expect$.Expect.equals(7.0, dart.dload(c, 'z'));
    expect$.Expect.equals(9.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_unbox_regress_test.testAdd);
  float32x4_unbox_regress_test.testAddDeopt = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(2.0, 3.0, 4.0, 5.0);
    let smi = 12;
    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testAdd(a, b);
    }
    try {
      float32x4_unbox_regress_test.testAdd(a, smi);
    } catch (_) {
    }

  };
  dart.fn(float32x4_unbox_regress_test.testAddDeopt, dart.void, []);
  float32x4_unbox_regress_test.testGet = function(a) {
    let c = dart.dsend(dart.dsend(dart.dsend(dart.dload(a, 'x'), '+', dart.dload(a, 'y')), '+', dart.dload(a, 'z')), '+', dart.dload(a, 'w'));
    expect$.Expect.equals(10.0, c);
  };
  dart.fn(float32x4_unbox_regress_test.testGet);
  float32x4_unbox_regress_test.testGetDeopt = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let smi = 12;
    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testGet(a);
    }
    try {
      float32x4_unbox_regress_test.testGet(12);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testGet(a);
    }
  };
  dart.fn(float32x4_unbox_regress_test.testGetDeopt, dart.void, []);
  float32x4_unbox_regress_test.testComparison = function(a, b) {
    let r = dart.as(dart.dsend(a, 'equal', b), typed_data.Int32x4);
    expect$.Expect.equals(true, r.flagX);
    expect$.Expect.equals(false, r.flagY);
    expect$.Expect.equals(false, r.flagZ);
    expect$.Expect.equals(true, r.flagW);
  };
  dart.fn(float32x4_unbox_regress_test.testComparison, dart.void, [dart.dynamic, dart.dynamic]);
  float32x4_unbox_regress_test.testComparisonDeopt = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(1.0, 2.1, 3.1, 4.0);
    let smi = 12;
    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testComparison(a, b);
    }
    try {
      float32x4_unbox_regress_test.testComparison(a, smi);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testComparison(a, b);
    }
    try {
      float32x4_unbox_regress_test.testComparison(smi, a);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testComparison(a, b);
    }
  };
  dart.fn(float32x4_unbox_regress_test.testComparisonDeopt, dart.void, []);
  float32x4_unbox_regress_test.main = function() {
    float32x4_unbox_regress_test.testListStoreDeopt();
    float32x4_unbox_regress_test.testAddDeopt();
    float32x4_unbox_regress_test.testGetDeopt();
    float32x4_unbox_regress_test.testComparisonDeopt();
  };
  dart.fn(float32x4_unbox_regress_test.main);
  // Exports:
  exports.float32x4_unbox_regress_test = float32x4_unbox_regress_test;
});
dart_library.library('float64x2_typed_list_test', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const float64x2_typed_list_test = Object.create(null);
  float64x2_typed_list_test.test = function(l) {
    let a = l.get(0);
    let b = l.get(1);
    l.set(0, b);
    l.set(1, a);
  };
  dart.fn(float64x2_typed_list_test.test, dart.void, [typed_data.Float64x2List]);
  float64x2_typed_list_test.compare = function(a, b) {
    return dart.equals(dart.dload(a, 'x'), dart.dload(b, 'x')) && dart.equals(dart.dload(a, 'y'), dart.dload(b, 'y'));
  };
  dart.fn(float64x2_typed_list_test.compare, core.bool, [dart.dynamic, dart.dynamic]);
  float64x2_typed_list_test.main = function() {
    let l = typed_data.Float64x2List.new(2);
    let a = typed_data.Float64x2.new(1.0, 2.0);
    let b = typed_data.Float64x2.new(3.0, 4.0);
    l.set(0, a);
    l.set(1, b);
    for (let i = 0; i < 41; i++) {
      float64x2_typed_list_test.test(l);
    }
    if (!dart.notNull(float64x2_typed_list_test.compare(l.get(0), b)) || !dart.notNull(float64x2_typed_list_test.compare(l.get(1), a))) {
      dart.throw(123);
    }
  };
  dart.fn(float64x2_typed_list_test.main);
  // Exports:
  exports.float64x2_typed_list_test = float64x2_typed_list_test;
});
dart_library.library('int32x4_arithmetic_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_arithmetic_test = Object.create(null);
  int32x4_arithmetic_test.testAdd = function() {
    let m = typed_data.Int32x4.new(0, 0, 0, 0);
    let n = typed_data.Int32x4.new(-1, -1, -1, -1);
    let o = m['+'](n);
    expect$.Expect.equals(-1, o.x);
    expect$.Expect.equals(-1, o.y);
    expect$.Expect.equals(-1, o.z);
    expect$.Expect.equals(-1, o.w);
    m = typed_data.Int32x4.new(0, 0, 0, 0);
    n = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    o = m['+'](n);
    expect$.Expect.equals(-1, o.x);
    expect$.Expect.equals(-1, o.y);
    expect$.Expect.equals(-1, o.z);
    expect$.Expect.equals(-1, o.w);
    n = typed_data.Int32x4.new(1, 1, 1, 1);
    m = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    o = m['+'](n);
    expect$.Expect.equals(0, o.x);
    expect$.Expect.equals(0, o.y);
    expect$.Expect.equals(0, o.z);
    expect$.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    m = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    o = m['+'](n);
    expect$.Expect.equals(-2, o.x);
    expect$.Expect.equals(-2, o.y);
    expect$.Expect.equals(-2, o.z);
    expect$.Expect.equals(-2, o.w);
    n = typed_data.Int32x4.new(1, 0, 0, 0);
    m = typed_data.Int32x4.new(2, 0, 0, 0);
    o = n['+'](m);
    expect$.Expect.equals(3, o.x);
    expect$.Expect.equals(0, o.y);
    expect$.Expect.equals(0, o.z);
    expect$.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(1, 3, 0, 0);
    m = typed_data.Int32x4.new(2, 4, 0, 0);
    o = n['+'](m);
    expect$.Expect.equals(3, o.x);
    expect$.Expect.equals(7, o.y);
    expect$.Expect.equals(0, o.z);
    expect$.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(1, 3, 5, 0);
    m = typed_data.Int32x4.new(2, 4, 6, 0);
    o = n['+'](m);
    expect$.Expect.equals(3, o.x);
    expect$.Expect.equals(7, o.y);
    expect$.Expect.equals(11, o.z);
    expect$.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(1, 3, 5, 7);
    m = typed_data.Int32x4.new(-2, -4, -6, -8);
    o = n['+'](m);
    expect$.Expect.equals(-1, o.x);
    expect$.Expect.equals(-1, o.y);
    expect$.Expect.equals(-1, o.z);
    expect$.Expect.equals(-1, o.w);
  };
  dart.fn(int32x4_arithmetic_test.testAdd);
  int32x4_arithmetic_test.testSub = function() {
    let m = typed_data.Int32x4.new(0, 0, 0, 0);
    let n = typed_data.Int32x4.new(1, 1, 1, 1);
    let o = m['-'](n);
    expect$.Expect.equals(-1, o.x);
    expect$.Expect.equals(-1, o.y);
    expect$.Expect.equals(-1, o.z);
    expect$.Expect.equals(-1, o.w);
    o = n['-'](m);
    expect$.Expect.equals(1, o.x);
    expect$.Expect.equals(1, o.y);
    expect$.Expect.equals(1, o.z);
    expect$.Expect.equals(1, o.w);
  };
  dart.fn(int32x4_arithmetic_test.testSub);
  int32x4_arithmetic_test.main = function() {
    for (let i = 0; i < 20; i++) {
      int32x4_arithmetic_test.testAdd();
      int32x4_arithmetic_test.testSub();
    }
  };
  dart.fn(int32x4_arithmetic_test.main);
  // Exports:
  exports.int32x4_arithmetic_test = int32x4_arithmetic_test;
});
dart_library.library('int32x4_bigint_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_bigint_test = Object.create(null);
  int32x4_bigint_test.main = function() {
    let n = 18446744073709551617;
    let x = typed_data.Int32x4.new(n, 0, 0, 0);
    expect$.Expect.equals(x.x, 1);
  };
  dart.fn(int32x4_bigint_test.main);
  // Exports:
  exports.int32x4_bigint_test = int32x4_bigint_test;
});
dart_library.library('int32x4_list_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_list_test = Object.create(null);
  int32x4_list_test.testLoadStore = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(dart.is(array, core.List$(typed_data.Int32x4)));
    dart.dsetindex(array, 0, typed_data.Int32x4.new(1, 2, 3, 4));
    expect$.Expect.equals(1, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(4, dart.dload(dart.dindex(array, 0), 'w'));
    dart.dsetindex(array, 1, dart.dindex(array, 0));
    dart.dsetindex(array, 0, dart.dsend(dart.dindex(array, 0), 'withX', 9));
    expect$.Expect.equals(9, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(4, dart.dload(dart.dindex(array, 0), 'w'));
    expect$.Expect.equals(1, dart.dload(dart.dindex(array, 1), 'x'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(array, 1), 'y'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(array, 1), 'z'));
    expect$.Expect.equals(4, dart.dload(dart.dindex(array, 1), 'w'));
  };
  dart.fn(int32x4_list_test.testLoadStore);
  int32x4_list_test.testLoadStoreDeopt = function(array, index, value) {
    dart.dsetindex(array, index, value);
    expect$.Expect.equals(dart.dload(value, 'x'), dart.dload(dart.dindex(array, index), 'x'));
    expect$.Expect.equals(dart.dload(value, 'y'), dart.dload(dart.dindex(array, index), 'y'));
    expect$.Expect.equals(dart.dload(value, 'z'), dart.dload(dart.dindex(array, index), 'z'));
    expect$.Expect.equals(dart.dload(value, 'w'), dart.dload(dart.dindex(array, index), 'w'));
  };
  dart.fn(int32x4_list_test.testLoadStoreDeopt);
  int32x4_list_test.testLoadStoreDeoptDriver = function() {
    let list = typed_data.Int32x4List.new(4);
    let value = typed_data.Int32x4.new(1, 2, 3, 4);
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(list, 5, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(null, 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(list, 0, null);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(list, 3.14159, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(list, 0, (4)[dartx.toDouble]());
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(dart.list([typed_data.Int32x4.new(2, 3, 4, 5)], typed_data.Int32x4), 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
  };
  dart.fn(int32x4_list_test.testLoadStoreDeoptDriver);
  int32x4_list_test.testListZero = function() {
    let list = typed_data.Int32x4List.new(1);
    expect$.Expect.equals(0, list.get(0).x);
    expect$.Expect.equals(0, list.get(0).y);
    expect$.Expect.equals(0, list.get(0).z);
    expect$.Expect.equals(0, list.get(0).w);
  };
  dart.fn(int32x4_list_test.testListZero);
  int32x4_list_test.testView = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(dart.is(array, core.List$(typed_data.Int32x4)));
    expect$.Expect.equals(0, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(1, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(array, 0), 'w'));
    expect$.Expect.equals(4, dart.dload(dart.dindex(array, 1), 'x'));
    expect$.Expect.equals(5, dart.dload(dart.dindex(array, 1), 'y'));
    expect$.Expect.equals(6, dart.dload(dart.dindex(array, 1), 'z'));
    expect$.Expect.equals(7, dart.dload(dart.dindex(array, 1), 'w'));
  };
  dart.fn(int32x4_list_test.testView);
  int32x4_list_test.testSublist = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(dart.is(array, typed_data.Int32x4List));
    let a = dart.dsend(array, 'sublist', 0, 1);
    expect$.Expect.equals(1, dart.dload(a, 'length'));
    expect$.Expect.equals(0, dart.dload(dart.dindex(a, 0), 'x'));
    expect$.Expect.equals(1, dart.dload(dart.dindex(a, 0), 'y'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(a, 0), 'z'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 1, 2);
    expect$.Expect.equals(4, dart.dload(dart.dindex(a, 0), 'x'));
    expect$.Expect.equals(5, dart.dload(dart.dindex(a, 0), 'y'));
    expect$.Expect.equals(6, dart.dload(dart.dindex(a, 0), 'z'));
    expect$.Expect.equals(7, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 0);
    expect$.Expect.equals(dart.dload(a, 'length'), dart.dload(array, 'length'));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(array, 'length'), core.num)); i++) {
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'x'), dart.dload(dart.dindex(a, i), 'x'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'y'), dart.dload(dart.dindex(a, i), 'y'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'z'), dart.dload(dart.dindex(a, i), 'z'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'w'), dart.dload(dart.dindex(a, i), 'w'));
    }
  };
  dart.fn(int32x4_list_test.testSublist);
  int32x4_list_test.testSpecialValues = function(array) {
    let tests = dart.list([dart.list([2410207675578512, 878082192], core.int), dart.list([2410209554626704, -1537836912], core.int), dart.list([2147483648, -2147483648], core.int), dart.list([-2147483648, -2147483648], core.int), dart.list([2147483647, 2147483647], core.int), dart.list([-2147483647, -2147483647], core.int)], core.List$(core.int));
    let int32x4 = null;
    for (let test of tests) {
      let input = test[dartx.get](0);
      let expected = test[dartx.get](1);
      int32x4 = typed_data.Int32x4.new(input, 2, 3, 4);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect$.Expect.equals(expected, dart.dload(int32x4, 'x'));
      expect$.Expect.equals(2, dart.dload(int32x4, 'y'));
      expect$.Expect.equals(3, dart.dload(int32x4, 'z'));
      expect$.Expect.equals(4, dart.dload(int32x4, 'w'));
      int32x4 = typed_data.Int32x4.new(1, input, 3, 4);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect$.Expect.equals(1, dart.dload(int32x4, 'x'));
      expect$.Expect.equals(expected, dart.dload(int32x4, 'y'));
      expect$.Expect.equals(3, dart.dload(int32x4, 'z'));
      expect$.Expect.equals(4, dart.dload(int32x4, 'w'));
      int32x4 = typed_data.Int32x4.new(1, 2, input, 4);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect$.Expect.equals(1, dart.dload(int32x4, 'x'));
      expect$.Expect.equals(2, dart.dload(int32x4, 'y'));
      expect$.Expect.equals(expected, dart.dload(int32x4, 'z'));
      expect$.Expect.equals(4, dart.dload(int32x4, 'w'));
      int32x4 = typed_data.Int32x4.new(1, 2, 3, input);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect$.Expect.equals(1, dart.dload(int32x4, 'x'));
      expect$.Expect.equals(2, dart.dload(int32x4, 'y'));
      expect$.Expect.equals(3, dart.dload(int32x4, 'z'));
      expect$.Expect.equals(expected, dart.dload(int32x4, 'w'));
    }
  };
  dart.fn(int32x4_list_test.testSpecialValues, dart.void, [dart.dynamic]);
  int32x4_list_test.main = function() {
    let list = null;
    list = typed_data.Int32x4List.new(8);
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStore(list);
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testSpecialValues(list);
    }
    let uint32List = typed_data.Uint32List.new(32);
    for (let i = 0; i < dart.notNull(uint32List[dartx.length]); i++) {
      uint32List[dartx.set](i, i);
    }
    list = typed_data.Int32x4List.view(uint32List[dartx.buffer]);
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testView(list);
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testSublist(list);
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStore(list);
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testListZero();
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testSpecialValues(list);
    }
    int32x4_list_test.testLoadStoreDeoptDriver();
  };
  dart.fn(int32x4_list_test.main);
  // Exports:
  exports.int32x4_list_test = int32x4_list_test;
});
dart_library.library('int32x4_shuffle_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_shuffle_test = Object.create(null);
  int32x4_shuffle_test.testShuffle = function() {
    let m = typed_data.Int32x4.new(1, 2, 3, 4);
    let c = null;
    c = m.shuffle(typed_data.Int32x4.WZYX);
    expect$.Expect.equals(4, dart.dload(c, 'x'));
    expect$.Expect.equals(3, dart.dload(c, 'y'));
    expect$.Expect.equals(2, dart.dload(c, 'z'));
    expect$.Expect.equals(1, dart.dload(c, 'w'));
  };
  dart.fn(int32x4_shuffle_test.testShuffle, dart.void, []);
  int32x4_shuffle_test.testShuffleNonConstant = function(mask) {
    let m = typed_data.Int32x4.new(1, 2, 3, 4);
    let c = null;
    c = m.shuffle(dart.as(mask, core.int));
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
  dart.fn(int32x4_shuffle_test.testShuffleNonConstant, dart.void, [dart.dynamic]);
  int32x4_shuffle_test.testShuffleMix = function() {
    let m = typed_data.Int32x4.new(1, 2, 3, 4);
    let n = typed_data.Int32x4.new(5, 6, 7, 8);
    let c = m.shuffleMix(n, typed_data.Int32x4.XYXY);
    expect$.Expect.equals(1, c.x);
    expect$.Expect.equals(2, c.y);
    expect$.Expect.equals(5, c.z);
    expect$.Expect.equals(6, c.w);
  };
  dart.fn(int32x4_shuffle_test.testShuffleMix, dart.void, []);
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
  dart.fn(int32x4_shuffle_test.main);
  // Exports:
  exports.int32x4_shuffle_test = int32x4_shuffle_test;
});
dart_library.library('int32x4_sign_mask_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_sign_mask_test = Object.create(null);
  int32x4_sign_mask_test.testImmediates = function() {
    let f = typed_data.Int32x4.new(1, 2, 3, 4);
    let m = f.signMask;
    expect$.Expect.equals(0, m);
    f = typed_data.Int32x4.new(-1, -2, -3, -4);
    m = f.signMask;
    expect$.Expect.equals(15, m);
    f = typed_data.Int32x4.bool(true, false, false, false);
    m = f.signMask;
    expect$.Expect.equals(1, m);
    f = typed_data.Int32x4.bool(false, true, false, false);
    m = f.signMask;
    expect$.Expect.equals(2, m);
    f = typed_data.Int32x4.bool(false, false, true, false);
    m = f.signMask;
    expect$.Expect.equals(4, m);
    f = typed_data.Int32x4.bool(false, false, false, true);
    m = f.signMask;
    expect$.Expect.equals(8, m);
  };
  dart.fn(int32x4_sign_mask_test.testImmediates, dart.void, []);
  int32x4_sign_mask_test.testZero = function() {
    let f = typed_data.Int32x4.new(0, 0, 0, 0);
    let m = f.signMask;
    expect$.Expect.equals(0, m);
    f = typed_data.Int32x4.new(-0, -0, -0, -0);
    m = f.signMask;
    expect$.Expect.equals(0, m);
  };
  dart.fn(int32x4_sign_mask_test.testZero, dart.void, []);
  int32x4_sign_mask_test.testLogic = function() {
    let a = typed_data.Int32x4.new(2147483648, 2147483648, 2147483648, 2147483648);
    let b = typed_data.Int32x4.new(1879048192, 1879048192, 1879048192, 1879048192);
    let c = typed_data.Int32x4.new(4026531840, 4026531840, 4026531840, 4026531840);
    let m1 = a['&'](c).signMask;
    expect$.Expect.equals(15, m1);
    let m2 = a['&'](b).signMask;
    expect$.Expect.equals(0, m2);
    let m3 = b['^'](a).signMask;
    expect$.Expect.equals(15, m3);
    let m4 = b['|'](c).signMask;
    expect$.Expect.equals(15, m4);
  };
  dart.fn(int32x4_sign_mask_test.testLogic, dart.void, []);
  int32x4_sign_mask_test.main = function() {
    for (let i = 0; i < 2000; i++) {
      int32x4_sign_mask_test.testImmediates();
      int32x4_sign_mask_test.testZero();
      int32x4_sign_mask_test.testLogic();
    }
  };
  dart.fn(int32x4_sign_mask_test.main);
  // Exports:
  exports.int32x4_sign_mask_test = int32x4_sign_mask_test;
});
dart_library.library('int64_list_load_store_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int64_list_load_store_test = Object.create(null);
  int64_list_load_store_test.testStoreLoad = function(l, z) {
    dart.dsetindex(l, 0, 9223372036854775807);
    dart.dsetindex(l, 1, 9223372036854775806);
    dart.dsetindex(l, 2, dart.dindex(l, 0));
    dart.dsetindex(l, 3, z);
    expect$.Expect.equals(dart.dindex(l, 0), 9223372036854775807);
    expect$.Expect.equals(dart.dindex(l, 1), 9223372036854775806);
    expect$.Expect.isTrue(dart.dsend(dart.dindex(l, 1), '<', dart.dindex(l, 0)));
    expect$.Expect.equals(dart.dindex(l, 2), dart.dindex(l, 0));
    expect$.Expect.equals(dart.dindex(l, 3), z);
  };
  dart.fn(int64_list_load_store_test.testStoreLoad, dart.void, [dart.dynamic, dart.dynamic]);
  int64_list_load_store_test.main = function() {
    let l = typed_data.Int64List.new(4);
    let zGood = 9223372036854775807;
    let zBad = false;
    for (let i = 0; i < 40; i++) {
      int64_list_load_store_test.testStoreLoad(l, zGood);
    }
    try {
      int64_list_load_store_test.testStoreLoad(l, zBad);
    } catch (_) {
    }

    for (let i = 0; i < 40; i++) {
      int64_list_load_store_test.testStoreLoad(l, zGood);
    }
  };
  dart.fn(int64_list_load_store_test.main);
  // Exports:
  exports.int64_list_load_store_test = int64_list_load_store_test;
});
dart_library.library('native_interceptor_no_own_method_to_intercept_test', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const native_interceptor_no_own_method_to_intercept_test = Object.create(null);
  native_interceptor_no_own_method_to_intercept_test.use = function(s) {
    return s;
  };
  dart.fn(native_interceptor_no_own_method_to_intercept_test.use);
  native_interceptor_no_own_method_to_intercept_test.main = function() {
    native_interceptor_no_own_method_to_intercept_test.use(dart.toString(typed_data.ByteData.new(1)));
  };
  dart.fn(native_interceptor_no_own_method_to_intercept_test.main);
  // Exports:
  exports.native_interceptor_no_own_method_to_intercept_test = native_interceptor_no_own_method_to_intercept_test;
});
dart_library.library('setRange_1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setRange_1_test = Object.create(null);
  const setRange_lib = Object.create(null);
  setRange_1_test.sameTypeTest = function() {
    setRange_lib.checkSameSize(setRange_lib.makeInt16List, setRange_lib.makeInt16View, setRange_lib.makeInt16View);
    setRange_lib.checkSameSize(setRange_lib.makeUint16List, setRange_lib.makeUint16View, setRange_lib.makeUint16View);
  };
  dart.fn(setRange_1_test.sameTypeTest);
  setRange_1_test.main = function() {
    setRange_1_test.sameTypeTest();
  };
  dart.fn(setRange_1_test.main);
  setRange_lib.initialize = function(a) {
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(a, 'length'), core.num)); i++) {
      dart.dsetindex(a, i, i + 1);
    }
  };
  dart.fn(setRange_lib.initialize);
  setRange_lib.makeInt16View = function(buffer, byteOffset, length) {
    return typed_data.Int16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16View);
  setRange_lib.makeUint16View = function(buffer, byteOffset, length) {
    return typed_data.Uint16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16View);
  setRange_lib.makeInt16List = function(length) {
    return typed_data.Int16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16List);
  setRange_lib.makeUint16List = function(length) {
    return typed_data.Uint16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16List);
  setRange_lib.checkSameSize = function(constructor0, constructor1, constructor2) {
    let a0 = dart.dcall(constructor0, 9);
    let buffer = dart.dload(a0, 'buffer');
    let a1 = dart.dcall(constructor1, buffer, 0, 7);
    let a2 = dart.dcall(constructor2, buffer, 2 * dart.notNull(dart.as(dart.dload(a0, 'elementSizeInBytes'), core.num)), 7);
    setRange_lib.initialize(a0);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9]', `${a0}`);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7]', `${a1}`);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9]', `${a2}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 7, a2);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 7, a1);
    expect$.Expect.equals('[1, 2, 1, 2, 3, 4, 5, 6, 7]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 1, 7, a2);
    expect$.Expect.equals('[1, 3, 4, 5, 6, 7, 8, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 1, 7, a1);
    expect$.Expect.equals('[1, 2, 3, 1, 2, 3, 4, 5, 6]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 6, a2, 1);
    expect$.Expect.equals('[4, 5, 6, 7, 8, 9, 7, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 6, a1, 1);
    expect$.Expect.equals('[1, 2, 2, 3, 4, 5, 6, 7, 9]', `${a0}`);
  };
  dart.fn(setRange_lib.checkSameSize);
  // Exports:
  exports.setRange_1_test = setRange_1_test;
  exports.setRange_lib = setRange_lib;
});
dart_library.library('setRange_2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setRange_2_test = Object.create(null);
  const setRange_lib = Object.create(null);
  setRange_2_test.sameElementSizeTest = function() {
    setRange_lib.checkSameSize(setRange_lib.makeInt16List, setRange_lib.makeInt16View, setRange_lib.makeUint16View);
    setRange_lib.checkSameSize(setRange_lib.makeInt16List, setRange_lib.makeUint16View, setRange_lib.makeInt16View);
  };
  dart.fn(setRange_2_test.sameElementSizeTest);
  setRange_2_test.main = function() {
    setRange_2_test.sameElementSizeTest();
  };
  dart.fn(setRange_2_test.main);
  setRange_lib.initialize = function(a) {
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(a, 'length'), core.num)); i++) {
      dart.dsetindex(a, i, i + 1);
    }
  };
  dart.fn(setRange_lib.initialize);
  setRange_lib.makeInt16View = function(buffer, byteOffset, length) {
    return typed_data.Int16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16View);
  setRange_lib.makeUint16View = function(buffer, byteOffset, length) {
    return typed_data.Uint16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16View);
  setRange_lib.makeInt16List = function(length) {
    return typed_data.Int16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16List);
  setRange_lib.makeUint16List = function(length) {
    return typed_data.Uint16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16List);
  setRange_lib.checkSameSize = function(constructor0, constructor1, constructor2) {
    let a0 = dart.dcall(constructor0, 9);
    let buffer = dart.dload(a0, 'buffer');
    let a1 = dart.dcall(constructor1, buffer, 0, 7);
    let a2 = dart.dcall(constructor2, buffer, 2 * dart.notNull(dart.as(dart.dload(a0, 'elementSizeInBytes'), core.num)), 7);
    setRange_lib.initialize(a0);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9]', `${a0}`);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7]', `${a1}`);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9]', `${a2}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 7, a2);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 7, a1);
    expect$.Expect.equals('[1, 2, 1, 2, 3, 4, 5, 6, 7]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 1, 7, a2);
    expect$.Expect.equals('[1, 3, 4, 5, 6, 7, 8, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 1, 7, a1);
    expect$.Expect.equals('[1, 2, 3, 1, 2, 3, 4, 5, 6]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 6, a2, 1);
    expect$.Expect.equals('[4, 5, 6, 7, 8, 9, 7, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 6, a1, 1);
    expect$.Expect.equals('[1, 2, 2, 3, 4, 5, 6, 7, 9]', `${a0}`);
  };
  dart.fn(setRange_lib.checkSameSize);
  // Exports:
  exports.setRange_2_test = setRange_2_test;
  exports.setRange_lib = setRange_lib;
});
dart_library.library('setRange_3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setRange_3_test = Object.create(null);
  const setRange_lib = Object.create(null);
  setRange_3_test.expandContractTest = function() {
    let a1 = typed_data.Int32List.new(8);
    let buffer = a1[dartx.buffer];
    let a2 = typed_data.Int8List.view(buffer, 12, 8);
    setRange_lib.initialize(a2);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a2}`);
    a1[dartx.setRange](0, 8, a2);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a1}`);
    setRange_lib.initialize(a1);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a1}`);
    a2[dartx.setRange](0, 8, a1);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a2}`);
  };
  dart.fn(setRange_3_test.expandContractTest);
  setRange_3_test.main = function() {
    setRange_3_test.expandContractTest();
  };
  dart.fn(setRange_3_test.main);
  setRange_lib.initialize = function(a) {
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(a, 'length'), core.num)); i++) {
      dart.dsetindex(a, i, i + 1);
    }
  };
  dart.fn(setRange_lib.initialize);
  setRange_lib.makeInt16View = function(buffer, byteOffset, length) {
    return typed_data.Int16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16View);
  setRange_lib.makeUint16View = function(buffer, byteOffset, length) {
    return typed_data.Uint16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16View);
  setRange_lib.makeInt16List = function(length) {
    return typed_data.Int16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16List);
  setRange_lib.makeUint16List = function(length) {
    return typed_data.Uint16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16List);
  setRange_lib.checkSameSize = function(constructor0, constructor1, constructor2) {
    let a0 = dart.dcall(constructor0, 9);
    let buffer = dart.dload(a0, 'buffer');
    let a1 = dart.dcall(constructor1, buffer, 0, 7);
    let a2 = dart.dcall(constructor2, buffer, 2 * dart.notNull(dart.as(dart.dload(a0, 'elementSizeInBytes'), core.num)), 7);
    setRange_lib.initialize(a0);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9]', `${a0}`);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7]', `${a1}`);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9]', `${a2}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 7, a2);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 7, a1);
    expect$.Expect.equals('[1, 2, 1, 2, 3, 4, 5, 6, 7]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 1, 7, a2);
    expect$.Expect.equals('[1, 3, 4, 5, 6, 7, 8, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 1, 7, a1);
    expect$.Expect.equals('[1, 2, 3, 1, 2, 3, 4, 5, 6]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 6, a2, 1);
    expect$.Expect.equals('[4, 5, 6, 7, 8, 9, 7, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 6, a1, 1);
    expect$.Expect.equals('[1, 2, 2, 3, 4, 5, 6, 7, 9]', `${a0}`);
  };
  dart.fn(setRange_lib.checkSameSize);
  // Exports:
  exports.setRange_3_test = setRange_3_test;
  exports.setRange_lib = setRange_lib;
});
dart_library.library('setRange_4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setRange_4_test = Object.create(null);
  const setRange_lib = Object.create(null);
  setRange_4_test.clampingTest = function() {
    let a1 = typed_data.Int8List.new(8);
    let a2 = typed_data.Uint8ClampedList.view(a1[dartx.buffer]);
    setRange_lib.initialize(a1);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a1}`);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a2}`);
    a1[dartx.set](0, -1);
    a2[dartx.setRange](0, 2, a1);
    expect$.Expect.equals('[0, 2, 3, 4, 5, 6, 7, 8]', `${a2}`);
  };
  dart.fn(setRange_4_test.clampingTest);
  setRange_4_test.main = function() {
    setRange_4_test.clampingTest();
  };
  dart.fn(setRange_4_test.main);
  setRange_lib.initialize = function(a) {
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(a, 'length'), core.num)); i++) {
      dart.dsetindex(a, i, i + 1);
    }
  };
  dart.fn(setRange_lib.initialize);
  setRange_lib.makeInt16View = function(buffer, byteOffset, length) {
    return typed_data.Int16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16View);
  setRange_lib.makeUint16View = function(buffer, byteOffset, length) {
    return typed_data.Uint16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16View);
  setRange_lib.makeInt16List = function(length) {
    return typed_data.Int16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16List);
  setRange_lib.makeUint16List = function(length) {
    return typed_data.Uint16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16List);
  setRange_lib.checkSameSize = function(constructor0, constructor1, constructor2) {
    let a0 = dart.dcall(constructor0, 9);
    let buffer = dart.dload(a0, 'buffer');
    let a1 = dart.dcall(constructor1, buffer, 0, 7);
    let a2 = dart.dcall(constructor2, buffer, 2 * dart.notNull(dart.as(dart.dload(a0, 'elementSizeInBytes'), core.num)), 7);
    setRange_lib.initialize(a0);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9]', `${a0}`);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7]', `${a1}`);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9]', `${a2}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 7, a2);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 7, a1);
    expect$.Expect.equals('[1, 2, 1, 2, 3, 4, 5, 6, 7]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 1, 7, a2);
    expect$.Expect.equals('[1, 3, 4, 5, 6, 7, 8, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 1, 7, a1);
    expect$.Expect.equals('[1, 2, 3, 1, 2, 3, 4, 5, 6]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 6, a2, 1);
    expect$.Expect.equals('[4, 5, 6, 7, 8, 9, 7, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 6, a1, 1);
    expect$.Expect.equals('[1, 2, 2, 3, 4, 5, 6, 7, 9]', `${a0}`);
  };
  dart.fn(setRange_lib.checkSameSize);
  // Exports:
  exports.setRange_4_test = setRange_4_test;
  exports.setRange_lib = setRange_lib;
});
dart_library.library('setRange_5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setRange_5_test = Object.create(null);
  const setRange_lib = Object.create(null);
  setRange_5_test.overlapTest = function() {
    let buffer = typed_data.Float32List.new(3)[dartx.buffer];
    let a0 = typed_data.Int8List.view(buffer);
    let a1 = typed_data.Int8List.view(buffer, 1, 5);
    let a2 = typed_data.Int8List.view(buffer, 2, 5);
    setRange_lib.initialize(a0);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]', `${a0}`);
    expect$.Expect.equals('[2, 3, 4, 5, 6]', `${a1}`);
    expect$.Expect.equals('[3, 4, 5, 6, 7]', `${a2}`);
    a1[dartx.setRange](0, 5, a2);
    expect$.Expect.equals('[1, 3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12]', `${a0}`);
    setRange_lib.initialize(a0);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]', `${a0}`);
    expect$.Expect.equals('[2, 3, 4, 5, 6]', `${a1}`);
    expect$.Expect.equals('[3, 4, 5, 6, 7]', `${a2}`);
    a2[dartx.setRange](0, 5, a1);
    expect$.Expect.equals('[1, 2, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12]', `${a0}`);
  };
  dart.fn(setRange_5_test.overlapTest);
  setRange_5_test.main = function() {
    setRange_5_test.overlapTest();
  };
  dart.fn(setRange_5_test.main);
  setRange_lib.initialize = function(a) {
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(a, 'length'), core.num)); i++) {
      dart.dsetindex(a, i, i + 1);
    }
  };
  dart.fn(setRange_lib.initialize);
  setRange_lib.makeInt16View = function(buffer, byteOffset, length) {
    return typed_data.Int16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16View);
  setRange_lib.makeUint16View = function(buffer, byteOffset, length) {
    return typed_data.Uint16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16View);
  setRange_lib.makeInt16List = function(length) {
    return typed_data.Int16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeInt16List);
  setRange_lib.makeUint16List = function(length) {
    return typed_data.Uint16List.new(dart.as(length, core.int));
  };
  dart.fn(setRange_lib.makeUint16List);
  setRange_lib.checkSameSize = function(constructor0, constructor1, constructor2) {
    let a0 = dart.dcall(constructor0, 9);
    let buffer = dart.dload(a0, 'buffer');
    let a1 = dart.dcall(constructor1, buffer, 0, 7);
    let a2 = dart.dcall(constructor2, buffer, 2 * dart.notNull(dart.as(dart.dload(a0, 'elementSizeInBytes'), core.num)), 7);
    setRange_lib.initialize(a0);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9]', `${a0}`);
    expect$.Expect.equals('[1, 2, 3, 4, 5, 6, 7]', `${a1}`);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9]', `${a2}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 7, a2);
    expect$.Expect.equals('[3, 4, 5, 6, 7, 8, 9, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 7, a1);
    expect$.Expect.equals('[1, 2, 1, 2, 3, 4, 5, 6, 7]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 1, 7, a2);
    expect$.Expect.equals('[1, 3, 4, 5, 6, 7, 8, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 1, 7, a1);
    expect$.Expect.equals('[1, 2, 3, 1, 2, 3, 4, 5, 6]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a1, 'setRange', 0, 6, a2, 1);
    expect$.Expect.equals('[4, 5, 6, 7, 8, 9, 7, 8, 9]', `${a0}`);
    setRange_lib.initialize(a0);
    dart.dsend(a2, 'setRange', 0, 6, a1, 1);
    expect$.Expect.equals('[1, 2, 2, 3, 4, 5, 6, 7, 9]', `${a0}`);
  };
  dart.fn(setRange_lib.checkSameSize);
  // Exports:
  exports.setRange_5_test = setRange_5_test;
  exports.setRange_lib = setRange_lib;
});
dart_library.library('simd_store_to_load_forward_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const simd_store_to_load_forward_test = Object.create(null);
  simd_store_to_load_forward_test.testLoadStoreForwardingFloat32x4 = function(l, v) {
    l.set(1, v);
    let r = l.get(1);
    return r;
  };
  dart.fn(simd_store_to_load_forward_test.testLoadStoreForwardingFloat32x4, typed_data.Float32x4, [typed_data.Float32x4List, typed_data.Float32x4]);
  simd_store_to_load_forward_test.main = function() {
    let l = typed_data.Float32x4List.new(4);
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = null;
    for (let i = 0; i < 20; i++) {
      b = simd_store_to_load_forward_test.testLoadStoreForwardingFloat32x4(l, a);
    }
    expect$.Expect.equals(a.x, b.x);
    expect$.Expect.equals(a.y, b.y);
    expect$.Expect.equals(a.z, b.z);
    expect$.Expect.equals(a.w, b.w);
  };
  dart.fn(simd_store_to_load_forward_test.main);
  // Exports:
  exports.simd_store_to_load_forward_test = simd_store_to_load_forward_test;
});
dart_library.library('typed_data_from_list_test', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const typed_data_from_list_test = Object.create(null);
  typed_data_from_list_test.main = function() {
    let list = new collection.UnmodifiableListView(dart.list([1, 2], core.int));
    let typed = typed_data.Uint8List.fromList(dart.as(list, core.List$(core.int)));
    if (typed[dartx.get](0) != 1 || typed[dartx.get](1) != 2 || typed[dartx.length] != 2) {
      dart.throw('Test failed');
    }
  };
  dart.fn(typed_data_from_list_test.main);
  // Exports:
  exports.typed_data_from_list_test = typed_data_from_list_test;
});
dart_library.library('typed_data_hierarchy_int64_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_hierarchy_int64_test = Object.create(null);
  typed_data_hierarchy_int64_test.inscrutable = null;
  typed_data_hierarchy_int64_test.implementsTypedData = function() {
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_int64_test.inscrutable, typed_data.Int64List.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_int64_test.inscrutable, typed_data.Uint64List.new(1)), typed_data.TypedData));
  };
  dart.fn(typed_data_hierarchy_int64_test.implementsTypedData, dart.void, []);
  typed_data_hierarchy_int64_test.implementsList = function() {
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_int64_test.inscrutable, typed_data.Int64List.new(1)), core.List$(core.int)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_int64_test.inscrutable, typed_data.Uint64List.new(1)), core.List$(core.int)));
  };
  dart.fn(typed_data_hierarchy_int64_test.implementsList, dart.void, []);
  typed_data_hierarchy_int64_test.main = function() {
    typed_data_hierarchy_int64_test.inscrutable = dart.fn(x => x);
    typed_data_hierarchy_int64_test.implementsTypedData();
    typed_data_hierarchy_int64_test.implementsList();
  };
  dart.fn(typed_data_hierarchy_int64_test.main);
  // Exports:
  exports.typed_data_hierarchy_int64_test = typed_data_hierarchy_int64_test;
});
dart_library.library('typed_data_hierarchy_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_hierarchy_test = Object.create(null);
  typed_data_hierarchy_test.inscrutable = null;
  typed_data_hierarchy_test.testClampedList = function() {
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8List.new(1)), typed_data.Uint8List));
    expect$.Expect.isFalse(dart.is(typed_data.Uint8ClampedList.new(1), typed_data.Uint8List), 'Uint8ClampedList should not be a subtype of Uint8List ' + 'in optimizable test');
    expect$.Expect.isFalse(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8ClampedList.new(1)), typed_data.Uint8List), 'Uint8ClampedList should not be a subtype of Uint8List in dynamic test');
  };
  dart.fn(typed_data_hierarchy_test.testClampedList, dart.void, []);
  typed_data_hierarchy_test.implementsTypedData = function() {
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.ByteData.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float32List.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float32x4List.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float64List.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int8List.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int16List.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int32List.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8List.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8ClampedList.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint16List.new(1)), typed_data.TypedData));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint32List.new(1)), typed_data.TypedData));
  };
  dart.fn(typed_data_hierarchy_test.implementsTypedData, dart.void, []);
  typed_data_hierarchy_test.implementsList = function() {
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float32List.new(1)), core.List$(core.double)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float32x4List.new(1)), core.List$(typed_data.Float32x4)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float64List.new(1)), core.List$(core.double)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int8List.new(1)), core.List$(core.int)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int16List.new(1)), core.List$(core.int)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int32List.new(1)), core.List$(core.int)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8List.new(1)), core.List$(core.int)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8ClampedList.new(1)), core.List$(core.int)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint16List.new(1)), core.List$(core.int)));
    expect$.Expect.isTrue(dart.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint32List.new(1)), core.List$(core.int)));
  };
  dart.fn(typed_data_hierarchy_test.implementsList, dart.void, []);
  typed_data_hierarchy_test.main = function() {
    typed_data_hierarchy_test.inscrutable = dart.fn(x => x);
    typed_data_hierarchy_test.testClampedList();
    typed_data_hierarchy_test.implementsTypedData();
    typed_data_hierarchy_test.implementsList();
  };
  dart.fn(typed_data_hierarchy_test.main);
  // Exports:
  exports.typed_data_hierarchy_test = typed_data_hierarchy_test;
});
dart_library.library('typed_data_list_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_list_test = Object.create(null);
  typed_data_list_test.confuse = function(x) {
    return x;
  };
  dart.fn(typed_data_list_test.confuse);
  typed_data_list_test.testListFunctions = function(list, first, last, toElementType) {
    dart.assert(dart.dsend(dart.dload(list, 'length'), '>', 0));
    let reversed = dart.dload(list, 'reversed');
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dload(dart.dsend(reversed, 'toList'), 'reversed'), 'toList'), core.List));
    let index = dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.int);
    for (let x of dart.as(reversed, core.Iterable)) {
      expect$.Expect.equals(dart.dindex(list, index), x);
      index = dart.notNull(index) - 1;
    }
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'add', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'addAll', dart.list([1, 2], core.int)), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'clear'), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'insert', 0, 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'insertAll', 0, dart.list([1, 2], core.int)), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'remove', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeAt', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeLast'), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeRange', 0, 1), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'replaceRange', 0, 1, []), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'retainWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    let map = dart.dsend(list, 'asMap');
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(map, 'length'));
    expect$.Expect.isTrue(dart.is(map, core.Map));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dload(map, 'values'), 'toList'), core.List));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(list, 'length'), core.num)); i++) {
      expect$.Expect.equals(dart.dindex(list, i), dart.dindex(map, i));
    }
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'getRange', 0, dart.dload(list, 'length')), 'toList'), core.List));
    let subRange = dart.dsend(dart.dsend(list, 'getRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), 'toList');
    expect$.Expect.equals(dart.dsend(dart.dload(list, 'length'), '-', 2), dart.dload(subRange, 'length'));
    index = 1;
    for (let x of dart.as(subRange, core.Iterable)) {
      expect$.Expect.equals(dart.dindex(list, index), x);
      index = dart.notNull(index) + 1;
    }
    expect$.Expect.equals(0, dart.dsend(list, 'lastIndexOf', first));
    expect$.Expect.equals(dart.dsend(dart.dload(list, 'length'), '-', 1), dart.dsend(list, 'lastIndexOf', last));
    expect$.Expect.equals(-1, dart.dsend(list, 'lastIndexOf', -1));
    let copy = dart.dsend(list, 'toList');
    dart.dsend(list, 'fillRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), dart.dcall(toElementType, 0));
    expect$.Expect.equals(dart.dload(copy, 'first'), dart.dload(list, 'first'));
    expect$.Expect.equals(dart.dload(copy, 'last'), dart.dload(list, 'last'));
    for (let i = 1; i < dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.num)); i++) {
      expect$.Expect.equals(0, dart.dindex(list, i));
    }
    dart.dsend(list, 'setAll', 1, dart.dsend(dart.dsend(list, 'getRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), 'map', dart.fn(x => dart.dcall(toElementType, 2))));
    expect$.Expect.equals(dart.dload(copy, 'first'), dart.dload(list, 'first'));
    expect$.Expect.equals(dart.dload(copy, 'last'), dart.dload(list, 'last'));
    for (let i = 1; i < dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.num)); i++) {
      expect$.Expect.equals(2, dart.dindex(list, i));
    }
    dart.dsend(list, 'setRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), core.Iterable.generate(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 2), core.int), dart.fn(x => dart.dcall(toElementType, dart.notNull(x) + 5), dart.dynamic, [core.int])));
    expect$.Expect.equals(first, dart.dload(list, 'first'));
    expect$.Expect.equals(last, dart.dload(list, 'last'));
    for (let i = 1; i < dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.num)); i++) {
      expect$.Expect.equals(4 + i, dart.dindex(list, i));
    }
    dart.dsend(list, 'setRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), core.Iterable.generate(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.int), dart.fn(x => dart.dcall(toElementType, dart.notNull(x) + 5), dart.dynamic, [core.int])), 1);
    expect$.Expect.equals(first, dart.dload(list, 'first'));
    expect$.Expect.equals(last, dart.dload(list, 'last'));
    for (let i = 1; i < dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.num)); i++) {
      expect$.Expect.equals(5 + i, dart.dindex(list, i));
    }
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'setRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), []), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(list, 'length'), core.num)); i++) {
      dart.dsetindex(list, dart.dsend(dart.dsend(dart.dload(list, 'length'), '-', 1), '-', i), dart.dcall(toElementType, i));
    }
    dart.dsend(list, 'sort');
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(list, 'length'), core.num)); i++) {
      expect$.Expect.equals(i, dart.dindex(list, i));
    }
    expect$.Expect.listEquals(dart.as(dart.dsend(dart.dsend(list, 'getRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), 'toList'), core.List), dart.as(dart.dsend(list, 'sublist', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), core.List));
    expect$.Expect.listEquals(dart.as(dart.dsend(dart.dsend(list, 'getRange', 1, dart.dload(list, 'length')), 'toList'), core.List), dart.as(dart.dsend(list, 'sublist', 1), core.List));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(list, 'sublist', 0), core.List));
    expect$.Expect.listEquals([], dart.as(dart.dsend(list, 'sublist', 0, 0), core.List));
    expect$.Expect.listEquals([], dart.as(dart.dsend(list, 'sublist', dart.dload(list, 'length')), core.List));
    expect$.Expect.listEquals([], dart.as(dart.dsend(list, 'sublist', dart.dload(list, 'length'), dart.dload(list, 'length')), core.List));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'sublist', dart.dsend(dart.dload(list, 'length'), '+', 1)), dart.void, []), dart.fn(e => dart.is(e, core.RangeError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'sublist', 0, dart.dsend(dart.dload(list, 'length'), '+', 1)), dart.void, []), dart.fn(e => dart.is(e, core.RangeError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'sublist', 1, 0), dart.void, []), dart.fn(e => dart.is(e, core.RangeError), core.bool, [dart.dynamic]));
  };
  dart.fn(typed_data_list_test.testListFunctions, dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]);
  typed_data_list_test.emptyChecks = function(list) {
    dart.assert(dart.equals(dart.dload(list, 'length'), 0));
    expect$.Expect.isTrue(dart.dload(list, 'isEmpty'));
    let reversed = dart.dload(list, 'reversed');
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dload(dart.dsend(reversed, 'toList'), 'reversed'), 'toList'), core.List));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'add', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'addAll', dart.list([1, 2], core.int)), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'clear'), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'insert', 0, 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'insertAll', 0, dart.list([1, 2], core.int)), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'remove', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeAt', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeLast'), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeRange', 0, 1), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'replaceRange', 0, 1, []), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'retainWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    let map = dart.dsend(list, 'asMap');
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(map, 'length'));
    expect$.Expect.isTrue(dart.is(map, core.Map));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dload(map, 'values'), 'toList'), core.List));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(list, 'length'), core.num)); i++) {
      expect$.Expect.equals(dart.dindex(list, i), dart.dindex(map, i));
    }
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'getRange', 0, dart.dload(list, 'length')), 'toList'), core.List));
    expect$.Expect.equals(-1, dart.dsend(list, 'lastIndexOf', -1));
    let copy = dart.dsend(list, 'toList');
    dart.dsend(list, 'fillRange', 0, 0);
    expect$.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'getRange', 0, 0), 'toList'), core.List));
    dart.dsend(list, 'setRange', 0, 0, dart.list([1, 2], core.int));
    dart.dsend(list, 'sort');
    expect$.Expect.listEquals([], dart.as(dart.dsend(list, 'sublist', 0, 0), core.List));
  };
  dart.fn(typed_data_list_test.emptyChecks, dart.void, [dart.dynamic]);
  typed_data_list_test.main = function() {
    function toDouble(x) {
      return dart.dsend(x, 'toDouble');
    }
    dart.fn(toDouble);
    function toInt(x) {
      return dart.dsend(x, 'toInt');
    }
    dart.fn(toInt);
    typed_data_list_test.testListFunctions(typed_data.Float32List.fromList(dart.list([1.5, 6.3, 9.5], core.double)), 1.5, 9.5, toDouble);
    typed_data_list_test.testListFunctions(typed_data.Float64List.fromList(dart.list([1.5, 6.3, 9.5], core.double)), 1.5, 9.5, toDouble);
    typed_data_list_test.testListFunctions(typed_data.Int8List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    typed_data_list_test.testListFunctions(typed_data.Int16List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    typed_data_list_test.testListFunctions(typed_data.Int32List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    typed_data_list_test.testListFunctions(typed_data.Uint8List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    typed_data_list_test.testListFunctions(typed_data.Uint16List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    typed_data_list_test.testListFunctions(typed_data.Uint32List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    typed_data_list_test.emptyChecks(typed_data.Float32List.new(0));
    typed_data_list_test.emptyChecks(typed_data.Float64List.new(0));
    typed_data_list_test.emptyChecks(typed_data.Int8List.new(0));
    typed_data_list_test.emptyChecks(typed_data.Int16List.new(0));
    typed_data_list_test.emptyChecks(typed_data.Int32List.new(0));
    typed_data_list_test.emptyChecks(typed_data.Uint8List.new(0));
    typed_data_list_test.emptyChecks(typed_data.Uint16List.new(0));
    typed_data_list_test.emptyChecks(typed_data.Uint32List.new(0));
  };
  dart.fn(typed_data_list_test.main);
  // Exports:
  exports.typed_data_list_test = typed_data_list_test;
});
dart_library.library('typed_data_load2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_load2_test = Object.create(null);
  typed_data_load2_test.aliasWithByteData1 = function() {
    let aa = typed_data.Int8List.new(10);
    let b = typed_data.ByteData.view(aa[dartx.buffer]);
    for (let i = 0; i < dart.notNull(aa[dartx.length]); i++)
      aa[dartx.set](i, 9);
    let x1 = aa[dartx.get](3);
    b[dartx.setInt8](3, 1);
    let x2 = aa[dartx.get](3);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(1, x2);
  };
  dart.fn(typed_data_load2_test.aliasWithByteData1);
  typed_data_load2_test.aliasWithByteData2 = function() {
    let b = typed_data.ByteData.new(10);
    let aa = typed_data.Int8List.view(b[dartx.buffer]);
    for (let i = 0; i < dart.notNull(aa[dartx.length]); i++)
      aa[dartx.set](i, 9);
    let x1 = aa[dartx.get](3);
    b[dartx.setInt8](3, 1);
    let x2 = aa[dartx.get](3);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(1, x2);
  };
  dart.fn(typed_data_load2_test.aliasWithByteData2);
  typed_data_load2_test.alias8x8 = function() {
    let buffer = typed_data.Int8List.new(10)[dartx.buffer];
    let a1 = typed_data.Int8List.view(buffer);
    let a2 = typed_data.Int8List.view(buffer, 1);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    let x1 = a1[dartx.get](1);
    a2[dartx.set](0, 0);
    let x2 = a1[dartx.get](1);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(0, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](1);
    a2[dartx.set](1, 5);
    x2 = a1[dartx.get](1);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(9, x2);
  };
  dart.fn(typed_data_load2_test.alias8x8);
  typed_data_load2_test.alias8x16 = function() {
    let a1 = typed_data.Int8List.new(10);
    let a2 = typed_data.Int16List.view(a1[dartx.buffer]);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    let x1 = a1[dartx.get](0);
    a2[dartx.set](0, 257);
    let x2 = a1[dartx.get](0);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(1, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](4);
    a2[dartx.set](2, 1285);
    x2 = a1[dartx.get](4);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(5, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](3);
    a2[dartx.set](3, 1285);
    x2 = a1[dartx.get](3);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(9, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](2);
    a2[dartx.set](0, 1285);
    x2 = a1[dartx.get](2);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(9, x2);
  };
  dart.fn(typed_data_load2_test.alias8x16);
  typed_data_load2_test.main = function() {
    typed_data_load2_test.aliasWithByteData1();
    typed_data_load2_test.aliasWithByteData2();
    typed_data_load2_test.alias8x8();
    typed_data_load2_test.alias8x16();
  };
  dart.fn(typed_data_load2_test.main);
  // Exports:
  exports.typed_data_load2_test = typed_data_load2_test;
});
dart_library.library('typed_data_load_test', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const typed_data_load_test = Object.create(null);
  typed_data_load_test.main = function() {
    let list = typed_data.Int8List.new(1);
    list[dartx.set](0, 300);
    if (list[dartx.get](0) != 44) {
      dart.throw('Test failed');
    }
    let a = list[dartx.get](0);
    list[dartx.set](0, 0);
    if (list[dartx.get](0) != 0) {
      dart.throw('Test failed');
    }
  };
  dart.fn(typed_data_load_test.main);
  // Exports:
  exports.typed_data_load_test = typed_data_load_test;
});
dart_library.library('typed_data_sublist_type_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_sublist_type_test = Object.create(null);
  typed_data_sublist_type_test.inscrutable = null;
  typed_data_sublist_type_test.Is$ = dart.generic(T => {
    class Is extends core.Object {
      Is(name) {
        this.name = name;
      }
      check(x) {
        return dart.is(x, T);
      }
      expect(x, part) {
        expect$.Expect.isTrue(this.check(x), `(${part}: ${dart.runtimeType(x)}) is ${this.name}`);
      }
      expectNot(x, part) {
        expect$.Expect.isFalse(this.check(x), `(${part}: ${dart.runtimeType(x)}) is! ${this.name}`);
      }
    }
    dart.setSignature(Is, {
      constructors: () => ({Is: [typed_data_sublist_type_test.Is$(T), [dart.dynamic]]}),
      methods: () => ({
        check: [dart.dynamic, [dart.dynamic]],
        expect: [dart.dynamic, [dart.dynamic, dart.dynamic]],
        expectNot: [dart.dynamic, [dart.dynamic, dart.dynamic]]
      })
    });
    return Is;
  });
  typed_data_sublist_type_test.Is = typed_data_sublist_type_test.Is$();
  typed_data_sublist_type_test.testSublistType = function(input, positive, all) {
    let negative = dart.dsend(all, 'where', dart.fn(check => !dart.notNull(dart.as(dart.dsend(positive, 'contains', check), core.bool)), core.bool, [dart.dynamic]));
    input = dart.dcall(typed_data_sublist_type_test.inscrutable, input);
    for (let check of dart.as(positive, core.Iterable))
      dart.dsend(check, 'expect', input, 'input');
    for (let check of dart.as(negative, core.Iterable))
      dart.dsend(check, 'expectNot', input, 'input');
    let sub = dart.dcall(typed_data_sublist_type_test.inscrutable, dart.dsend(input, 'sublist', 1));
    for (let check of dart.as(positive, core.Iterable))
      dart.dsend(check, 'expect', sub, 'sublist');
    for (let check of dart.as(negative, core.Iterable))
      dart.dsend(check, 'expectNot', sub, 'sublist');
    let sub2 = dart.dcall(typed_data_sublist_type_test.inscrutable, dart.dsend(input, 'sublist', 10));
    expect$.Expect.equals(0, dart.dload(sub2, 'length'));
    for (let check of dart.as(positive, core.Iterable))
      dart.dsend(check, 'expect', sub2, 'empty sublist');
    for (let check of dart.as(negative, core.Iterable))
      dart.dsend(check, 'expectNot', sub2, 'empty sublist');
  };
  dart.fn(typed_data_sublist_type_test.testSublistType, dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]);
  typed_data_sublist_type_test.testTypes = function() {
    let isFloat32list = new (typed_data_sublist_type_test.Is$(typed_data.Float32List))('Float32List');
    let isFloat64list = new (typed_data_sublist_type_test.Is$(typed_data.Float64List))('Float64List');
    let isInt8List = new (typed_data_sublist_type_test.Is$(typed_data.Int8List))('Int8List');
    let isInt16List = new (typed_data_sublist_type_test.Is$(typed_data.Int16List))('Int16List');
    let isInt32List = new (typed_data_sublist_type_test.Is$(typed_data.Int32List))('Int32List');
    let isUint8List = new (typed_data_sublist_type_test.Is$(typed_data.Uint8List))('Uint8List');
    let isUint16List = new (typed_data_sublist_type_test.Is$(typed_data.Uint16List))('Uint16List');
    let isUint32List = new (typed_data_sublist_type_test.Is$(typed_data.Uint32List))('Uint32List');
    let isUint8ClampedList = new (typed_data_sublist_type_test.Is$(typed_data.Uint8ClampedList))('Uint8ClampedList');
    let isIntList = new (typed_data_sublist_type_test.Is$(core.List$(core.int)))('List<int>');
    let isDoubleList = new (typed_data_sublist_type_test.Is$(core.List$(core.double)))('List<double>');
    let isNumList = new (typed_data_sublist_type_test.Is$(core.List$(core.num)))('List<num>');
    let allChecks = dart.list([isFloat32list, isFloat64list, isInt8List, isInt16List, isInt32List, isUint8List, isUint16List, isUint32List, isUint8ClampedList], typed_data_sublist_type_test.Is$(core.List));
    function testInt(list, check) {
      typed_data_sublist_type_test.testSublistType(list, dart.list([dart.as(check, typed_data_sublist_type_test.Is$(core.List)), isIntList, isNumList], typed_data_sublist_type_test.Is$(core.List)), allChecks);
    }
    dart.fn(testInt);
    function testDouble(list, check) {
      typed_data_sublist_type_test.testSublistType(list, dart.list([dart.as(check, typed_data_sublist_type_test.Is$(core.List)), isDoubleList, isNumList], typed_data_sublist_type_test.Is$(core.List)), allChecks);
    }
    dart.fn(testDouble);
    testDouble(typed_data.Float32List.new(10), isFloat32list);
    testDouble(typed_data.Float64List.new(10), isFloat64list);
    testInt(typed_data.Int8List.new(10), isInt8List);
    testInt(typed_data.Int16List.new(10), isInt16List);
    testInt(typed_data.Int32List.new(10), isInt32List);
    testInt(typed_data.Uint8List.new(10), isUint8List);
    testInt(typed_data.Uint16List.new(10), isUint16List);
    testInt(typed_data.Uint32List.new(10), isUint32List);
    testInt(typed_data.Uint8ClampedList.new(10), isUint8ClampedList);
  };
  dart.fn(typed_data_sublist_type_test.testTypes, dart.void, []);
  typed_data_sublist_type_test.main = function() {
    typed_data_sublist_type_test.inscrutable = dart.fn(x => x);
    typed_data_sublist_type_test.testTypes();
  };
  dart.fn(typed_data_sublist_type_test.main);
  // Exports:
  exports.typed_data_sublist_type_test = typed_data_sublist_type_test;
});
dart_library.library('typed_list_iterable_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_list_iterable_test = Object.create(null);
  typed_list_iterable_test.testIterableFunctions = function(list, first, last) {
    dart.assert(dart.dsend(dart.dload(list, 'length'), '>', 0));
    expect$.Expect.equals(first, dart.dload(list, 'first'));
    expect$.Expect.equals(last, dart.dload(list, 'last'));
    expect$.Expect.equals(first, dart.dsend(list, 'firstWhere', dart.fn(x => dart.equals(x, first), core.bool, [dart.dynamic])));
    expect$.Expect.equals(last, dart.dsend(list, 'lastWhere', dart.fn(x => dart.equals(x, last), core.bool, [dart.dynamic])));
    if (dart.equals(dart.dload(list, 'length'), 1)) {
      expect$.Expect.equals(first, dart.dload(list, 'single'));
      expect$.Expect.equals(first, dart.dsend(list, 'singleWhere', dart.fn(x => dart.equals(x, last), core.bool, [dart.dynamic])));
    } else {
      expect$.Expect.throws(dart.fn(() => dart.dload(list, 'single'), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
      let isFirst = true;
      expect$.Expect.equals(first, dart.dsend(list, 'singleWhere', dart.fn(x => {
        if (isFirst) {
          isFirst = false;
          return true;
        }
        return false;
      }, core.bool, [dart.dynamic])));
    }
    expect$.Expect.isFalse(dart.dload(list, 'isEmpty'));
    let i = 0;
    for (let x of dart.as(list, core.Iterable)) {
      expect$.Expect.equals(dart.dindex(list, i++), x);
    }
    expect$.Expect.isTrue(dart.dsend(list, 'any', dart.fn(x => dart.equals(x, last), core.bool, [dart.dynamic])));
    expect$.Expect.isFalse(dart.dsend(list, 'any', dart.fn(x => false, core.bool, [dart.dynamic])));
    expect$.Expect.isTrue(dart.dsend(list, 'contains', last));
    expect$.Expect.equals(first, dart.dsend(list, 'elementAt', 0));
    expect$.Expect.isTrue(dart.dsend(list, 'every', dart.fn(x => true, core.bool, [dart.dynamic])));
    expect$.Expect.isFalse(dart.dsend(list, 'every', dart.fn(x => !dart.equals(x, last), core.bool, [dart.dynamic])));
    expect$.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => [], core.List, [dart.dynamic])), 'toList'), core.List));
    let expand2 = dart.dsend(list, 'expand', dart.fn(x => [x, x], core.List, [dart.dynamic]));
    i = 0;
    for (let x of dart.as(expand2, core.Iterable)) {
      expect$.Expect.equals(dart.dindex(list, (i / 2)[dartx.truncate]()), x);
      i++;
    }
    expect$.Expect.equals(2 * dart.notNull(dart.as(dart.dload(list, 'length'), core.num)), i);
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(list, 'fold', [], dart.fn((result, x) => ((() => {
      dart.dsend(result, 'add', x);
      return result;
    })()))), core.List));
    i = 0;
    dart.dsend(list, 'forEach', dart.fn(x => {
      expect$.Expect.equals(dart.dindex(list, i++), x);
    }));
    expect$.Expect.equals(dart.dsend(dart.dsend(list, 'toList'), 'join', "*"), dart.dsend(list, 'join', "*"));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'map', dart.fn(x => x)), 'toList'), core.List));
    let mapCount = 0;
    let mappedList = dart.dsend(list, 'map', dart.fn(x => {
      mapCount++;
      return x;
    }));
    expect$.Expect.equals(0, mapCount);
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(mappedList, 'length'));
    expect$.Expect.equals(0, mapCount);
    dart.dsend(mappedList, 'join');
    expect$.Expect.equals(dart.dload(list, 'length'), mapCount);
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'where', dart.fn(x => true, core.bool, [dart.dynamic])), 'toList'), core.List));
    let whereCount = 0;
    let whereList = dart.dsend(list, 'where', dart.fn(x => {
      whereCount++;
      return true;
    }, core.bool, [dart.dynamic]));
    expect$.Expect.equals(0, whereCount);
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(whereList, 'length'));
    expect$.Expect.equals(dart.dload(list, 'length'), whereCount);
    if (dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '>', 1), core.bool))) {
      let reduceResult = 1;
      expect$.Expect.equals(dart.dload(list, 'length'), dart.dsend(list, 'reduce', dart.fn((x, y) => ++reduceResult, core.int, [dart.dynamic, dart.dynamic])));
    } else {
      expect$.Expect.equals(first, dart.dsend(list, 'reduce', dart.fn((x, y) => {
        dart.throw("should not be called");
      })));
    }
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skip', dart.dload(list, 'length')), 'isEmpty'));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'skip', 0), 'toList'), core.List));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skipWhile', dart.fn(x => true, core.bool, [dart.dynamic])), 'isEmpty'));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'skipWhile', dart.fn(x => false, core.bool, [dart.dynamic])), 'toList'), core.List));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'take', dart.dload(list, 'length')), 'toList'), core.List));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'take', 0), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'takeWhile', dart.fn(x => false, core.bool, [dart.dynamic])), 'isEmpty'));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'takeWhile', dart.fn(x => true, core.bool, [dart.dynamic])), 'toList'), core.List));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'toList'), 'toList'), core.List));
    let l2 = dart.dsend(list, 'toList');
    dart.dsend(l2, 'add', first);
    expect$.Expect.equals(first, dart.dload(l2, 'last'));
    let l3 = dart.dsend(list, 'toList', {growable: false});
    expect$.Expect.throws(dart.fn(() => dart.dsend(l3, 'add', last), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
  };
  dart.fn(typed_list_iterable_test.testIterableFunctions, dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]);
  typed_list_iterable_test.emptyChecks = function(list) {
    dart.assert(dart.equals(dart.dload(list, 'length'), 0));
    expect$.Expect.isTrue(dart.dload(list, 'isEmpty'));
    expect$.Expect.throws(dart.fn(() => dart.dload(list, 'first'), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dload(list, 'last'), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dload(list, 'single'), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'firstWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'lastWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'singleWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect$.Expect.isFalse(dart.dsend(list, 'any', dart.fn(x => true, core.bool, [dart.dynamic])));
    expect$.Expect.isFalse(dart.dsend(list, 'contains', null));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'elementAt', 0), dart.void, []), dart.fn(e => dart.is(e, core.RangeError), core.bool, [dart.dynamic]));
    expect$.Expect.isTrue(dart.dsend(list, 'every', dart.fn(x => false, core.bool, [dart.dynamic])));
    expect$.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => [], core.List, [dart.dynamic])), 'toList'), core.List));
    expect$.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => [x, x], core.List, [dart.dynamic])), 'toList'), core.List));
    expect$.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => {
      dart.throw("should not be reached");
    })), 'toList'), core.List));
    expect$.Expect.listEquals([], dart.as(dart.dsend(list, 'fold', [], dart.fn((result, x) => ((() => {
      dart.dsend(result, 'add', x);
      return result;
    })()))), core.List));
    expect$.Expect.equals(dart.dsend(dart.dsend(list, 'toList'), 'join', "*"), dart.dsend(list, 'join', "*"));
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'map', dart.fn(x => x)), 'toList'), core.List));
    let mapCount = 0;
    let mappedList = dart.dsend(list, 'map', dart.fn(x => {
      mapCount++;
      return x;
    }));
    expect$.Expect.equals(0, mapCount);
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(mappedList, 'length'));
    expect$.Expect.equals(0, mapCount);
    dart.dsend(mappedList, 'join');
    expect$.Expect.equals(dart.dload(list, 'length'), mapCount);
    expect$.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'where', dart.fn(x => true, core.bool, [dart.dynamic])), 'toList'), core.List));
    let whereCount = 0;
    let whereList = dart.dsend(list, 'where', dart.fn(x => {
      whereCount++;
      return true;
    }, core.bool, [dart.dynamic]));
    expect$.Expect.equals(0, whereCount);
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(whereList, 'length'));
    expect$.Expect.equals(dart.dload(list, 'length'), whereCount);
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'reduce', dart.fn((x, y) => x)), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skip', dart.dload(list, 'length')), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skip', 0), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skipWhile', dart.fn(x => true, core.bool, [dart.dynamic])), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skipWhile', dart.fn(x => false, core.bool, [dart.dynamic])), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'take', dart.dload(list, 'length')), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'take', 0), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'takeWhile', dart.fn(x => false, core.bool, [dart.dynamic])), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'takeWhile', dart.fn(x => true, core.bool, [dart.dynamic])), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'toList'), 'isEmpty'));
    let l2 = dart.dsend(list, 'toList');
    dart.dsend(l2, 'add', 0);
    expect$.Expect.equals(0, dart.dload(l2, 'last'));
    let l3 = dart.dsend(list, 'toList', {growable: false});
    expect$.Expect.throws(dart.fn(() => dart.dsend(l3, 'add', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
  };
  dart.fn(typed_list_iterable_test.emptyChecks, dart.void, [dart.dynamic]);
  typed_list_iterable_test.main = function() {
    typed_list_iterable_test.testIterableFunctions(typed_data.Float32List.fromList(dart.list([1.5, 9.5], core.double)), 1.5, 9.5);
    typed_list_iterable_test.testIterableFunctions(typed_data.Float64List.fromList(dart.list([1.5, 9.5], core.double)), 1.5, 9.5);
    typed_list_iterable_test.testIterableFunctions(typed_data.Int8List.fromList(dart.list([3, 9], core.int)), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Int16List.fromList(dart.list([3, 9], core.int)), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Int32List.fromList(dart.list([3, 9], core.int)), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Uint8List.fromList(dart.list([3, 9], core.int)), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Uint16List.fromList(dart.list([3, 9], core.int)), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Uint32List.fromList(dart.list([3, 9], core.int)), 3, 9);
    typed_list_iterable_test.emptyChecks(typed_data.Float32List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Float64List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Int8List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Int16List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Int32List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Uint8List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Uint16List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Uint32List.new(0));
  };
  dart.fn(typed_list_iterable_test.main);
  // Exports:
  exports.typed_list_iterable_test = typed_list_iterable_test;
});
