import 'dart:isolate';
import 'dart:scalarlist';

void main() {
  int8_receiver();
  uint8_receiver();
  int16_receiver();
  uint16_receiver();
  int32_receiver();
  uint32_receiver();
  int64_receiver();
  uint64_receiver();
  float32_receiver();
  float64_receiver();
}

// Int8 array.
Int8List initInt8() {
  var int8 = new Int8List(2);
  int8[0] = 10;
  int8[1] = 100;
  return int8;
}
Int8List int8 = initInt8();

void int8_receiver() {
  var sp = spawnFunction(int8_sender);
  sp.call(int8.length).then((a) {
    Expect.equals(int8.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(int8[i], a[i]);
    }
    print("int8_receiver");
  });
}

int8_sender() {
  port.receive((len, r) {
    Expect.equals(int8.length, len);
    var a = new Int8List(len);
    for (int i = 0; i < len; i++) {
      a[i] = int8[i];
    }
    r.send(a);
  });
}


// Uint8 array.
Uint8List initUint8() {
  var uint8 = new Uint8List(2);
  uint8[0] = 0xff;
  uint8[1] = 0x7f;
  return uint8;
}
Uint8List uint8 = initUint8();

void uint8_receiver() {
  var sp = spawnFunction(uint8_sender);
  sp.call(uint8.length).then((a) {
    Expect.equals(uint8.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(uint8[i], a[i]);
    }
    print("uint8_receiver");
  });
}

uint8_sender() {
  port.receive((len, r) {
    Expect.equals(uint8.length, len);
    var a = new Uint8List(len);
    for (int i = 0; i < len; i++) {
      a[i] = uint8[i];
    }
    r.send(a);
  });
}


// Int16 array.
Int16List initInt16() {
  var int16 = new Int16List(2);
  int16[0] = 1000;
  int16[1] = 10000;
  return int16;
}
Int16List int16 = initInt16();

void int16_receiver() {
  var sp = spawnFunction(int16_sender);
  sp.call(int16.length).then((a) {
    Expect.equals(int16.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(int16[i], a[i]);
    }
    print("int16_receiver");
  });
}

int16_sender() {
  port.receive((len, r) {
    Expect.equals(int16.length, len);
    var a = new Int16List(len);
    for (int i = 0; i < len; i++) {
      a[i] = int16[i];
    }
    r.send(a);
  });
}


// Uint16 array.
Uint16List initUint16() {
  var uint16 = new Uint16List(2);
  uint16[0] = 0xffff;
  uint16[1] = 0x7fff;
  return uint16;
}
Uint16List uint16 = initUint16();

void uint16_receiver() {
  var sp = spawnFunction(uint16_sender);
  sp.call(uint16.length).then((a) {
    Expect.equals(uint16.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(uint16[i], a[i]);
    }
    print("uint16_receiver");
  });
}

uint16_sender() {
  port.receive((len, r) {
    Expect.equals(uint16.length, len);
    var a = new Uint16List(len);
    for (int i = 0; i < len; i++) {
      a[i] = uint16[i];
    }
    r.send(a);
  });
}


// Int32 array.
Int32List initInt32() {
  var int32 = new Int32List(2);
  int32[0] = 100000;
  int32[1] = 1000000;
  return int32;
}
Int32List int32 = initInt32();

void int32_receiver() {
  var sp = spawnFunction(int32_sender);
  sp.call(int32.length).then((a) {
    Expect.equals(int32.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(int32[i], a[i]);
    }
    print("int32_receiver");
  });
}

int32_sender() {
  port.receive((len, r) {
    Expect.equals(int32.length, len);
    var a = new Int32List(len);
    for (int i = 0; i < len; i++) {
      a[i] = int32[i];
    }
    r.send(a);
  });
}


// Uint32 array.
Uint32List initUint32() {
  var uint32 = new Uint32List(2);
  uint32[0] = 0xffffffff;
  uint32[1] = 0x7fffffff;
  return uint32;
}
Uint32List uint32 = initUint32();

void uint32_receiver() {
  var sp = spawnFunction(uint32_sender);
  sp.call(uint32.length).then((a) {
    Expect.equals(uint32.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(uint32[i], a[i]);
    }
    print("uint32_receiver");
  });
}

uint32_sender() {
  port.receive((len, r) {
    Expect.equals(uint32.length, len);
    var a = new Uint32List(len);
    for (int i = 0; i < len; i++) {
      a[i] = uint32[i];
    }
    r.send(a);
  });
}


// Int64 array.
Int64List initInt64() {
  var int64 = new Int64List(2);
  int64[0] = 10000000;
  int64[1] = 100000000;
  return int64;
}
Int64List int64 = initInt64();

void int64_receiver() {
  var sp = spawnFunction(int64_sender);
  sp.call(int64.length).then((a) {
    Expect.equals(int64.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(int64[i], a[i]);
    }
    print("int64_receiver");
  });
}

int64_sender() {
  port.receive((len, r) {
    Expect.equals(int64.length, len);
    var a = new Int64List(len);
    for (int i = 0; i < len; i++) {
      a[i] = int64[i];
    }
    r.send(a);
  });
}


// Uint64 array.
Uint64List initUint64() {
  var uint64 = new Uint64List(2);
  uint64[0] = 0xffffffffffffffff;
  uint64[1] = 0x7fffffffffffffff;
  return uint64;
}
Uint64List uint64 = initUint64();

void uint64_receiver() {
  var sp = spawnFunction(uint64_sender);
  sp.call(uint64.length).then((a) {
    Expect.equals(uint64.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(uint64[i], a[i]);
    }
    print("uint64_receiver");
  });
}

uint64_sender() {
  port.receive((len, r) {
    Expect.equals(uint64.length, len);
    var a = new Uint64List(len);
    for (int i = 0; i < len; i++) {
      a[i] = uint64[i];
    }
    r.send(a);
  });
}


// Float32 Array.
Float32List initFloat32() {
  var float32 = new Float32List(2);
  float32[0] = 1.0;
  float32[1] = 2.0;
  return float32;
}
Float32List float32 = new Float32List(2);

void float32_receiver() {
  var sp = spawnFunction(float32_sender);
  sp.call(float32.length).then((a) {
    Expect.equals(float32.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(float32[i], a[i]);
    }
    print("float32_receiver");
  });
}

float32_sender() {
  port.receive((len, r) {
    Expect.equals(float32.length, len);
    var a = new Float32List(len);
    for (int i = 0; i < len; i++) {
      a[i] = float32[i];
    }
    r.send(a);
  });
}


// Float64 Array.
Float64List initFloat64() {
  var float64 = new Float64List(2);
  float64[0] = 101.234;
  float64[1] = 201.765;
  return float64;
}
Float64List float64 = initFloat64();

void float64_receiver() {
  var sp = spawnFunction(float64_sender);
  sp.call(float64.length).then((a) {
    Expect.equals(float64.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(float64[i], a[i]);
    }
    print("float64_receiver");
  });
}

float64_sender() {
  port.receive((len, r) {
    Expect.equals(float64.length, len);
    var a = new Float64List(len);
    for (int i = 0; i < len; i++) {
      a[i] = float64[i];
    }
    r.send(a);
  });
}
