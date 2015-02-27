var _native_typed_data;
(function(_native_typed_data) {
  'use strict';
  class NativeByteBuffer extends dart.Object {
    NativeByteBuffer() {
      this.lengthInBytes = dart.as(null, core.int);
    }
    get runtimeType() {
      return typed_data.ByteBuffer;
    }
    asUint8List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeUint8List.view(this, offsetInBytes, length);
    }
    asInt8List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeInt8List.view(this, offsetInBytes, length);
    }
    asUint8ClampedList(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeUint8ClampedList.view(this, offsetInBytes, length);
    }
    asUint16List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeUint16List.view(this, offsetInBytes, length);
    }
    asInt16List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeInt16List.view(this, offsetInBytes, length);
    }
    asUint32List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeUint32List.view(this, offsetInBytes, length);
    }
    asInt32List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeInt32List.view(this, offsetInBytes, length);
    }
    asUint64List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      throw new core.UnsupportedError("Uint64List not supported by dart2js.");
    }
    asInt64List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      throw new core.UnsupportedError("Int64List not supported by dart2js.");
    }
    asInt32x4List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      let storage = dart.as(this.asInt32List(offsetInBytes, dart.as(length !== null ? length * 4 : null, core.int)), NativeInt32List);
      return new NativeInt32x4List._externalStorage(storage);
    }
    asFloat32List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeFloat32List.view(this, offsetInBytes, length);
    }
    asFloat64List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeFloat64List.view(this, offsetInBytes, length);
    }
    asFloat32x4List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      let storage = dart.as(this.asFloat32List(offsetInBytes, dart.as(length !== null ? length * 4 : null, core.int)), NativeFloat32List);
      return new NativeFloat32x4List._externalStorage(storage);
    }
    asFloat64x2List(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      let storage = dart.as(this.asFloat64List(offsetInBytes, dart.as(length !== null ? length * 2 : null, core.int)), NativeFloat64List);
      return new NativeFloat64x2List._externalStorage(storage);
    }
    asByteData(offsetInBytes, length) {
      if (offsetInBytes === void 0)
        offsetInBytes = 0;
      if (length === void 0)
        length = null;
      return new NativeByteData.view(this, offsetInBytes, length);
    }
  }
  class NativeFloat32x4List extends dart.mixin(core.Object, collection.ListMixin$(typed_data.Float32x4), _internal.FixedLengthListMixin$(typed_data.Float32x4)) {
    NativeFloat32x4List(length) {
      this._storage = new NativeFloat32List(length * 4);
    }
    NativeFloat32x4List$_externalStorage(_storage) {
      this._storage = _storage;
    }
    NativeFloat32x4List$_slowFromList(list) {
      this._storage = new NativeFloat32List(list.length * 4);
      for (let i = 0; i < list.length; i++) {
        let e = list.get(i);
        this._storage.set(i * 4 + 0, e.x);
        this._storage.set(i * 4 + 1, e.y);
        this._storage.set(i * 4 + 2, e.z);
        this._storage.set(i * 4 + 3, e.w);
      }
    }
    get runtimeType() {
      return typed_data.Float32x4List;
    }
    NativeFloat32x4List$fromList(list) {
      if (dart.is(list, NativeFloat32x4List)) {
        return new NativeFloat32x4List._externalStorage(new NativeFloat32List.fromList(list._storage));
      } else {
        return new NativeFloat32x4List._slowFromList(list);
      }
    }
    get buffer() {
      return this._storage.buffer;
    }
    get lengthInBytes() {
      return this._storage.lengthInBytes;
    }
    get offsetInBytes() {
      return this._storage.offsetInBytes;
    }
    get elementSizeInBytes() {
      return typed_data.Float32x4List.BYTES_PER_ELEMENT;
    }
    _invalidIndex(index, length) {
      if (dart.notNull(index < 0) || dart.notNull(index >= length)) {
        if (length === this.length) {
          throw new core.RangeError.index(index, this);
        }
        throw new core.RangeError.range(index, 0, length - 1);
      } else {
        throw new core.ArgumentError(`Invalid list index ${index}`);
      }
    }
    _checkIndex(index, length) {
      if (dart.dbinary(_foreign_helper.JS('bool', '(# >>> 0 != #)', index, index), '||', index >= length)) {
        this._invalidIndex(index, length);
      }
    }
    _checkSublistArguments(start, end, length) {
      this._checkIndex(start, length + 1);
      if (end === null)
        return length;
      this._checkIndex(end, length + 1);
      if (start > end)
        throw new core.RangeError.range(start, 0, end);
      return end;
    }
    get length() {
      return (this._storage.length / 4).truncate();
    }
    get(index) {
      this._checkIndex(index, this.length);
      let _x = dart.notNull(this._storage.get(index * 4 + 0));
      let _y = dart.notNull(this._storage.get(index * 4 + 1));
      let _z = dart.notNull(this._storage.get(index * 4 + 2));
      let _w = dart.notNull(this._storage.get(index * 4 + 3));
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    set(index, value) {
      this._checkIndex(index, this.length);
      this._storage.set(index * 4 + 0, value.x);
      this._storage.set(index * 4 + 1, value.y);
      this._storage.set(index * 4 + 2, value.z);
      this._storage.set(index * 4 + 3, value.w);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      return new NativeFloat32x4List._externalStorage(dart.as(this._storage.sublist(start * 4, end * 4), NativeFloat32List));
    }
  }
  dart.defineNamedConstructor(NativeFloat32x4List, '_externalStorage');
  dart.defineNamedConstructor(NativeFloat32x4List, '_slowFromList');
  dart.defineNamedConstructor(NativeFloat32x4List, 'fromList');
  class NativeInt32x4List extends dart.mixin(core.Object, collection.ListMixin$(typed_data.Int32x4), _internal.FixedLengthListMixin$(typed_data.Int32x4)) {
    NativeInt32x4List(length) {
      this._storage = new NativeInt32List(length * 4);
    }
    NativeInt32x4List$_externalStorage(storage) {
      this._storage = storage;
    }
    NativeInt32x4List$_slowFromList(list) {
      this._storage = new NativeInt32List(list.length * 4);
      for (let i = 0; i < list.length; i++) {
        let e = list.get(i);
        this._storage.set(i * 4 + 0, e.x);
        this._storage.set(i * 4 + 1, e.y);
        this._storage.set(i * 4 + 2, e.z);
        this._storage.set(i * 4 + 3, e.w);
      }
    }
    get runtimeType() {
      return typed_data.Int32x4List;
    }
    NativeInt32x4List$fromList(list) {
      if (dart.is(list, NativeInt32x4List)) {
        return new NativeInt32x4List._externalStorage(new NativeInt32List.fromList(list._storage));
      } else {
        return new NativeInt32x4List._slowFromList(list);
      }
    }
    get buffer() {
      return this._storage.buffer;
    }
    get lengthInBytes() {
      return this._storage.lengthInBytes;
    }
    get offsetInBytes() {
      return this._storage.offsetInBytes;
    }
    get elementSizeInBytes() {
      return typed_data.Int32x4List.BYTES_PER_ELEMENT;
    }
    _invalidIndex(index, length) {
      if (dart.notNull(index < 0) || dart.notNull(index >= length)) {
        if (length === this.length) {
          throw new core.RangeError.index(index, this);
        }
        throw new core.RangeError.range(index, 0, length - 1);
      } else {
        throw new core.ArgumentError(`Invalid list index ${index}`);
      }
    }
    _checkIndex(index, length) {
      if (dart.dbinary(_foreign_helper.JS('bool', '(# >>> 0 != #)', index, index), '||', _foreign_helper.JS('bool', '# >= #', index, length))) {
        this._invalidIndex(index, length);
      }
    }
    _checkSublistArguments(start, end, length) {
      this._checkIndex(start, length + 1);
      if (end === null)
        return length;
      this._checkIndex(end, length + 1);
      if (start > end)
        throw new core.RangeError.range(start, 0, end);
      return end;
    }
    get length() {
      return (this._storage.length / 4).truncate();
    }
    get(index) {
      this._checkIndex(index, this.length);
      let _x = this._storage.get(index * 4 + 0);
      let _y = this._storage.get(index * 4 + 1);
      let _z = this._storage.get(index * 4 + 2);
      let _w = this._storage.get(index * 4 + 3);
      return new NativeInt32x4._truncated(_x, _y, _z, _w);
    }
    set(index, value) {
      this._checkIndex(index, this.length);
      this._storage.set(index * 4 + 0, value.x);
      this._storage.set(index * 4 + 1, value.y);
      this._storage.set(index * 4 + 2, value.z);
      this._storage.set(index * 4 + 3, value.w);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      return new NativeInt32x4List._externalStorage(dart.as(this._storage.sublist(start * 4, end * 4), typed_data.Int32List));
    }
  }
  dart.defineNamedConstructor(NativeInt32x4List, '_externalStorage');
  dart.defineNamedConstructor(NativeInt32x4List, '_slowFromList');
  dart.defineNamedConstructor(NativeInt32x4List, 'fromList');
  class NativeFloat64x2List extends dart.mixin(core.Object, collection.ListMixin$(typed_data.Float64x2), _internal.FixedLengthListMixin$(typed_data.Float64x2)) {
    NativeFloat64x2List(length) {
      this._storage = new NativeFloat64List(length * 2);
    }
    NativeFloat64x2List$_externalStorage(_storage) {
      this._storage = _storage;
    }
    NativeFloat64x2List$_slowFromList(list) {
      this._storage = new NativeFloat64List(list.length * 2);
      for (let i = 0; i < list.length; i++) {
        let e = list.get(i);
        this._storage.set(i * 2 + 0, e.x);
        this._storage.set(i * 2 + 1, e.y);
      }
    }
    NativeFloat64x2List$fromList(list) {
      if (dart.is(list, NativeFloat64x2List)) {
        return new NativeFloat64x2List._externalStorage(new NativeFloat64List.fromList(list._storage));
      } else {
        return new NativeFloat64x2List._slowFromList(list);
      }
    }
    get runtimeType() {
      return typed_data.Float64x2List;
    }
    get buffer() {
      return this._storage.buffer;
    }
    get lengthInBytes() {
      return this._storage.lengthInBytes;
    }
    get offsetInBytes() {
      return this._storage.offsetInBytes;
    }
    get elementSizeInBytes() {
      return typed_data.Float64x2List.BYTES_PER_ELEMENT;
    }
    _invalidIndex(index, length) {
      if (dart.notNull(index < 0) || dart.notNull(index >= length)) {
        if (length === this.length) {
          throw new core.RangeError.index(index, this);
        }
        throw new core.RangeError.range(index, 0, length - 1);
      } else {
        throw new core.ArgumentError(`Invalid list index ${index}`);
      }
    }
    _checkIndex(index, length) {
      if (dart.dbinary(_foreign_helper.JS('bool', '(# >>> 0 != #)', index, index), '||', index >= length)) {
        this._invalidIndex(index, length);
      }
    }
    _checkSublistArguments(start, end, length) {
      this._checkIndex(start, length + 1);
      if (end === null)
        return length;
      this._checkIndex(end, length + 1);
      if (start > end)
        throw new core.RangeError.range(start, 0, end);
      return end;
    }
    get length() {
      return (this._storage.length / 2).truncate();
    }
    get(index) {
      this._checkIndex(index, this.length);
      let _x = dart.notNull(this._storage.get(index * 2 + 0));
      let _y = dart.notNull(this._storage.get(index * 2 + 1));
      return new typed_data.Float64x2(_x, _y);
    }
    set(index, value) {
      this._checkIndex(index, this.length);
      this._storage.set(index * 2 + 0, value.x);
      this._storage.set(index * 2 + 1, value.y);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      return new NativeFloat64x2List._externalStorage(dart.as(this._storage.sublist(start * 2, end * 2), NativeFloat64List));
    }
  }
  dart.defineNamedConstructor(NativeFloat64x2List, '_externalStorage');
  dart.defineNamedConstructor(NativeFloat64x2List, '_slowFromList');
  dart.defineNamedConstructor(NativeFloat64x2List, 'fromList');
  class NativeTypedData extends dart.Object {
    NativeTypedData() {
      this.buffer = null;
      this.lengthInBytes = dart.as(null, core.int);
      this.offsetInBytes = dart.as(null, core.int);
      this.elementSizeInBytes = dart.as(null, core.int);
    }
    _invalidIndex(index, length) {
      if (dart.notNull(index < 0) || dart.notNull(index >= length)) {
        if (dart.is(this, core.List)) {
          let list = this;
          if (length === list.length) {
            throw new core.RangeError.index(index, this);
          }
        }
        throw new core.RangeError.range(index, 0, length - 1);
      } else {
        throw new core.ArgumentError(`Invalid list index ${index}`);
      }
    }
    _checkIndex(index, length) {
      if (dart.dbinary(_foreign_helper.JS('bool', '(# >>> 0) !== #', index, index), '||', dart.dbinary(_foreign_helper.JS('int', '#', index), '>=', length))) {
        this._invalidIndex(index, length);
      }
    }
    _checkSublistArguments(start, end, length) {
      this._checkIndex(start, length + 1);
      if (end === null)
        return length;
      this._checkIndex(end, length + 1);
      if (start > end)
        throw new core.RangeError.range(start, 0, end);
      return end;
    }
  }
  // Function _checkLength: (dynamic) → int
  function _checkLength(length) {
    if (!(typeof length == number))
      throw new core.ArgumentError(`Invalid length ${length}`);
    return dart.as(length, core.int);
  }
  // Function _checkViewArguments: (dynamic, dynamic, dynamic) → void
  function _checkViewArguments(buffer, offsetInBytes, length) {
    if (!dart.is(buffer, NativeByteBuffer)) {
      throw new core.ArgumentError('Invalid view buffer');
    }
    if (!(typeof offsetInBytes == number)) {
      throw new core.ArgumentError(`Invalid view offsetInBytes ${offsetInBytes}`);
    }
    if (dart.notNull(length !== null) && dart.notNull(!(typeof length == number))) {
      throw new core.ArgumentError(`Invalid view length ${length}`);
    }
  }
  // Function _ensureNativeList: (List<dynamic>) → List
  function _ensureNativeList(list) {
    if (dart.is(list, _interceptors.JSIndexable))
      return list;
    let result = new core.List(list.length);
    for (let i = 0; i < list.length; i++) {
      result.set(i, list.get(i));
    }
    return result;
  }
  class NativeByteData extends NativeTypedData {
    NativeByteData(length) {
      return _create1(_checkLength(length));
    }
    NativeByteData$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.ByteData;
    }
    get elementSizeInBytes() {
      return 1;
    }
    getFloat32(byteOffset, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._getFloat32(byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getFloat64(byteOffset, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._getFloat64(byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getInt16(byteOffset, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._getInt16(byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getInt32(byteOffset, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._getInt32(byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getInt64(byteOffset, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      throw new core.UnsupportedError('Int64 accessor not supported by dart2js.');
    }
    getUint16(byteOffset, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._getUint16(byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getUint32(byteOffset, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._getUint32(byteOffset, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    getUint64(byteOffset, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      throw new core.UnsupportedError('Uint64 accessor not supported by dart2js.');
    }
    setFloat32(byteOffset, value, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._setFloat32(byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setFloat64(byteOffset, value, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._setFloat64(byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setInt16(byteOffset, value, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._setInt16(byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setInt32(byteOffset, value, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._setInt32(byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setInt64(byteOffset, value, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      throw new core.UnsupportedError('Int64 accessor not supported by dart2js.');
    }
    setUint16(byteOffset, value, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._setUint16(byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setUint32(byteOffset, value, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      return this._setUint32(byteOffset, value, dart.equals(typed_data.Endianness.LITTLE_ENDIAN, endian));
    }
    setUint64(byteOffset, value, endian) {
      if (endian === void 0)
        endian = typed_data.Endianness.BIG_ENDIAN;
      throw new core.UnsupportedError('Uint64 accessor not supported by dart2js.');
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeByteData', 'new DataView(new ArrayBuffer(#))', arg), NativeByteData);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeByteData', 'new DataView(#, #)', arg1, arg2), NativeByteData);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeByteData', 'new DataView(#, #, #)', arg1, arg2, arg3), NativeByteData);
    }
  }
  dart.defineNamedConstructor(NativeByteData, 'view');
  class NativeTypedArray extends NativeTypedData {
    get length() {
      return dart.as(_foreign_helper.JS('JSUInt32', '#.length', this), core.int);
    }
    _setRangeFast(start, end, source, skipCount) {
      let targetLength = this.length;
      this._checkIndex(start, targetLength + 1);
      this._checkIndex(end, targetLength + 1);
      if (start > end)
        throw new core.RangeError.range(start, 0, end);
      let count = end - start;
      if (skipCount < 0)
        throw new core.ArgumentError(skipCount);
      let sourceLength = source.length;
      if (sourceLength - skipCount < count) {
        throw new core.StateError('Not enough elements');
      }
      if (dart.notNull(skipCount !== 0) || dart.notNull(sourceLength !== count)) {
        source = dart.as(_foreign_helper.JS('', '#.subarray(#, #)', source, skipCount, skipCount + count), NativeTypedArray);
      }
      _foreign_helper.JS('void', '#.set(#, #)', this, source, start);
    }
  }
  class NativeTypedArrayOfDouble extends dart.mixin(NativeTypedArray, collection.ListMixin$(core.double), _internal.FixedLengthListMixin$(core.double)) {
    get(index) {
      this._checkIndex(index, this.length);
      return dart.as(_foreign_helper.JS('num', '#[#]', this, index), core.num);
    }
    set(index, value) {
      this._checkIndex(index, this.length);
      _foreign_helper.JS('void', '#[#] = #', this, index, value);
    }
    setRange(start, end, iterable, skipCount) {
      if (skipCount === void 0)
        skipCount = 0;
      if (dart.is(iterable, NativeTypedArrayOfDouble)) {
        this._setRangeFast(start, end, iterable, skipCount);
        return;
      }
      super.setRange(start, end, iterable, skipCount);
    }
  }
  class NativeTypedArrayOfInt extends dart.mixin(NativeTypedArray, collection.ListMixin$(core.int), _internal.FixedLengthListMixin$(core.int)) {
    set(index, value) {
      this._checkIndex(index, this.length);
      _foreign_helper.JS('void', '#[#] = #', this, index, value);
    }
    setRange(start, end, iterable, skipCount) {
      if (skipCount === void 0)
        skipCount = 0;
      if (dart.is(iterable, NativeTypedArrayOfInt)) {
        this._setRangeFast(start, end, iterable, skipCount);
        return;
      }
      super.setRange(start, end, iterable, skipCount);
    }
  }
  class NativeFloat32List extends NativeTypedArrayOfDouble {
    NativeFloat32List(length) {
      return _create1(_checkLength(length));
    }
    NativeFloat32List$fromList(elements) {
      return _create1(_ensureNativeList(elements));
    }
    NativeFloat32List$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Float32List;
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      let source = _foreign_helper.JS('NativeFloat32List', '#.subarray(#, #)', this, start, end);
      return _create1(source);
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeFloat32List', 'new Float32Array(#)', arg), NativeFloat32List);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeFloat32List', 'new Float32Array(#, #)', arg1, arg2), NativeFloat32List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeFloat32List', 'new Float32Array(#, #, #)', arg1, arg2, arg3), NativeFloat32List);
    }
  }
  dart.defineNamedConstructor(NativeFloat32List, 'fromList');
  dart.defineNamedConstructor(NativeFloat32List, 'view');
  class NativeFloat64List extends NativeTypedArrayOfDouble {
    NativeFloat64List(length) {
      return _create1(_checkLength(length));
    }
    NativeFloat64List$fromList(elements) {
      return _create1(_ensureNativeList(elements));
    }
    NativeFloat64List$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Float64List;
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      let source = _foreign_helper.JS('NativeFloat64List', '#.subarray(#, #)', this, start, end);
      return _create1(source);
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeFloat64List', 'new Float64Array(#)', arg), NativeFloat64List);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeFloat64List', 'new Float64Array(#, #)', arg1, arg2), NativeFloat64List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeFloat64List', 'new Float64Array(#, #, #)', arg1, arg2, arg3), NativeFloat64List);
    }
  }
  dart.defineNamedConstructor(NativeFloat64List, 'fromList');
  dart.defineNamedConstructor(NativeFloat64List, 'view');
  class NativeInt16List extends NativeTypedArrayOfInt {
    NativeInt16List(length) {
      return _create1(_checkLength(length));
    }
    NativeInt16List$fromList(elements) {
      return _create1(_ensureNativeList(elements));
    }
    NativeInt16List$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Int16List;
    }
    get(index) {
      this._checkIndex(index, this.length);
      return dart.as(_foreign_helper.JS('int', '#[#]', this, index), core.int);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      let source = _foreign_helper.JS('NativeInt16List', '#.subarray(#, #)', this, start, end);
      return _create1(source);
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeInt16List', 'new Int16Array(#)', arg), NativeInt16List);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeInt16List', 'new Int16Array(#, #)', arg1, arg2), NativeInt16List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeInt16List', 'new Int16Array(#, #, #)', arg1, arg2, arg3), NativeInt16List);
    }
  }
  dart.defineNamedConstructor(NativeInt16List, 'fromList');
  dart.defineNamedConstructor(NativeInt16List, 'view');
  class NativeInt32List extends NativeTypedArrayOfInt {
    NativeInt32List(length) {
      return _create1(_checkLength(length));
    }
    NativeInt32List$fromList(elements) {
      return _create1(_ensureNativeList(elements));
    }
    NativeInt32List$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Int32List;
    }
    get(index) {
      this._checkIndex(index, this.length);
      return dart.as(_foreign_helper.JS('int', '#[#]', this, index), core.int);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      let source = _foreign_helper.JS('NativeInt32List', '#.subarray(#, #)', this, start, end);
      return _create1(source);
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeInt32List', 'new Int32Array(#)', arg), NativeInt32List);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeInt32List', 'new Int32Array(#, #)', arg1, arg2), NativeInt32List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeInt32List', 'new Int32Array(#, #, #)', arg1, arg2, arg3), NativeInt32List);
    }
  }
  dart.defineNamedConstructor(NativeInt32List, 'fromList');
  dart.defineNamedConstructor(NativeInt32List, 'view');
  class NativeInt8List extends NativeTypedArrayOfInt {
    NativeInt8List(length) {
      return _create1(_checkLength(length));
    }
    NativeInt8List$fromList(elements) {
      return _create1(_ensureNativeList(elements));
    }
    NativeInt8List$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return dart.as(length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length), NativeInt8List);
    }
    get runtimeType() {
      return typed_data.Int8List;
    }
    get(index) {
      this._checkIndex(index, this.length);
      return dart.as(_foreign_helper.JS('int', '#[#]', this, index), core.int);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      let source = _foreign_helper.JS('NativeInt8List', '#.subarray(#, #)', this, start, end);
      return _create1(source);
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeInt8List', 'new Int8Array(#)', arg), NativeInt8List);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeInt8List', 'new Int8Array(#, #)', arg1, arg2), NativeInt8List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeInt8List', 'new Int8Array(#, #, #)', arg1, arg2, arg3), typed_data.Int8List);
    }
  }
  dart.defineNamedConstructor(NativeInt8List, 'fromList');
  dart.defineNamedConstructor(NativeInt8List, 'view');
  class NativeUint16List extends NativeTypedArrayOfInt {
    NativeUint16List(length) {
      return _create1(_checkLength(length));
    }
    NativeUint16List$fromList(list) {
      return _create1(_ensureNativeList(list));
    }
    NativeUint16List$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Uint16List;
    }
    get(index) {
      this._checkIndex(index, this.length);
      return dart.as(_foreign_helper.JS('JSUInt31', '#[#]', this, index), core.int);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      let source = _foreign_helper.JS('NativeUint16List', '#.subarray(#, #)', this, start, end);
      return _create1(source);
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeUint16List', 'new Uint16Array(#)', arg), NativeUint16List);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeUint16List', 'new Uint16Array(#, #)', arg1, arg2), NativeUint16List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeUint16List', 'new Uint16Array(#, #, #)', arg1, arg2, arg3), NativeUint16List);
    }
  }
  dart.defineNamedConstructor(NativeUint16List, 'fromList');
  dart.defineNamedConstructor(NativeUint16List, 'view');
  class NativeUint32List extends NativeTypedArrayOfInt {
    NativeUint32List(length) {
      return _create1(_checkLength(length));
    }
    NativeUint32List$fromList(elements) {
      return _create1(_ensureNativeList(elements));
    }
    NativeUint32List$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Uint32List;
    }
    get(index) {
      this._checkIndex(index, this.length);
      return dart.as(_foreign_helper.JS('JSUInt32', '#[#]', this, index), core.int);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      let source = _foreign_helper.JS('NativeUint32List', '#.subarray(#, #)', this, start, end);
      return _create1(source);
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeUint32List', 'new Uint32Array(#)', arg), NativeUint32List);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeUint32List', 'new Uint32Array(#, #)', arg1, arg2), NativeUint32List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeUint32List', 'new Uint32Array(#, #, #)', arg1, arg2, arg3), NativeUint32List);
    }
  }
  dart.defineNamedConstructor(NativeUint32List, 'fromList');
  dart.defineNamedConstructor(NativeUint32List, 'view');
  class NativeUint8ClampedList extends NativeTypedArrayOfInt {
    NativeUint8ClampedList(length) {
      return _create1(_checkLength(length));
    }
    NativeUint8ClampedList$fromList(elements) {
      return _create1(_ensureNativeList(elements));
    }
    NativeUint8ClampedList$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Uint8ClampedList;
    }
    get length() {
      return dart.as(_foreign_helper.JS('JSUInt32', '#.length', this), core.int);
    }
    get(index) {
      this._checkIndex(index, this.length);
      return dart.as(_foreign_helper.JS('JSUInt31', '#[#]', this, index), core.int);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      let source = _foreign_helper.JS('NativeUint8ClampedList', '#.subarray(#, #)', this, start, end);
      return _create1(source);
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeUint8ClampedList', 'new Uint8ClampedArray(#)', arg), NativeUint8ClampedList);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeUint8ClampedList', 'new Uint8ClampedArray(#, #)', arg1, arg2), NativeUint8ClampedList);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeUint8ClampedList', 'new Uint8ClampedArray(#, #, #)', arg1, arg2, arg3), NativeUint8ClampedList);
    }
  }
  dart.defineNamedConstructor(NativeUint8ClampedList, 'fromList');
  dart.defineNamedConstructor(NativeUint8ClampedList, 'view');
  class NativeUint8List extends NativeTypedArrayOfInt {
    NativeUint8List(length) {
      return _create1(_checkLength(length));
    }
    NativeUint8List$fromList(elements) {
      return _create1(_ensureNativeList(elements));
    }
    NativeUint8List$view(buffer, offsetInBytes, length) {
      _checkViewArguments(buffer, offsetInBytes, length);
      return length === null ? _create2(buffer, offsetInBytes) : _create3(buffer, offsetInBytes, length);
    }
    get runtimeType() {
      return typed_data.Uint8List;
    }
    get length() {
      return dart.as(_foreign_helper.JS('JSUInt32', '#.length', this), core.int);
    }
    get(index) {
      this._checkIndex(index, this.length);
      return dart.as(_foreign_helper.JS('JSUInt31', '#[#]', this, index), core.int);
    }
    sublist(start, end) {
      if (end === void 0)
        end = null;
      end = this._checkSublistArguments(start, end, this.length);
      let source = _foreign_helper.JS('NativeUint8List', '#.subarray(#, #)', this, start, end);
      return _create1(source);
    }
    static _create1(arg) {
      return dart.as(_foreign_helper.JS('NativeUint8List', 'new Uint8Array(#)', arg), NativeUint8List);
    }
    static _create2(arg1, arg2) {
      return dart.as(_foreign_helper.JS('NativeUint8List', 'new Uint8Array(#, #)', arg1, arg2), NativeUint8List);
    }
    static _create3(arg1, arg2, arg3) {
      return dart.as(_foreign_helper.JS('NativeUint8List', 'new Uint8Array(#, #, #)', arg1, arg2, arg3), NativeUint8List);
    }
  }
  dart.defineNamedConstructor(NativeUint8List, 'fromList');
  dart.defineNamedConstructor(NativeUint8List, 'view');
  class NativeFloat32x4 extends dart.Object {
    static _truncate(x) {
      _list.set(0, dart.as(x, core.num));
      return _list.get(0);
    }
    NativeFloat32x4(x, y, z, w) {
      this.x = dart.as(_truncate(x), core.double);
      this.y = dart.as(_truncate(y), core.double);
      this.z = dart.as(_truncate(z), core.double);
      this.w = dart.as(_truncate(w), core.double);
      if (!dart.is(x, core.num))
        throw new core.ArgumentError(x);
      if (!dart.is(y, core.num))
        throw new core.ArgumentError(y);
      if (!dart.is(z, core.num))
        throw new core.ArgumentError(z);
      if (!dart.is(w, core.num))
        throw new core.ArgumentError(w);
    }
    NativeFloat32x4$splat(v) {
      this.NativeFloat32x4(v, v, v, v);
    }
    NativeFloat32x4$zero() {
      this.NativeFloat32x4$_truncated(0.0, 0.0, 0.0, 0.0);
    }
    NativeFloat32x4$fromInt32x4Bits(i) {
      _uint32view.set(0, i.x);
      _uint32view.set(1, i.y);
      _uint32view.set(2, i.z);
      _uint32view.set(3, i.w);
      return new NativeFloat32x4._truncated(dart.notNull(_list.get(0)), dart.notNull(_list.get(1)), dart.notNull(_list.get(2)), dart.notNull(_list.get(3)));
    }
    NativeFloat32x4$fromFloat64x2(v) {
      this.NativeFloat32x4$_truncated(dart.as(_truncate(v.x), core.double), dart.as(_truncate(v.y), core.double), 0.0, 0.0);
    }
    NativeFloat32x4$_doubles(x, y, z, w) {
      this.x = dart.as(_truncate(x), core.double);
      this.y = dart.as(_truncate(y), core.double);
      this.z = dart.as(_truncate(z), core.double);
      this.w = dart.as(_truncate(w), core.double);
    }
    NativeFloat32x4$_truncated(x, y, z, w) {
      this.x = x;
      this.y = y;
      this.z = z;
      this.w = w;
    }
    toString() {
      return `[${this.x}, ${this.y}, ${this.z}, ${this.w}]`;
    }
    ['+'](other) {
      let _x = this.x + other.x;
      let _y = this.y + other.y;
      let _z = this.z + other.z;
      let _w = this.w + other.w;
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    ['-']() {
      return new NativeFloat32x4._truncated(-this.x, -this.y, -this.z, -this.w);
    }
    ['-'](other) {
      let _x = this.x - other.x;
      let _y = this.y - other.y;
      let _z = this.z - other.z;
      let _w = this.w - other.w;
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    ['*'](other) {
      let _x = this.x * other.x;
      let _y = this.y * other.y;
      let _z = this.z * other.z;
      let _w = this.w * other.w;
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    ['/'](other) {
      let _x = this.x / other.x;
      let _y = this.y / other.y;
      let _z = this.z / other.z;
      let _w = this.w / other.w;
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    lessThan(other) {
      let _cx = this.x < other.x;
      let _cy = this.y < other.y;
      let _cz = this.z < other.z;
      let _cw = this.w < other.w;
      return new NativeInt32x4._truncated(_cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
    }
    lessThanOrEqual(other) {
      let _cx = this.x <= other.x;
      let _cy = this.y <= other.y;
      let _cz = this.z <= other.z;
      let _cw = this.w <= other.w;
      return new NativeInt32x4._truncated(_cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
    }
    greaterThan(other) {
      let _cx = this.x > other.x;
      let _cy = this.y > other.y;
      let _cz = this.z > other.z;
      let _cw = this.w > other.w;
      return new NativeInt32x4._truncated(_cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
    }
    greaterThanOrEqual(other) {
      let _cx = this.x >= other.x;
      let _cy = this.y >= other.y;
      let _cz = this.z >= other.z;
      let _cw = this.w >= other.w;
      return new NativeInt32x4._truncated(_cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
    }
    equal(other) {
      let _cx = this.x === other.x;
      let _cy = this.y === other.y;
      let _cz = this.z === other.z;
      let _cw = this.w === other.w;
      return new NativeInt32x4._truncated(_cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
    }
    notEqual(other) {
      let _cx = this.x !== other.x;
      let _cy = this.y !== other.y;
      let _cz = this.z !== other.z;
      let _cw = this.w !== other.w;
      return new NativeInt32x4._truncated(_cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
    }
    scale(s) {
      let _x = s * this.x;
      let _y = s * this.y;
      let _z = s * this.z;
      let _w = s * this.w;
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    abs() {
      let _x = this.x.abs();
      let _y = this.y.abs();
      let _z = this.z.abs();
      let _w = this.w.abs();
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
      _x = _x > _ux ? _ux : _x;
      _y = _y > _uy ? _uy : _y;
      _z = _z > _uz ? _uz : _z;
      _w = _w > _uw ? _uw : _w;
      _x = _x < _lx ? _lx : _x;
      _y = _y < _ly ? _ly : _y;
      _z = _z < _lz ? _lz : _z;
      _w = _w < _lw ? _lw : _w;
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    get signMask() {
      let view = _uint32view;
      let mx = null, my = null, mz = null, mw = null;
      _list.set(0, this.x);
      _list.set(1, this.y);
      _list.set(2, this.z);
      _list.set(3, this.w);
      mx = (view.get(0) & 2147483648) >> 31;
      my = (view.get(1) & 2147483648) >> 30;
      mz = (view.get(2) & 2147483648) >> 29;
      mw = (view.get(3) & 2147483648) >> 28;
      return dart.as(dart.dbinary(dart.dbinary(dart.dbinary(mx, '|', my), '|', mz), '|', mw), core.int);
    }
    shuffle(m) {
      if (dart.notNull(m < 0) || dart.notNull(m > 255)) {
        throw new core.RangeError(`mask ${m} must be in the range [0..256)`);
      }
      _list.set(0, this.x);
      _list.set(1, this.y);
      _list.set(2, this.z);
      _list.set(3, this.w);
      let _x = dart.notNull(_list.get(m & 3));
      let _y = dart.notNull(_list.get(m >> 2 & 3));
      let _z = dart.notNull(_list.get(m >> 4 & 3));
      let _w = dart.notNull(_list.get(m >> 6 & 3));
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    shuffleMix(other, m) {
      if (dart.notNull(m < 0) || dart.notNull(m > 255)) {
        throw new core.RangeError(`mask ${m} must be in the range [0..256)`);
      }
      _list.set(0, this.x);
      _list.set(1, this.y);
      _list.set(2, this.z);
      _list.set(3, this.w);
      let _x = dart.notNull(_list.get(m & 3));
      let _y = dart.notNull(_list.get(m >> 2 & 3));
      _list.set(0, other.x);
      _list.set(1, other.y);
      _list.set(2, other.z);
      _list.set(3, other.w);
      let _z = dart.notNull(_list.get(m >> 4 & 3));
      let _w = dart.notNull(_list.get(m >> 6 & 3));
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    withX(newX) {
      return new NativeFloat32x4._truncated(dart.as(_truncate(newX), core.double), this.y, this.z, this.w);
    }
    withY(newY) {
      return new NativeFloat32x4._truncated(this.x, dart.as(_truncate(newY), core.double), this.z, this.w);
    }
    withZ(newZ) {
      return new NativeFloat32x4._truncated(this.x, this.y, dart.as(_truncate(newZ), core.double), this.w);
    }
    withW(newW) {
      return new NativeFloat32x4._truncated(this.x, this.y, this.z, dart.as(_truncate(newW), core.double));
    }
    min(other) {
      let _x = this.x < other.x ? this.x : other.x;
      let _y = this.y < other.y ? this.y : other.y;
      let _z = this.z < other.z ? this.z : other.z;
      let _w = this.w < other.w ? this.w : other.w;
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    max(other) {
      let _x = this.x > other.x ? this.x : other.x;
      let _y = this.y > other.y ? this.y : other.y;
      let _z = this.z > other.z ? this.z : other.z;
      let _w = this.w > other.w ? this.w : other.w;
      return new NativeFloat32x4._truncated(_x, _y, _z, _w);
    }
    sqrt() {
      let _x = Math.sqrt(this.x);
      let _y = Math.sqrt(this.y);
      let _z = Math.sqrt(this.z);
      let _w = Math.sqrt(this.w);
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    reciprocal() {
      let _x = 1.0 / this.x;
      let _y = 1.0 / this.y;
      let _z = 1.0 / this.z;
      let _w = 1.0 / this.w;
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
    reciprocalSqrt() {
      let _x = Math.sqrt(1.0 / this.x);
      let _y = Math.sqrt(1.0 / this.y);
      let _z = Math.sqrt(1.0 / this.z);
      let _w = Math.sqrt(1.0 / this.w);
      return new NativeFloat32x4._doubles(_x, _y, _z, _w);
    }
  }
  dart.defineNamedConstructor(NativeFloat32x4, 'splat');
  dart.defineNamedConstructor(NativeFloat32x4, 'zero');
  dart.defineNamedConstructor(NativeFloat32x4, 'fromInt32x4Bits');
  dart.defineNamedConstructor(NativeFloat32x4, 'fromFloat64x2');
  dart.defineNamedConstructor(NativeFloat32x4, '_doubles');
  dart.defineNamedConstructor(NativeFloat32x4, '_truncated');
  dart.defineLazyProperties(NativeFloat32x4, {
    get _list() {
      return new NativeFloat32List(4);
    },
    get _uint32view() {
      return _list.buffer.asUint32List();
    }
  });
  class NativeInt32x4 extends dart.Object {
    static _truncate(x) {
      dart.dsetindex(_list, 0, x);
      return dart.dindex(_list, 0);
    }
    NativeInt32x4(x, y, z, w) {
      this.x = dart.as(_truncate(x), core.int);
      this.y = dart.as(_truncate(y), core.int);
      this.z = dart.as(_truncate(z), core.int);
      this.w = dart.as(_truncate(w), core.int);
      if (dart.notNull(x !== this.x) && dart.notNull(!(typeof x == number)))
        throw new core.ArgumentError(x);
      if (dart.notNull(y !== this.y) && dart.notNull(!(typeof y == number)))
        throw new core.ArgumentError(y);
      if (dart.notNull(z !== this.z) && dart.notNull(!(typeof z == number)))
        throw new core.ArgumentError(z);
      if (dart.notNull(w !== this.w) && dart.notNull(!(typeof w == number)))
        throw new core.ArgumentError(w);
    }
    NativeInt32x4$bool(x, y, z, w) {
      this.x = x ? -1 : 0;
      this.y = y ? -1 : 0;
      this.z = z ? -1 : 0;
      this.w = w ? -1 : 0;
    }
    NativeInt32x4$fromFloat32x4Bits(f) {
      let floatList = NativeFloat32x4._list;
      floatList.set(0, f.x);
      floatList.set(1, f.y);
      floatList.set(2, f.z);
      floatList.set(3, f.w);
      let view = dart.as(floatList.buffer.asInt32List(), NativeInt32List);
      return new NativeInt32x4._truncated(view.get(0), view.get(1), view.get(2), view.get(3));
    }
    NativeInt32x4$_truncated(x, y, z, w) {
      this.x = x;
      this.y = y;
      this.z = z;
      this.w = w;
    }
    toString() {
      return `[${this.x}, ${this.y}, ${this.z}, ${this.w}]`;
    }
    ['|'](other) {
      return new NativeInt32x4._truncated(dart.as(_foreign_helper.JS("int", "# | #", this.x, other.x), core.int), dart.as(_foreign_helper.JS("int", "# | #", this.y, other.y), core.int), dart.as(_foreign_helper.JS("int", "# | #", this.z, other.z), core.int), dart.as(_foreign_helper.JS("int", "# | #", this.w, other.w), core.int));
    }
    ['&'](other) {
      return new NativeInt32x4._truncated(dart.as(_foreign_helper.JS("int", "# & #", this.x, other.x), core.int), dart.as(_foreign_helper.JS("int", "# & #", this.y, other.y), core.int), dart.as(_foreign_helper.JS("int", "# & #", this.z, other.z), core.int), dart.as(_foreign_helper.JS("int", "# & #", this.w, other.w), core.int));
    }
    ['^'](other) {
      return new NativeInt32x4._truncated(dart.as(_foreign_helper.JS("int", "# ^ #", this.x, other.x), core.int), dart.as(_foreign_helper.JS("int", "# ^ #", this.y, other.y), core.int), dart.as(_foreign_helper.JS("int", "# ^ #", this.z, other.z), core.int), dart.as(_foreign_helper.JS("int", "# ^ #", this.w, other.w), core.int));
    }
    ['+'](other) {
      return new NativeInt32x4._truncated(dart.as(_foreign_helper.JS("int", "(# + #) | 0", this.x, other.x), core.int), dart.as(_foreign_helper.JS("int", "(# + #) | 0", this.y, other.y), core.int), dart.as(_foreign_helper.JS("int", "(# + #) | 0", this.z, other.z), core.int), dart.as(_foreign_helper.JS("int", "(# + #) | 0", this.w, other.w), core.int));
    }
    ['-'](other) {
      return new NativeInt32x4._truncated(dart.as(_foreign_helper.JS("int", "(# - #) | 0", this.x, other.x), core.int), dart.as(_foreign_helper.JS("int", "(# - #) | 0", this.y, other.y), core.int), dart.as(_foreign_helper.JS("int", "(# - #) | 0", this.z, other.z), core.int), dart.as(_foreign_helper.JS("int", "(# - #) | 0", this.w, other.w), core.int));
    }
    ['-']() {
      return new NativeInt32x4._truncated(dart.as(_foreign_helper.JS("int", "(-#) | 0", this.x), core.int), dart.as(_foreign_helper.JS("int", "(-#) | 0", this.y), core.int), dart.as(_foreign_helper.JS("int", "(-#) | 0", this.z), core.int), dart.as(_foreign_helper.JS("int", "(-#) | 0", this.w), core.int));
    }
    get signMask() {
      let mx = (this.x & 2147483648) >> 31;
      let my = (this.y & 2147483648) >> 31;
      let mz = (this.z & 2147483648) >> 31;
      let mw = (this.w & 2147483648) >> 31;
      return mx | my << 1 | mz << 2 | mw << 3;
    }
    shuffle(mask) {
      if (dart.notNull(mask < 0) || dart.notNull(mask > 255)) {
        throw new core.RangeError(`mask ${mask} must be in the range [0..256)`);
      }
      dart.dsetindex(_list, 0, this.x);
      dart.dsetindex(_list, 1, this.y);
      dart.dsetindex(_list, 2, this.z);
      dart.dsetindex(_list, 3, this.w);
      let _x = dart.as(dart.dindex(_list, mask & 3), core.int);
      let _y = dart.as(dart.dindex(_list, mask >> 2 & 3), core.int);
      let _z = dart.as(dart.dindex(_list, mask >> 4 & 3), core.int);
      let _w = dart.as(dart.dindex(_list, mask >> 6 & 3), core.int);
      return new NativeInt32x4._truncated(_x, _y, _z, _w);
    }
    shuffleMix(other, mask) {
      if (dart.notNull(mask < 0) || dart.notNull(mask > 255)) {
        throw new core.RangeError(`mask ${mask} must be in the range [0..256)`);
      }
      dart.dsetindex(_list, 0, this.x);
      dart.dsetindex(_list, 1, this.y);
      dart.dsetindex(_list, 2, this.z);
      dart.dsetindex(_list, 3, this.w);
      let _x = dart.as(dart.dindex(_list, mask & 3), core.int);
      let _y = dart.as(dart.dindex(_list, mask >> 2 & 3), core.int);
      dart.dsetindex(_list, 0, other.x);
      dart.dsetindex(_list, 1, other.y);
      dart.dsetindex(_list, 2, other.z);
      dart.dsetindex(_list, 3, other.w);
      let _z = dart.as(dart.dindex(_list, mask >> 4 & 3), core.int);
      let _w = dart.as(dart.dindex(_list, mask >> 6 & 3), core.int);
      return new NativeInt32x4._truncated(_x, _y, _z, _w);
    }
    withX(x) {
      let _x = dart.as(_truncate(x), core.int);
      return new NativeInt32x4._truncated(_x, this.y, this.z, this.w);
    }
    withY(y) {
      let _y = dart.as(_truncate(y), core.int);
      return new NativeInt32x4._truncated(this.x, _y, this.z, this.w);
    }
    withZ(z) {
      let _z = dart.as(_truncate(z), core.int);
      return new NativeInt32x4._truncated(this.x, this.y, _z, this.w);
    }
    withW(w) {
      let _w = dart.as(_truncate(w), core.int);
      return new NativeInt32x4._truncated(this.x, this.y, this.z, _w);
    }
    get flagX() {
      return this.x !== 0;
    }
    get flagY() {
      return this.y !== 0;
    }
    get flagZ() {
      return this.z !== 0;
    }
    get flagW() {
      return this.w !== 0;
    }
    withFlagX(flagX) {
      let _x = flagX ? -1 : 0;
      return new NativeInt32x4._truncated(_x, this.y, this.z, this.w);
    }
    withFlagY(flagY) {
      let _y = flagY ? -1 : 0;
      return new NativeInt32x4._truncated(this.x, _y, this.z, this.w);
    }
    withFlagZ(flagZ) {
      let _z = flagZ ? -1 : 0;
      return new NativeInt32x4._truncated(this.x, this.y, _z, this.w);
    }
    withFlagW(flagW) {
      let _w = flagW ? -1 : 0;
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
      let _x = this.x & stx | ~this.x & sfx;
      let _y = this.y & sty | ~this.y & sfy;
      let _z = this.z & stz | ~this.z & sfz;
      let _w = this.w & stw | ~this.w & sfw;
      intView.set(0, _x);
      intView.set(1, _y);
      intView.set(2, _z);
      intView.set(3, _w);
      return new NativeFloat32x4._truncated(dart.notNull(floatList.get(0)), dart.notNull(floatList.get(1)), dart.notNull(floatList.get(2)), dart.notNull(floatList.get(3)));
    }
  }
  dart.defineNamedConstructor(NativeInt32x4, 'bool');
  dart.defineNamedConstructor(NativeInt32x4, 'fromFloat32x4Bits');
  dart.defineNamedConstructor(NativeInt32x4, '_truncated');
  dart.defineLazyProperties(NativeInt32x4, {
    get _list() {
      return new NativeInt32List(4);
    }
  });
  class NativeFloat64x2 extends dart.Object {
    NativeFloat64x2(x, y) {
      this.x = x;
      this.y = y;
      if (!dart.is(this.x, core.num))
        throw new core.ArgumentError(this.x);
      if (!dart.is(this.y, core.num))
        throw new core.ArgumentError(this.y);
    }
    NativeFloat64x2$splat(v) {
      this.NativeFloat64x2(v, v);
    }
    NativeFloat64x2$zero() {
      this.NativeFloat64x2$splat(0.0);
    }
    NativeFloat64x2$fromFloat32x4(v) {
      this.NativeFloat64x2(v.x, v.y);
    }
    NativeFloat64x2$_doubles(x, y) {
      this.x = x;
      this.y = y;
    }
    toString() {
      return `[${this.x}, ${this.y}]`;
    }
    ['+'](other) {
      return new NativeFloat64x2._doubles(this.x + other.x, this.y + other.y);
    }
    ['-']() {
      return new NativeFloat64x2._doubles(-this.x, -this.y);
    }
    ['-'](other) {
      return new NativeFloat64x2._doubles(this.x - other.x, this.y - other.y);
    }
    ['*'](other) {
      return new NativeFloat64x2._doubles(this.x * other.x, this.y * other.y);
    }
    ['/'](other) {
      return new NativeFloat64x2._doubles(this.x / other.x, this.y / other.y);
    }
    scale(s) {
      return new NativeFloat64x2._doubles(this.x * s, this.y * s);
    }
    abs() {
      return new NativeFloat64x2._doubles(this.x.abs(), this.y.abs());
    }
    clamp(lowerLimit, upperLimit) {
      let _lx = lowerLimit.x;
      let _ly = lowerLimit.y;
      let _ux = upperLimit.x;
      let _uy = upperLimit.y;
      let _x = this.x;
      let _y = this.y;
      _x = _x > _ux ? _ux : _x;
      _y = _y > _uy ? _uy : _y;
      _x = _x < _lx ? _lx : _x;
      _y = _y < _ly ? _ly : _y;
      return new NativeFloat64x2._doubles(_x, _y);
    }
    get signMask() {
      let view = _uint32View;
      _list.set(0, this.x);
      _list.set(1, this.y);
      let mx = (view.get(1) & 2147483648) >> 31;
      let my = (view.get(3) & 2147483648) >> 31;
      return mx | my << 1;
    }
    withX(x) {
      if (!dart.is(x, core.num))
        throw new core.ArgumentError(x);
      return new NativeFloat64x2._doubles(x, this.y);
    }
    withY(y) {
      if (!dart.is(y, core.num))
        throw new core.ArgumentError(y);
      return new NativeFloat64x2._doubles(this.x, y);
    }
    min(other) {
      return new NativeFloat64x2._doubles(this.x < other.x ? this.x : other.x, this.y < other.y ? this.y : other.y);
    }
    max(other) {
      return new NativeFloat64x2._doubles(this.x > other.x ? this.x : other.x, this.y > other.y ? this.y : other.y);
    }
    sqrt() {
      return new NativeFloat64x2._doubles(Math.sqrt(this.x), Math.sqrt(this.y));
    }
  }
  dart.defineNamedConstructor(NativeFloat64x2, 'splat');
  dart.defineNamedConstructor(NativeFloat64x2, 'zero');
  dart.defineNamedConstructor(NativeFloat64x2, 'fromFloat32x4');
  dart.defineNamedConstructor(NativeFloat64x2, '_doubles');
  dart.defineLazyProperties(NativeFloat64x2, {
    get _list() {
      return new NativeFloat64List(2);
    },
    set _list() {},
    get _uint32View() {
      return dart.as(_list.buffer.asUint32List(), NativeUint32List);
    },
    set _uint32View() {}
  });
  // Exports:
  _native_typed_data.NativeByteBuffer = NativeByteBuffer;
  _native_typed_data.NativeFloat32x4List = NativeFloat32x4List;
  _native_typed_data.NativeInt32x4List = NativeInt32x4List;
  _native_typed_data.NativeFloat64x2List = NativeFloat64x2List;
  _native_typed_data.NativeTypedData = NativeTypedData;
  _native_typed_data.NativeByteData = NativeByteData;
  _native_typed_data.NativeTypedArray = NativeTypedArray;
  _native_typed_data.NativeTypedArrayOfDouble = NativeTypedArrayOfDouble;
  _native_typed_data.NativeTypedArrayOfInt = NativeTypedArrayOfInt;
  _native_typed_data.NativeFloat32List = NativeFloat32List;
  _native_typed_data.NativeFloat64List = NativeFloat64List;
  _native_typed_data.NativeInt16List = NativeInt16List;
  _native_typed_data.NativeInt32List = NativeInt32List;
  _native_typed_data.NativeInt8List = NativeInt8List;
  _native_typed_data.NativeUint16List = NativeUint16List;
  _native_typed_data.NativeUint32List = NativeUint32List;
  _native_typed_data.NativeUint8ClampedList = NativeUint8ClampedList;
  _native_typed_data.NativeUint8List = NativeUint8List;
  _native_typed_data.NativeFloat32x4 = NativeFloat32x4;
  _native_typed_data.NativeInt32x4 = NativeInt32x4;
  _native_typed_data.NativeFloat64x2 = NativeFloat64x2;
})(_native_typed_data || (_native_typed_data = {}));
