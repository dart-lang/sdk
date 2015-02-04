var typed_data;
(function (typed_data) {
  'use strict';
  class ByteBuffer {
  }

  class TypedData {
  }

  class Endianness {
    __init__(_littleEndian) {
      this._littleEndian = _littleEndian;
    }
  }
  Endianness._ = function(_littleEndian) { this.__init__(_littleEndian) };
  Endianness._.prototype = Endianness.prototype;
  Endianness.BIG_ENDIAN = new Endianness._(false);
  Endianness.LITTLE_ENDIAN = new Endianness._(true);
  dart.defineLazyProperties(Endianness, {
    get HOST_ENDIAN() { return (new ByteData.view(new Uint16List.fromList(new List.from([1])).buffer)).getInt8(0) === 1 ? LITTLE_ENDIAN : BIG_ENDIAN },
  });

  class ByteData {
    /* Unimplemented external factory ByteData(int length); */
    __init_view(buffer, offsetInBytes, length) {
      if (offsetInBytes === undefined) offsetInBytes = 0;
      if (length === undefined) length = null;
      return buffer.asByteData(offsetInBytes, length);
    }
  }
  ByteData.view = function(buffer, offsetInBytes, length) { this.__init_view(buffer, offsetInBytes, length) };
  ByteData.view.prototype = ByteData.prototype;

  class Int8List {
    /* Unimplemented external factory Int8List(int length); */
    /* Unimplemented external factory Int8List.fromList(List<int> elements); */
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
  Int8List.BYTES_PER_ELEMENT = 1;

  class Uint8List {
    /* Unimplemented external factory Uint8List(int length); */
    /* Unimplemented external factory Uint8List.fromList(List<int> elements); */
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
  Uint8List.BYTES_PER_ELEMENT = 1;

  class Uint8ClampedList {
    /* Unimplemented external factory Uint8ClampedList(int length); */
    /* Unimplemented external factory Uint8ClampedList.fromList(List<int> elements); */
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
  Uint8ClampedList.BYTES_PER_ELEMENT = 1;

  class Int16List {
    /* Unimplemented external factory Int16List(int length); */
    /* Unimplemented external factory Int16List.fromList(List<int> elements); */
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
  Int16List.BYTES_PER_ELEMENT = 2;

  class Uint16List {
    /* Unimplemented external factory Uint16List(int length); */
    /* Unimplemented external factory Uint16List.fromList(List<int> elements); */
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
  Uint16List.BYTES_PER_ELEMENT = 2;

  class Int32List {
    /* Unimplemented external factory Int32List(int length); */
    /* Unimplemented external factory Int32List.fromList(List<int> elements); */
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
  Int32List.BYTES_PER_ELEMENT = 4;

  class Uint32List {
    /* Unimplemented external factory Uint32List(int length); */
    /* Unimplemented external factory Uint32List.fromList(List<int> elements); */
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
  Uint32List.BYTES_PER_ELEMENT = 4;

  class Int64List {
    /* Unimplemented external factory Int64List(int length); */
    /* Unimplemented external factory Int64List.fromList(List<int> elements); */
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
  Int64List.BYTES_PER_ELEMENT = 8;

  class Uint64List {
    /* Unimplemented external factory Uint64List(int length); */
    /* Unimplemented external factory Uint64List.fromList(List<int> elements); */
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
  Uint64List.BYTES_PER_ELEMENT = 8;

  class Float32List {
    /* Unimplemented external factory Float32List(int length); */
    /* Unimplemented external factory Float32List.fromList(List<double> elements); */
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
  Float32List.BYTES_PER_ELEMENT = 4;

  class Float64List {
    /* Unimplemented external factory Float64List(int length); */
    /* Unimplemented external factory Float64List.fromList(List<double> elements); */
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
  Float64List.BYTES_PER_ELEMENT = 8;

  class Float32x4List {
    /* Unimplemented external factory Float32x4List(int length); */
    /* Unimplemented external factory Float32x4List.fromList(List<Float32x4> elements); */
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
  Float32x4List.BYTES_PER_ELEMENT = 16;

  class Int32x4List {
    /* Unimplemented external factory Int32x4List(int length); */
    /* Unimplemented external factory Int32x4List.fromList(List<Int32x4> elements); */
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
  Int32x4List.BYTES_PER_ELEMENT = 16;

  class Float64x2List {
    /* Unimplemented external factory Float64x2List(int length); */
    /* Unimplemented external factory Float64x2List.fromList(List<Float64x2> elements); */
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
  Float64x2List.BYTES_PER_ELEMENT = 16;

  class Float32x4 {
    /* Unimplemented external factory Float32x4(double x, double y, double z, double w); */
    /* Unimplemented external factory Float32x4.splat(double v); */
    /* Unimplemented external factory Float32x4.zero(); */
    /* Unimplemented external factory Float32x4.fromInt32x4Bits(Int32x4 x); */
    /* Unimplemented external factory Float32x4.fromFloat64x2(Float64x2 v); */
  }
  Float32x4.splat = function(v) { this.__init_splat(v) };
  Float32x4.splat.prototype = Float32x4.prototype;
  Float32x4.zero = function() { this.__init_zero() };
  Float32x4.zero.prototype = Float32x4.prototype;
  Float32x4.fromInt32x4Bits = function(x) { this.__init_fromInt32x4Bits(x) };
  Float32x4.fromInt32x4Bits.prototype = Float32x4.prototype;
  Float32x4.fromFloat64x2 = function(v) { this.__init_fromFloat64x2(v) };
  Float32x4.fromFloat64x2.prototype = Float32x4.prototype;
  Float32x4.XXXX = 0;
  Float32x4.XXXY = 64;
  Float32x4.XXXZ = 128;
  Float32x4.XXXW = 192;
  Float32x4.XXYX = 16;
  Float32x4.XXYY = 80;
  Float32x4.XXYZ = 144;
  Float32x4.XXYW = 208;
  Float32x4.XXZX = 32;
  Float32x4.XXZY = 96;
  Float32x4.XXZZ = 160;
  Float32x4.XXZW = 224;
  Float32x4.XXWX = 48;
  Float32x4.XXWY = 112;
  Float32x4.XXWZ = 176;
  Float32x4.XXWW = 240;
  Float32x4.XYXX = 4;
  Float32x4.XYXY = 68;
  Float32x4.XYXZ = 132;
  Float32x4.XYXW = 196;
  Float32x4.XYYX = 20;
  Float32x4.XYYY = 84;
  Float32x4.XYYZ = 148;
  Float32x4.XYYW = 212;
  Float32x4.XYZX = 36;
  Float32x4.XYZY = 100;
  Float32x4.XYZZ = 164;
  Float32x4.XYZW = 228;
  Float32x4.XYWX = 52;
  Float32x4.XYWY = 116;
  Float32x4.XYWZ = 180;
  Float32x4.XYWW = 244;
  Float32x4.XZXX = 8;
  Float32x4.XZXY = 72;
  Float32x4.XZXZ = 136;
  Float32x4.XZXW = 200;
  Float32x4.XZYX = 24;
  Float32x4.XZYY = 88;
  Float32x4.XZYZ = 152;
  Float32x4.XZYW = 216;
  Float32x4.XZZX = 40;
  Float32x4.XZZY = 104;
  Float32x4.XZZZ = 168;
  Float32x4.XZZW = 232;
  Float32x4.XZWX = 56;
  Float32x4.XZWY = 120;
  Float32x4.XZWZ = 184;
  Float32x4.XZWW = 248;
  Float32x4.XWXX = 12;
  Float32x4.XWXY = 76;
  Float32x4.XWXZ = 140;
  Float32x4.XWXW = 204;
  Float32x4.XWYX = 28;
  Float32x4.XWYY = 92;
  Float32x4.XWYZ = 156;
  Float32x4.XWYW = 220;
  Float32x4.XWZX = 44;
  Float32x4.XWZY = 108;
  Float32x4.XWZZ = 172;
  Float32x4.XWZW = 236;
  Float32x4.XWWX = 60;
  Float32x4.XWWY = 124;
  Float32x4.XWWZ = 188;
  Float32x4.XWWW = 252;
  Float32x4.YXXX = 1;
  Float32x4.YXXY = 65;
  Float32x4.YXXZ = 129;
  Float32x4.YXXW = 193;
  Float32x4.YXYX = 17;
  Float32x4.YXYY = 81;
  Float32x4.YXYZ = 145;
  Float32x4.YXYW = 209;
  Float32x4.YXZX = 33;
  Float32x4.YXZY = 97;
  Float32x4.YXZZ = 161;
  Float32x4.YXZW = 225;
  Float32x4.YXWX = 49;
  Float32x4.YXWY = 113;
  Float32x4.YXWZ = 177;
  Float32x4.YXWW = 241;
  Float32x4.YYXX = 5;
  Float32x4.YYXY = 69;
  Float32x4.YYXZ = 133;
  Float32x4.YYXW = 197;
  Float32x4.YYYX = 21;
  Float32x4.YYYY = 85;
  Float32x4.YYYZ = 149;
  Float32x4.YYYW = 213;
  Float32x4.YYZX = 37;
  Float32x4.YYZY = 101;
  Float32x4.YYZZ = 165;
  Float32x4.YYZW = 229;
  Float32x4.YYWX = 53;
  Float32x4.YYWY = 117;
  Float32x4.YYWZ = 181;
  Float32x4.YYWW = 245;
  Float32x4.YZXX = 9;
  Float32x4.YZXY = 73;
  Float32x4.YZXZ = 137;
  Float32x4.YZXW = 201;
  Float32x4.YZYX = 25;
  Float32x4.YZYY = 89;
  Float32x4.YZYZ = 153;
  Float32x4.YZYW = 217;
  Float32x4.YZZX = 41;
  Float32x4.YZZY = 105;
  Float32x4.YZZZ = 169;
  Float32x4.YZZW = 233;
  Float32x4.YZWX = 57;
  Float32x4.YZWY = 121;
  Float32x4.YZWZ = 185;
  Float32x4.YZWW = 249;
  Float32x4.YWXX = 13;
  Float32x4.YWXY = 77;
  Float32x4.YWXZ = 141;
  Float32x4.YWXW = 205;
  Float32x4.YWYX = 29;
  Float32x4.YWYY = 93;
  Float32x4.YWYZ = 157;
  Float32x4.YWYW = 221;
  Float32x4.YWZX = 45;
  Float32x4.YWZY = 109;
  Float32x4.YWZZ = 173;
  Float32x4.YWZW = 237;
  Float32x4.YWWX = 61;
  Float32x4.YWWY = 125;
  Float32x4.YWWZ = 189;
  Float32x4.YWWW = 253;
  Float32x4.ZXXX = 2;
  Float32x4.ZXXY = 66;
  Float32x4.ZXXZ = 130;
  Float32x4.ZXXW = 194;
  Float32x4.ZXYX = 18;
  Float32x4.ZXYY = 82;
  Float32x4.ZXYZ = 146;
  Float32x4.ZXYW = 210;
  Float32x4.ZXZX = 34;
  Float32x4.ZXZY = 98;
  Float32x4.ZXZZ = 162;
  Float32x4.ZXZW = 226;
  Float32x4.ZXWX = 50;
  Float32x4.ZXWY = 114;
  Float32x4.ZXWZ = 178;
  Float32x4.ZXWW = 242;
  Float32x4.ZYXX = 6;
  Float32x4.ZYXY = 70;
  Float32x4.ZYXZ = 134;
  Float32x4.ZYXW = 198;
  Float32x4.ZYYX = 22;
  Float32x4.ZYYY = 86;
  Float32x4.ZYYZ = 150;
  Float32x4.ZYYW = 214;
  Float32x4.ZYZX = 38;
  Float32x4.ZYZY = 102;
  Float32x4.ZYZZ = 166;
  Float32x4.ZYZW = 230;
  Float32x4.ZYWX = 54;
  Float32x4.ZYWY = 118;
  Float32x4.ZYWZ = 182;
  Float32x4.ZYWW = 246;
  Float32x4.ZZXX = 10;
  Float32x4.ZZXY = 74;
  Float32x4.ZZXZ = 138;
  Float32x4.ZZXW = 202;
  Float32x4.ZZYX = 26;
  Float32x4.ZZYY = 90;
  Float32x4.ZZYZ = 154;
  Float32x4.ZZYW = 218;
  Float32x4.ZZZX = 42;
  Float32x4.ZZZY = 106;
  Float32x4.ZZZZ = 170;
  Float32x4.ZZZW = 234;
  Float32x4.ZZWX = 58;
  Float32x4.ZZWY = 122;
  Float32x4.ZZWZ = 186;
  Float32x4.ZZWW = 250;
  Float32x4.ZWXX = 14;
  Float32x4.ZWXY = 78;
  Float32x4.ZWXZ = 142;
  Float32x4.ZWXW = 206;
  Float32x4.ZWYX = 30;
  Float32x4.ZWYY = 94;
  Float32x4.ZWYZ = 158;
  Float32x4.ZWYW = 222;
  Float32x4.ZWZX = 46;
  Float32x4.ZWZY = 110;
  Float32x4.ZWZZ = 174;
  Float32x4.ZWZW = 238;
  Float32x4.ZWWX = 62;
  Float32x4.ZWWY = 126;
  Float32x4.ZWWZ = 190;
  Float32x4.ZWWW = 254;
  Float32x4.WXXX = 3;
  Float32x4.WXXY = 67;
  Float32x4.WXXZ = 131;
  Float32x4.WXXW = 195;
  Float32x4.WXYX = 19;
  Float32x4.WXYY = 83;
  Float32x4.WXYZ = 147;
  Float32x4.WXYW = 211;
  Float32x4.WXZX = 35;
  Float32x4.WXZY = 99;
  Float32x4.WXZZ = 163;
  Float32x4.WXZW = 227;
  Float32x4.WXWX = 51;
  Float32x4.WXWY = 115;
  Float32x4.WXWZ = 179;
  Float32x4.WXWW = 243;
  Float32x4.WYXX = 7;
  Float32x4.WYXY = 71;
  Float32x4.WYXZ = 135;
  Float32x4.WYXW = 199;
  Float32x4.WYYX = 23;
  Float32x4.WYYY = 87;
  Float32x4.WYYZ = 151;
  Float32x4.WYYW = 215;
  Float32x4.WYZX = 39;
  Float32x4.WYZY = 103;
  Float32x4.WYZZ = 167;
  Float32x4.WYZW = 231;
  Float32x4.WYWX = 55;
  Float32x4.WYWY = 119;
  Float32x4.WYWZ = 183;
  Float32x4.WYWW = 247;
  Float32x4.WZXX = 11;
  Float32x4.WZXY = 75;
  Float32x4.WZXZ = 139;
  Float32x4.WZXW = 203;
  Float32x4.WZYX = 27;
  Float32x4.WZYY = 91;
  Float32x4.WZYZ = 155;
  Float32x4.WZYW = 219;
  Float32x4.WZZX = 43;
  Float32x4.WZZY = 107;
  Float32x4.WZZZ = 171;
  Float32x4.WZZW = 235;
  Float32x4.WZWX = 59;
  Float32x4.WZWY = 123;
  Float32x4.WZWZ = 187;
  Float32x4.WZWW = 251;
  Float32x4.WWXX = 15;
  Float32x4.WWXY = 79;
  Float32x4.WWXZ = 143;
  Float32x4.WWXW = 207;
  Float32x4.WWYX = 31;
  Float32x4.WWYY = 95;
  Float32x4.WWYZ = 159;
  Float32x4.WWYW = 223;
  Float32x4.WWZX = 47;
  Float32x4.WWZY = 111;
  Float32x4.WWZZ = 175;
  Float32x4.WWZW = 239;
  Float32x4.WWWX = 63;
  Float32x4.WWWY = 127;
  Float32x4.WWWZ = 191;
  Float32x4.WWWW = 255;

  class Int32x4 {
    /* Unimplemented external factory Int32x4(int x, int y, int z, int w); */
    /* Unimplemented external factory Int32x4.bool(bool x, bool y, bool z, bool w); */
    /* Unimplemented external factory Int32x4.fromFloat32x4Bits(Float32x4 x); */
  }
  Int32x4.bool = function(x, y, z, w) { this.__init_bool(x, y, z, w) };
  Int32x4.bool.prototype = Int32x4.prototype;
  Int32x4.fromFloat32x4Bits = function(x) { this.__init_fromFloat32x4Bits(x) };
  Int32x4.fromFloat32x4Bits.prototype = Int32x4.prototype;
  Int32x4.XXXX = 0;
  Int32x4.XXXY = 64;
  Int32x4.XXXZ = 128;
  Int32x4.XXXW = 192;
  Int32x4.XXYX = 16;
  Int32x4.XXYY = 80;
  Int32x4.XXYZ = 144;
  Int32x4.XXYW = 208;
  Int32x4.XXZX = 32;
  Int32x4.XXZY = 96;
  Int32x4.XXZZ = 160;
  Int32x4.XXZW = 224;
  Int32x4.XXWX = 48;
  Int32x4.XXWY = 112;
  Int32x4.XXWZ = 176;
  Int32x4.XXWW = 240;
  Int32x4.XYXX = 4;
  Int32x4.XYXY = 68;
  Int32x4.XYXZ = 132;
  Int32x4.XYXW = 196;
  Int32x4.XYYX = 20;
  Int32x4.XYYY = 84;
  Int32x4.XYYZ = 148;
  Int32x4.XYYW = 212;
  Int32x4.XYZX = 36;
  Int32x4.XYZY = 100;
  Int32x4.XYZZ = 164;
  Int32x4.XYZW = 228;
  Int32x4.XYWX = 52;
  Int32x4.XYWY = 116;
  Int32x4.XYWZ = 180;
  Int32x4.XYWW = 244;
  Int32x4.XZXX = 8;
  Int32x4.XZXY = 72;
  Int32x4.XZXZ = 136;
  Int32x4.XZXW = 200;
  Int32x4.XZYX = 24;
  Int32x4.XZYY = 88;
  Int32x4.XZYZ = 152;
  Int32x4.XZYW = 216;
  Int32x4.XZZX = 40;
  Int32x4.XZZY = 104;
  Int32x4.XZZZ = 168;
  Int32x4.XZZW = 232;
  Int32x4.XZWX = 56;
  Int32x4.XZWY = 120;
  Int32x4.XZWZ = 184;
  Int32x4.XZWW = 248;
  Int32x4.XWXX = 12;
  Int32x4.XWXY = 76;
  Int32x4.XWXZ = 140;
  Int32x4.XWXW = 204;
  Int32x4.XWYX = 28;
  Int32x4.XWYY = 92;
  Int32x4.XWYZ = 156;
  Int32x4.XWYW = 220;
  Int32x4.XWZX = 44;
  Int32x4.XWZY = 108;
  Int32x4.XWZZ = 172;
  Int32x4.XWZW = 236;
  Int32x4.XWWX = 60;
  Int32x4.XWWY = 124;
  Int32x4.XWWZ = 188;
  Int32x4.XWWW = 252;
  Int32x4.YXXX = 1;
  Int32x4.YXXY = 65;
  Int32x4.YXXZ = 129;
  Int32x4.YXXW = 193;
  Int32x4.YXYX = 17;
  Int32x4.YXYY = 81;
  Int32x4.YXYZ = 145;
  Int32x4.YXYW = 209;
  Int32x4.YXZX = 33;
  Int32x4.YXZY = 97;
  Int32x4.YXZZ = 161;
  Int32x4.YXZW = 225;
  Int32x4.YXWX = 49;
  Int32x4.YXWY = 113;
  Int32x4.YXWZ = 177;
  Int32x4.YXWW = 241;
  Int32x4.YYXX = 5;
  Int32x4.YYXY = 69;
  Int32x4.YYXZ = 133;
  Int32x4.YYXW = 197;
  Int32x4.YYYX = 21;
  Int32x4.YYYY = 85;
  Int32x4.YYYZ = 149;
  Int32x4.YYYW = 213;
  Int32x4.YYZX = 37;
  Int32x4.YYZY = 101;
  Int32x4.YYZZ = 165;
  Int32x4.YYZW = 229;
  Int32x4.YYWX = 53;
  Int32x4.YYWY = 117;
  Int32x4.YYWZ = 181;
  Int32x4.YYWW = 245;
  Int32x4.YZXX = 9;
  Int32x4.YZXY = 73;
  Int32x4.YZXZ = 137;
  Int32x4.YZXW = 201;
  Int32x4.YZYX = 25;
  Int32x4.YZYY = 89;
  Int32x4.YZYZ = 153;
  Int32x4.YZYW = 217;
  Int32x4.YZZX = 41;
  Int32x4.YZZY = 105;
  Int32x4.YZZZ = 169;
  Int32x4.YZZW = 233;
  Int32x4.YZWX = 57;
  Int32x4.YZWY = 121;
  Int32x4.YZWZ = 185;
  Int32x4.YZWW = 249;
  Int32x4.YWXX = 13;
  Int32x4.YWXY = 77;
  Int32x4.YWXZ = 141;
  Int32x4.YWXW = 205;
  Int32x4.YWYX = 29;
  Int32x4.YWYY = 93;
  Int32x4.YWYZ = 157;
  Int32x4.YWYW = 221;
  Int32x4.YWZX = 45;
  Int32x4.YWZY = 109;
  Int32x4.YWZZ = 173;
  Int32x4.YWZW = 237;
  Int32x4.YWWX = 61;
  Int32x4.YWWY = 125;
  Int32x4.YWWZ = 189;
  Int32x4.YWWW = 253;
  Int32x4.ZXXX = 2;
  Int32x4.ZXXY = 66;
  Int32x4.ZXXZ = 130;
  Int32x4.ZXXW = 194;
  Int32x4.ZXYX = 18;
  Int32x4.ZXYY = 82;
  Int32x4.ZXYZ = 146;
  Int32x4.ZXYW = 210;
  Int32x4.ZXZX = 34;
  Int32x4.ZXZY = 98;
  Int32x4.ZXZZ = 162;
  Int32x4.ZXZW = 226;
  Int32x4.ZXWX = 50;
  Int32x4.ZXWY = 114;
  Int32x4.ZXWZ = 178;
  Int32x4.ZXWW = 242;
  Int32x4.ZYXX = 6;
  Int32x4.ZYXY = 70;
  Int32x4.ZYXZ = 134;
  Int32x4.ZYXW = 198;
  Int32x4.ZYYX = 22;
  Int32x4.ZYYY = 86;
  Int32x4.ZYYZ = 150;
  Int32x4.ZYYW = 214;
  Int32x4.ZYZX = 38;
  Int32x4.ZYZY = 102;
  Int32x4.ZYZZ = 166;
  Int32x4.ZYZW = 230;
  Int32x4.ZYWX = 54;
  Int32x4.ZYWY = 118;
  Int32x4.ZYWZ = 182;
  Int32x4.ZYWW = 246;
  Int32x4.ZZXX = 10;
  Int32x4.ZZXY = 74;
  Int32x4.ZZXZ = 138;
  Int32x4.ZZXW = 202;
  Int32x4.ZZYX = 26;
  Int32x4.ZZYY = 90;
  Int32x4.ZZYZ = 154;
  Int32x4.ZZYW = 218;
  Int32x4.ZZZX = 42;
  Int32x4.ZZZY = 106;
  Int32x4.ZZZZ = 170;
  Int32x4.ZZZW = 234;
  Int32x4.ZZWX = 58;
  Int32x4.ZZWY = 122;
  Int32x4.ZZWZ = 186;
  Int32x4.ZZWW = 250;
  Int32x4.ZWXX = 14;
  Int32x4.ZWXY = 78;
  Int32x4.ZWXZ = 142;
  Int32x4.ZWXW = 206;
  Int32x4.ZWYX = 30;
  Int32x4.ZWYY = 94;
  Int32x4.ZWYZ = 158;
  Int32x4.ZWYW = 222;
  Int32x4.ZWZX = 46;
  Int32x4.ZWZY = 110;
  Int32x4.ZWZZ = 174;
  Int32x4.ZWZW = 238;
  Int32x4.ZWWX = 62;
  Int32x4.ZWWY = 126;
  Int32x4.ZWWZ = 190;
  Int32x4.ZWWW = 254;
  Int32x4.WXXX = 3;
  Int32x4.WXXY = 67;
  Int32x4.WXXZ = 131;
  Int32x4.WXXW = 195;
  Int32x4.WXYX = 19;
  Int32x4.WXYY = 83;
  Int32x4.WXYZ = 147;
  Int32x4.WXYW = 211;
  Int32x4.WXZX = 35;
  Int32x4.WXZY = 99;
  Int32x4.WXZZ = 163;
  Int32x4.WXZW = 227;
  Int32x4.WXWX = 51;
  Int32x4.WXWY = 115;
  Int32x4.WXWZ = 179;
  Int32x4.WXWW = 243;
  Int32x4.WYXX = 7;
  Int32x4.WYXY = 71;
  Int32x4.WYXZ = 135;
  Int32x4.WYXW = 199;
  Int32x4.WYYX = 23;
  Int32x4.WYYY = 87;
  Int32x4.WYYZ = 151;
  Int32x4.WYYW = 215;
  Int32x4.WYZX = 39;
  Int32x4.WYZY = 103;
  Int32x4.WYZZ = 167;
  Int32x4.WYZW = 231;
  Int32x4.WYWX = 55;
  Int32x4.WYWY = 119;
  Int32x4.WYWZ = 183;
  Int32x4.WYWW = 247;
  Int32x4.WZXX = 11;
  Int32x4.WZXY = 75;
  Int32x4.WZXZ = 139;
  Int32x4.WZXW = 203;
  Int32x4.WZYX = 27;
  Int32x4.WZYY = 91;
  Int32x4.WZYZ = 155;
  Int32x4.WZYW = 219;
  Int32x4.WZZX = 43;
  Int32x4.WZZY = 107;
  Int32x4.WZZZ = 171;
  Int32x4.WZZW = 235;
  Int32x4.WZWX = 59;
  Int32x4.WZWY = 123;
  Int32x4.WZWZ = 187;
  Int32x4.WZWW = 251;
  Int32x4.WWXX = 15;
  Int32x4.WWXY = 79;
  Int32x4.WWXZ = 143;
  Int32x4.WWXW = 207;
  Int32x4.WWYX = 31;
  Int32x4.WWYY = 95;
  Int32x4.WWYZ = 159;
  Int32x4.WWYW = 223;
  Int32x4.WWZX = 47;
  Int32x4.WWZY = 111;
  Int32x4.WWZZ = 175;
  Int32x4.WWZW = 239;
  Int32x4.WWWX = 63;
  Int32x4.WWWY = 127;
  Int32x4.WWWZ = 191;
  Int32x4.WWWW = 255;

  class Float64x2 {
    /* Unimplemented external factory Float64x2(double x, double y); */
    /* Unimplemented external factory Float64x2.splat(double v); */
    /* Unimplemented external factory Float64x2.zero(); */
    /* Unimplemented external factory Float64x2.fromFloat32x4(Float32x4 v); */
  }
  Float64x2.splat = function(v) { this.__init_splat(v) };
  Float64x2.splat.prototype = Float64x2.prototype;
  Float64x2.zero = function() { this.__init_zero() };
  Float64x2.zero.prototype = Float64x2.prototype;
  Float64x2.fromFloat32x4 = function(v) { this.__init_fromFloat32x4(v) };
  Float64x2.fromFloat32x4.prototype = Float64x2.prototype;

  // Exports:
  typed_data.ByteBuffer = ByteBuffer;
  typed_data.TypedData = TypedData;
  typed_data.Endianness = Endianness;
  typed_data.ByteData = ByteData;
  typed_data.Int8List = Int8List;
  typed_data.Uint8List = Uint8List;
  typed_data.Uint8ClampedList = Uint8ClampedList;
  typed_data.Int16List = Int16List;
  typed_data.Uint16List = Uint16List;
  typed_data.Int32List = Int32List;
  typed_data.Uint32List = Uint32List;
  typed_data.Int64List = Int64List;
  typed_data.Uint64List = Uint64List;
  typed_data.Float32List = Float32List;
  typed_data.Float64List = Float64List;
  typed_data.Float32x4List = Float32x4List;
  typed_data.Int32x4List = Int32x4List;
  typed_data.Float64x2List = Float64x2List;
  typed_data.Float32x4 = Float32x4;
  typed_data.Int32x4 = Int32x4;
  typed_data.Float64x2 = Float64x2;
})(typed_data || (typed_data = {}));
