dart_library.library('dart/_native_typed_data', null, /* Imports */[
  "dart/_runtime",
  'dart/core',
  'dart/typed_data',
  'dart/_js_helper',
  'dart/collection',
  'dart/_internal',
  'dart/_interceptors',
  'dart/math'
], /* Lazy imports */[
], function(exports, dart, core, typed_data, _js_helper, collection, _internal, _interceptors, math) {
  'use strict';
  let dartx = dart.dartx;
  class NativeByteBuffer extends core.Object {
    get runtimeType() {
      return typed_data.ByteBuffer;
    }
    asUint8List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeUint8List.view(this, offsetInBytes, length);
    }
    asInt8List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeInt8List.view(this, offsetInBytes, length);
    }
    asUint8ClampedList(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeUint8ClampedList.view(this, offsetInBytes, length);
    }
    asUint16List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeUint16List.view(this, offsetInBytes, length);
    }
    asInt16List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeInt16List.view(this, offsetInBytes, length);
    }
    asUint32List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeUint32List.view(this, offsetInBytes, length);
    }
    asInt32List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeInt32List.view(this, offsetInBytes, length);
    }
    asUint64List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      dart.throw(new core.UnsupportedError("Uint64List not supported by dart2js."));
    }
    asInt64List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      dart.throw(new core.UnsupportedError("Int64List not supported by dart2js."));
    }
    asInt32x4List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      let storage = dart.as(this.asInt32List(offsetInBytes, length != null ? dart.notNull(length) * 4 : null), NativeInt32List);
      return new NativeInt32x4List._externalStorage(storage);
    }
    asFloat32List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeFloat32List.view(this, offsetInBytes, length);
    }
    asFloat64List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeFloat64List.view(this, offsetInBytes, length);
    }
    asFloat32x4List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      let storage = dart.as(this.asFloat32List(offsetInBytes, length != null ? dart.notNull(length) * 4 : null), NativeFloat32List);
      return new NativeFloat32x4List._externalStorage(storage);
    }
    asFloat64x2List(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      let storage = dart.as(this.asFloat64List(offsetInBytes, length != null ? dart.notNull(length) * 2 : null), NativeFloat64List);
      return new NativeFloat64x2List._externalStorage(storage);
    }
    asByteData(offsetInBytes, length) {
      if (offsetInBytes === void 0) offsetInBytes = 0;
      if (length === void 0) length = null;
      return NativeByteData.view(this, offsetInBytes, length);
    }
  }
  NativeByteBuffer[dart.implements] = () => [typed_data.ByteBuffer];
  dart.setSignature(NativeByteBuffer, {
    methods: () => ({
      asUint8List: [typed_data.Uint8List, [], [core.int, core.int]],
      asInt8List: [typed_data.Int8List, [], [core.int, core.int]],
      asUint8ClampedList: [typed_data.Uint8ClampedList, [], [core.int, core.int]],
      asUint16List: [typed_data.Uint16List, [], [core.int, core.int]],
      asInt16List: [typed_data.Int16List, [], [core.int, core.int]],
      asUint32List: [typed_data.Uint32List, [], [core.int, core.int]],
      asInt32List: [typed_data.Int32List, [], [core.int, core.int]],
      asUint64List: [typed_data.Uint64List, [], [core.int, core.int]],
      asInt64List: [typed_data.Int64List, [], [core.int, core.int]],
      asInt32x4List: [typed_data.Int32x4List, [], [core.int, core.int]],
      asFloat32List: [typed_data.Float32List, [], [core.int, core.int]],
      asFloat64List: [typed_data.Float64List, [], [core.int, core.int]],
      asFloat32x4List: [typed_data.Float32x4List, [], [core.int, core.int]],
      asFloat64x2List: [typed_data.Float64x2List, [], [core.int, core.int]],
      asByteData: [typed_data.ByteData, [], [core.int, core.int]]
    })
  });
  NativeByteBuffer[dart.metadata] = () => [dart.const(new _js_helper.Native("ArrayBuffer"))];
  const _storage = Symbol('_storage');
  const _invalidIndex = Symbol('_invalidIndex');
  const _checkIndex = Symbol('_checkIndex');
  const _checkSublistArguments = Symbol('_checkSublistArguments');
  class NativeFloat32x4List extends dart.mixin(core.Object, collection.ListMixin$(typed_data.Float32x4), _internal.FixedLengthListMixin$(typed_data.Float32x4)) {
    NativeFloat32x4List(length) {
      this[_storage] = NativeFloat32List.new(dart.notNull(length) * 4);
    }
    _externalStorage(storage) {
      this[_storage] = storage;
    }
    _slowFromList(list) {
      this[_storage] = NativeFloat32List.new(dart.notNull(list[dartx.length]) * 4);
      for (let i = 0; dart.notNull(i) < dart.notNull(list[dartx.length]); i = dart.notNull(i) + 1) {
        let e = list[dartx.get](i);
        this[_storage].set(dart.notNull(i) * 4 + 0, e.x);
        this[_storage].set(dart.notNull(i) * 4 + 1, e.y);
        this[_storage].set(dart.notNull(i) * 4 + 2, e.z);
        this[_storage].set(dart.notNull(i) * 4 + 3, e.w);
      }
    }
    get runtimeType() {
      return typed_data.Float32x4List;
    }
    static fromList(list) {
      if (dart.is(list, NativeFloat32x4List)) {
        return new NativeFloat32x4List._externalStorage(NativeFloat32List.fromList(list[_storage]));
      } else {
        return new NativeFloat32x4List._slowFromList(list);
      }
    }
    get buffer() {
      return this[_storage].buffer;
    }
    get lengthInBytes() {
      return this[_storage].lengthInBytes;
    }
    get offsetInBytes() {
      return this[_storage].offsetInBytes;
    }
    get elementSizeInBytes() {
      return typed_data.Float32x4List.BYTES_PER_ELEMENT;
    }
    [_invalidIndex](index, length) {
      if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(length)) {
        if (length == this.length) {
          dart.throw(core.RangeError.index(index, this));
        }
        dart.throw(new core.RangeError.range(index, 0, dart.notNull(length) - 1));
      } else {
        dart.throw(new core.ArgumentError(`Invalid list index ${index}`));
      }
    }
    [_checkIndex](index, length) {
      if (index >>> 0 != index || dart.notNull(index) >= dart.notNull(length)) {
        this[_invalidIndex](index, length);
      }
    }
    [_checkSublistArguments](start, end, length) {
      this[_checkIndex](start, dart.notNull(length) + 1);
      if (end == null) return length;
      this[_checkIndex](end, dart.notNull(length) + 1);
      if (dart.notNull(start) > dart.notNull(end)) dart.throw(new core.RangeError.range(start, 0, end));
      return end;
    }
    get length() {
      return (dart.notNull(this[_storage].length) / 4)[dartx.truncate]();
    }
    get(index) {
      this[_checkIndex](index, this.length);
      let _x = this[_storage].get(dart.notNull(index) * 4 + 0);
      let _y = this[_storage].get(dart.notNull(index) * 4 + 1);
      let _z = this[_storage].get(dart.notNull(index) * 4 + 2);
      let _w = this[_storage].get(dart.notNull(index) * 4 + 3);
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    set(index, value) {
      this[_checkIndex](index, this.length);
      this[_storage].set(dart.notNull(index) * 4 + 0, value.x);
      this[_storage].set(dart.notNull(index) * 4 + 1, value.y);
      this[_storage].set(dart.notNull(index) * 4 + 2, value.z);
      this[_storage].set(dart.notNull(index) * 4 + 3, value.w);
      return value;
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      return new NativeFloat32x4List._externalStorage(dart.as(this[_storage].sublist(dart.notNull(start) * 4, dart.notNull(end) * 4), NativeFloat32List));
    }
  }
  NativeFloat32x4List[dart.implements] = () => [typed_data.Float32x4List];
  dart.defineNamedConstructor(NativeFloat32x4List, '_externalStorage');
  dart.defineNamedConstructor(NativeFloat32x4List, '_slowFromList');
  dart.setSignature(NativeFloat32x4List, {
    constructors: () => ({
      NativeFloat32x4List: [NativeFloat32x4List, [core.int]],
      _externalStorage: [NativeFloat32x4List, [NativeFloat32List]],
      _slowFromList: [NativeFloat32x4List, [core.List$(typed_data.Float32x4)]],
      fromList: [NativeFloat32x4List, [core.List$(typed_data.Float32x4)]]
    }),
    methods: () => ({
      [_invalidIndex]: [dart.void, [core.int, core.int]],
      [_checkIndex]: [dart.void, [core.int, core.int]],
      [_checkSublistArguments]: [core.int, [core.int, core.int, core.int]],
      get: [typed_data.Float32x4, [core.int]],
      set: [dart.void, [core.int, typed_data.Float32x4]],
      sublist: [core.List$(typed_data.Float32x4), [core.int], [core.int]]
    })
  });
  dart.defineExtensionMembers(NativeFloat32x4List, ['get', 'set', 'sublist', 'length']);
  class NativeInt32x4List extends dart.mixin(core.Object, collection.ListMixin$(typed_data.Int32x4), _internal.FixedLengthListMixin$(typed_data.Int32x4)) {
    NativeInt32x4List(length) {
      this[_storage] = NativeInt32List.new(dart.notNull(length) * 4);
    }
    _externalStorage(storage) {
      this[_storage] = storage;
    }
    _slowFromList(list) {
      this[_storage] = NativeInt32List.new(dart.notNull(list[dartx.length]) * 4);
      for (let i = 0; dart.notNull(i) < dart.notNull(list[dartx.length]); i = dart.notNull(i) + 1) {
        let e = list[dartx.get](i);
        this[_storage].set(dart.notNull(i) * 4 + 0, e.x);
        this[_storage].set(dart.notNull(i) * 4 + 1, e.y);
        this[_storage].set(dart.notNull(i) * 4 + 2, e.z);
        this[_storage].set(dart.notNull(i) * 4 + 3, e.w);
      }
    }
    get runtimeType() {
      return typed_data.Int32x4List;
    }
    static fromList(list) {
      if (dart.is(list, NativeInt32x4List)) {
        return new NativeInt32x4List._externalStorage(NativeInt32List.fromList(list[_storage]));
      } else {
        return new NativeInt32x4List._slowFromList(list);
      }
    }
    get buffer() {
      return this[_storage].buffer;
    }
    get lengthInBytes() {
      return this[_storage].lengthInBytes;
    }
    get offsetInBytes() {
      return this[_storage].offsetInBytes;
    }
    get elementSizeInBytes() {
      return typed_data.Int32x4List.BYTES_PER_ELEMENT;
    }
    [_invalidIndex](index, length) {
      if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(length)) {
        if (length == this.length) {
          dart.throw(core.RangeError.index(index, this));
        }
        dart.throw(new core.RangeError.range(index, 0, dart.notNull(length) - 1));
      } else {
        dart.throw(new core.ArgumentError(`Invalid list index ${index}`));
      }
    }
    [_checkIndex](index, length) {
      if (index >>> 0 != index || index >= length) {
        this[_invalidIndex](index, length);
      }
    }
    [_checkSublistArguments](start, end, length) {
      this[_checkIndex](start, dart.notNull(length) + 1);
      if (end == null) return length;
      this[_checkIndex](end, dart.notNull(length) + 1);
      if (dart.notNull(start) > dart.notNull(end)) dart.throw(new core.RangeError.range(start, 0, end));
      return end;
    }
    get length() {
      return (dart.notNull(this[_storage].length) / 4)[dartx.truncate]();
    }
    get(index) {
      this[_checkIndex](index, this.length);
      let _x = this[_storage].get(dart.notNull(index) * 4 + 0);
      let _y = this[_storage].get(dart.notNull(index) * 4 + 1);
      let _z = this[_storage].get(dart.notNull(index) * 4 + 2);
      let _w = this[_storage].get(dart.notNull(index) * 4 + 3);
      return new NativeInt32x4._truncated(_x, _y, _z, _w);
    }
    set(index, value) {
      this[_checkIndex](index, this.length);
      this[_storage].set(dart.notNull(index) * 4 + 0, value.x);
      this[_storage].set(dart.notNull(index) * 4 + 1, value.y);
      this[_storage].set(dart.notNull(index) * 4 + 2, value.z);
      this[_storage].set(dart.notNull(index) * 4 + 3, value.w);
      return value;
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      return new NativeInt32x4List._externalStorage(dart.as(this[_storage].sublist(dart.notNull(start) * 4, dart.notNull(end) * 4), typed_data.Int32List));
    }
  }
  NativeInt32x4List[dart.implements] = () => [typed_data.Int32x4List];
  dart.defineNamedConstructor(NativeInt32x4List, '_externalStorage');
  dart.defineNamedConstructor(NativeInt32x4List, '_slowFromList');
  dart.setSignature(NativeInt32x4List, {
    constructors: () => ({
      NativeInt32x4List: [NativeInt32x4List, [core.int]],
      _externalStorage: [NativeInt32x4List, [typed_data.Int32List]],
      _slowFromList: [NativeInt32x4List, [core.List$(typed_data.Int32x4)]],
      fromList: [NativeInt32x4List, [core.List$(typed_data.Int32x4)]]
    }),
    methods: () => ({
      [_invalidIndex]: [dart.void, [core.int, core.int]],
      [_checkIndex]: [dart.void, [core.int, core.int]],
      [_checkSublistArguments]: [core.int, [core.int, core.int, core.int]],
      get: [typed_data.Int32x4, [core.int]],
      set: [dart.void, [core.int, typed_data.Int32x4]],
      sublist: [core.List$(typed_data.Int32x4), [core.int], [core.int]]
    })
  });
  dart.defineExtensionMembers(NativeInt32x4List, ['get', 'set', 'sublist', 'length']);
  class NativeFloat64x2List extends dart.mixin(core.Object, collection.ListMixin$(typed_data.Float64x2), _internal.FixedLengthListMixin$(typed_data.Float64x2)) {
    NativeFloat64x2List(length) {
      this[_storage] = NativeFloat64List.new(dart.notNull(length) * 2);
    }
    _externalStorage(storage) {
      this[_storage] = storage;
    }
    _slowFromList(list) {
      this[_storage] = NativeFloat64List.new(dart.notNull(list[dartx.length]) * 2);
      for (let i = 0; dart.notNull(i) < dart.notNull(list[dartx.length]); i = dart.notNull(i) + 1) {
        let e = list[dartx.get](i);
        this[_storage].set(dart.notNull(i) * 2 + 0, e.x);
        this[_storage].set(dart.notNull(i) * 2 + 1, e.y);
      }
    }
    static fromList(list) {
      if (dart.is(list, NativeFloat64x2List)) {
        return new NativeFloat64x2List._externalStorage(NativeFloat64List.fromList(list[_storage]));
      } else {
        return new NativeFloat64x2List._slowFromList(list);
      }
    }
    get runtimeType() {
      return typed_data.Float64x2List;
    }
    get buffer() {
      return this[_storage].buffer;
    }
    get lengthInBytes() {
      return this[_storage].lengthInBytes;
    }
    get offsetInBytes() {
      return this[_storage].offsetInBytes;
    }
    get elementSizeInBytes() {
      return typed_data.Float64x2List.BYTES_PER_ELEMENT;
    }
    [_invalidIndex](index, length) {
      if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(length)) {
        if (length == this.length) {
          dart.throw(core.RangeError.index(index, this));
        }
        dart.throw(new core.RangeError.range(index, 0, dart.notNull(length) - 1));
      } else {
        dart.throw(new core.ArgumentError(`Invalid list index ${index}`));
      }
    }
    [_checkIndex](index, length) {
      if (index >>> 0 != index || dart.notNull(index) >= dart.notNull(length)) {
        this[_invalidIndex](index, length);
      }
    }
    [_checkSublistArguments](start, end, length) {
      this[_checkIndex](start, dart.notNull(length) + 1);
      if (end == null) return length;
      this[_checkIndex](end, dart.notNull(length) + 1);
      if (dart.notNull(start) > dart.notNull(end)) dart.throw(new core.RangeError.range(start, 0, end));
      return end;
    }
    get length() {
      return (dart.notNull(this[_storage].length) / 2)[dartx.truncate]();
    }
    get(index) {
      this[_checkIndex](index, this.length);
      let _x = this[_storage].get(dart.notNull(index) * 2 + 0);
      let _y = this[_storage].get(dart.notNull(index) * 2 + 1);
      return typed_data.Float64x2.new(_x, _y);
    }
    set(index, value) {
      this[_checkIndex](index, this.length);
      this[_storage].set(dart.notNull(index) * 2 + 0, value.x);
      this[_storage].set(dart.notNull(index) * 2 + 1, value.y);
      return value;
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      return new NativeFloat64x2List._externalStorage(dart.as(this[_storage].sublist(dart.notNull(start) * 2, dart.notNull(end) * 2), NativeFloat64List));
    }
  }
  NativeFloat64x2List[dart.implements] = () => [typed_data.Float64x2List];
  dart.defineNamedConstructor(NativeFloat64x2List, '_externalStorage');
  dart.defineNamedConstructor(NativeFloat64x2List, '_slowFromList');
  dart.setSignature(NativeFloat64x2List, {
    constructors: () => ({
      NativeFloat64x2List: [NativeFloat64x2List, [core.int]],
      _externalStorage: [NativeFloat64x2List, [NativeFloat64List]],
      _slowFromList: [NativeFloat64x2List, [core.List$(typed_data.Float64x2)]],
      fromList: [NativeFloat64x2List, [core.List$(typed_data.Float64x2)]]
    }),
    methods: () => ({
      [_invalidIndex]: [dart.void, [core.int, core.int]],
      [_checkIndex]: [dart.void, [core.int, core.int]],
      [_checkSublistArguments]: [core.int, [core.int, core.int, core.int]],
      get: [typed_data.Float64x2, [core.int]],
      set: [dart.void, [core.int, typed_data.Float64x2]],
      sublist: [core.List$(typed_data.Float64x2), [core.int], [core.int]]
    })
  });
  dart.defineExtensionMembers(NativeFloat64x2List, ['get', 'set', 'sublist', 'length']);
  class NativeTypedData extends core.Object {
    [_invalidIndex](index, length) {
      if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(length)) {
        if (dart.is(this, core.List)) {
          if (dart.equals(length, dart.dload(this, 'length'))) {
            dart.throw(core.RangeError.index(index, this));
          }
        }
        dart.throw(new core.RangeError.range(index, 0, dart.notNull(length) - 1));
      } else {
        dart.throw(new core.ArgumentError(`Invalid list index ${index}`));
      }
    }
    [_checkIndex](index, length) {
      if (index >>> 0 !== index || index >= dart.notNull(length)) {
        this[_invalidIndex](index, length);
      }
    }
    [_checkSublistArguments](start, end, length) {
      this[_checkIndex](start, dart.notNull(length) + 1);
      if (end == null) return length;
      this[_checkIndex](end, dart.notNull(length) + 1);
      if (dart.notNull(start) > dart.notNull(end)) dart.throw(new core.RangeError.range(start, 0, end));
      return end;
    }
  }
  NativeTypedData[dart.implements] = () => [typed_data.TypedData];
  dart.setSignature(NativeTypedData, {
    methods: () => ({
      [_invalidIndex]: [dart.void, [core.int, core.int]],
      [_checkIndex]: [dart.void, [core.int, core.int]],
      [_checkSublistArguments]: [core.int, [core.int, core.int, core.int]]
    })
  });
  NativeTypedData[dart.metadata] = () => [dart.const(new _js_helper.Native("ArrayBufferView"))];
  function _checkLength(length) {
    if (!(typeof length == 'number')) dart.throw(new core.ArgumentError(`Invalid length ${length}`));
    return dart.as(length, core.int);
  }
  dart.fn(_checkLength, core.int, [dart.dynamic]);
  function _checkViewArguments(buffer, offsetInBytes, length) {
    if (!dart.is(buffer, NativeByteBuffer)) {
      dart.throw(new core.ArgumentError('Invalid view buffer'));
    }
    if (!(typeof offsetInBytes == 'number')) {
      dart.throw(new core.ArgumentError(`Invalid view offsetInBytes ${offsetInBytes}`));
    }
    if (length != null && !(typeof length == 'number')) {
      dart.throw(new core.ArgumentError(`Invalid view length ${length}`));
    }
  }
  dart.fn(_checkViewArguments, dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]);
  function _ensureNativeList(list) {
    if (dart.is(list, _interceptors.JSIndexable)) return list;
    let result = core.List.new(list[dartx.length]);
    for (let i = 0; dart.notNull(i) < dart.notNull(list[dartx.length]); i = dart.notNull(i) + 1) {
      result[dartx.set](i, list[dartx.get](i));
    }
    return result;
  }
  dart.fn(_ensureNativeList, core.List, [core.List]);
  const _getFloat32 = Symbol('_getFloat32');
  const _getFloat64 = Symbol('_getFloat64');
  const _getInt16 = Symbol('_getInt16');
  const _getInt32 = Symbol('_getInt32');
  const _getUint16 = Symbol('_getUint16');
  const _getUint32 = Symbol('_getUint32');
  const _setFloat32 = Symbol('_setFloat32');
  const _setFloat64 = Symbol('_setFloat64');
  const _setInt16 = Symbol('_setInt16');
  const _setInt32 = Symbol('_setInt32');
  const _setUint16 = Symbol('_setUint16');
  const _setUint32 = Symbol('_setUint32');
  class NativeByteData extends NativeTypedData {
    static new(length) {
      return NativeByteData._create1(_checkLength(length));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length == null ? NativeByteData._create2(buffer, offsetInBytes) : NativeByteData._create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.ByteData;
    }
    get elementSizeInBytes() {
      return 1;
    }
    getFloat32(byteOffset, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_getFloat32](byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getFloat64(byteOffset, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_getFloat64](byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getInt16(byteOffset, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_getInt16](byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getInt32(byteOffset, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_getInt32](byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getInt64(byteOffset, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      dart.throw(new core.UnsupportedError('Int64 accessor not supported by dart2js.'));
    }
    getUint16(byteOffset, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_getUint16](byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getUint32(byteOffset, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_getUint32](byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getUint64(byteOffset, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      dart.throw(new core.UnsupportedError('Uint64 accessor not supported by dart2js.'));
    }
    setFloat32(byteOffset, value, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_setFloat32](byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setFloat64(byteOffset, value, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_setFloat64](byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setInt16(byteOffset, value, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_setInt16](byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setInt32(byteOffset, value, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_setInt32](byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setInt64(byteOffset, value, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      dart.throw(new core.UnsupportedError('Int64 accessor not supported by dart2js.'));
    }
    setUint16(byteOffset, value, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_setUint16](byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setUint32(byteOffset, value, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      return this[_setUint32](byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setUint64(byteOffset, value, endian) {
      if (endian === void 0) endian = typed_data.Endianness.BIG_ENDIAN;
      dart.throw(new core.UnsupportedError('Uint64 accessor not supported by dart2js.'));
    }
    static _create1(arg) {
      return dart.as(new DataView(new ArrayBuffer(arg)), NativeByteData);
    }
    static _create2(arg1, arg2) {
      return dart.as(new DataView(arg1, arg2), NativeByteData);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new DataView(arg1, arg2, arg3), NativeByteData);
    }
  }
  NativeByteData[dart.implements] = () => [typed_data.ByteData];
  dart.setSignature(NativeByteData, {
    constructors: () => ({
      new: [NativeByteData, [core.int]],
      view: [NativeByteData, [typed_data.ByteBuffer, core.int, core.int]]
    }),
    methods: () => ({
      getFloat32: [core.double, [core.int], [typed_data.Endianness]],
      [_getFloat32]: [core.double, [core.int], [core.bool]],
      getFloat64: [core.double, [core.int], [typed_data.Endianness]],
      [_getFloat64]: [core.double, [core.int], [core.bool]],
      getInt16: [core.int, [core.int], [typed_data.Endianness]],
      [_getInt16]: [core.int, [core.int], [core.bool]],
      getInt32: [core.int, [core.int], [typed_data.Endianness]],
      [_getInt32]: [core.int, [core.int], [core.bool]],
      getInt64: [core.int, [core.int], [typed_data.Endianness]],
      getInt8: [core.int, [core.int]],
      getUint16: [core.int, [core.int], [typed_data.Endianness]],
      [_getUint16]: [core.int, [core.int], [core.bool]],
      getUint32: [core.int, [core.int], [typed_data.Endianness]],
      [_getUint32]: [core.int, [core.int], [core.bool]],
      getUint64: [core.int, [core.int], [typed_data.Endianness]],
      getUint8: [core.int, [core.int]],
      setFloat32: [dart.void, [core.int, core.num], [typed_data.Endianness]],
      [_setFloat32]: [dart.void, [core.int, core.num], [core.bool]],
      setFloat64: [dart.void, [core.int, core.num], [typed_data.Endianness]],
      [_setFloat64]: [dart.void, [core.int, core.num], [core.bool]],
      setInt16: [dart.void, [core.int, core.int], [typed_data.Endianness]],
      [_setInt16]: [dart.void, [core.int, core.int], [core.bool]],
      setInt32: [dart.void, [core.int, core.int], [typed_data.Endianness]],
      [_setInt32]: [dart.void, [core.int, core.int], [core.bool]],
      setInt64: [dart.void, [core.int, core.int], [typed_data.Endianness]],
      setInt8: [dart.void, [core.int, core.int]],
      setUint16: [dart.void, [core.int, core.int], [typed_data.Endianness]],
      [_setUint16]: [dart.void, [core.int, core.int], [core.bool]],
      setUint32: [dart.void, [core.int, core.int], [typed_data.Endianness]],
      [_setUint32]: [dart.void, [core.int, core.int], [core.bool]],
      setUint64: [dart.void, [core.int, core.int], [typed_data.Endianness]],
      setUint8: [dart.void, [core.int, core.int]]
    }),
    statics: () => ({
      _create1: [NativeByteData, [dart.dynamic]],
      _create2: [NativeByteData, [dart.dynamic, dart.dynamic]],
      _create3: [NativeByteData, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  NativeByteData[dart.metadata] = () => [dart.const(new _js_helper.Native("DataView"))];
  const _setRangeFast = Symbol('_setRangeFast');
  class NativeTypedArray extends NativeTypedData {
    [_setRangeFast](start, end, source, skipCount) {
      let targetLength = this.length;
      this[_checkIndex](start, dart.notNull(targetLength) + 1);
      this[_checkIndex](end, dart.notNull(targetLength) + 1);
      if (dart.notNull(start) > dart.notNull(end)) dart.throw(new core.RangeError.range(start, 0, end));
      let count = dart.notNull(end) - dart.notNull(start);
      if (dart.notNull(skipCount) < 0) dart.throw(new core.ArgumentError(skipCount));
      let sourceLength = source.length;
      if (dart.notNull(sourceLength) - dart.notNull(skipCount) < dart.notNull(count)) {
        dart.throw(new core.StateError('Not enough elements'));
      }
      if (skipCount != 0 || sourceLength != count) {
        source = dart.as(source.subarray(skipCount, dart.notNull(skipCount) + dart.notNull(count)), NativeTypedArray);
      }
      this.set(source, start);
    }
  }
  NativeTypedArray[dart.implements] = () => [_js_helper.JavaScriptIndexingBehavior];
  dart.setSignature(NativeTypedArray, {
    methods: () => ({[_setRangeFast]: [dart.void, [core.int, core.int, NativeTypedArray, core.int]]})
  });
  class NativeTypedArrayOfDouble extends dart.mixin(NativeTypedArray, collection.ListMixin$(core.double), _internal.FixedLengthListMixin$(core.double)) {
    get length() {
      return this.length;
    }
    get(index) {
      this[_checkIndex](index, this.length);
      return this[index];
    }
    set(index, value) {
      this[_checkIndex](index, this.length);
      this[index] = value;
      return value;
    }
    setRange(start, end, iterable, skipCount) {
      if (skipCount === void 0) skipCount = 0;
      if (dart.is(iterable, NativeTypedArrayOfDouble)) {
        this[_setRangeFast](start, end, iterable, skipCount);
        return;
      }
      super.setRange(start, end, iterable, skipCount);
    }
  }
  dart.setSignature(NativeTypedArrayOfDouble, {
    methods: () => ({
      get: [core.double, [core.int]],
      set: [dart.void, [core.int, core.num]],
      setRange: [dart.void, [core.int, core.int, core.Iterable$(core.double)], [core.int]]
    })
  });
  dart.defineExtensionMembers(NativeTypedArrayOfDouble, ['get', 'set', 'setRange', 'length']);
  class NativeTypedArrayOfInt extends dart.mixin(NativeTypedArray, collection.ListMixin$(core.int), _internal.FixedLengthListMixin$(core.int)) {
    get length() {
      return this.length;
    }
    set(index, value) {
      this[_checkIndex](index, this.length);
      this[index] = value;
      return value;
    }
    setRange(start, end, iterable, skipCount) {
      if (skipCount === void 0) skipCount = 0;
      if (dart.is(iterable, NativeTypedArrayOfInt)) {
        this[_setRangeFast](start, end, iterable, skipCount);
        return;
      }
      super.setRange(start, end, iterable, skipCount);
    }
  }
  NativeTypedArrayOfInt[dart.implements] = () => [core.List$(core.int)];
  dart.setSignature(NativeTypedArrayOfInt, {
    methods: () => ({
      set: [dart.void, [core.int, core.int]],
      setRange: [dart.void, [core.int, core.int, core.Iterable$(core.int)], [core.int]]
    })
  });
  dart.defineExtensionMembers(NativeTypedArrayOfInt, ['set', 'setRange', 'length']);
  class NativeFloat32List extends NativeTypedArrayOfDouble {
    static new(length) {
      return NativeFloat32List._create1(_checkLength(length));
    }
    static fromList(elements) {
      return NativeFloat32List._create1(_ensureNativeList(elements));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length == null ? NativeFloat32List._create2(buffer, offsetInBytes) : NativeFloat32List._create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Float32List;
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      let source = this.subarray(start, end);
      return NativeFloat32List._create1(source);
    }
    static _create1(arg) {
      return dart.as(new Float32Array(arg), NativeFloat32List);
    }
    static _create2(arg1, arg2) {
      return dart.as(new Float32Array(arg1, arg2), NativeFloat32List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new Float32Array(arg1, arg2, arg3), NativeFloat32List);
    }
  }
  NativeFloat32List[dart.implements] = () => [typed_data.Float32List];
  dart.setSignature(NativeFloat32List, {
    constructors: () => ({
      new: [NativeFloat32List, [core.int]],
      fromList: [NativeFloat32List, [core.List$(core.double)]],
      view: [NativeFloat32List, [typed_data.ByteBuffer, core.int, core.int]]
    }),
    methods: () => ({sublist: [core.List$(core.double), [core.int], [core.int]]}),
    statics: () => ({
      _create1: [NativeFloat32List, [dart.dynamic]],
      _create2: [NativeFloat32List, [dart.dynamic, dart.dynamic]],
      _create3: [NativeFloat32List, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  dart.defineExtensionMembers(NativeFloat32List, ['sublist']);
  NativeFloat32List[dart.metadata] = () => [dart.const(new _js_helper.Native("Float32Array"))];
  class NativeFloat64List extends NativeTypedArrayOfDouble {
    static new(length) {
      return NativeFloat64List._create1(_checkLength(length));
    }
    static fromList(elements) {
      return NativeFloat64List._create1(_ensureNativeList(elements));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length == null ? NativeFloat64List._create2(buffer, offsetInBytes) : NativeFloat64List._create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Float64List;
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      let source = this.subarray(start, end);
      return NativeFloat64List._create1(source);
    }
    static _create1(arg) {
      return dart.as(new Float64Array(arg), NativeFloat64List);
    }
    static _create2(arg1, arg2) {
      return dart.as(new Float64Array(arg1, arg2), NativeFloat64List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new Float64Array(arg1, arg2, arg3), NativeFloat64List);
    }
  }
  NativeFloat64List[dart.implements] = () => [typed_data.Float64List];
  dart.setSignature(NativeFloat64List, {
    constructors: () => ({
      new: [NativeFloat64List, [core.int]],
      fromList: [NativeFloat64List, [core.List$(core.double)]],
      view: [NativeFloat64List, [typed_data.ByteBuffer, core.int, core.int]]
    }),
    methods: () => ({sublist: [core.List$(core.double), [core.int], [core.int]]}),
    statics: () => ({
      _create1: [NativeFloat64List, [dart.dynamic]],
      _create2: [NativeFloat64List, [dart.dynamic, dart.dynamic]],
      _create3: [NativeFloat64List, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  dart.defineExtensionMembers(NativeFloat64List, ['sublist']);
  NativeFloat64List[dart.metadata] = () => [dart.const(new _js_helper.Native("Float64Array"))];
  class NativeInt16List extends NativeTypedArrayOfInt {
    static new(length) {
      return NativeInt16List._create1(_checkLength(length));
    }
    static fromList(elements) {
      return NativeInt16List._create1(_ensureNativeList(elements));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length == null ? NativeInt16List._create2(buffer, offsetInBytes) : NativeInt16List._create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Int16List;
    }
    get(index) {
      this[_checkIndex](index, this.length);
      return this[index];
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      let source = this.subarray(start, end);
      return NativeInt16List._create1(source);
    }
    static _create1(arg) {
      return dart.as(new Int16Array(arg), NativeInt16List);
    }
    static _create2(arg1, arg2) {
      return dart.as(new Int16Array(arg1, arg2), NativeInt16List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new Int16Array(arg1, arg2, arg3), NativeInt16List);
    }
  }
  NativeInt16List[dart.implements] = () => [typed_data.Int16List];
  dart.setSignature(NativeInt16List, {
    constructors: () => ({
      new: [NativeInt16List, [core.int]],
      fromList: [NativeInt16List, [core.List$(core.int)]],
      view: [NativeInt16List, [NativeByteBuffer, core.int, core.int]]
    }),
    methods: () => ({
      get: [core.int, [core.int]],
      sublist: [core.List$(core.int), [core.int], [core.int]]
    }),
    statics: () => ({
      _create1: [NativeInt16List, [dart.dynamic]],
      _create2: [NativeInt16List, [dart.dynamic, dart.dynamic]],
      _create3: [NativeInt16List, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  dart.defineExtensionMembers(NativeInt16List, ['get', 'sublist']);
  NativeInt16List[dart.metadata] = () => [dart.const(new _js_helper.Native("Int16Array"))];
  class NativeInt32List extends NativeTypedArrayOfInt {
    static new(length) {
      return NativeInt32List._create1(_checkLength(length));
    }
    static fromList(elements) {
      return NativeInt32List._create1(_ensureNativeList(elements));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length == null ? NativeInt32List._create2(buffer, offsetInBytes) : NativeInt32List._create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Int32List;
    }
    get(index) {
      this[_checkIndex](index, this.length);
      return this[index];
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      let source = this.subarray(start, end);
      return NativeInt32List._create1(source);
    }
    static _create1(arg) {
      return dart.as(new Int32Array(arg), NativeInt32List);
    }
    static _create2(arg1, arg2) {
      return dart.as(new Int32Array(arg1, arg2), NativeInt32List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new Int32Array(arg1, arg2, arg3), NativeInt32List);
    }
  }
  NativeInt32List[dart.implements] = () => [typed_data.Int32List];
  dart.setSignature(NativeInt32List, {
    constructors: () => ({
      new: [NativeInt32List, [core.int]],
      fromList: [NativeInt32List, [core.List$(core.int)]],
      view: [NativeInt32List, [typed_data.ByteBuffer, core.int, core.int]]
    }),
    methods: () => ({
      get: [core.int, [core.int]],
      sublist: [core.List$(core.int), [core.int], [core.int]]
    }),
    statics: () => ({
      _create1: [NativeInt32List, [dart.dynamic]],
      _create2: [NativeInt32List, [dart.dynamic, dart.dynamic]],
      _create3: [NativeInt32List, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  dart.defineExtensionMembers(NativeInt32List, ['get', 'sublist']);
  NativeInt32List[dart.metadata] = () => [dart.const(new _js_helper.Native("Int32Array"))];
  class NativeInt8List extends NativeTypedArrayOfInt {
    static new(length) {
      return NativeInt8List._create1(_checkLength(length));
    }
    static fromList(elements) {
      return NativeInt8List._create1(_ensureNativeList(elements));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return dart.as(length == null ? NativeInt8List._create2(buffer, offsetInBytes) : NativeInt8List._create3(buffer, offsetInBytes, length), NativeInt8List);
    }
    get runtimeType() {
      return typed_data.Int8List;
    }
    get(index) {
      this[_checkIndex](index, this.length);
      return this[index];
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      let source = this.subarray(start, end);
      return NativeInt8List._create1(source);
    }
    static _create1(arg) {
      return dart.as(new Int8Array(arg), NativeInt8List);
    }
    static _create2(arg1, arg2) {
      return dart.as(new Int8Array(arg1, arg2), NativeInt8List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new Int8Array(arg1, arg2, arg3), typed_data.Int8List);
    }
  }
  NativeInt8List[dart.implements] = () => [typed_data.Int8List];
  dart.setSignature(NativeInt8List, {
    constructors: () => ({
      new: [NativeInt8List, [core.int]],
      fromList: [NativeInt8List, [core.List$(core.int)]],
      view: [NativeInt8List, [typed_data.ByteBuffer, core.int, core.int]]
    }),
    methods: () => ({
      get: [core.int, [core.int]],
      sublist: [core.List$(core.int), [core.int], [core.int]]
    }),
    statics: () => ({
      _create1: [NativeInt8List, [dart.dynamic]],
      _create2: [NativeInt8List, [dart.dynamic, dart.dynamic]],
      _create3: [typed_data.Int8List, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  dart.defineExtensionMembers(NativeInt8List, ['get', 'sublist']);
  NativeInt8List[dart.metadata] = () => [dart.const(new _js_helper.Native("Int8Array"))];
  class NativeUint16List extends NativeTypedArrayOfInt {
    static new(length) {
      return NativeUint16List._create1(_checkLength(length));
    }
    static fromList(list) {
      return NativeUint16List._create1(_ensureNativeList(list));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length == null ? NativeUint16List._create2(buffer, offsetInBytes) : NativeUint16List._create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Uint16List;
    }
    get(index) {
      this[_checkIndex](index, this.length);
      return this[index];
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      let source = this.subarray(start, end);
      return NativeUint16List._create1(source);
    }
    static _create1(arg) {
      return dart.as(new Uint16Array(arg), NativeUint16List);
    }
    static _create2(arg1, arg2) {
      return dart.as(new Uint16Array(arg1, arg2), NativeUint16List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new Uint16Array(arg1, arg2, arg3), NativeUint16List);
    }
  }
  NativeUint16List[dart.implements] = () => [typed_data.Uint16List];
  dart.setSignature(NativeUint16List, {
    constructors: () => ({
      new: [NativeUint16List, [core.int]],
      fromList: [NativeUint16List, [core.List$(core.int)]],
      view: [NativeUint16List, [typed_data.ByteBuffer, core.int, core.int]]
    }),
    methods: () => ({
      get: [core.int, [core.int]],
      sublist: [core.List$(core.int), [core.int], [core.int]]
    }),
    statics: () => ({
      _create1: [NativeUint16List, [dart.dynamic]],
      _create2: [NativeUint16List, [dart.dynamic, dart.dynamic]],
      _create3: [NativeUint16List, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  dart.defineExtensionMembers(NativeUint16List, ['get', 'sublist']);
  NativeUint16List[dart.metadata] = () => [dart.const(new _js_helper.Native("Uint16Array"))];
  class NativeUint32List extends NativeTypedArrayOfInt {
    static new(length) {
      return NativeUint32List._create1(_checkLength(length));
    }
    static fromList(elements) {
      return NativeUint32List._create1(_ensureNativeList(elements));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length == null ? NativeUint32List._create2(buffer, offsetInBytes) : NativeUint32List._create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Uint32List;
    }
    get(index) {
      this[_checkIndex](index, this.length);
      return this[index];
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      let source = this.subarray(start, end);
      return NativeUint32List._create1(source);
    }
    static _create1(arg) {
      return dart.as(new Uint32Array(arg), NativeUint32List);
    }
    static _create2(arg1, arg2) {
      return dart.as(new Uint32Array(arg1, arg2), NativeUint32List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new Uint32Array(arg1, arg2, arg3), NativeUint32List);
    }
  }
  NativeUint32List[dart.implements] = () => [typed_data.Uint32List];
  dart.setSignature(NativeUint32List, {
    constructors: () => ({
      new: [NativeUint32List, [core.int]],
      fromList: [NativeUint32List, [core.List$(core.int)]],
      view: [NativeUint32List, [typed_data.ByteBuffer, core.int, core.int]]
    }),
    methods: () => ({
      get: [core.int, [core.int]],
      sublist: [core.List$(core.int), [core.int], [core.int]]
    }),
    statics: () => ({
      _create1: [NativeUint32List, [dart.dynamic]],
      _create2: [NativeUint32List, [dart.dynamic, dart.dynamic]],
      _create3: [NativeUint32List, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  dart.defineExtensionMembers(NativeUint32List, ['get', 'sublist']);
  NativeUint32List[dart.metadata] = () => [dart.const(new _js_helper.Native("Uint32Array"))];
  class NativeUint8ClampedList extends NativeTypedArrayOfInt {
    static new(length) {
      return NativeUint8ClampedList._create1(_checkLength(length));
    }
    static fromList(elements) {
      return NativeUint8ClampedList._create1(_ensureNativeList(elements));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length == null ? NativeUint8ClampedList._create2(buffer, offsetInBytes) : NativeUint8ClampedList._create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Uint8ClampedList;
    }
    get length() {
      return this.length;
    }
    get(index) {
      this[_checkIndex](index, this.length);
      return this[index];
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      let source = this.subarray(start, end);
      return NativeUint8ClampedList._create1(source);
    }
    static _create1(arg) {
      return dart.as(new Uint8ClampedArray(arg), NativeUint8ClampedList);
    }
    static _create2(arg1, arg2) {
      return dart.as(new Uint8ClampedArray(arg1, arg2), NativeUint8ClampedList);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new Uint8ClampedArray(arg1, arg2, arg3), NativeUint8ClampedList);
    }
  }
  NativeUint8ClampedList[dart.implements] = () => [typed_data.Uint8ClampedList];
  dart.setSignature(NativeUint8ClampedList, {
    constructors: () => ({
      new: [NativeUint8ClampedList, [core.int]],
      fromList: [NativeUint8ClampedList, [core.List$(core.int)]],
      view: [NativeUint8ClampedList, [typed_data.ByteBuffer, core.int, core.int]]
    }),
    methods: () => ({
      get: [core.int, [core.int]],
      sublist: [core.List$(core.int), [core.int], [core.int]]
    }),
    statics: () => ({
      _create1: [NativeUint8ClampedList, [dart.dynamic]],
      _create2: [NativeUint8ClampedList, [dart.dynamic, dart.dynamic]],
      _create3: [NativeUint8ClampedList, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  dart.defineExtensionMembers(NativeUint8ClampedList, ['get', 'sublist', 'length']);
  NativeUint8ClampedList[dart.metadata] = () => [dart.const(new _js_helper.Native("Uint8ClampedArray,CanvasPixelArray"))];
  class NativeUint8List extends NativeTypedArrayOfInt {
    static new(length) {
      return NativeUint8List._create1(_checkLength(length));
    }
    static fromList(elements) {
      return NativeUint8List._create1(_ensureNativeList(elements));
    }
    static view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length == null ? NativeUint8List._create2(buffer, offsetInBytes) : NativeUint8List._create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Uint8List;
    }
    get length() {
      return this.length;
    }
    get(index) {
      this[_checkIndex](index, this.length);
      return this[index];
    }
    sublist(start, end) {
      if (end === void 0) end = null;
      end = this[_checkSublistArguments](start, end, this.length);
      let source = this.subarray(start, end);
      return NativeUint8List._create1(source);
    }
    static _create1(arg) {
      return dart.as(new Uint8Array(arg), NativeUint8List);
    }
    static _create2(arg1, arg2) {
      return dart.as(new Uint8Array(arg1, arg2), NativeUint8List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(new Uint8Array(arg1, arg2, arg3), NativeUint8List);
    }
  }
  NativeUint8List[dart.implements] = () => [typed_data.Uint8List];
  dart.setSignature(NativeUint8List, {
    constructors: () => ({
      new: [NativeUint8List, [core.int]],
      fromList: [NativeUint8List, [core.List$(core.int)]],
      view: [NativeUint8List, [typed_data.ByteBuffer, core.int, core.int]]
    }),
    methods: () => ({
      get: [core.int, [core.int]],
      sublist: [core.List$(core.int), [core.int], [core.int]]
    }),
    statics: () => ({
      _create1: [NativeUint8List, [dart.dynamic]],
      _create2: [NativeUint8List, [dart.dynamic, dart.dynamic]],
      _create3: [NativeUint8List, [dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['_create1', '_create2', '_create3']
  });
  dart.defineExtensionMembers(NativeUint8List, ['get', 'sublist', 'length']);
  NativeUint8List[dart.metadata] = () => [dart.const(new _js_helper.Native("Uint8Array,!nonleaf"))];
  class NativeFloat32x4 extends core.Object {
    static _truncate(x) {
      NativeFloat32x4._list.set(0, dart.as(x, core.num));
      return NativeFloat32x4._list.get(0);
    }
    NativeFloat32x4(x, y, z, w) {
      this.x = dart.as(NativeFloat32x4._truncate(x), core.double);
      this.y = dart.as(NativeFloat32x4._truncate(y), core.double);
      this.z = dart.as(NativeFloat32x4._truncate(z), core.double);
      this.w = dart.as(NativeFloat32x4._truncate(w), core.double);
      if (!(typeof x == 'number')) dart.throw(new core.ArgumentError(x));
      if (!(typeof y == 'number')) dart.throw(new core.ArgumentError(y));
      if (!(typeof z == 'number')) dart.throw(new core.ArgumentError(z));
      if (!(typeof w == 'number')) dart.throw(new core.ArgumentError(w));
    }
    splat(v) {
      this.NativeFloat32x4(v, v, v, v);
    }
    zero() {
      this._truncated(0.0, 0.0, 0.0, 0.0);
    }
    static fromInt32x4Bits(i) {
      NativeFloat32x4._uint32view.set(0, i.x);
      NativeFloat32x4._uint32view.set(1, i.y);
      NativeFloat32x4._uint32view.set(2, i.z);
      NativeFloat32x4._uint32view.set(3, i.w);
      return new NativeFloat32x4._truncated(NativeFloat32x4._list.get(0), NativeFloat32x4._list.get(1), NativeFloat32x4._list.get(2), NativeFloat32x4._list.get(3));
    }
    fromFloat64x2(v) {
      this._truncated(dart.as(NativeFloat32x4._truncate(v.x), core.double), dart.as(NativeFloat32x4._truncate(v.y), core.double), 0.0, 0.0);
    }
    _doubles(x, y, z, w) {
      this.x = dart.as(NativeFloat32x4._truncate(x), core.double);
      this.y = dart.as(NativeFloat32x4._truncate(y), core.double);
      this.z = dart.as(NativeFloat32x4._truncate(z), core.double);
      this.w = dart.as(NativeFloat32x4._truncate(w), core.double);
    }
    _truncated(x, y, z, w) {
      this.x = x;
      this.y = y;
      this.z = z;
      this.w = w;
    }
    toString() {
      return `[${this.x}, ${this.y}, ${this.z}, ${this.w}]`;
    }
    ['+'](other) {
      let _x = dart.notNull(this.x) + dart.notNull(other.x);
      let _y = dart.notNull(this.y) + dart.notNull(other.y);
      let _z = dart.notNull(this.z) + dart.notNull(other.z);
      let _w = dart.notNull(this.w) + dart.notNull(other.w);
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    ['unary-']() {
      return new NativeFloat32x4._truncated(-dart.notNull(this.x), -dart.notNull(this.y), -dart.notNull(this.z), -dart.notNull(this.w));
    }
    ['-'](other) {
      let _x = dart.notNull(this.x) - dart.notNull(other.x);
      let _y = dart.notNull(this.y) - dart.notNull(other.y);
      let _z = dart.notNull(this.z) - dart.notNull(other.z);
      let _w = dart.notNull(this.w) - dart.notNull(other.w);
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    ['*'](other) {
      let _x = dart.notNull(this.x) * dart.notNull(other.x);
      let _y = dart.notNull(this.y) * dart.notNull(other.y);
      let _z = dart.notNull(this.z) * dart.notNull(other.z);
      let _w = dart.notNull(this.w) * dart.notNull(other.w);
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    ['/'](other) {
      let _x = dart.notNull(this.x) / dart.notNull(other.x);
      let _y = dart.notNull(this.y) / dart.notNull(other.y);
      let _z = dart.notNull(this.z) / dart.notNull(other.z);
      let _w = dart.notNull(this.w) / dart.notNull(other.w);
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    lessThan(other) {
      let _cx = dart.notNull(this.x) < dart.notNull(other.x);
      let _cy = dart.notNull(this.y) < dart.notNull(other.y);
      let _cz = dart.notNull(this.z) < dart.notNull(other.z);
      let _cw = dart.notNull(this.w) < dart.notNull(other.w);
      return new NativeInt32x4._truncated(dart.notNull(_cx) ? -1 : 0, dart.notNull(_cy) ? -1 : 0, dart.notNull(_cz) ? -1 : 0, dart.notNull(_cw) ? -1 : 0);
    }
    lessThanOrEqual(other) {
      let _cx = dart.notNull(this.x) <= dart.notNull(other.x);
      let _cy = dart.notNull(this.y) <= dart.notNull(other.y);
      let _cz = dart.notNull(this.z) <= dart.notNull(other.z);
      let _cw = dart.notNull(this.w) <= dart.notNull(other.w);
      return new NativeInt32x4._truncated(dart.notNull(_cx) ? -1 : 0, dart.notNull(_cy) ? -1 : 0, dart.notNull(_cz) ? -1 : 0, dart.notNull(_cw) ? -1 : 0);
    }
    greaterThan(other) {
      let _cx = dart.notNull(this.x) > dart.notNull(other.x);
      let _cy = dart.notNull(this.y) > dart.notNull(other.y);
      let _cz = dart.notNull(this.z) > dart.notNull(other.z);
      let _cw = dart.notNull(this.w) > dart.notNull(other.w);
      return new NativeInt32x4._truncated(dart.notNull(_cx) ? -1 : 0, dart.notNull(_cy) ? -1 : 0, dart.notNull(_cz) ? -1 : 0, dart.notNull(_cw) ? -1 : 0);
    }
    greaterThanOrEqual(other) {
      let _cx = dart.notNull(this.x) >= dart.notNull(other.x);
      let _cy = dart.notNull(this.y) >= dart.notNull(other.y);
      let _cz = dart.notNull(this.z) >= dart.notNull(other.z);
      let _cw = dart.notNull(this.w) >= dart.notNull(other.w);
      return new NativeInt32x4._truncated(dart.notNull(_cx) ? -1 : 0, dart.notNull(_cy) ? -1 : 0, dart.notNull(_cz) ? -1 : 0, dart.notNull(_cw) ? -1 : 0);
    }
    equal(other) {
      let _cx = this.x == other.x;
      let _cy = this.y == other.y;
      let _cz = this.z == other.z;
      let _cw = this.w == other.w;
      return new NativeInt32x4._truncated(dart.notNull(_cx) ? -1 : 0, dart.notNull(_cy) ? -1 : 0, dart.notNull(_cz) ? -1 : 0, dart.notNull(_cw) ? -1 : 0);
    }
    notEqual(other) {
      let _cx = this.x != other.x;
      let _cy = this.y != other.y;
      let _cz = this.z != other.z;
      let _cw = this.w != other.w;
      return new NativeInt32x4._truncated(dart.notNull(_cx) ? -1 : 0, dart.notNull(_cy) ? -1 : 0, dart.notNull(_cz) ? -1 : 0, dart.notNull(_cw) ? -1 : 0);
    }
    scale(s) {
      let _x = dart.notNull(s) * dart.notNull(this.x);
      let _y = dart.notNull(s) * dart.notNull(this.y);
      let _z = dart.notNull(s) * dart.notNull(this.z);
      let _w = dart.notNull(s) * dart.notNull(this.w);
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    abs() {
      let _x = this.x[dartx.abs]();
      let _y = this.y[dartx.abs]();
      let _z = this.z[dartx.abs]();
      let _w = this.w[dartx.abs]();
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    clamp(lowerLimit, upperLimit) {
      let _lx = lowerLimit.x;
      let _ly = lowerLimit.y;
      let _lz = lowerLimit.z;
      let _lw = lowerLimit.w;
      let _ux = upperLimit.x;
      let _uy = upperLimit.y;
      let _uz = upperLimit.z;
      let _uw = upperLimit.w;
      let _x = this.x;
      let _y = this.y;
      let _z = this.z;
      let _w = this.w;
      _x = dart.notNull(_x) > dart.notNull(_ux) ? _ux : _x;
      _y = dart.notNull(_y) > dart.notNull(_uy) ? _uy : _y;
      _z = dart.notNull(_z) > dart.notNull(_uz) ? _uz : _z;
      _w = dart.notNull(_w) > dart.notNull(_uw) ? _uw : _w;
      _x = dart.notNull(_x) < dart.notNull(_lx) ? _lx : _x;
      _y = dart.notNull(_y) < dart.notNull(_ly) ? _ly : _y;
      _z = dart.notNull(_z) < dart.notNull(_lz) ? _lz : _z;
      _w = dart.notNull(_w) < dart.notNull(_lw) ? _lw : _w;
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    get signMask() {
      let view = NativeFloat32x4._uint32view;
      let mx = null, my = null, mz = null, mw = null;
      NativeFloat32x4._list.set(0, this.x);
      NativeFloat32x4._list.set(1, this.y);
      NativeFloat32x4._list.set(2, this.z);
      NativeFloat32x4._list.set(3, this.w);
      mx = (dart.notNull(view.get(0)) & 2147483648) >> 31;
      my = (dart.notNull(view.get(1)) & 2147483648) >> 30;
      mz = (dart.notNull(view.get(2)) & 2147483648) >> 29;
      mw = (dart.notNull(view.get(3)) & 2147483648) >> 28;
      return dart.as(dart.dsend(dart.dsend(dart.dsend(mx, '|', my), '|', mz), '|', mw), core.int);
    }
    shuffle(m) {
      if (dart.notNull(m) < 0 || dart.notNull(m) > 255) {
        dart.throw(new core.RangeError(`mask ${m} must be in the range [0..256)`));
      }
      NativeFloat32x4._list.set(0, this.x);
      NativeFloat32x4._list.set(1, this.y);
      NativeFloat32x4._list.set(2, this.z);
      NativeFloat32x4._list.set(3, this.w);
      let _x = NativeFloat32x4._list.get(dart.notNull(m) & 3);
      let _y = NativeFloat32x4._list.get(dart.notNull(m) >> 2 & 3);
      let _z = NativeFloat32x4._list.get(dart.notNull(m) >> 4 & 3);
      let _w = NativeFloat32x4._list.get(dart.notNull(m) >> 6 & 3);
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    shuffleMix(other, m) {
      if (dart.notNull(m) < 0 || dart.notNull(m) > 255) {
        dart.throw(new core.RangeError(`mask ${m} must be in the range [0..256)`));
      }
      NativeFloat32x4._list.set(0, this.x);
      NativeFloat32x4._list.set(1, this.y);
      NativeFloat32x4._list.set(2, this.z);
      NativeFloat32x4._list.set(3, this.w);
      let _x = NativeFloat32x4._list.get(dart.notNull(m) & 3);
      let _y = NativeFloat32x4._list.get(dart.notNull(m) >> 2 & 3);
      NativeFloat32x4._list.set(0, other.x);
      NativeFloat32x4._list.set(1, other.y);
      NativeFloat32x4._list.set(2, other.z);
      NativeFloat32x4._list.set(3, other.w);
      let _z = NativeFloat32x4._list.get(dart.notNull(m) >> 4 & 3);
      let _w = NativeFloat32x4._list.get(dart.notNull(m) >> 6 & 3);
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    withX(newX) {
      return new NativeFloat32x4._truncated(dart.as(NativeFloat32x4._truncate(newX), core.double), this.y, this.z, this.w);
    }
    withY(newY) {
      return new NativeFloat32x4._truncated(this.x, dart.as(NativeFloat32x4._truncate(newY), core.double), this.z, this.w);
    }
    withZ(newZ) {
      return new NativeFloat32x4._truncated(this.x, this.y, dart.as(NativeFloat32x4._truncate(newZ), core.double), this.w);
    }
    withW(newW) {
      return new NativeFloat32x4._truncated(this.x, this.y, this.z, dart.as(NativeFloat32x4._truncate(newW), core.double));
    }
    min(other) {
      let _x = dart.notNull(this.x) < dart.notNull(other.x) ? this.x : other.x;
      let _y = dart.notNull(this.y) < dart.notNull(other.y) ? this.y : other.y;
      let _z = dart.notNull(this.z) < dart.notNull(other.z) ? this.z : other.z;
      let _w = dart.notNull(this.w) < dart.notNull(other.w) ? this.w : other.w;
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    max(other) {
      let _x = dart.notNull(this.x) > dart.notNull(other.x) ? this.x : other.x;
      let _y = dart.notNull(this.y) > dart.notNull(other.y) ? this.y : other.y;
      let _z = dart.notNull(this.z) > dart.notNull(other.z) ? this.z : other.z;
      let _w = dart.notNull(this.w) > dart.notNull(other.w) ? this.w : other.w;
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    sqrt() {
      let _x = math.sqrt(this.x);
      let _y = math.sqrt(this.y);
      let _z = math.sqrt(this.z);
      let _w = math.sqrt(this.w);
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    reciprocal() {
      let _x = 1.0 / dart.notNull(this.x);
      let _y = 1.0 / dart.notNull(this.y);
      let _z = 1.0 / dart.notNull(this.z);
      let _w = 1.0 / dart.notNull(this.w);
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    reciprocalSqrt() {
      let _x = math.sqrt(1.0 / dart.notNull(this.x));
      let _y = math.sqrt(1.0 / dart.notNull(this.y));
      let _z = math.sqrt(1.0 / dart.notNull(this.z));
      let _w = math.sqrt(1.0 / dart.notNull(this.w));
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
  }
  NativeFloat32x4[dart.implements] = () => [typed_data.Float32x4];
  dart.defineNamedConstructor(NativeFloat32x4, 'splat');
  dart.defineNamedConstructor(NativeFloat32x4, 'zero');
  dart.defineNamedConstructor(NativeFloat32x4, 'fromFloat64x2');
  dart.defineNamedConstructor(NativeFloat32x4, '_doubles');
  dart.defineNamedConstructor(NativeFloat32x4, '_truncated');
  dart.setSignature(NativeFloat32x4, {
    constructors: () => ({
      NativeFloat32x4: [NativeFloat32x4, [core.double, core.double, core.double, core.double]],
      splat: [NativeFloat32x4, [core.double]],
      zero: [NativeFloat32x4, []],
      fromInt32x4Bits: [NativeFloat32x4, [typed_data.Int32x4]],
      fromFloat64x2: [NativeFloat32x4, [typed_data.Float64x2]],
      _doubles: [NativeFloat32x4, [core.double, core.double, core.double, core.double]],
      _truncated: [NativeFloat32x4, [core.double, core.double, core.double, core.double]]
    }),
    methods: () => ({
      '+': [typed_data.Float32x4, [typed_data.Float32x4]],
      'unary-': [typed_data.Float32x4, []],
      '-': [typed_data.Float32x4, [typed_data.Float32x4]],
      '*': [typed_data.Float32x4, [typed_data.Float32x4]],
      '/': [typed_data.Float32x4, [typed_data.Float32x4]],
      lessThan: [typed_data.Int32x4, [typed_data.Float32x4]],
      lessThanOrEqual: [typed_data.Int32x4, [typed_data.Float32x4]],
      greaterThan: [typed_data.Int32x4, [typed_data.Float32x4]],
      greaterThanOrEqual: [typed_data.Int32x4, [typed_data.Float32x4]],
      equal: [typed_data.Int32x4, [typed_data.Float32x4]],
      notEqual: [typed_data.Int32x4, [typed_data.Float32x4]],
      scale: [typed_data.Float32x4, [core.double]],
      abs: [typed_data.Float32x4, []],
      clamp: [typed_data.Float32x4, [typed_data.Float32x4, typed_data.Float32x4]],
      shuffle: [typed_data.Float32x4, [core.int]],
      shuffleMix: [typed_data.Float32x4, [typed_data.Float32x4, core.int]],
      withX: [typed_data.Float32x4, [core.double]],
      withY: [typed_data.Float32x4, [core.double]],
      withZ: [typed_data.Float32x4, [core.double]],
      withW: [typed_data.Float32x4, [core.double]],
      min: [typed_data.Float32x4, [typed_data.Float32x4]],
      max: [typed_data.Float32x4, [typed_data.Float32x4]],
      sqrt: [typed_data.Float32x4, []],
      reciprocal: [typed_data.Float32x4, []],
      reciprocalSqrt: [typed_data.Float32x4, []]
    }),
    statics: () => ({_truncate: [dart.dynamic, [dart.dynamic]]}),
    names: ['_truncate']
  });
  dart.defineLazyProperties(NativeFloat32x4, {
    get _list() {
      return NativeFloat32List.new(4);
    },
    get _uint32view() {
      return NativeFloat32x4._list.buffer.asUint32List();
    }
  });
  class NativeInt32x4 extends core.Object {
    static _truncate(x) {
      NativeInt32x4._list.set(0, dart.as(x, core.int));
      return NativeInt32x4._list.get(0);
    }
    NativeInt32x4(x, y, z, w) {
      this.x = dart.as(NativeInt32x4._truncate(x), core.int);
      this.y = dart.as(NativeInt32x4._truncate(y), core.int);
      this.z = dart.as(NativeInt32x4._truncate(z), core.int);
      this.w = dart.as(NativeInt32x4._truncate(w), core.int);
      if (x != this.x && !(typeof x == 'number')) dart.throw(new core.ArgumentError(x));
      if (y != this.y && !(typeof y == 'number')) dart.throw(new core.ArgumentError(y));
      if (z != this.z && !(typeof z == 'number')) dart.throw(new core.ArgumentError(z));
      if (w != this.w && !(typeof w == 'number')) dart.throw(new core.ArgumentError(w));
    }
    bool(x, y, z, w) {
      this.x = dart.notNull(x) ? -1 : 0;
      this.y = dart.notNull(y) ? -1 : 0;
      this.z = dart.notNull(z) ? -1 : 0;
      this.w = dart.notNull(w) ? -1 : 0;
    }
    static fromFloat32x4Bits(f) {
      let floatList = NativeFloat32x4._list;
      floatList.set(0, f.x);
      floatList.set(1, f.y);
      floatList.set(2, f.z);
      floatList.set(3, f.w);
      let view = dart.as(floatList.buffer.asInt32List(), NativeInt32List);
      return new NativeInt32x4._truncated(view.get(0), view.get(1), view.get(2), view.get(3));
    }
    _truncated(x, y, z, w) {
      this.x = x;
      this.y = y;
      this.z = z;
      this.w = w;
    }
    toString() {
      return `[${this.x}, ${this.y}, ${this.z}, ${this.w}]`;
    }
    ['|'](other) {
      return new NativeInt32x4._truncated(this.x | other.x, this.y | other.y, this.z | other.z, this.w | other.w);
    }
    ['&'](other) {
      return new NativeInt32x4._truncated(this.x & other.x, this.y & other.y, this.z & other.z, this.w & other.w);
    }
    ['^'](other) {
      return new NativeInt32x4._truncated(this.x ^ other.x, this.y ^ other.y, this.z ^ other.z, this.w ^ other.w);
    }
    ['+'](other) {
      return new NativeInt32x4._truncated(this.x + other.x | 0, this.y + other.y | 0, this.z + other.z | 0, this.w + other.w | 0);
    }
    ['-'](other) {
      return new NativeInt32x4._truncated(this.x - other.x | 0, this.y - other.y | 0, this.z - other.z | 0, this.w - other.w | 0);
    }
    ['unary-']() {
      return new NativeInt32x4._truncated(-this.x | 0, -this.y | 0, -this.z | 0, -this.w | 0);
    }
    get signMask() {
      let mx = (dart.notNull(this.x) & 2147483648) >> 31;
      let my = (dart.notNull(this.y) & 2147483648) >> 31;
      let mz = (dart.notNull(this.z) & 2147483648) >> 31;
      let mw = (dart.notNull(this.w) & 2147483648) >> 31;
      return dart.notNull(mx) | dart.notNull(my) << 1 | dart.notNull(mz) << 2 | dart.notNull(mw) << 3;
    }
    shuffle(mask) {
      if (dart.notNull(mask) < 0 || dart.notNull(mask) > 255) {
        dart.throw(new core.RangeError(`mask ${mask} must be in the range [0..256)`));
      }
      NativeInt32x4._list.set(0, this.x);
      NativeInt32x4._list.set(1, this.y);
      NativeInt32x4._list.set(2, this.z);
      NativeInt32x4._list.set(3, this.w);
      let _x = NativeInt32x4._list.get(dart.notNull(mask) & 3);
      let _y = NativeInt32x4._list.get(dart.notNull(mask) >> 2 & 3);
      let _z = NativeInt32x4._list.get(dart.notNull(mask) >> 4 & 3);
      let _w = NativeInt32x4._list.get(dart.notNull(mask) >> 6 & 3);
      return new NativeInt32x4._truncated(_x, _y, _z, _w);
    }
    shuffleMix(other, mask) {
      if (dart.notNull(mask) < 0 || dart.notNull(mask) > 255) {
        dart.throw(new core.RangeError(`mask ${mask} must be in the range [0..256)`));
      }
      NativeInt32x4._list.set(0, this.x);
      NativeInt32x4._list.set(1, this.y);
      NativeInt32x4._list.set(2, this.z);
      NativeInt32x4._list.set(3, this.w);
      let _x = NativeInt32x4._list.get(dart.notNull(mask) & 3);
      let _y = NativeInt32x4._list.get(dart.notNull(mask) >> 2 & 3);
      NativeInt32x4._list.set(0, other.x);
      NativeInt32x4._list.set(1, other.y);
      NativeInt32x4._list.set(2, other.z);
      NativeInt32x4._list.set(3, other.w);
      let _z = NativeInt32x4._list.get(dart.notNull(mask) >> 4 & 3);
      let _w = NativeInt32x4._list.get(dart.notNull(mask) >> 6 & 3);
      return new NativeInt32x4._truncated(_x, _y, _z, _w);
    }
    withX(x) {
      let _x = dart.as(NativeInt32x4._truncate(x), core.int);
      return new NativeInt32x4._truncated(_x, this.y, this.z, this.w);
    }
    withY(y) {
      let _y = dart.as(NativeInt32x4._truncate(y), core.int);
      return new NativeInt32x4._truncated(this.x, _y, this.z, this.w);
    }
    withZ(z) {
      let _z = dart.as(NativeInt32x4._truncate(z), core.int);
      return new NativeInt32x4._truncated(this.x, this.y, _z, this.w);
    }
    withW(w) {
      let _w = dart.as(NativeInt32x4._truncate(w), core.int);
      return new NativeInt32x4._truncated(this.x, this.y, this.z, _w);
    }
    get flagX() {
      return this.x != 0;
    }
    get flagY() {
      return this.y != 0;
    }
    get flagZ() {
      return this.z != 0;
    }
    get flagW() {
      return this.w != 0;
    }
    withFlagX(flagX) {
      let _x = dart.notNull(flagX) ? -1 : 0;
      return new NativeInt32x4._truncated(_x, this.y, this.z, this.w);
    }
    withFlagY(flagY) {
      let _y = dart.notNull(flagY) ? -1 : 0;
      return new NativeInt32x4._truncated(this.x, _y, this.z, this.w);
    }
    withFlagZ(flagZ) {
      let _z = dart.notNull(flagZ) ? -1 : 0;
      return new NativeInt32x4._truncated(this.x, this.y, _z, this.w);
    }
    withFlagW(flagW) {
      let _w = dart.notNull(flagW) ? -1 : 0;
      return new NativeInt32x4._truncated(this.x, this.y, this.z, _w);
    }
    select(trueValue, falseValue) {
      let floatList = NativeFloat32x4._list;
      let intView = NativeFloat32x4._uint32view;
      floatList.set(0, trueValue.x);
      floatList.set(1, trueValue.y);
      floatList.set(2, trueValue.z);
      floatList.set(3, trueValue.w);
      let stx = intView.get(0);
      let sty = intView.get(1);
      let stz = intView.get(2);
      let stw = intView.get(3);
      floatList.set(0, falseValue.x);
      floatList.set(1, falseValue.y);
      floatList.set(2, falseValue.z);
      floatList.set(3, falseValue.w);
      let sfx = intView.get(0);
      let sfy = intView.get(1);
      let sfz = intView.get(2);
      let sfw = intView.get(3);
      let _x = dart.notNull(this.x) & dart.notNull(stx) | ~dart.notNull(this.x) & dart.notNull(sfx);
      let _y = dart.notNull(this.y) & dart.notNull(sty) | ~dart.notNull(this.y) & dart.notNull(sfy);
      let _z = dart.notNull(this.z) & dart.notNull(stz) | ~dart.notNull(this.z) & dart.notNull(sfz);
      let _w = dart.notNull(this.w) & dart.notNull(stw) | ~dart.notNull(this.w) & dart.notNull(sfw);
      intView.set(0, _x);
      intView.set(1, _y);
      intView.set(2, _z);
      intView.set(3, _w);
      return new NativeFloat32x4._truncated(floatList.get(0), floatList.get(1), floatList.get(2), floatList.get(3));
    }
  }
  NativeInt32x4[dart.implements] = () => [typed_data.Int32x4];
  dart.defineNamedConstructor(NativeInt32x4, 'bool');
  dart.defineNamedConstructor(NativeInt32x4, '_truncated');
  dart.setSignature(NativeInt32x4, {
    constructors: () => ({
      NativeInt32x4: [NativeInt32x4, [core.int, core.int, core.int, core.int]],
      bool: [NativeInt32x4, [core.bool, core.bool, core.bool, core.bool]],
      fromFloat32x4Bits: [NativeInt32x4, [typed_data.Float32x4]],
      _truncated: [NativeInt32x4, [core.int, core.int, core.int, core.int]]
    }),
    methods: () => ({
      '|': [typed_data.Int32x4, [typed_data.Int32x4]],
      '&': [typed_data.Int32x4, [typed_data.Int32x4]],
      '^': [typed_data.Int32x4, [typed_data.Int32x4]],
      '+': [typed_data.Int32x4, [typed_data.Int32x4]],
      '-': [typed_data.Int32x4, [typed_data.Int32x4]],
      'unary-': [typed_data.Int32x4, []],
      shuffle: [typed_data.Int32x4, [core.int]],
      shuffleMix: [typed_data.Int32x4, [typed_data.Int32x4, core.int]],
      withX: [typed_data.Int32x4, [core.int]],
      withY: [typed_data.Int32x4, [core.int]],
      withZ: [typed_data.Int32x4, [core.int]],
      withW: [typed_data.Int32x4, [core.int]],
      withFlagX: [typed_data.Int32x4, [core.bool]],
      withFlagY: [typed_data.Int32x4, [core.bool]],
      withFlagZ: [typed_data.Int32x4, [core.bool]],
      withFlagW: [typed_data.Int32x4, [core.bool]],
      select: [typed_data.Float32x4, [typed_data.Float32x4, typed_data.Float32x4]]
    }),
    statics: () => ({_truncate: [dart.dynamic, [dart.dynamic]]}),
    names: ['_truncate']
  });
  dart.defineLazyProperties(NativeInt32x4, {
    get _list() {
      return NativeInt32List.new(4);
    }
  });
  class NativeFloat64x2 extends core.Object {
    NativeFloat64x2(x, y) {
      this.x = x;
      this.y = y;
      if (!(typeof this.x == 'number')) dart.throw(new core.ArgumentError(this.x));
      if (!(typeof this.y == 'number')) dart.throw(new core.ArgumentError(this.y));
    }
    splat(v) {
      this.NativeFloat64x2(v, v);
    }
    zero() {
      this.splat(0.0);
    }
    fromFloat32x4(v) {
      this.NativeFloat64x2(v.x, v.y);
    }
    _doubles(x, y) {
      this.x = x;
      this.y = y;
    }
    toString() {
      return `[${this.x}, ${this.y}]`;
    }
    ['+'](other) {
      return new NativeFloat64x2._doubles(dart.notNull(this.x) + dart.notNull(other.x), dart.notNull(this.y) + dart.notNull(other.y));
    }
    ['unary-']() {
      return new NativeFloat64x2._doubles(-dart.notNull(this.x), -dart.notNull(this.y));
    }
    ['-'](other) {
      return new NativeFloat64x2._doubles(dart.notNull(this.x) - dart.notNull(other.x), dart.notNull(this.y) - dart.notNull(other.y));
    }
    ['*'](other) {
      return new NativeFloat64x2._doubles(dart.notNull(this.x) * dart.notNull(other.x), dart.notNull(this.y) * dart.notNull(other.y));
    }
    ['/'](other) {
      return new NativeFloat64x2._doubles(dart.notNull(this.x) / dart.notNull(other.x), dart.notNull(this.y) / dart.notNull(other.y));
    }
    scale(s) {
      return new NativeFloat64x2._doubles(dart.notNull(this.x) * dart.notNull(s), dart.notNull(this.y) * dart.notNull(s));
    }
    abs() {
      return new NativeFloat64x2._doubles(this.x[dartx.abs](), this.y[dartx.abs]());
    }
    clamp(lowerLimit, upperLimit) {
      let _lx = lowerLimit.x;
      let _ly = lowerLimit.y;
      let _ux = upperLimit.x;
      let _uy = upperLimit.y;
      let _x = this.x;
      let _y = this.y;
      _x = dart.notNull(_x) > dart.notNull(_ux) ? _ux : _x;
      _y = dart.notNull(_y) > dart.notNull(_uy) ? _uy : _y;
      _x = dart.notNull(_x) < dart.notNull(_lx) ? _lx : _x;
      _y = dart.notNull(_y) < dart.notNull(_ly) ? _ly : _y;
      return new NativeFloat64x2._doubles(_x, _y);
    }
    get signMask() {
      let view = NativeFloat64x2._uint32View;
      NativeFloat64x2._list.set(0, this.x);
      NativeFloat64x2._list.set(1, this.y);
      let mx = (dart.notNull(view.get(1)) & 2147483648) >> 31;
      let my = (dart.notNull(view.get(3)) & 2147483648) >> 31;
      return dart.notNull(mx) | dart.notNull(my) << 1;
    }
    withX(x) {
      if (!(typeof x == 'number')) dart.throw(new core.ArgumentError(x));
      return new NativeFloat64x2._doubles(x, this.y);
    }
    withY(y) {
      if (!(typeof y == 'number')) dart.throw(new core.ArgumentError(y));
      return new NativeFloat64x2._doubles(this.x, y);
    }
    min(other) {
      return new NativeFloat64x2._doubles(dart.notNull(this.x) < dart.notNull(other.x) ? this.x : other.x, dart.notNull(this.y) < dart.notNull(other.y) ? this.y : other.y);
    }
    max(other) {
      return new NativeFloat64x2._doubles(dart.notNull(this.x) > dart.notNull(other.x) ? this.x : other.x, dart.notNull(this.y) > dart.notNull(other.y) ? this.y : other.y);
    }
    sqrt() {
      return new NativeFloat64x2._doubles(math.sqrt(this.x), math.sqrt(this.y));
    }
  }
  NativeFloat64x2[dart.implements] = () => [typed_data.Float64x2];
  dart.defineNamedConstructor(NativeFloat64x2, 'splat');
  dart.defineNamedConstructor(NativeFloat64x2, 'zero');
  dart.defineNamedConstructor(NativeFloat64x2, 'fromFloat32x4');
  dart.defineNamedConstructor(NativeFloat64x2, '_doubles');
  dart.setSignature(NativeFloat64x2, {
    constructors: () => ({
      NativeFloat64x2: [NativeFloat64x2, [core.double, core.double]],
      splat: [NativeFloat64x2, [core.double]],
      zero: [NativeFloat64x2, []],
      fromFloat32x4: [NativeFloat64x2, [typed_data.Float32x4]],
      _doubles: [NativeFloat64x2, [core.double, core.double]]
    }),
    methods: () => ({
      '+': [typed_data.Float64x2, [typed_data.Float64x2]],
      'unary-': [typed_data.Float64x2, []],
      '-': [typed_data.Float64x2, [typed_data.Float64x2]],
      '*': [typed_data.Float64x2, [typed_data.Float64x2]],
      '/': [typed_data.Float64x2, [typed_data.Float64x2]],
      scale: [typed_data.Float64x2, [core.double]],
      abs: [typed_data.Float64x2, []],
      clamp: [typed_data.Float64x2, [typed_data.Float64x2, typed_data.Float64x2]],
      withX: [typed_data.Float64x2, [core.double]],
      withY: [typed_data.Float64x2, [core.double]],
      min: [typed_data.Float64x2, [typed_data.Float64x2]],
      max: [typed_data.Float64x2, [typed_data.Float64x2]],
      sqrt: [typed_data.Float64x2, []]
    })
  });
  dart.defineLazyProperties(NativeFloat64x2, {
    get _list() {
      return NativeFloat64List.new(2);
    },
    set _list(_) {},
    get _uint32View() {
      return dart.as(NativeFloat64x2._list.buffer.asUint32List(), NativeUint32List);
    },
    set _uint32View(_) {}
  });
  // Exports:
  exports.NativeByteBuffer = NativeByteBuffer;
  exports.NativeFloat32x4List = NativeFloat32x4List;
  exports.NativeInt32x4List = NativeInt32x4List;
  exports.NativeFloat64x2List = NativeFloat64x2List;
  exports.NativeTypedData = NativeTypedData;
  exports.NativeByteData = NativeByteData;
  exports.NativeTypedArray = NativeTypedArray;
  exports.NativeTypedArrayOfDouble = NativeTypedArrayOfDouble;
  exports.NativeTypedArrayOfInt = NativeTypedArrayOfInt;
  exports.NativeFloat32List = NativeFloat32List;
  exports.NativeFloat64List = NativeFloat64List;
  exports.NativeInt16List = NativeInt16List;
  exports.NativeInt32List = NativeInt32List;
  exports.NativeInt8List = NativeInt8List;
  exports.NativeUint16List = NativeUint16List;
  exports.NativeUint32List = NativeUint32List;
  exports.NativeUint8ClampedList = NativeUint8ClampedList;
  exports.NativeUint8List = NativeUint8List;
  exports.NativeFloat32x4 = NativeFloat32x4;
  exports.NativeInt32x4 = NativeInt32x4;
  exports.NativeFloat64x2 = NativeFloat64x2;
});
