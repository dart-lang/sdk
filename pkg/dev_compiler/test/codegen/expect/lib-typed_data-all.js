dart_library.library('lib/typed_data/byte_data_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function main() {
    testRegress10898();
  }
  dart.fn(main);
  function testRegress10898() {
    let data = typed_data.ByteData.new(16);
    expect.Expect.equals(16, data[dartx.lengthInBytes]);
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i++) {
      expect.Expect.equals(0, data[dartx.getInt8](i));
      data[dartx.setInt8](i, 42 + i);
      expect.Expect.equals(42 + i, data[dartx.getInt8](i));
    }
    let backing = typed_data.ByteData.new(16);
    let view = typed_data.ByteData.view(backing[dartx.buffer]);
    for (let i = 0; i < dart.notNull(view[dartx.lengthInBytes]); i++) {
      expect.Expect.equals(0, view[dartx.getInt8](i));
      view[dartx.setInt8](i, 87 + i);
      expect.Expect.equals(87 + i, view[dartx.getInt8](i));
    }
    view = typed_data.ByteData.view(backing[dartx.buffer], 4);
    expect.Expect.equals(12, view[dartx.lengthInBytes]);
    for (let i = 0; i < dart.notNull(view[dartx.lengthInBytes]); i++) {
      expect.Expect.equals(87 + i + 4, view[dartx.getInt8](i));
    }
    view = typed_data.ByteData.view(backing[dartx.buffer], 8, 4);
    expect.Expect.equals(4, view[dartx.lengthInBytes]);
    for (let i = 0; i < dart.notNull(view[dartx.lengthInBytes]); i++) {
      expect.Expect.equals(87 + i + 8, view[dartx.getInt8](i));
    }
  }
  dart.fn(testRegress10898);
  // Exports:
  exports.main = main;
  exports.testRegress10898 = testRegress10898;
});
dart_library.library('lib/typed_data/constructor_checks_test', null, /* Imports */[
  'dart/_runtime',
  'expect/expect',
  'dart/typed_data',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, expect, typed_data, core) {
  'use strict';
  let dartx = dart.dartx;
  function checkLengthConstructors() {
    function check(creator) {
      expect.Expect.throws(dart.fn(() => dart.dcall(creator, null), dart.void, []));
      expect.Expect.throws(dart.fn(() => dart.dcall(creator, 8.5), dart.void, []));
      expect.Expect.throws(dart.fn(() => dart.dcall(creator, '10'), dart.void, []));
      let a = dart.dcall(creator, 10);
      expect.Expect.equals(10, dart.dload(a, 'length'));
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
  }
  dart.fn(checkLengthConstructors);
  function checkViewConstructors() {
    let buffer = typed_data.Int8List.new(256)[dartx.buffer];
    function check1(creator) {
      expect.Expect.throws(dart.fn(() => dart.dcall(creator, 10), dart.void, []));
      expect.Expect.throws(dart.fn(() => dart.dcall(creator, null), dart.void, []));
      let a = dart.dcall(creator, buffer);
      expect.Expect.equals(buffer, dart.dload(a, 'buffer'));
    }
    dart.fn(check1);
    function check2(creator) {
      expect.Expect.throws(dart.fn(() => dart.dcall(creator, 10, 0), dart.void, []));
      expect.Expect.throws(dart.fn(() => dart.dcall(creator, null, 0), dart.void, []));
      expect.Expect.throws(dart.fn(() => dart.dcall(creator, buffer, null), dart.void, []));
      expect.Expect.throws(dart.fn(() => dart.dcall(creator, buffer, '8'), dart.void, []));
      let a = dart.dcall(creator, buffer, 8);
      expect.Expect.equals(buffer, dart.dload(a, 'buffer'));
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
  }
  dart.fn(checkViewConstructors);
  function main() {
    checkLengthConstructors();
    checkViewConstructors();
  }
  dart.fn(main);
  // Exports:
  exports.checkLengthConstructors = checkLengthConstructors;
  exports.checkViewConstructors = checkViewConstructors;
  exports.main = main;
});
dart_library.library('lib/typed_data/endianness_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function main() {
    swapTest();
    swapTestVar(typed_data.Endianness.LITTLE_ENDIAN, typed_data.Endianness.BIG_ENDIAN);
    swapTestVar(typed_data.Endianness.BIG_ENDIAN, typed_data.Endianness.LITTLE_ENDIAN);
  }
  dart.fn(main);
  function swapTest() {
    let data = typed_data.ByteData.new(16);
    expect.Expect.equals(16, data[dartx.lengthInBytes]);
    for (let i = 0; i < 4; i++) {
      data[dartx.setInt32](i * 4, i);
    }
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getInt32](i, typed_data.Endianness.BIG_ENDIAN);
      data[dartx.setInt32](i, e, typed_data.Endianness.LITTLE_ENDIAN);
    }
    expect.Expect.equals(33554432, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getInt16](i, typed_data.Endianness.BIG_ENDIAN);
      data[dartx.setInt16](i, e, typed_data.Endianness.LITTLE_ENDIAN);
    }
    expect.Expect.equals(131072, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getUint32](i, typed_data.Endianness.LITTLE_ENDIAN);
      data[dartx.setUint32](i, e, typed_data.Endianness.BIG_ENDIAN);
    }
    expect.Expect.equals(512, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getUint16](i, typed_data.Endianness.LITTLE_ENDIAN);
      data[dartx.setUint16](i, e, typed_data.Endianness.BIG_ENDIAN);
    }
    expect.Expect.equals(2, data[dartx.getInt32](8));
  }
  dart.fn(swapTest);
  function swapTestVar(read, write) {
    let data = typed_data.ByteData.new(16);
    expect.Expect.equals(16, data[dartx.lengthInBytes]);
    for (let i = 0; i < 4; i++) {
      data[dartx.setInt32](i * 4, i);
    }
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getInt32](i, dart.as(read, typed_data.Endianness));
      data[dartx.setInt32](i, e, dart.as(write, typed_data.Endianness));
    }
    expect.Expect.equals(33554432, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getInt16](i, dart.as(read, typed_data.Endianness));
      data[dartx.setInt16](i, e, dart.as(write, typed_data.Endianness));
    }
    expect.Expect.equals(131072, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getUint32](i, dart.as(read, typed_data.Endianness));
      data[dartx.setUint32](i, e, dart.as(write, typed_data.Endianness));
    }
    expect.Expect.equals(512, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getUint16](i, dart.as(read, typed_data.Endianness));
      data[dartx.setUint16](i, e, dart.as(write, typed_data.Endianness));
    }
    expect.Expect.equals(2, data[dartx.getInt32](8));
  }
  dart.fn(swapTestVar);
  // Exports:
  exports.main = main;
  exports.swapTest = swapTest;
  exports.swapTestVar = swapTestVar;
});
dart_library.library('lib/typed_data/float32x4_clamp_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function testClampLowerGreaterThanUpper() {
    let l = typed_data.Float32x4.new(1.0, 1.0, 1.0, 1.0);
    let u = typed_data.Float32x4.new(-1.0, -1.0, -1.0, -1.0);
    let z = typed_data.Float32x4.zero();
    let a = z.clamp(l, u);
    expect.Expect.equals(a.x, 1.0);
    expect.Expect.equals(a.y, 1.0);
    expect.Expect.equals(a.z, 1.0);
    expect.Expect.equals(a.w, 1.0);
  }
  dart.fn(testClampLowerGreaterThanUpper, dart.void, []);
  function testClamp() {
    let l = typed_data.Float32x4.new(-1.0, -1.0, -1.0, -1.0);
    let u = typed_data.Float32x4.new(1.0, 1.0, 1.0, 1.0);
    let z = typed_data.Float32x4.zero();
    let a = z.clamp(l, u);
    expect.Expect.equals(a.x, 0.0);
    expect.Expect.equals(a.y, 0.0);
    expect.Expect.equals(a.z, 0.0);
    expect.Expect.equals(a.w, 0.0);
  }
  dart.fn(testClamp, dart.void, []);
  function main() {
    for (let i = 0; i < 2000; i++) {
      testClampLowerGreaterThanUpper();
      testClamp();
    }
  }
  dart.fn(main);
  // Exports:
  exports.testClampLowerGreaterThanUpper = testClampLowerGreaterThanUpper;
  exports.testClamp = testClamp;
  exports.main = main;
});
dart_library.library('lib/typed_data/float32x4_cross_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function cross(a, b) {
    let t0 = a.shuffle(typed_data.Float32x4.YZXW);
    let t1 = b.shuffle(typed_data.Float32x4.ZXYW);
    let l = t0['*'](t1);
    t0 = a.shuffle(typed_data.Float32x4.ZXYW);
    t1 = b.shuffle(typed_data.Float32x4.YZXW);
    let r = t0['*'](t1);
    return l['-'](r);
  }
  dart.fn(cross, typed_data.Float32x4, [typed_data.Float32x4, typed_data.Float32x4]);
  function testCross(a, b, r) {
    let x = cross(a, b);
    expect.Expect.equals(r.x, x.x);
    expect.Expect.equals(r.y, x.y);
    expect.Expect.equals(r.z, x.z);
    expect.Expect.equals(r.w, x.w);
  }
  dart.fn(testCross, dart.void, [typed_data.Float32x4, typed_data.Float32x4, typed_data.Float32x4]);
  function main() {
    let x = typed_data.Float32x4.new(1.0, 0.0, 0.0, 0.0);
    let y = typed_data.Float32x4.new(0.0, 1.0, 0.0, 0.0);
    let z = typed_data.Float32x4.new(0.0, 0.0, 1.0, 0.0);
    let zero = typed_data.Float32x4.zero();
    for (let i = 0; i < 20; i++) {
      testCross(x, y, z);
      testCross(z, x, y);
      testCross(y, z, x);
      testCross(z, y, x['unary-']());
      testCross(x, z, y['unary-']());
      testCross(y, x, z['unary-']());
      testCross(x, x, zero);
      testCross(y, y, zero);
      testCross(z, z, zero);
      testCross(x, y, cross(y['unary-'](), x));
      testCross(x, y['+'](z), cross(x, y)['+'](cross(x, z)));
    }
  }
  dart.fn(main);
  // Exports:
  exports.cross = cross;
  exports.testCross = testCross;
  exports.main = main;
});
dart_library.library('lib/typed_data/float32x4_list_test', null, /* Imports */[
  'dart/_runtime',
  'expect/expect',
  'dart/core',
  'dart/typed_data'
], /* Lazy imports */[
], function(exports, dart, expect, core, typed_data) {
  'use strict';
  let dartx = dart.dartx;
  function testLoadStore(array) {
    expect.Expect.equals(8, dart.dload(array, 'length'));
    expect.Expect.isTrue(dart.is(array, core.List$(typed_data.Float32x4)));
    dart.dsetindex(array, 0, typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0));
    expect.Expect.equals(1.0, dart.dload(dart.dindex(array, 0), 'x'));
    expect.Expect.equals(2.0, dart.dload(dart.dindex(array, 0), 'y'));
    expect.Expect.equals(3.0, dart.dload(dart.dindex(array, 0), 'z'));
    expect.Expect.equals(4.0, dart.dload(dart.dindex(array, 0), 'w'));
    dart.dsetindex(array, 1, dart.dindex(array, 0));
    dart.dsetindex(array, 0, dart.dsend(dart.dindex(array, 0), 'withX', 9.0));
    expect.Expect.equals(9.0, dart.dload(dart.dindex(array, 0), 'x'));
    expect.Expect.equals(2.0, dart.dload(dart.dindex(array, 0), 'y'));
    expect.Expect.equals(3.0, dart.dload(dart.dindex(array, 0), 'z'));
    expect.Expect.equals(4.0, dart.dload(dart.dindex(array, 0), 'w'));
    expect.Expect.equals(1.0, dart.dload(dart.dindex(array, 1), 'x'));
    expect.Expect.equals(2.0, dart.dload(dart.dindex(array, 1), 'y'));
    expect.Expect.equals(3.0, dart.dload(dart.dindex(array, 1), 'z'));
    expect.Expect.equals(4.0, dart.dload(dart.dindex(array, 1), 'w'));
  }
  dart.fn(testLoadStore);
  function testLoadStoreDeopt(array, index, value) {
    dart.dsetindex(array, index, value);
    expect.Expect.equals(dart.dload(value, 'x'), dart.dload(dart.dindex(array, index), 'x'));
    expect.Expect.equals(dart.dload(value, 'y'), dart.dload(dart.dindex(array, index), 'y'));
    expect.Expect.equals(dart.dload(value, 'z'), dart.dload(dart.dindex(array, index), 'z'));
    expect.Expect.equals(dart.dload(value, 'w'), dart.dload(dart.dindex(array, index), 'w'));
  }
  dart.fn(testLoadStoreDeopt);
  function testLoadStoreDeoptDriver() {
    let list = typed_data.Float32x4List.new(4);
    let value = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(list, 5, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(null, 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(list, 0, null);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(list, 3.14159, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(list, 0, (4)[dartx.toDouble]());
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt([typed_data.Float32x4.new(2.0, 3.0, 4.0, 5.0)], 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
  }
  dart.fn(testLoadStoreDeoptDriver);
  function testListZero() {
    let list = typed_data.Float32x4List.new(1);
    expect.Expect.equals(0.0, list.get(0).x);
    expect.Expect.equals(0.0, list.get(0).y);
    expect.Expect.equals(0.0, list.get(0).z);
    expect.Expect.equals(0.0, list.get(0).w);
  }
  dart.fn(testListZero);
  function testView(array) {
    expect.Expect.equals(8, dart.dload(array, 'length'));
    expect.Expect.isTrue(dart.is(array, core.List$(typed_data.Float32x4)));
    expect.Expect.equals(0.0, dart.dload(dart.dindex(array, 0), 'x'));
    expect.Expect.equals(1.0, dart.dload(dart.dindex(array, 0), 'y'));
    expect.Expect.equals(2.0, dart.dload(dart.dindex(array, 0), 'z'));
    expect.Expect.equals(3.0, dart.dload(dart.dindex(array, 0), 'w'));
    expect.Expect.equals(4.0, dart.dload(dart.dindex(array, 1), 'x'));
    expect.Expect.equals(5.0, dart.dload(dart.dindex(array, 1), 'y'));
    expect.Expect.equals(6.0, dart.dload(dart.dindex(array, 1), 'z'));
    expect.Expect.equals(7.0, dart.dload(dart.dindex(array, 1), 'w'));
  }
  dart.fn(testView);
  function testSublist(array) {
    expect.Expect.equals(8, dart.dload(array, 'length'));
    expect.Expect.isTrue(dart.is(array, typed_data.Float32x4List));
    let a = dart.dsend(array, 'sublist', 0, 1);
    expect.Expect.equals(1, dart.dload(a, 'length'));
    expect.Expect.equals(0.0, dart.dload(dart.dindex(a, 0), 'x'));
    expect.Expect.equals(1.0, dart.dload(dart.dindex(a, 0), 'y'));
    expect.Expect.equals(2.0, dart.dload(dart.dindex(a, 0), 'z'));
    expect.Expect.equals(3.0, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 1, 2);
    expect.Expect.equals(4.0, dart.dload(dart.dindex(a, 0), 'x'));
    expect.Expect.equals(5.0, dart.dload(dart.dindex(a, 0), 'y'));
    expect.Expect.equals(6.0, dart.dload(dart.dindex(a, 0), 'z'));
    expect.Expect.equals(7.0, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 0);
    expect.Expect.equals(dart.dload(a, 'length'), dart.dload(array, 'length'));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(array, 'length'), core.num)); i++) {
      expect.Expect.equals(dart.dload(dart.dindex(array, i), 'x'), dart.dload(dart.dindex(a, i), 'x'));
      expect.Expect.equals(dart.dload(dart.dindex(array, i), 'y'), dart.dload(dart.dindex(a, i), 'y'));
      expect.Expect.equals(dart.dload(dart.dindex(array, i), 'z'), dart.dload(dart.dindex(a, i), 'z'));
      expect.Expect.equals(dart.dload(dart.dindex(array, i), 'w'), dart.dload(dart.dindex(a, i), 'w'));
    }
  }
  dart.fn(testSublist);
  function testSpecialValues(array) {
    function checkEquals(expected, actual) {
      if (dart.notNull(dart.as(dart.dload(expected, 'isNaN'), core.bool))) {
        expect.Expect.isTrue(dart.dload(actual, 'isNaN'));
      } else if (dart.equals(expected, 0.0) && dart.notNull(dart.as(dart.dload(expected, 'isNegative'), core.bool))) {
        expect.Expect.isTrue(dart.equals(actual, 0.0) && dart.notNull(dart.as(dart.dload(actual, 'isNegative'), core.bool)));
      } else {
        expect.Expect.equals(expected, actual);
      }
    }
    dart.fn(checkEquals, dart.void, [dart.dynamic, dart.dynamic]);
    let pairs = [[0.0, 0.0], [5e-324, 0.0], [2.225073858507201e-308, 0.0], [2.2250738585072014e-308, 0.0], [0.9999999999999999, 1.0], [1.0, 1.0], [1.0000000000000002, 1.0], [4294967295.0, 4294967296.0], [4294967296.0, 4294967296.0], [4503599627370495.5, 4503599627370496.0], [9007199254740992.0, 9007199254740992.0], [1.7976931348623157e+308, core.double.INFINITY], [0.49999999999999994, 0.5], [4503599627370497.0, 4503599627370496.0], [9007199254740991.0, 9007199254740992.0], [core.double.INFINITY, core.double.INFINITY], [core.double.NAN, core.double.NAN]];
    let conserved = [1.401298464324817e-45, 1.1754942106924411e-38, 1.1754943508222875e-38, 0.9999999403953552, 1.0000001192092896, 8388607.5, 8388608.0, 3.4028234663852886e+38, 8388609.0, 16777215.0];
    let minusPairs = pairs[dartx.map](dart.fn(pair => {
      return [dart.dsend(dart.dindex(pair, 0), 'unary-'), dart.dsend(dart.dindex(pair, 1), 'unary-')];
    }));
    let conservedPairs = conserved[dartx.map](dart.fn(value => [value, value], core.List, [dart.dynamic]));
    let allTests = [pairs, minusPairs, conservedPairs][dartx.expand](dart.fn(x => dart.as(x, core.Iterable), core.Iterable, [dart.dynamic]));
    for (let pair of allTests) {
      let input = dart.dindex(pair, 0);
      let expected = dart.dindex(pair, 1);
      let f = null;
      f = typed_data.Float32x4.new(dart.as(input, core.double), 2.0, 3.0, 4.0);
      dart.dsetindex(array, 0, f);
      f = dart.dindex(array, 0);
      checkEquals(expected, dart.dload(f, 'x'));
      expect.Expect.equals(2.0, dart.dload(f, 'y'));
      expect.Expect.equals(3.0, dart.dload(f, 'z'));
      expect.Expect.equals(4.0, dart.dload(f, 'w'));
      f = typed_data.Float32x4.new(1.0, dart.as(input, core.double), 3.0, 4.0);
      dart.dsetindex(array, 1, f);
      f = dart.dindex(array, 1);
      expect.Expect.equals(1.0, dart.dload(f, 'x'));
      checkEquals(expected, dart.dload(f, 'y'));
      expect.Expect.equals(3.0, dart.dload(f, 'z'));
      expect.Expect.equals(4.0, dart.dload(f, 'w'));
      f = typed_data.Float32x4.new(1.0, 2.0, dart.as(input, core.double), 4.0);
      dart.dsetindex(array, 2, f);
      f = dart.dindex(array, 2);
      expect.Expect.equals(1.0, dart.dload(f, 'x'));
      expect.Expect.equals(2.0, dart.dload(f, 'y'));
      checkEquals(expected, dart.dload(f, 'z'));
      expect.Expect.equals(4.0, dart.dload(f, 'w'));
      f = typed_data.Float32x4.new(1.0, 2.0, 3.0, dart.as(input, core.double));
      dart.dsetindex(array, 3, f);
      f = dart.dindex(array, 3);
      expect.Expect.equals(1.0, dart.dload(f, 'x'));
      expect.Expect.equals(2.0, dart.dload(f, 'y'));
      expect.Expect.equals(3.0, dart.dload(f, 'z'));
      checkEquals(expected, dart.dload(f, 'w'));
    }
  }
  dart.fn(testSpecialValues, dart.void, [dart.dynamic]);
  function main() {
    let list = null;
    list = typed_data.Float32x4List.new(8);
    for (let i = 0; i < 20; i++) {
      testLoadStore(list);
    }
    let floatList = typed_data.Float32List.new(32);
    for (let i = 0; i < dart.notNull(floatList[dartx.length]); i++) {
      floatList[dartx.set](i, i[dartx.toDouble]());
    }
    list = typed_data.Float32x4List.view(floatList[dartx.buffer]);
    for (let i = 0; i < 20; i++) {
      testView(list);
    }
    for (let i = 0; i < 20; i++) {
      testSublist(list);
    }
    for (let i = 0; i < 20; i++) {
      testLoadStore(list);
    }
    for (let i = 0; i < 20; i++) {
      testListZero();
    }
    for (let i = 0; i < 20; i++) {
      testSpecialValues(list);
    }
    testLoadStoreDeoptDriver();
  }
  dart.fn(main);
  // Exports:
  exports.testLoadStore = testLoadStore;
  exports.testLoadStoreDeopt = testLoadStoreDeopt;
  exports.testLoadStoreDeoptDriver = testLoadStoreDeoptDriver;
  exports.testListZero = testListZero;
  exports.testView = testView;
  exports.testSublist = testSublist;
  exports.testSpecialValues = testSpecialValues;
  exports.main = main;
});
dart_library.library('lib/typed_data/float32x4_shuffle_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect, core) {
  'use strict';
  let dartx = dart.dartx;
  function testShuffle00() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.XXXX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXXY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXXZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXXW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXYX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXYY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXYZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXYW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXZX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXZY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXZZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXZW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXWX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXWY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXWZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XXWW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle00, dart.void, []);
  function testShuffle01() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.XYXX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYXY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYXZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYXW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYYX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYYY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYYZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYYW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYZX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYZY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYZZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYZW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYWX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYWY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYWZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XYWW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle01, dart.void, []);
  function testShuffle02() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.XZXX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZXY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZXZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZXW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZYX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZYY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZYZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZYW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZZX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZZY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZZZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZZW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZWX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZWY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZWZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XZWW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle02, dart.void, []);
  function testShuffle03() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.XWXX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWXY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWXZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWXW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWYX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWYY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWYZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWYW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWZX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWZY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWZZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWZW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWWX);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWWY);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWWZ);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.XWWW);
    expect.Expect.equals(1.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle03, dart.void, []);
  function testShuffle10() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.YXXX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXXY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXXZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXXW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXYX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXYY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXYZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXYW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXZX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXZY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXZZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXZW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXWX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXWY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXWZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YXWW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle10, dart.void, []);
  function testShuffle11() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.YYXX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYXY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYXZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYXW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYYX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYYY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYYZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYYW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYZX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYZY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYZZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYZW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYWX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYWY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYWZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YYWW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle11, dart.void, []);
  function testShuffle12() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.YZXX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZXY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZXZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZXW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZYX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZYY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZYZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZYW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZZX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZZY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZZZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZZW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZWX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZWY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZWZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YZWW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle12, dart.void, []);
  function testShuffle13() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.YWXX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWXY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWXZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWXW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWYX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWYY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWYZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWYW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWZX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWZY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWZZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWZW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWWX);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWWY);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWWZ);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.YWWW);
    expect.Expect.equals(2.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle13, dart.void, []);
  function testShuffle20() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.ZXXX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXXY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXXZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXXW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXYX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXYY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXYZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXYW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXZX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXZY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXZZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXZW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXWX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXWY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXWZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZXWW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle20, dart.void, []);
  function testShuffle21() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.ZYXX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYXY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYXZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYXW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYYX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYYY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYYZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYYW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYZX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYZY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYZZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYZW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYWX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYWY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYWZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZYWW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle21, dart.void, []);
  function testShuffle22() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.ZZXX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZXY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZXZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZXW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZYX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZYY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZYZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZYW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZZX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZZY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZZZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZZW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZWX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZWY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZWZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZZWW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle22, dart.void, []);
  function testShuffle23() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.ZWXX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWXY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWXZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWXW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWYX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWYY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWYZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWYW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWZX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWZY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWZZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWZW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWWX);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWWY);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWWZ);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.ZWWW);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle23, dart.void, []);
  function testShuffle30() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WXXX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXXY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXXZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXXW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXYX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXYY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXYZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXYW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXZX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXZY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXZZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXZW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXWX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXWY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXWZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WXWW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(1.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle30, dart.void, []);
  function testShuffle31() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WYXX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYXY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYXZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYXW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYYX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYYY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYYZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYYW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYZX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYZY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYZZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYZW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYWX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYWY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYWZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WYWW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(2.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle31, dart.void, []);
  function testShuffle32() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WZXX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZXY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZXZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZXW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZYX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZYY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZYZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZYW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZZX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZZY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZZZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZZW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZWX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZWY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZWZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WZWW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle32, dart.void, []);
  function testShuffle33() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WWXX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWXY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWXZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWXW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(1.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWYX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWYY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWYZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWYW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWZX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWZY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWZZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWZW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(3.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWWX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWWY);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(2.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWWZ);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(3.0, dart.dload(c, 'w'));
    c = m.shuffle(typed_data.Float32x4.WWWW);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(4.0, dart.dload(c, 'y'));
    expect.Expect.equals(4.0, dart.dload(c, 'z'));
    expect.Expect.equals(4.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle33, dart.void, []);
  function testShuffleNonConstant(mask) {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(dart.as(mask, core.int));
    if (dart.equals(mask, 1)) {
      expect.Expect.equals(2.0, dart.dload(c, 'x'));
      expect.Expect.equals(1.0, dart.dload(c, 'y'));
      expect.Expect.equals(1.0, dart.dload(c, 'z'));
      expect.Expect.equals(1.0, dart.dload(c, 'w'));
    } else {
      expect.Expect.equals(dart.notNull(typed_data.Float32x4.YYYY) + 1, mask);
      expect.Expect.equals(3.0, dart.dload(c, 'x'));
      expect.Expect.equals(2.0, dart.dload(c, 'y'));
      expect.Expect.equals(2.0, dart.dload(c, 'z'));
      expect.Expect.equals(2.0, dart.dload(c, 'w'));
    }
  }
  dart.fn(testShuffleNonConstant, dart.void, [dart.dynamic]);
  function testInvalidShuffle(mask) {
    expect.Expect.isFalse(dart.notNull(dart.as(dart.dsend(mask, '<=', 255), core.bool)) && dart.notNull(dart.as(dart.dsend(mask, '>=', 0), core.bool)));
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    expect.Expect.throws(dart.fn(() => {
      c = m.shuffle(dart.as(mask, core.int));
    }, dart.void, []));
  }
  dart.fn(testInvalidShuffle, dart.void, [dart.dynamic]);
  function testShuffle() {
    let m = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let c = null;
    c = m.shuffle(typed_data.Float32x4.WZYX);
    expect.Expect.equals(4.0, dart.dload(c, 'x'));
    expect.Expect.equals(3.0, dart.dload(c, 'y'));
    expect.Expect.equals(2.0, dart.dload(c, 'z'));
    expect.Expect.equals(1.0, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle, dart.void, []);
  function main() {
    let xxxx = dart.notNull(typed_data.Float32x4.XXXX) + 1;
    let yyyy = dart.notNull(typed_data.Float32x4.YYYY) + 1;
    for (let i = 0; i < 20; i++) {
      testShuffle();
      testShuffle00();
      testShuffle01();
      testShuffle02();
      testShuffle03();
      testShuffle10();
      testShuffle11();
      testShuffle12();
      testShuffle13();
      testShuffle20();
      testShuffle21();
      testShuffle22();
      testShuffle23();
      testShuffle30();
      testShuffle31();
      testShuffle32();
      testShuffle33();
      testShuffleNonConstant(xxxx);
      testShuffleNonConstant(yyyy);
      testInvalidShuffle(256);
      testInvalidShuffle(-1);
    }
  }
  dart.fn(main);
  // Exports:
  exports.testShuffle00 = testShuffle00;
  exports.testShuffle01 = testShuffle01;
  exports.testShuffle02 = testShuffle02;
  exports.testShuffle03 = testShuffle03;
  exports.testShuffle10 = testShuffle10;
  exports.testShuffle11 = testShuffle11;
  exports.testShuffle12 = testShuffle12;
  exports.testShuffle13 = testShuffle13;
  exports.testShuffle20 = testShuffle20;
  exports.testShuffle21 = testShuffle21;
  exports.testShuffle22 = testShuffle22;
  exports.testShuffle23 = testShuffle23;
  exports.testShuffle30 = testShuffle30;
  exports.testShuffle31 = testShuffle31;
  exports.testShuffle32 = testShuffle32;
  exports.testShuffle33 = testShuffle33;
  exports.testShuffleNonConstant = testShuffleNonConstant;
  exports.testInvalidShuffle = testInvalidShuffle;
  exports.testShuffle = testShuffle;
  exports.main = main;
});
dart_library.library('lib/typed_data/float32x4_sign_mask_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function testImmediates() {
    let f = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let m = f.signMask;
    expect.Expect.equals(0, m);
    f = typed_data.Float32x4.new(-1.0, -2.0, -3.0, -0.0);
    m = f.signMask;
    expect.Expect.equals(15, m);
    f = typed_data.Float32x4.new(-1.0, 2.0, 3.0, 4.0);
    m = f.signMask;
    expect.Expect.equals(1, m);
    f = typed_data.Float32x4.new(1.0, -2.0, 3.0, 4.0);
    m = f.signMask;
    expect.Expect.equals(2, m);
    f = typed_data.Float32x4.new(1.0, 2.0, -3.0, 4.0);
    m = f.signMask;
    expect.Expect.equals(4, m);
    f = typed_data.Float32x4.new(1.0, 2.0, 3.0, -4.0);
    m = f.signMask;
    expect.Expect.equals(8, m);
  }
  dart.fn(testImmediates, dart.void, []);
  function testZero() {
    let f = typed_data.Float32x4.new(0.0, 0.0, 0.0, 0.0);
    let m = f.signMask;
    expect.Expect.equals(0, m);
    f = typed_data.Float32x4.new(-0.0, -0.0, -0.0, -0.0);
    m = f.signMask;
    expect.Expect.equals(15, m);
  }
  dart.fn(testZero, dart.void, []);
  function testArithmetic() {
    let a = typed_data.Float32x4.new(1.0, 1.0, 1.0, 1.0);
    let b = typed_data.Float32x4.new(2.0, 2.0, 2.0, 2.0);
    let c = typed_data.Float32x4.new(-1.0, -1.0, -1.0, -1.0);
    let m1 = a['-'](b).signMask;
    expect.Expect.equals(15, m1);
    let m2 = b['-'](a).signMask;
    expect.Expect.equals(0, m2);
    let m3 = c['*'](c).signMask;
    expect.Expect.equals(0, m3);
    let m4 = a['*'](c).signMask;
    expect.Expect.equals(15, m4);
  }
  dart.fn(testArithmetic, dart.void, []);
  function main() {
    for (let i = 0; i < 2000; i++) {
      testImmediates();
      testZero();
      testArithmetic();
    }
  }
  dart.fn(main);
  // Exports:
  exports.testImmediates = testImmediates;
  exports.testZero = testZero;
  exports.testArithmetic = testArithmetic;
  exports.main = main;
});
dart_library.library('lib/typed_data/float32x4_transpose_test', null, /* Imports */[
  'dart/_runtime',
  'expect/expect',
  'dart/typed_data'
], /* Lazy imports */[
], function(exports, dart, expect, typed_data) {
  'use strict';
  let dartx = dart.dartx;
  function transpose(m) {
    expect.Expect.equals(4, m.length);
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
  }
  dart.fn(transpose, dart.void, [typed_data.Float32x4List]);
  function testTranspose(m, r) {
    transpose(m);
    for (let i = 0; i < 4; i++) {
      let a = m.get(i);
      let b = r.get(i);
      expect.Expect.equals(b.x, a.x);
      expect.Expect.equals(b.y, a.y);
      expect.Expect.equals(b.z, a.z);
      expect.Expect.equals(b.w, a.w);
    }
  }
  dart.fn(testTranspose, dart.void, [typed_data.Float32x4List, typed_data.Float32x4List]);
  function main() {
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
      testTranspose(m, I);
      m = typed_data.Float32x4List.fromList(A);
      testTranspose(m, B);
    }
  }
  dart.fn(main);
  // Exports:
  exports.transpose = transpose;
  exports.testTranspose = testTranspose;
  exports.main = main;
});
dart_library.library('lib/typed_data/float32x4_two_arg_shuffle_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function testWithZWInXY() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = b.shuffleMix(a, typed_data.Float32x4.ZWZW);
    expect.Expect.equals(7.0, c.x);
    expect.Expect.equals(8.0, c.y);
    expect.Expect.equals(3.0, c.z);
    expect.Expect.equals(4.0, c.w);
  }
  dart.fn(testWithZWInXY);
  function testInterleaveXY() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.XYXY).shuffle(typed_data.Float32x4.XZYW);
    expect.Expect.equals(1.0, c.x);
    expect.Expect.equals(5.0, c.y);
    expect.Expect.equals(2.0, c.z);
    expect.Expect.equals(6.0, c.w);
  }
  dart.fn(testInterleaveXY);
  function testInterleaveZW() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.ZWZW).shuffle(typed_data.Float32x4.XZYW);
    expect.Expect.equals(3.0, c.x);
    expect.Expect.equals(7.0, c.y);
    expect.Expect.equals(4.0, c.z);
    expect.Expect.equals(8.0, c.w);
  }
  dart.fn(testInterleaveZW);
  function testInterleaveXYPairs() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.XYXY);
    expect.Expect.equals(1.0, c.x);
    expect.Expect.equals(2.0, c.y);
    expect.Expect.equals(5.0, c.z);
    expect.Expect.equals(6.0, c.w);
  }
  dart.fn(testInterleaveXYPairs);
  function testInterleaveZWPairs() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.ZWZW);
    expect.Expect.equals(3.0, c.x);
    expect.Expect.equals(4.0, c.y);
    expect.Expect.equals(7.0, c.z);
    expect.Expect.equals(8.0, c.w);
  }
  dart.fn(testInterleaveZWPairs);
  function main() {
    for (let i = 0; i < 20; i++) {
      testWithZWInXY();
      testInterleaveXY();
      testInterleaveZW();
      testInterleaveXYPairs();
      testInterleaveZWPairs();
    }
  }
  dart.fn(main);
  // Exports:
  exports.testWithZWInXY = testWithZWInXY;
  exports.testInterleaveXY = testInterleaveXY;
  exports.testInterleaveZW = testInterleaveZW;
  exports.testInterleaveXYPairs = testInterleaveXYPairs;
  exports.testInterleaveZWPairs = testInterleaveZWPairs;
  exports.main = main;
});
dart_library.library('lib/typed_data/float32x4_unbox_phi_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'dart/core',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, core, expect) {
  'use strict';
  let dartx = dart.dartx;
  function testUnboxPhi(data) {
    let res = typed_data.Float32x4.zero();
    for (let i = 0; i < dart.notNull(data.length); i++) {
      res = res['+'](data.get(i));
    }
    return dart.notNull(res.x) + dart.notNull(res.y) + dart.notNull(res.z) + dart.notNull(res.w);
  }
  dart.fn(testUnboxPhi, core.double, [typed_data.Float32x4List]);
  function main() {
    let list = typed_data.Float32x4List.new(10);
    let floatList = typed_data.Float32List.view(list.buffer);
    for (let i = 0; i < dart.notNull(floatList[dartx.length]); i++) {
      floatList[dartx.set](i, i[dartx.toDouble]());
    }
    for (let i = 0; i < 20; i++) {
      let r = testUnboxPhi(list);
      expect.Expect.equals(780.0, r);
    }
  }
  dart.fn(main);
  // Exports:
  exports.testUnboxPhi = testUnboxPhi;
  exports.main = main;
});
dart_library.library('lib/typed_data/float32x4_unbox_regress_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function testListStore(array, index, value) {
    dart.dsetindex(array, index, value);
  }
  dart.fn(testListStore);
  function testListStoreDeopt() {
    let list = null;
    let value = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let smi = 12;
    list = typed_data.Float32x4List.new(8);
    for (let i = 0; i < 20; i++) {
      testListStore(list, 0, value);
    }
    try {
      testListStore(list, 0, smi);
    } catch (_) {
    }

  }
  dart.fn(testListStoreDeopt, dart.void, []);
  function testAdd(a, b) {
    let c = dart.dsend(a, '+', b);
    expect.Expect.equals(3.0, dart.dload(c, 'x'));
    expect.Expect.equals(5.0, dart.dload(c, 'y'));
    expect.Expect.equals(7.0, dart.dload(c, 'z'));
    expect.Expect.equals(9.0, dart.dload(c, 'w'));
  }
  dart.fn(testAdd);
  function testAddDeopt() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(2.0, 3.0, 4.0, 5.0);
    let smi = 12;
    for (let i = 0; i < 20; i++) {
      testAdd(a, b);
    }
    try {
      testAdd(a, smi);
    } catch (_) {
    }

  }
  dart.fn(testAddDeopt, dart.void, []);
  function testGet(a) {
    let c = dart.dsend(dart.dsend(dart.dsend(dart.dload(a, 'x'), '+', dart.dload(a, 'y')), '+', dart.dload(a, 'z')), '+', dart.dload(a, 'w'));
    expect.Expect.equals(10.0, c);
  }
  dart.fn(testGet);
  function testGetDeopt() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let smi = 12;
    for (let i = 0; i < 20; i++) {
      testGet(a);
    }
    try {
      testGet(12);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testGet(a);
    }
  }
  dart.fn(testGetDeopt, dart.void, []);
  function testComparison(a, b) {
    let r = dart.as(dart.dsend(a, 'equal', b), typed_data.Int32x4);
    expect.Expect.equals(true, r.flagX);
    expect.Expect.equals(false, r.flagY);
    expect.Expect.equals(false, r.flagZ);
    expect.Expect.equals(true, r.flagW);
  }
  dart.fn(testComparison, dart.void, [dart.dynamic, dart.dynamic]);
  function testComparisonDeopt() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(1.0, 2.1, 3.1, 4.0);
    let smi = 12;
    for (let i = 0; i < 20; i++) {
      testComparison(a, b);
    }
    try {
      testComparison(a, smi);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testComparison(a, b);
    }
    try {
      testComparison(smi, a);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testComparison(a, b);
    }
  }
  dart.fn(testComparisonDeopt, dart.void, []);
  function main() {
    testListStoreDeopt();
    testAddDeopt();
    testGetDeopt();
    testComparisonDeopt();
  }
  dart.fn(main);
  // Exports:
  exports.testListStore = testListStore;
  exports.testListStoreDeopt = testListStoreDeopt;
  exports.testAdd = testAdd;
  exports.testAddDeopt = testAddDeopt;
  exports.testGet = testGet;
  exports.testGetDeopt = testGetDeopt;
  exports.testComparison = testComparison;
  exports.testComparisonDeopt = testComparisonDeopt;
  exports.main = main;
});
dart_library.library('lib/typed_data/float64x2_typed_list_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, typed_data, core) {
  'use strict';
  let dartx = dart.dartx;
  function test(l) {
    let a = l.get(0);
    let b = l.get(1);
    l.set(0, b);
    l.set(1, a);
  }
  dart.fn(test, dart.void, [typed_data.Float64x2List]);
  function compare(a, b) {
    return dart.equals(dart.dload(a, 'x'), dart.dload(b, 'x')) && dart.equals(dart.dload(a, 'y'), dart.dload(b, 'y'));
  }
  dart.fn(compare, core.bool, [dart.dynamic, dart.dynamic]);
  function main() {
    let l = typed_data.Float64x2List.new(2);
    let a = typed_data.Float64x2.new(1.0, 2.0);
    let b = typed_data.Float64x2.new(3.0, 4.0);
    l.set(0, a);
    l.set(1, b);
    for (let i = 0; i < 41; i++) {
      test(l);
    }
    if (!dart.notNull(compare(l.get(0), b)) || !dart.notNull(compare(l.get(1), a))) {
      dart.throw(123);
    }
  }
  dart.fn(main);
  // Exports:
  exports.test = test;
  exports.compare = compare;
  exports.main = main;
});
dart_library.library('lib/typed_data/int32x4_arithmetic_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function testAdd() {
    let m = typed_data.Int32x4.new(0, 0, 0, 0);
    let n = typed_data.Int32x4.new(-1, -1, -1, -1);
    let o = m['+'](n);
    expect.Expect.equals(-1, o.x);
    expect.Expect.equals(-1, o.y);
    expect.Expect.equals(-1, o.z);
    expect.Expect.equals(-1, o.w);
    m = typed_data.Int32x4.new(0, 0, 0, 0);
    n = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    o = m['+'](n);
    expect.Expect.equals(-1, o.x);
    expect.Expect.equals(-1, o.y);
    expect.Expect.equals(-1, o.z);
    expect.Expect.equals(-1, o.w);
    n = typed_data.Int32x4.new(1, 1, 1, 1);
    m = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    o = m['+'](n);
    expect.Expect.equals(0, o.x);
    expect.Expect.equals(0, o.y);
    expect.Expect.equals(0, o.z);
    expect.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    m = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    o = m['+'](n);
    expect.Expect.equals(-2, o.x);
    expect.Expect.equals(-2, o.y);
    expect.Expect.equals(-2, o.z);
    expect.Expect.equals(-2, o.w);
    n = typed_data.Int32x4.new(1, 0, 0, 0);
    m = typed_data.Int32x4.new(2, 0, 0, 0);
    o = n['+'](m);
    expect.Expect.equals(3, o.x);
    expect.Expect.equals(0, o.y);
    expect.Expect.equals(0, o.z);
    expect.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(1, 3, 0, 0);
    m = typed_data.Int32x4.new(2, 4, 0, 0);
    o = n['+'](m);
    expect.Expect.equals(3, o.x);
    expect.Expect.equals(7, o.y);
    expect.Expect.equals(0, o.z);
    expect.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(1, 3, 5, 0);
    m = typed_data.Int32x4.new(2, 4, 6, 0);
    o = n['+'](m);
    expect.Expect.equals(3, o.x);
    expect.Expect.equals(7, o.y);
    expect.Expect.equals(11, o.z);
    expect.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(1, 3, 5, 7);
    m = typed_data.Int32x4.new(-2, -4, -6, -8);
    o = n['+'](m);
    expect.Expect.equals(-1, o.x);
    expect.Expect.equals(-1, o.y);
    expect.Expect.equals(-1, o.z);
    expect.Expect.equals(-1, o.w);
  }
  dart.fn(testAdd);
  function testSub() {
    let m = typed_data.Int32x4.new(0, 0, 0, 0);
    let n = typed_data.Int32x4.new(1, 1, 1, 1);
    let o = m['-'](n);
    expect.Expect.equals(-1, o.x);
    expect.Expect.equals(-1, o.y);
    expect.Expect.equals(-1, o.z);
    expect.Expect.equals(-1, o.w);
    o = n['-'](m);
    expect.Expect.equals(1, o.x);
    expect.Expect.equals(1, o.y);
    expect.Expect.equals(1, o.z);
    expect.Expect.equals(1, o.w);
  }
  dart.fn(testSub);
  function main() {
    for (let i = 0; i < 20; i++) {
      testAdd();
      testSub();
    }
  }
  dart.fn(main);
  // Exports:
  exports.testAdd = testAdd;
  exports.testSub = testSub;
  exports.main = main;
});
dart_library.library('lib/typed_data/int32x4_bigint_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function main() {
    let n = 18446744073709551617;
    let x = typed_data.Int32x4.new(n, 0, 0, 0);
    expect.Expect.equals(x.x, 1);
  }
  dart.fn(main);
  // Exports:
  exports.main = main;
});
dart_library.library('lib/typed_data/int32x4_list_test', null, /* Imports */[
  'dart/_runtime',
  'expect/expect',
  'dart/core',
  'dart/typed_data'
], /* Lazy imports */[
], function(exports, dart, expect, core, typed_data) {
  'use strict';
  let dartx = dart.dartx;
  function testLoadStore(array) {
    expect.Expect.equals(8, dart.dload(array, 'length'));
    expect.Expect.isTrue(dart.is(array, core.List$(typed_data.Int32x4)));
    dart.dsetindex(array, 0, typed_data.Int32x4.new(1, 2, 3, 4));
    expect.Expect.equals(1, dart.dload(dart.dindex(array, 0), 'x'));
    expect.Expect.equals(2, dart.dload(dart.dindex(array, 0), 'y'));
    expect.Expect.equals(3, dart.dload(dart.dindex(array, 0), 'z'));
    expect.Expect.equals(4, dart.dload(dart.dindex(array, 0), 'w'));
    dart.dsetindex(array, 1, dart.dindex(array, 0));
    dart.dsetindex(array, 0, dart.dsend(dart.dindex(array, 0), 'withX', 9));
    expect.Expect.equals(9, dart.dload(dart.dindex(array, 0), 'x'));
    expect.Expect.equals(2, dart.dload(dart.dindex(array, 0), 'y'));
    expect.Expect.equals(3, dart.dload(dart.dindex(array, 0), 'z'));
    expect.Expect.equals(4, dart.dload(dart.dindex(array, 0), 'w'));
    expect.Expect.equals(1, dart.dload(dart.dindex(array, 1), 'x'));
    expect.Expect.equals(2, dart.dload(dart.dindex(array, 1), 'y'));
    expect.Expect.equals(3, dart.dload(dart.dindex(array, 1), 'z'));
    expect.Expect.equals(4, dart.dload(dart.dindex(array, 1), 'w'));
  }
  dart.fn(testLoadStore);
  function testLoadStoreDeopt(array, index, value) {
    dart.dsetindex(array, index, value);
    expect.Expect.equals(dart.dload(value, 'x'), dart.dload(dart.dindex(array, index), 'x'));
    expect.Expect.equals(dart.dload(value, 'y'), dart.dload(dart.dindex(array, index), 'y'));
    expect.Expect.equals(dart.dload(value, 'z'), dart.dload(dart.dindex(array, index), 'z'));
    expect.Expect.equals(dart.dload(value, 'w'), dart.dload(dart.dindex(array, index), 'w'));
  }
  dart.fn(testLoadStoreDeopt);
  function testLoadStoreDeoptDriver() {
    let list = typed_data.Int32x4List.new(4);
    let value = typed_data.Int32x4.new(1, 2, 3, 4);
    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(list, 5, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(null, 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(list, 0, null);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(list, 3.14159, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt(list, 0, (4)[dartx.toDouble]());
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
    try {
      testLoadStoreDeopt([typed_data.Int32x4.new(2, 3, 4, 5)], 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      testLoadStoreDeopt(list, 0, value);
    }
  }
  dart.fn(testLoadStoreDeoptDriver);
  function testListZero() {
    let list = typed_data.Int32x4List.new(1);
    expect.Expect.equals(0, list.get(0).x);
    expect.Expect.equals(0, list.get(0).y);
    expect.Expect.equals(0, list.get(0).z);
    expect.Expect.equals(0, list.get(0).w);
  }
  dart.fn(testListZero);
  function testView(array) {
    expect.Expect.equals(8, dart.dload(array, 'length'));
    expect.Expect.isTrue(dart.is(array, core.List$(typed_data.Int32x4)));
    expect.Expect.equals(0, dart.dload(dart.dindex(array, 0), 'x'));
    expect.Expect.equals(1, dart.dload(dart.dindex(array, 0), 'y'));
    expect.Expect.equals(2, dart.dload(dart.dindex(array, 0), 'z'));
    expect.Expect.equals(3, dart.dload(dart.dindex(array, 0), 'w'));
    expect.Expect.equals(4, dart.dload(dart.dindex(array, 1), 'x'));
    expect.Expect.equals(5, dart.dload(dart.dindex(array, 1), 'y'));
    expect.Expect.equals(6, dart.dload(dart.dindex(array, 1), 'z'));
    expect.Expect.equals(7, dart.dload(dart.dindex(array, 1), 'w'));
  }
  dart.fn(testView);
  function testSublist(array) {
    expect.Expect.equals(8, dart.dload(array, 'length'));
    expect.Expect.isTrue(dart.is(array, typed_data.Int32x4List));
    let a = dart.dsend(array, 'sublist', 0, 1);
    expect.Expect.equals(1, dart.dload(a, 'length'));
    expect.Expect.equals(0, dart.dload(dart.dindex(a, 0), 'x'));
    expect.Expect.equals(1, dart.dload(dart.dindex(a, 0), 'y'));
    expect.Expect.equals(2, dart.dload(dart.dindex(a, 0), 'z'));
    expect.Expect.equals(3, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 1, 2);
    expect.Expect.equals(4, dart.dload(dart.dindex(a, 0), 'x'));
    expect.Expect.equals(5, dart.dload(dart.dindex(a, 0), 'y'));
    expect.Expect.equals(6, dart.dload(dart.dindex(a, 0), 'z'));
    expect.Expect.equals(7, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 0);
    expect.Expect.equals(dart.dload(a, 'length'), dart.dload(array, 'length'));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(array, 'length'), core.num)); i++) {
      expect.Expect.equals(dart.dload(dart.dindex(array, i), 'x'), dart.dload(dart.dindex(a, i), 'x'));
      expect.Expect.equals(dart.dload(dart.dindex(array, i), 'y'), dart.dload(dart.dindex(a, i), 'y'));
      expect.Expect.equals(dart.dload(dart.dindex(array, i), 'z'), dart.dload(dart.dindex(a, i), 'z'));
      expect.Expect.equals(dart.dload(dart.dindex(array, i), 'w'), dart.dload(dart.dindex(a, i), 'w'));
    }
  }
  dart.fn(testSublist);
  function testSpecialValues(array) {
    let tests = [[2410207675578512, 878082192], [2410209554626704, -1537836912], [2147483648, -2147483648], [-2147483648, -2147483648], [2147483647, 2147483647], [-2147483647, -2147483647]];
    let int32x4 = null;
    for (let test of tests) {
      let input = dart.dindex(test, 0);
      let expected = dart.dindex(test, 1);
      int32x4 = typed_data.Int32x4.new(dart.as(input, core.int), 2, 3, 4);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect.Expect.equals(expected, dart.dload(int32x4, 'x'));
      expect.Expect.equals(2, dart.dload(int32x4, 'y'));
      expect.Expect.equals(3, dart.dload(int32x4, 'z'));
      expect.Expect.equals(4, dart.dload(int32x4, 'w'));
      int32x4 = typed_data.Int32x4.new(1, dart.as(input, core.int), 3, 4);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect.Expect.equals(1, dart.dload(int32x4, 'x'));
      expect.Expect.equals(expected, dart.dload(int32x4, 'y'));
      expect.Expect.equals(3, dart.dload(int32x4, 'z'));
      expect.Expect.equals(4, dart.dload(int32x4, 'w'));
      int32x4 = typed_data.Int32x4.new(1, 2, dart.as(input, core.int), 4);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect.Expect.equals(1, dart.dload(int32x4, 'x'));
      expect.Expect.equals(2, dart.dload(int32x4, 'y'));
      expect.Expect.equals(expected, dart.dload(int32x4, 'z'));
      expect.Expect.equals(4, dart.dload(int32x4, 'w'));
      int32x4 = typed_data.Int32x4.new(1, 2, 3, dart.as(input, core.int));
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect.Expect.equals(1, dart.dload(int32x4, 'x'));
      expect.Expect.equals(2, dart.dload(int32x4, 'y'));
      expect.Expect.equals(3, dart.dload(int32x4, 'z'));
      expect.Expect.equals(expected, dart.dload(int32x4, 'w'));
    }
  }
  dart.fn(testSpecialValues, dart.void, [dart.dynamic]);
  function main() {
    let list = null;
    list = typed_data.Int32x4List.new(8);
    for (let i = 0; i < 20; i++) {
      testLoadStore(list);
    }
    for (let i = 0; i < 20; i++) {
      testSpecialValues(list);
    }
    let uint32List = typed_data.Uint32List.new(32);
    for (let i = 0; i < dart.notNull(uint32List[dartx.length]); i++) {
      uint32List[dartx.set](i, i);
    }
    list = typed_data.Int32x4List.view(uint32List[dartx.buffer]);
    for (let i = 0; i < 20; i++) {
      testView(list);
    }
    for (let i = 0; i < 20; i++) {
      testSublist(list);
    }
    for (let i = 0; i < 20; i++) {
      testLoadStore(list);
    }
    for (let i = 0; i < 20; i++) {
      testListZero();
    }
    for (let i = 0; i < 20; i++) {
      testSpecialValues(list);
    }
    testLoadStoreDeoptDriver();
  }
  dart.fn(main);
  // Exports:
  exports.testLoadStore = testLoadStore;
  exports.testLoadStoreDeopt = testLoadStoreDeopt;
  exports.testLoadStoreDeoptDriver = testLoadStoreDeoptDriver;
  exports.testListZero = testListZero;
  exports.testView = testView;
  exports.testSublist = testSublist;
  exports.testSpecialValues = testSpecialValues;
  exports.main = main;
});
dart_library.library('lib/typed_data/int32x4_shuffle_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect, core) {
  'use strict';
  let dartx = dart.dartx;
  function testShuffle() {
    let m = typed_data.Int32x4.new(1, 2, 3, 4);
    let c = null;
    c = m.shuffle(typed_data.Int32x4.WZYX);
    expect.Expect.equals(4, dart.dload(c, 'x'));
    expect.Expect.equals(3, dart.dload(c, 'y'));
    expect.Expect.equals(2, dart.dload(c, 'z'));
    expect.Expect.equals(1, dart.dload(c, 'w'));
  }
  dart.fn(testShuffle, dart.void, []);
  function testShuffleNonConstant(mask) {
    let m = typed_data.Int32x4.new(1, 2, 3, 4);
    let c = null;
    c = m.shuffle(dart.as(mask, core.int));
    if (dart.equals(mask, 1)) {
      expect.Expect.equals(2, dart.dload(c, 'x'));
      expect.Expect.equals(1, dart.dload(c, 'y'));
      expect.Expect.equals(1, dart.dload(c, 'z'));
      expect.Expect.equals(1, dart.dload(c, 'w'));
    } else {
      expect.Expect.equals(dart.notNull(typed_data.Int32x4.YYYY) + 1, mask);
      expect.Expect.equals(3, dart.dload(c, 'x'));
      expect.Expect.equals(2, dart.dload(c, 'y'));
      expect.Expect.equals(2, dart.dload(c, 'z'));
      expect.Expect.equals(2, dart.dload(c, 'w'));
    }
  }
  dart.fn(testShuffleNonConstant, dart.void, [dart.dynamic]);
  function testShuffleMix() {
    let m = typed_data.Int32x4.new(1, 2, 3, 4);
    let n = typed_data.Int32x4.new(5, 6, 7, 8);
    let c = m.shuffleMix(n, typed_data.Int32x4.XYXY);
    expect.Expect.equals(1, c.x);
    expect.Expect.equals(2, c.y);
    expect.Expect.equals(5, c.z);
    expect.Expect.equals(6, c.w);
  }
  dart.fn(testShuffleMix, dart.void, []);
  function main() {
    let xxxx = dart.notNull(typed_data.Int32x4.XXXX) + 1;
    let yyyy = dart.notNull(typed_data.Int32x4.YYYY) + 1;
    for (let i = 0; i < 20; i++) {
      testShuffle();
      testShuffleNonConstant(xxxx);
      testShuffleNonConstant(yyyy);
      testShuffleMix();
    }
  }
  dart.fn(main);
  // Exports:
  exports.testShuffle = testShuffle;
  exports.testShuffleNonConstant = testShuffleNonConstant;
  exports.testShuffleMix = testShuffleMix;
  exports.main = main;
});
dart_library.library('lib/typed_data/int32x4_sign_mask_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function testImmediates() {
    let f = typed_data.Int32x4.new(1, 2, 3, 4);
    let m = f.signMask;
    expect.Expect.equals(0, m);
    f = typed_data.Int32x4.new(-1, -2, -3, -4);
    m = f.signMask;
    expect.Expect.equals(15, m);
    f = typed_data.Int32x4.bool(true, false, false, false);
    m = f.signMask;
    expect.Expect.equals(1, m);
    f = typed_data.Int32x4.bool(false, true, false, false);
    m = f.signMask;
    expect.Expect.equals(2, m);
    f = typed_data.Int32x4.bool(false, false, true, false);
    m = f.signMask;
    expect.Expect.equals(4, m);
    f = typed_data.Int32x4.bool(false, false, false, true);
    m = f.signMask;
    expect.Expect.equals(8, m);
  }
  dart.fn(testImmediates, dart.void, []);
  function testZero() {
    let f = typed_data.Int32x4.new(0, 0, 0, 0);
    let m = f.signMask;
    expect.Expect.equals(0, m);
    f = typed_data.Int32x4.new(-0, -0, -0, -0);
    m = f.signMask;
    expect.Expect.equals(0, m);
  }
  dart.fn(testZero, dart.void, []);
  function testLogic() {
    let a = typed_data.Int32x4.new(2147483648, 2147483648, 2147483648, 2147483648);
    let b = typed_data.Int32x4.new(1879048192, 1879048192, 1879048192, 1879048192);
    let c = typed_data.Int32x4.new(4026531840, 4026531840, 4026531840, 4026531840);
    let m1 = a['&'](c).signMask;
    expect.Expect.equals(15, m1);
    let m2 = a['&'](b).signMask;
    expect.Expect.equals(0, m2);
    let m3 = b['^'](a).signMask;
    expect.Expect.equals(15, m3);
    let m4 = b['|'](c).signMask;
    expect.Expect.equals(15, m4);
  }
  dart.fn(testLogic, dart.void, []);
  function main() {
    for (let i = 0; i < 2000; i++) {
      testImmediates();
      testZero();
      testLogic();
    }
  }
  dart.fn(main);
  // Exports:
  exports.testImmediates = testImmediates;
  exports.testZero = testZero;
  exports.testLogic = testLogic;
  exports.main = main;
});
dart_library.library('lib/typed_data/int64_list_load_store_test', null, /* Imports */[
  'dart/_runtime',
  'expect/expect',
  'dart/typed_data'
], /* Lazy imports */[
], function(exports, dart, expect, typed_data) {
  'use strict';
  let dartx = dart.dartx;
  function testStoreLoad(l, z) {
    dart.dsetindex(l, 0, 9223372036854775807);
    dart.dsetindex(l, 1, 9223372036854775806);
    dart.dsetindex(l, 2, dart.dindex(l, 0));
    dart.dsetindex(l, 3, z);
    expect.Expect.equals(dart.dindex(l, 0), 9223372036854775807);
    expect.Expect.equals(dart.dindex(l, 1), 9223372036854775806);
    expect.Expect.isTrue(dart.dsend(dart.dindex(l, 1), '<', dart.dindex(l, 0)));
    expect.Expect.equals(dart.dindex(l, 2), dart.dindex(l, 0));
    expect.Expect.equals(dart.dindex(l, 3), z);
  }
  dart.fn(testStoreLoad, dart.void, [dart.dynamic, dart.dynamic]);
  function main() {
    let l = typed_data.Int64List.new(4);
    let zGood = 9223372036854775807;
    let zBad = false;
    for (let i = 0; i < 40; i++) {
      testStoreLoad(l, zGood);
    }
    try {
      testStoreLoad(l, zBad);
    } catch (_) {
    }

    for (let i = 0; i < 40; i++) {
      testStoreLoad(l, zGood);
    }
  }
  dart.fn(main);
  // Exports:
  exports.testStoreLoad = testStoreLoad;
  exports.main = main;
});
dart_library.library('lib/typed_data/native_interceptor_no_own_method_to_intercept_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data'
], /* Lazy imports */[
], function(exports, dart, typed_data) {
  'use strict';
  let dartx = dart.dartx;
  function use(s) {
    return s;
  }
  dart.fn(use);
  function main() {
    use(dart.toString(typed_data.ByteData.new(1)));
  }
  dart.fn(main);
  // Exports:
  exports.use = use;
  exports.main = main;
});
dart_library.library('lib/typed_data/setRange_1_test', null, /* Imports */[
  'dart/_runtime',
  'lib/typed_data/setRange_lib'
], /* Lazy imports */[
], function(exports, dart, setRange_lib) {
  'use strict';
  let dartx = dart.dartx;
  function sameTypeTest() {
    setRange_lib.checkSameSize(setRange_lib.makeInt16List, setRange_lib.makeInt16View, setRange_lib.makeInt16View);
    setRange_lib.checkSameSize(setRange_lib.makeUint16List, setRange_lib.makeUint16View, setRange_lib.makeUint16View);
  }
  dart.fn(sameTypeTest);
  function main() {
    sameTypeTest();
  }
  dart.fn(main);
  // Exports:
  exports.sameTypeTest = sameTypeTest;
  exports.main = main;
});
dart_library.library('lib/typed_data/setRange_2_test', null, /* Imports */[
  'dart/_runtime',
  'lib/typed_data/setRange_lib'
], /* Lazy imports */[
], function(exports, dart, setRange_lib) {
  'use strict';
  let dartx = dart.dartx;
  function sameElementSizeTest() {
    setRange_lib.checkSameSize(setRange_lib.makeInt16List, setRange_lib.makeInt16View, setRange_lib.makeUint16View);
    setRange_lib.checkSameSize(setRange_lib.makeInt16List, setRange_lib.makeUint16View, setRange_lib.makeInt16View);
  }
  dart.fn(sameElementSizeTest);
  function main() {
    sameElementSizeTest();
  }
  dart.fn(main);
  // Exports:
  exports.sameElementSizeTest = sameElementSizeTest;
  exports.main = main;
});
dart_library.library('lib/typed_data/setRange_3_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'lib/typed_data/setRange_lib',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, setRange_lib, expect) {
  'use strict';
  let dartx = dart.dartx;
  function expandContractTest() {
    let a1 = typed_data.Int32List.new(8);
    let buffer = a1[dartx.buffer];
    let a2 = typed_data.Int8List.view(buffer, 12, 8);
    setRange_lib.initialize(a2);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a2}`);
    a1[dartx.setRange](0, 8, a2);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a1}`);
    setRange_lib.initialize(a1);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a1}`);
    a2[dartx.setRange](0, 8, a1);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a2}`);
  }
  dart.fn(expandContractTest);
  function main() {
    expandContractTest();
  }
  dart.fn(main);
  // Exports:
  exports.expandContractTest = expandContractTest;
  exports.main = main;
});
dart_library.library('lib/typed_data/setRange_4_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'lib/typed_data/setRange_lib',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, setRange_lib, expect) {
  'use strict';
  let dartx = dart.dartx;
  function clampingTest() {
    let a1 = typed_data.Int8List.new(8);
    let a2 = typed_data.Uint8ClampedList.view(a1[dartx.buffer]);
    setRange_lib.initialize(a1);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a1}`);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', `${a2}`);
    a1[dartx.set](0, -1);
    a2[dartx.setRange](0, 2, a1);
    expect.Expect.equals('[0, 2, 3, 4, 5, 6, 7, 8]', `${a2}`);
  }
  dart.fn(clampingTest);
  function main() {
    clampingTest();
  }
  dart.fn(main);
  // Exports:
  exports.clampingTest = clampingTest;
  exports.main = main;
});
dart_library.library('lib/typed_data/setRange_5_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'lib/typed_data/setRange_lib',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, setRange_lib, expect) {
  'use strict';
  let dartx = dart.dartx;
  function overlapTest() {
    let buffer = typed_data.Float32List.new(3)[dartx.buffer];
    let a0 = typed_data.Int8List.view(buffer);
    let a1 = typed_data.Int8List.view(buffer, 1, 5);
    let a2 = typed_data.Int8List.view(buffer, 2, 5);
    setRange_lib.initialize(a0);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]', `${a0}`);
    expect.Expect.equals('[2, 3, 4, 5, 6]', `${a1}`);
    expect.Expect.equals('[3, 4, 5, 6, 7]', `${a2}`);
    a1[dartx.setRange](0, 5, a2);
    expect.Expect.equals('[1, 3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12]', `${a0}`);
    setRange_lib.initialize(a0);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]', `${a0}`);
    expect.Expect.equals('[2, 3, 4, 5, 6]', `${a1}`);
    expect.Expect.equals('[3, 4, 5, 6, 7]', `${a2}`);
    a2[dartx.setRange](0, 5, a1);
    expect.Expect.equals('[1, 2, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12]', `${a0}`);
  }
  dart.fn(overlapTest);
  function main() {
    overlapTest();
  }
  dart.fn(main);
  // Exports:
  exports.overlapTest = overlapTest;
  exports.main = main;
});
dart_library.library('lib/typed_data/setRange_lib', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, core, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function initialize(a) {
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(a, 'length'), core.num)); i++) {
      dart.dsetindex(a, i, i + 1);
    }
  }
  dart.fn(initialize);
  function makeInt16View(buffer, byteOffset, length) {
    return typed_data.Int16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  }
  dart.fn(makeInt16View);
  function makeUint16View(buffer, byteOffset, length) {
    return typed_data.Uint16List.view(dart.as(buffer, typed_data.ByteBuffer), dart.as(byteOffset, core.int), dart.as(length, core.int));
  }
  dart.fn(makeUint16View);
  function makeInt16List(length) {
    return typed_data.Int16List.new(dart.as(length, core.int));
  }
  dart.fn(makeInt16List);
  function makeUint16List(length) {
    return typed_data.Uint16List.new(dart.as(length, core.int));
  }
  dart.fn(makeUint16List);
  function checkSameSize(constructor0, constructor1, constructor2) {
    let a0 = dart.dcall(constructor0, 9);
    let buffer = dart.dload(a0, 'buffer');
    let a1 = dart.dcall(constructor1, buffer, 0, 7);
    let a2 = dart.dcall(constructor2, buffer, 2 * dart.notNull(dart.as(dart.dload(a0, 'elementSizeInBytes'), core.num)), 7);
    initialize(a0);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9]', `${a0}`);
    expect.Expect.equals('[1, 2, 3, 4, 5, 6, 7]', `${a1}`);
    expect.Expect.equals('[3, 4, 5, 6, 7, 8, 9]', `${a2}`);
    initialize(a0);
    dart.dsend(a1, 'setRange', 0, 7, a2);
    expect.Expect.equals('[3, 4, 5, 6, 7, 8, 9, 8, 9]', `${a0}`);
    initialize(a0);
    dart.dsend(a2, 'setRange', 0, 7, a1);
    expect.Expect.equals('[1, 2, 1, 2, 3, 4, 5, 6, 7]', `${a0}`);
    initialize(a0);
    dart.dsend(a1, 'setRange', 1, 7, a2);
    expect.Expect.equals('[1, 3, 4, 5, 6, 7, 8, 8, 9]', `${a0}`);
    initialize(a0);
    dart.dsend(a2, 'setRange', 1, 7, a1);
    expect.Expect.equals('[1, 2, 3, 1, 2, 3, 4, 5, 6]', `${a0}`);
    initialize(a0);
    dart.dsend(a1, 'setRange', 0, 6, a2, 1);
    expect.Expect.equals('[4, 5, 6, 7, 8, 9, 7, 8, 9]', `${a0}`);
    initialize(a0);
    dart.dsend(a2, 'setRange', 0, 6, a1, 1);
    expect.Expect.equals('[1, 2, 2, 3, 4, 5, 6, 7, 9]', `${a0}`);
  }
  dart.fn(checkSameSize);
  // Exports:
  exports.initialize = initialize;
  exports.makeInt16View = makeInt16View;
  exports.makeUint16View = makeUint16View;
  exports.makeInt16List = makeInt16List;
  exports.makeUint16List = makeUint16List;
  exports.checkSameSize = checkSameSize;
});
dart_library.library('lib/typed_data/simd_store_to_load_forward_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function testLoadStoreForwardingFloat32x4(l, v) {
    l.set(1, v);
    let r = l.get(1);
    return r;
  }
  dart.fn(testLoadStoreForwardingFloat32x4, typed_data.Float32x4, [typed_data.Float32x4List, typed_data.Float32x4]);
  function main() {
    let l = typed_data.Float32x4List.new(4);
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = null;
    for (let i = 0; i < 20; i++) {
      b = testLoadStoreForwardingFloat32x4(l, a);
    }
    expect.Expect.equals(a.x, b.x);
    expect.Expect.equals(a.y, b.y);
    expect.Expect.equals(a.z, b.z);
    expect.Expect.equals(a.w, b.w);
  }
  dart.fn(main);
  // Exports:
  exports.testLoadStoreForwardingFloat32x4 = testLoadStoreForwardingFloat32x4;
  exports.main = main;
});
dart_library.library('lib/typed_data/typed_data_from_list_test', null, /* Imports */[
  'dart/_runtime',
  'dart/collection',
  'dart/typed_data',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, collection, typed_data, core) {
  'use strict';
  let dartx = dart.dartx;
  function main() {
    let list = new collection.UnmodifiableListView([1, 2]);
    let typed = typed_data.Uint8List.fromList(dart.as(list, core.List$(core.int)));
    if (typed[dartx.get](0) != 1 || typed[dartx.get](1) != 2 || typed[dartx.length] != 2) {
      dart.throw('Test failed');
    }
  }
  dart.fn(main);
  // Exports:
  exports.main = main;
});
dart_library.library('lib/typed_data/typed_data_hierarchy_int64_test', null, /* Imports */[
  'dart/_runtime',
  'expect/expect',
  'dart/typed_data',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, expect, typed_data, core) {
  'use strict';
  let dartx = dart.dartx;
  exports.inscrutable = null;
  function implementsTypedData() {
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Int64List.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint64List.new(1)), typed_data.TypedData));
  }
  dart.fn(implementsTypedData, dart.void, []);
  function implementsList() {
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Int64List.new(1)), core.List$(core.int)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint64List.new(1)), core.List$(core.int)));
  }
  dart.fn(implementsList, dart.void, []);
  function main() {
    exports.inscrutable = dart.fn(x => x);
    implementsTypedData();
    implementsList();
  }
  dart.fn(main);
  // Exports:
  exports.implementsTypedData = implementsTypedData;
  exports.implementsList = implementsList;
  exports.main = main;
});
dart_library.library('lib/typed_data/typed_data_hierarchy_test', null, /* Imports */[
  'dart/_runtime',
  'expect/expect',
  'dart/typed_data',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, expect, typed_data, core) {
  'use strict';
  let dartx = dart.dartx;
  exports.inscrutable = null;
  function testClampedList() {
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint8List.new(1)), typed_data.Uint8List));
    expect.Expect.isFalse(dart.is(typed_data.Uint8ClampedList.new(1), typed_data.Uint8List), 'Uint8ClampedList should not be a subtype of Uint8List ' + 'in optimizable test');
    expect.Expect.isFalse(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint8ClampedList.new(1)), typed_data.Uint8List), 'Uint8ClampedList should not be a subtype of Uint8List in dynamic test');
  }
  dart.fn(testClampedList, dart.void, []);
  function implementsTypedData() {
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.ByteData.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Float32List.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Float32x4List.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Float64List.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Int8List.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Int16List.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Int32List.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint8List.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint8ClampedList.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint16List.new(1)), typed_data.TypedData));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint32List.new(1)), typed_data.TypedData));
  }
  dart.fn(implementsTypedData, dart.void, []);
  function implementsList() {
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Float32List.new(1)), core.List$(core.double)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Float32x4List.new(1)), core.List$(typed_data.Float32x4)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Float64List.new(1)), core.List$(core.double)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Int8List.new(1)), core.List$(core.int)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Int16List.new(1)), core.List$(core.int)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Int32List.new(1)), core.List$(core.int)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint8List.new(1)), core.List$(core.int)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint8ClampedList.new(1)), core.List$(core.int)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint16List.new(1)), core.List$(core.int)));
    expect.Expect.isTrue(dart.is(dart.dcall(exports.inscrutable, typed_data.Uint32List.new(1)), core.List$(core.int)));
  }
  dart.fn(implementsList, dart.void, []);
  function main() {
    exports.inscrutable = dart.fn(x => x);
    testClampedList();
    implementsTypedData();
    implementsList();
  }
  dart.fn(main);
  // Exports:
  exports.testClampedList = testClampedList;
  exports.implementsTypedData = implementsTypedData;
  exports.implementsList = implementsList;
  exports.main = main;
});
dart_library.library('lib/typed_data/typed_data_list_test', null, /* Imports */[
  'dart/_runtime',
  'expect/expect',
  'dart/core',
  'dart/typed_data'
], /* Lazy imports */[
], function(exports, dart, expect, core, typed_data) {
  'use strict';
  let dartx = dart.dartx;
  function confuse(x) {
    return x;
  }
  dart.fn(confuse);
  function testListFunctions(list, first, last, toElementType) {
    dart.assert(dart.dsend(dart.dload(list, 'length'), '>', 0));
    let reversed = dart.dload(list, 'reversed');
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dload(dart.dsend(reversed, 'toList'), 'reversed'), 'toList'), core.List));
    let index = dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.int);
    for (let x of dart.as(reversed, core.Iterable)) {
      expect.Expect.equals(dart.dindex(list, index), x);
      index = dart.notNull(index) - 1;
    }
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'add', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'addAll', [1, 2]), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'clear'), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'insert', 0, 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'insertAll', 0, [1, 2]), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'remove', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'removeAt', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'removeLast'), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'removeRange', 0, 1), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'removeWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'replaceRange', 0, 1, []), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'retainWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    let map = dart.dsend(list, 'asMap');
    expect.Expect.equals(dart.dload(list, 'length'), dart.dload(map, 'length'));
    expect.Expect.isTrue(dart.is(map, core.Map));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dload(map, 'values'), 'toList'), core.List));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(list, 'length'), core.num)); i++) {
      expect.Expect.equals(dart.dindex(list, i), dart.dindex(map, i));
    }
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'getRange', 0, dart.dload(list, 'length')), 'toList'), core.List));
    let subRange = dart.dsend(dart.dsend(list, 'getRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), 'toList');
    expect.Expect.equals(dart.dsend(dart.dload(list, 'length'), '-', 2), dart.dload(subRange, 'length'));
    index = 1;
    for (let x of dart.as(subRange, core.Iterable)) {
      expect.Expect.equals(dart.dindex(list, index), x);
      index = dart.notNull(index) + 1;
    }
    expect.Expect.equals(0, dart.dsend(list, 'lastIndexOf', first));
    expect.Expect.equals(dart.dsend(dart.dload(list, 'length'), '-', 1), dart.dsend(list, 'lastIndexOf', last));
    expect.Expect.equals(-1, dart.dsend(list, 'lastIndexOf', -1));
    let copy = dart.dsend(list, 'toList');
    dart.dsend(list, 'fillRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), dart.dcall(toElementType, 0));
    expect.Expect.equals(dart.dload(copy, 'first'), dart.dload(list, 'first'));
    expect.Expect.equals(dart.dload(copy, 'last'), dart.dload(list, 'last'));
    for (let i = 1; i < dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.num)); i++) {
      expect.Expect.equals(0, dart.dindex(list, i));
    }
    dart.dsend(list, 'setAll', 1, dart.dsend(dart.dsend(list, 'getRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), 'map', dart.fn(x => dart.dcall(toElementType, 2))));
    expect.Expect.equals(dart.dload(copy, 'first'), dart.dload(list, 'first'));
    expect.Expect.equals(dart.dload(copy, 'last'), dart.dload(list, 'last'));
    for (let i = 1; i < dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.num)); i++) {
      expect.Expect.equals(2, dart.dindex(list, i));
    }
    dart.dsend(list, 'setRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), core.Iterable.generate(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 2), core.int), dart.fn(x => dart.dcall(toElementType, dart.notNull(x) + 5), dart.dynamic, [core.int])));
    expect.Expect.equals(first, dart.dload(list, 'first'));
    expect.Expect.equals(last, dart.dload(list, 'last'));
    for (let i = 1; i < dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.num)); i++) {
      expect.Expect.equals(4 + i, dart.dindex(list, i));
    }
    dart.dsend(list, 'setRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), core.Iterable.generate(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.int), dart.fn(x => dart.dcall(toElementType, dart.notNull(x) + 5), dart.dynamic, [core.int])), 1);
    expect.Expect.equals(first, dart.dload(list, 'first'));
    expect.Expect.equals(last, dart.dload(list, 'last'));
    for (let i = 1; i < dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '-', 1), core.num)); i++) {
      expect.Expect.equals(5 + i, dart.dindex(list, i));
    }
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'setRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), []), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(list, 'length'), core.num)); i++) {
      dart.dsetindex(list, dart.dsend(dart.dsend(dart.dload(list, 'length'), '-', 1), '-', i), dart.dcall(toElementType, i));
    }
    dart.dsend(list, 'sort');
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(list, 'length'), core.num)); i++) {
      expect.Expect.equals(i, dart.dindex(list, i));
    }
    expect.Expect.listEquals(dart.as(dart.dsend(dart.dsend(list, 'getRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), 'toList'), core.List), dart.as(dart.dsend(list, 'sublist', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), core.List));
    expect.Expect.listEquals(dart.as(dart.dsend(dart.dsend(list, 'getRange', 1, dart.dload(list, 'length')), 'toList'), core.List), dart.as(dart.dsend(list, 'sublist', 1), core.List));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(list, 'sublist', 0), core.List));
    expect.Expect.listEquals([], dart.as(dart.dsend(list, 'sublist', 0, 0), core.List));
    expect.Expect.listEquals([], dart.as(dart.dsend(list, 'sublist', dart.dload(list, 'length')), core.List));
    expect.Expect.listEquals([], dart.as(dart.dsend(list, 'sublist', dart.dload(list, 'length'), dart.dload(list, 'length')), core.List));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'sublist', dart.dsend(dart.dload(list, 'length'), '+', 1)), dart.void, []), dart.fn(e => dart.is(e, core.RangeError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'sublist', 0, dart.dsend(dart.dload(list, 'length'), '+', 1)), dart.void, []), dart.fn(e => dart.is(e, core.RangeError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'sublist', 1, 0), dart.void, []), dart.fn(e => dart.is(e, core.RangeError), core.bool, [dart.dynamic]));
  }
  dart.fn(testListFunctions, dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]);
  function emptyChecks(list) {
    dart.assert(dart.equals(dart.dload(list, 'length'), 0));
    expect.Expect.isTrue(dart.dload(list, 'isEmpty'));
    let reversed = dart.dload(list, 'reversed');
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dload(dart.dsend(reversed, 'toList'), 'reversed'), 'toList'), core.List));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'add', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'addAll', [1, 2]), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'clear'), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'insert', 0, 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'insertAll', 0, [1, 2]), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'remove', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'removeAt', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'removeLast'), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'removeRange', 0, 1), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'removeWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'replaceRange', 0, 1, []), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'retainWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
    let map = dart.dsend(list, 'asMap');
    expect.Expect.equals(dart.dload(list, 'length'), dart.dload(map, 'length'));
    expect.Expect.isTrue(dart.is(map, core.Map));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dload(map, 'values'), 'toList'), core.List));
    for (let i = 0; i < dart.notNull(dart.as(dart.dload(list, 'length'), core.num)); i++) {
      expect.Expect.equals(dart.dindex(list, i), dart.dindex(map, i));
    }
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'getRange', 0, dart.dload(list, 'length')), 'toList'), core.List));
    expect.Expect.equals(-1, dart.dsend(list, 'lastIndexOf', -1));
    let copy = dart.dsend(list, 'toList');
    dart.dsend(list, 'fillRange', 0, 0);
    expect.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'getRange', 0, 0), 'toList'), core.List));
    dart.dsend(list, 'setRange', 0, 0, [1, 2]);
    dart.dsend(list, 'sort');
    expect.Expect.listEquals([], dart.as(dart.dsend(list, 'sublist', 0, 0), core.List));
  }
  dart.fn(emptyChecks, dart.void, [dart.dynamic]);
  function main() {
    function toDouble(x) {
      return dart.dsend(x, 'toDouble');
    }
    dart.fn(toDouble);
    function toInt(x) {
      return dart.dsend(x, 'toInt');
    }
    dart.fn(toInt);
    testListFunctions(typed_data.Float32List.fromList(dart.list([1.5, 6.3, 9.5], core.double)), 1.5, 9.5, toDouble);
    testListFunctions(typed_data.Float64List.fromList(dart.list([1.5, 6.3, 9.5], core.double)), 1.5, 9.5, toDouble);
    testListFunctions(typed_data.Int8List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    testListFunctions(typed_data.Int16List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    testListFunctions(typed_data.Int32List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    testListFunctions(typed_data.Uint8List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    testListFunctions(typed_data.Uint16List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    testListFunctions(typed_data.Uint32List.fromList(dart.list([3, 5, 9], core.int)), 3, 9, toInt);
    emptyChecks(typed_data.Float32List.new(0));
    emptyChecks(typed_data.Float64List.new(0));
    emptyChecks(typed_data.Int8List.new(0));
    emptyChecks(typed_data.Int16List.new(0));
    emptyChecks(typed_data.Int32List.new(0));
    emptyChecks(typed_data.Uint8List.new(0));
    emptyChecks(typed_data.Uint16List.new(0));
    emptyChecks(typed_data.Uint32List.new(0));
  }
  dart.fn(main);
  // Exports:
  exports.confuse = confuse;
  exports.testListFunctions = testListFunctions;
  exports.emptyChecks = emptyChecks;
  exports.main = main;
});
dart_library.library('lib/typed_data/typed_data_load2_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data',
  'expect/expect'
], /* Lazy imports */[
], function(exports, dart, typed_data, expect) {
  'use strict';
  let dartx = dart.dartx;
  function aliasWithByteData1() {
    let aa = typed_data.Int8List.new(10);
    let b = typed_data.ByteData.view(aa[dartx.buffer]);
    for (let i = 0; i < dart.notNull(aa[dartx.length]); i++)
      aa[dartx.set](i, 9);
    let x1 = aa[dartx.get](3);
    b[dartx.setInt8](3, 1);
    let x2 = aa[dartx.get](3);
    expect.Expect.equals(9, x1);
    expect.Expect.equals(1, x2);
  }
  dart.fn(aliasWithByteData1);
  function aliasWithByteData2() {
    let b = typed_data.ByteData.new(10);
    let aa = typed_data.Int8List.view(b[dartx.buffer]);
    for (let i = 0; i < dart.notNull(aa[dartx.length]); i++)
      aa[dartx.set](i, 9);
    let x1 = aa[dartx.get](3);
    b[dartx.setInt8](3, 1);
    let x2 = aa[dartx.get](3);
    expect.Expect.equals(9, x1);
    expect.Expect.equals(1, x2);
  }
  dart.fn(aliasWithByteData2);
  function alias8x8() {
    let buffer = typed_data.Int8List.new(10)[dartx.buffer];
    let a1 = typed_data.Int8List.view(buffer);
    let a2 = typed_data.Int8List.view(buffer, 1);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    let x1 = a1[dartx.get](1);
    a2[dartx.set](0, 0);
    let x2 = a1[dartx.get](1);
    expect.Expect.equals(9, x1);
    expect.Expect.equals(0, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](1);
    a2[dartx.set](1, 5);
    x2 = a1[dartx.get](1);
    expect.Expect.equals(9, x1);
    expect.Expect.equals(9, x2);
  }
  dart.fn(alias8x8);
  function alias8x16() {
    let a1 = typed_data.Int8List.new(10);
    let a2 = typed_data.Int16List.view(a1[dartx.buffer]);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    let x1 = a1[dartx.get](0);
    a2[dartx.set](0, 257);
    let x2 = a1[dartx.get](0);
    expect.Expect.equals(9, x1);
    expect.Expect.equals(1, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](4);
    a2[dartx.set](2, 1285);
    x2 = a1[dartx.get](4);
    expect.Expect.equals(9, x1);
    expect.Expect.equals(5, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](3);
    a2[dartx.set](3, 1285);
    x2 = a1[dartx.get](3);
    expect.Expect.equals(9, x1);
    expect.Expect.equals(9, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](2);
    a2[dartx.set](0, 1285);
    x2 = a1[dartx.get](2);
    expect.Expect.equals(9, x1);
    expect.Expect.equals(9, x2);
  }
  dart.fn(alias8x16);
  function main() {
    aliasWithByteData1();
    aliasWithByteData2();
    alias8x8();
    alias8x16();
  }
  dart.fn(main);
  // Exports:
  exports.aliasWithByteData1 = aliasWithByteData1;
  exports.aliasWithByteData2 = aliasWithByteData2;
  exports.alias8x8 = alias8x8;
  exports.alias8x16 = alias8x16;
  exports.main = main;
});
dart_library.library('lib/typed_data/typed_data_load_test', null, /* Imports */[
  'dart/_runtime',
  'dart/typed_data'
], /* Lazy imports */[
], function(exports, dart, typed_data) {
  'use strict';
  let dartx = dart.dartx;
  function main() {
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
  }
  dart.fn(main);
  // Exports:
  exports.main = main;
});
dart_library.library('lib/typed_data/typed_data_sublist_type_test', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'expect/expect',
  'dart/typed_data'
], /* Lazy imports */[
], function(exports, dart, core, expect, typed_data) {
  'use strict';
  let dartx = dart.dartx;
  exports.inscrutable = null;
  const Is$ = dart.generic(function(T) {
    class Is extends core.Object {
      Is(name) {
        this.name = name;
      }
      check(x) {
        return dart.is(x, T);
      }
      expect(x, part) {
        expect.Expect.isTrue(this.check(x), `(${part}: ${dart.runtimeType(x)}) is ${this.name}`);
      }
      expectNot(x, part) {
        expect.Expect.isFalse(this.check(x), `(${part}: ${dart.runtimeType(x)}) is! ${this.name}`);
      }
    }
    dart.setSignature(Is, {
      constructors: () => ({Is: [Is$(T), [dart.dynamic]]}),
      methods: () => ({
        check: [dart.dynamic, [dart.dynamic]],
        expect: [dart.dynamic, [dart.dynamic, dart.dynamic]],
        expectNot: [dart.dynamic, [dart.dynamic, dart.dynamic]]
      })
    });
    return Is;
  });
  let Is = Is$();
  function testSublistType(input, positive, all) {
    let negative = dart.dsend(all, 'where', dart.fn(check => !dart.notNull(dart.as(dart.dsend(positive, 'contains', check), core.bool)), core.bool, [dart.dynamic]));
    input = dart.dcall(exports.inscrutable, input);
    for (let check of dart.as(positive, core.Iterable))
      dart.dsend(check, 'expect', input, 'input');
    for (let check of dart.as(negative, core.Iterable))
      dart.dsend(check, 'expectNot', input, 'input');
    let sub = dart.dcall(exports.inscrutable, dart.dsend(input, 'sublist', 1));
    for (let check of dart.as(positive, core.Iterable))
      dart.dsend(check, 'expect', sub, 'sublist');
    for (let check of dart.as(negative, core.Iterable))
      dart.dsend(check, 'expectNot', sub, 'sublist');
    let sub2 = dart.dcall(exports.inscrutable, dart.dsend(input, 'sublist', 10));
    expect.Expect.equals(0, dart.dload(sub2, 'length'));
    for (let check of dart.as(positive, core.Iterable))
      dart.dsend(check, 'expect', sub2, 'empty sublist');
    for (let check of dart.as(negative, core.Iterable))
      dart.dsend(check, 'expectNot', sub2, 'empty sublist');
  }
  dart.fn(testSublistType, dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]);
  function testTypes() {
    let isFloat32list = new (Is$(typed_data.Float32List))('Float32List');
    let isFloat64list = new (Is$(typed_data.Float64List))('Float64List');
    let isInt8List = new (Is$(typed_data.Int8List))('Int8List');
    let isInt16List = new (Is$(typed_data.Int16List))('Int16List');
    let isInt32List = new (Is$(typed_data.Int32List))('Int32List');
    let isUint8List = new (Is$(typed_data.Uint8List))('Uint8List');
    let isUint16List = new (Is$(typed_data.Uint16List))('Uint16List');
    let isUint32List = new (Is$(typed_data.Uint32List))('Uint32List');
    let isUint8ClampedList = new (Is$(typed_data.Uint8ClampedList))('Uint8ClampedList');
    let isIntList = new (Is$(core.List$(core.int)))('List<int>');
    let isDoubleList = new (Is$(core.List$(core.double)))('List<double>');
    let isNumList = new (Is$(core.List$(core.num)))('List<num>');
    let allChecks = [isFloat32list, isFloat64list, isInt8List, isInt16List, isInt32List, isUint8List, isUint16List, isUint32List, isUint8ClampedList];
    function testInt(list, check) {
      testSublistType(list, [check, isIntList, isNumList], allChecks);
    }
    dart.fn(testInt);
    function testDouble(list, check) {
      testSublistType(list, [check, isDoubleList, isNumList], allChecks);
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
  }
  dart.fn(testTypes, dart.void, []);
  function main() {
    exports.inscrutable = dart.fn(x => x);
    testTypes();
  }
  dart.fn(main);
  // Exports:
  exports.Is$ = Is$;
  exports.Is = Is;
  exports.testSublistType = testSublistType;
  exports.testTypes = testTypes;
  exports.main = main;
});
dart_library.library('lib/typed_data/typed_list_iterable_test', null, /* Imports */[
  'dart/_runtime',
  'expect/expect',
  'dart/core',
  'dart/typed_data'
], /* Lazy imports */[
], function(exports, dart, expect, core, typed_data) {
  'use strict';
  let dartx = dart.dartx;
  function testIterableFunctions(list, first, last) {
    dart.assert(dart.dsend(dart.dload(list, 'length'), '>', 0));
    expect.Expect.equals(first, dart.dload(list, 'first'));
    expect.Expect.equals(last, dart.dload(list, 'last'));
    expect.Expect.equals(first, dart.dsend(list, 'firstWhere', dart.fn(x => dart.equals(x, first), core.bool, [dart.dynamic])));
    expect.Expect.equals(last, dart.dsend(list, 'lastWhere', dart.fn(x => dart.equals(x, last), core.bool, [dart.dynamic])));
    if (dart.equals(dart.dload(list, 'length'), 1)) {
      expect.Expect.equals(first, dart.dload(list, 'single'));
      expect.Expect.equals(first, dart.dsend(list, 'singleWhere', dart.fn(x => dart.equals(x, last), core.bool, [dart.dynamic])));
    } else {
      expect.Expect.throws(dart.fn(() => dart.dload(list, 'single'), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
      let isFirst = true;
      expect.Expect.equals(first, dart.dsend(list, 'singleWhere', dart.fn(x => {
        if (isFirst) {
          isFirst = false;
          return true;
        }
        return false;
      })));
    }
    expect.Expect.isFalse(dart.dload(list, 'isEmpty'));
    let i = 0;
    for (let x of dart.as(list, core.Iterable)) {
      expect.Expect.equals(dart.dindex(list, i++), x);
    }
    expect.Expect.isTrue(dart.dsend(list, 'any', dart.fn(x => dart.equals(x, last), core.bool, [dart.dynamic])));
    expect.Expect.isFalse(dart.dsend(list, 'any', dart.fn(x => false, core.bool, [dart.dynamic])));
    expect.Expect.isTrue(dart.dsend(list, 'contains', last));
    expect.Expect.equals(first, dart.dsend(list, 'elementAt', 0));
    expect.Expect.isTrue(dart.dsend(list, 'every', dart.fn(x => true, core.bool, [dart.dynamic])));
    expect.Expect.isFalse(dart.dsend(list, 'every', dart.fn(x => !dart.equals(x, last), core.bool, [dart.dynamic])));
    expect.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => [], core.List, [dart.dynamic])), 'toList'), core.List));
    let expand2 = dart.dsend(list, 'expand', dart.fn(x => [x, x], core.List, [dart.dynamic]));
    i = 0;
    for (let x of dart.as(expand2, core.Iterable)) {
      expect.Expect.equals(dart.dindex(list, (i / 2)[dartx.truncate]()), x);
      i++;
    }
    expect.Expect.equals(2 * dart.notNull(dart.as(dart.dload(list, 'length'), core.num)), i);
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(list, 'fold', [], dart.fn((result, x) => ((() => {
      dart.dsend(result, 'add', x);
      return result;
    })()))), core.List));
    i = 0;
    dart.dsend(list, 'forEach', dart.fn(x => {
      expect.Expect.equals(dart.dindex(list, i++), x);
    }));
    expect.Expect.equals(dart.dsend(dart.dsend(list, 'toList'), 'join', "*"), dart.dsend(list, 'join', "*"));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'map', dart.fn(x => x)), 'toList'), core.List));
    let mapCount = 0;
    let mappedList = dart.dsend(list, 'map', dart.fn(x => {
      mapCount++;
      return x;
    }));
    expect.Expect.equals(0, mapCount);
    expect.Expect.equals(dart.dload(list, 'length'), dart.dload(mappedList, 'length'));
    expect.Expect.equals(0, mapCount);
    dart.dsend(mappedList, 'join');
    expect.Expect.equals(dart.dload(list, 'length'), mapCount);
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'where', dart.fn(x => true, core.bool, [dart.dynamic])), 'toList'), core.List));
    let whereCount = 0;
    let whereList = dart.dsend(list, 'where', dart.fn(x => {
      whereCount++;
      return true;
    }));
    expect.Expect.equals(0, whereCount);
    expect.Expect.equals(dart.dload(list, 'length'), dart.dload(whereList, 'length'));
    expect.Expect.equals(dart.dload(list, 'length'), whereCount);
    if (dart.notNull(dart.as(dart.dsend(dart.dload(list, 'length'), '>', 1), core.bool))) {
      let reduceResult = 1;
      expect.Expect.equals(dart.dload(list, 'length'), dart.dsend(list, 'reduce', dart.fn((x, y) => ++reduceResult, core.int, [dart.dynamic, dart.dynamic])));
    } else {
      expect.Expect.equals(first, dart.dsend(list, 'reduce', dart.fn((x, y) => {
        dart.throw("should not be called");
      })));
    }
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'skip', dart.dload(list, 'length')), 'isEmpty'));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'skip', 0), 'toList'), core.List));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'skipWhile', dart.fn(x => true, core.bool, [dart.dynamic])), 'isEmpty'));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'skipWhile', dart.fn(x => false, core.bool, [dart.dynamic])), 'toList'), core.List));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'take', dart.dload(list, 'length')), 'toList'), core.List));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'take', 0), 'isEmpty'));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'takeWhile', dart.fn(x => false, core.bool, [dart.dynamic])), 'isEmpty'));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'takeWhile', dart.fn(x => true, core.bool, [dart.dynamic])), 'toList'), core.List));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'toList'), 'toList'), core.List));
    let l2 = dart.dsend(list, 'toList');
    dart.dsend(l2, 'add', first);
    expect.Expect.equals(first, dart.dload(l2, 'last'));
    let l3 = dart.dsend(list, 'toList', {growable: false});
    expect.Expect.throws(dart.fn(() => dart.dsend(l3, 'add', last), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
  }
  dart.fn(testIterableFunctions, dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]);
  function emptyChecks(list) {
    dart.assert(dart.equals(dart.dload(list, 'length'), 0));
    expect.Expect.isTrue(dart.dload(list, 'isEmpty'));
    expect.Expect.throws(dart.fn(() => dart.dload(list, 'first'), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dload(list, 'last'), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dload(list, 'single'), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'firstWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'lastWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'singleWhere', dart.fn(x => true, core.bool, [dart.dynamic])), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect.Expect.isFalse(dart.dsend(list, 'any', dart.fn(x => true, core.bool, [dart.dynamic])));
    expect.Expect.isFalse(dart.dsend(list, 'contains', null));
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'elementAt', 0), dart.void, []), dart.fn(e => dart.is(e, core.RangeError), core.bool, [dart.dynamic]));
    expect.Expect.isTrue(dart.dsend(list, 'every', dart.fn(x => false, core.bool, [dart.dynamic])));
    expect.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => [], core.List, [dart.dynamic])), 'toList'), core.List));
    expect.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => [x, x], core.List, [dart.dynamic])), 'toList'), core.List));
    expect.Expect.listEquals([], dart.as(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => {
      dart.throw("should not be reached");
    })), 'toList'), core.List));
    expect.Expect.listEquals([], dart.as(dart.dsend(list, 'fold', [], dart.fn((result, x) => ((() => {
      dart.dsend(result, 'add', x);
      return result;
    })()))), core.List));
    expect.Expect.equals(dart.dsend(dart.dsend(list, 'toList'), 'join', "*"), dart.dsend(list, 'join', "*"));
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'map', dart.fn(x => x)), 'toList'), core.List));
    let mapCount = 0;
    let mappedList = dart.dsend(list, 'map', dart.fn(x => {
      mapCount++;
      return x;
    }));
    expect.Expect.equals(0, mapCount);
    expect.Expect.equals(dart.dload(list, 'length'), dart.dload(mappedList, 'length'));
    expect.Expect.equals(0, mapCount);
    dart.dsend(mappedList, 'join');
    expect.Expect.equals(dart.dload(list, 'length'), mapCount);
    expect.Expect.listEquals(dart.as(list, core.List), dart.as(dart.dsend(dart.dsend(list, 'where', dart.fn(x => true, core.bool, [dart.dynamic])), 'toList'), core.List));
    let whereCount = 0;
    let whereList = dart.dsend(list, 'where', dart.fn(x => {
      whereCount++;
      return true;
    }));
    expect.Expect.equals(0, whereCount);
    expect.Expect.equals(dart.dload(list, 'length'), dart.dload(whereList, 'length'));
    expect.Expect.equals(dart.dload(list, 'length'), whereCount);
    expect.Expect.throws(dart.fn(() => dart.dsend(list, 'reduce', dart.fn((x, y) => x)), dart.void, []), dart.fn(e => dart.is(e, core.StateError), core.bool, [dart.dynamic]));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'skip', dart.dload(list, 'length')), 'isEmpty'));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'skip', 0), 'isEmpty'));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'skipWhile', dart.fn(x => true, core.bool, [dart.dynamic])), 'isEmpty'));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'skipWhile', dart.fn(x => false, core.bool, [dart.dynamic])), 'isEmpty'));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'take', dart.dload(list, 'length')), 'isEmpty'));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'take', 0), 'isEmpty'));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'takeWhile', dart.fn(x => false, core.bool, [dart.dynamic])), 'isEmpty'));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'takeWhile', dart.fn(x => true, core.bool, [dart.dynamic])), 'isEmpty'));
    expect.Expect.isTrue(dart.dload(dart.dsend(list, 'toList'), 'isEmpty'));
    let l2 = dart.dsend(list, 'toList');
    dart.dsend(l2, 'add', 0);
    expect.Expect.equals(0, dart.dload(l2, 'last'));
    let l3 = dart.dsend(list, 'toList', {growable: false});
    expect.Expect.throws(dart.fn(() => dart.dsend(l3, 'add', 0), dart.void, []), dart.fn(e => dart.is(e, core.UnsupportedError), core.bool, [dart.dynamic]));
  }
  dart.fn(emptyChecks, dart.void, [dart.dynamic]);
  function main() {
    testIterableFunctions(typed_data.Float32List.fromList(dart.list([1.5, 9.5], core.double)), 1.5, 9.5);
    testIterableFunctions(typed_data.Float64List.fromList(dart.list([1.5, 9.5], core.double)), 1.5, 9.5);
    testIterableFunctions(typed_data.Int8List.fromList(dart.list([3, 9], core.int)), 3, 9);
    testIterableFunctions(typed_data.Int16List.fromList(dart.list([3, 9], core.int)), 3, 9);
    testIterableFunctions(typed_data.Int32List.fromList(dart.list([3, 9], core.int)), 3, 9);
    testIterableFunctions(typed_data.Uint8List.fromList(dart.list([3, 9], core.int)), 3, 9);
    testIterableFunctions(typed_data.Uint16List.fromList(dart.list([3, 9], core.int)), 3, 9);
    testIterableFunctions(typed_data.Uint32List.fromList(dart.list([3, 9], core.int)), 3, 9);
    emptyChecks(typed_data.Float32List.new(0));
    emptyChecks(typed_data.Float64List.new(0));
    emptyChecks(typed_data.Int8List.new(0));
    emptyChecks(typed_data.Int16List.new(0));
    emptyChecks(typed_data.Int32List.new(0));
    emptyChecks(typed_data.Uint8List.new(0));
    emptyChecks(typed_data.Uint16List.new(0));
    emptyChecks(typed_data.Uint32List.new(0));
  }
  dart.fn(main);
  // Exports:
  exports.testIterableFunctions = testIterableFunctions;
  exports.emptyChecks = emptyChecks;
  exports.main = main;
});
