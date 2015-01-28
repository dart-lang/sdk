var dart.typed_data;
(function (dart.typed_data) {
  'use strict';
  class ByteBuffer {
  }

  class TypedData {
  }

  class Endianness {
    __init__(_littleEndian) {
      HOST_ENDIAN = (new ByteData.view(new Uint16List.fromList(/* Unimplemented ArrayList */[1]).buffer)).getInt8(0) === 1 ? LITTLE_ENDIAN : BIG_ENDIAN;
      this._littleEndian = _littleEndian;
      this.BIG_ENDIAN = new Endianness.this._(false);
      this.LITTLE_ENDIAN = new Endianness.this._(true);
    }
  }
  Endianness._ = function(_littleEndian) { this.__init__(_littleEndian) };
  Endianness._.prototype = Endianness.prototype;

  class ByteData {
    constructor(length) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asByteData(offsetInBytes, length);
    }
  }
  ByteData.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  ByteData.view.prototype = ByteData.prototype;

  class Int8List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asInt8List(offsetInBytes, length);
    }
  }
  Int8List.fromList = function(elements) { this.__init_fromList(elements) };
  Int8List.fromList.prototype = Int8List.prototype;
  Int8List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Int8List.view.prototype = Int8List.prototype;

  class Uint8List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asUint8List(offsetInBytes, length);
    }
  }
  Uint8List.fromList = function(elements) { this.__init_fromList(elements) };
  Uint8List.fromList.prototype = Uint8List.prototype;
  Uint8List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Uint8List.view.prototype = Uint8List.prototype;

  class Uint8ClampedList {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asUint8ClampedList(offsetInBytes, length);
    }
  }
  Uint8ClampedList.fromList = function(elements) { this.__init_fromList(elements) };
  Uint8ClampedList.fromList.prototype = Uint8ClampedList.prototype;
  Uint8ClampedList.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Uint8ClampedList.view.prototype = Uint8ClampedList.prototype;

  class Int16List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asInt16List(offsetInBytes, length);
    }
  }
  Int16List.fromList = function(elements) { this.__init_fromList(elements) };
  Int16List.fromList.prototype = Int16List.prototype;
  Int16List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Int16List.view.prototype = Int16List.prototype;

  class Uint16List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asUint16List(offsetInBytes, length);
    }
  }
  Uint16List.fromList = function(elements) { this.__init_fromList(elements) };
  Uint16List.fromList.prototype = Uint16List.prototype;
  Uint16List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Uint16List.view.prototype = Uint16List.prototype;

  class Int32List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asInt32List(offsetInBytes, length);
    }
  }
  Int32List.fromList = function(elements) { this.__init_fromList(elements) };
  Int32List.fromList.prototype = Int32List.prototype;
  Int32List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Int32List.view.prototype = Int32List.prototype;

  class Uint32List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asUint32List(offsetInBytes, length);
    }
  }
  Uint32List.fromList = function(elements) { this.__init_fromList(elements) };
  Uint32List.fromList.prototype = Uint32List.prototype;
  Uint32List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Uint32List.view.prototype = Uint32List.prototype;

  class Int64List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asInt64List(offsetInBytes, length);
    }
  }
  Int64List.fromList = function(elements) { this.__init_fromList(elements) };
  Int64List.fromList.prototype = Int64List.prototype;
  Int64List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Int64List.view.prototype = Int64List.prototype;

  class Uint64List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asUint64List(offsetInBytes, length);
    }
  }
  Uint64List.fromList = function(elements) { this.__init_fromList(elements) };
  Uint64List.fromList.prototype = Uint64List.prototype;
  Uint64List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Uint64List.view.prototype = Uint64List.prototype;

  class Float32List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asFloat32List(offsetInBytes, length);
    }
  }
  Float32List.fromList = function(elements) { this.__init_fromList(elements) };
  Float32List.fromList.prototype = Float32List.prototype;
  Float32List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Float32List.view.prototype = Float32List.prototype;

  class Float64List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asFloat64List(offsetInBytes, length);
    }
  }
  Float64List.fromList = function(elements) { this.__init_fromList(elements) };
  Float64List.fromList.prototype = Float64List.prototype;
  Float64List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Float64List.view.prototype = Float64List.prototype;

  class Float32x4List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asFloat32x4List(offsetInBytes, length);
    }
  }
  Float32x4List.fromList = function(elements) { this.__init_fromList(elements) };
  Float32x4List.fromList.prototype = Float32x4List.prototype;
  Float32x4List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Float32x4List.view.prototype = Float32x4List.prototype;

  class Int32x4List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asInt32x4List(offsetInBytes, length);
    }
  }
  Int32x4List.fromList = function(elements) { this.__init_fromList(elements) };
  Int32x4List.fromList.prototype = Int32x4List.prototype;
  Int32x4List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Int32x4List.view.prototype = Int32x4List.prototype;

  class Float64x2List {
    constructor(length) {
    }
    __init_fromList(elements) {
    }
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asFloat64x2List(offsetInBytes, length);
    }
  }
  Float64x2List.fromList = function(elements) { this.__init_fromList(elements) };
  Float64x2List.fromList.prototype = Float64x2List.prototype;
  Float64x2List.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  Float64x2List.view.prototype = Float64x2List.prototype;

  class Float32x4 {
    constructor(x, y, z, w) {
    }
    __init_splat(v) {
    }
    __init_zero() {
    }
    __init_fromInt32x4Bits(x) {
    }
    __init_fromFloat64x2(v) {
    }
  }
  Float32x4.splat = function(v) { this.__init_splat(v) };
  Float32x4.splat.prototype = Float32x4.prototype;
  Float32x4.zero = function() { this.__init_zero() };
  Float32x4.zero.prototype = Float32x4.prototype;
  Float32x4.fromInt32x4Bits = function(x) { this.__init_fromInt32x4Bits(x) };
  Float32x4.fromInt32x4Bits.prototype = Float32x4.prototype;
  Float32x4.fromFloat64x2 = function(v) { this.__init_fromFloat64x2(v) };
  Float32x4.fromFloat64x2.prototype = Float32x4.prototype;

  class Int32x4 {
    constructor(x, y, z, w) {
    }
    __init_bool(x, y, z, w) {
    }
    __init_fromFloat32x4Bits(x) {
    }
  }
  Int32x4.bool = function(x, y, z, w) { this.__init_bool(x, y, z, w) };
  Int32x4.bool.prototype = Int32x4.prototype;
  Int32x4.fromFloat32x4Bits = function(x) { this.__init_fromFloat32x4Bits(x) };
  Int32x4.fromFloat32x4Bits.prototype = Int32x4.prototype;

  class Float64x2 {
    constructor(x, y) {
    }
    __init_splat(v) {
    }
    __init_zero() {
    }
    __init_fromFloat32x4(v) {
    }
  }
  Float64x2.splat = function(v) { this.__init_splat(v) };
  Float64x2.splat.prototype = Float64x2.prototype;
  Float64x2.zero = function() { this.__init_zero() };
  Float64x2.zero.prototype = Float64x2.prototype;
  Float64x2.fromFloat32x4 = function(v) { this.__init_fromFloat32x4(v) };
  Float64x2.fromFloat32x4.prototype = Float64x2.prototype;

  // Exports:
  dart.typed_data.ByteBuffer = ByteBuffer;
  dart.typed_data.TypedData = TypedData;
  dart.typed_data.Endianness = Endianness;
  dart.typed_data.ByteData = ByteData;
  dart.typed_data.Int8List = Int8List;
  dart.typed_data.Uint8List = Uint8List;
  dart.typed_data.Uint8ClampedList = Uint8ClampedList;
  dart.typed_data.Int16List = Int16List;
  dart.typed_data.Uint16List = Uint16List;
  dart.typed_data.Int32List = Int32List;
  dart.typed_data.Uint32List = Uint32List;
  dart.typed_data.Int64List = Int64List;
  dart.typed_data.Uint64List = Uint64List;
  dart.typed_data.Float32List = Float32List;
  dart.typed_data.Float64List = Float64List;
  dart.typed_data.Float32x4List = Float32x4List;
  dart.typed_data.Int32x4List = Int32x4List;
  dart.typed_data.Float64x2List = Float64x2List;
  dart.typed_data.Float32x4 = Float32x4;
  dart.typed_data.Int32x4 = Int32x4;
  dart.typed_data.Float64x2 = Float64x2;
})(dart.typed_data || (dart.typed_data = {}));
