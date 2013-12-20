// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests typed-data buffer classes.

import "package:typed_data/typed_buffers.dart";
import "package:unittest/unittest.dart";
import "dart:typed_data";

main() {
  testUint(8, (l) => new Uint8Buffer(l));
  testInt(8, (l) => new Int8Buffer(l));
  test("Uint8ClampedBuffer", () {
    testIntBuffer(8, 0, 255, (l) => new Uint8ClampedBuffer(l), clampUint8);
  });
  testUint(16, (l) => new Uint16Buffer(l));
  testInt(16, (l) => new Int16Buffer(l));
  testUint(32, (l) => new Uint32Buffer(l));  /// 01: ok
  testInt(32, (l) => new Int32Buffer(l));
  testUint(64, (l) => new Uint64Buffer(l));  /// 01: continued
  testInt(64, (l) => new Int64Buffer(l));    /// 01: continued

  testInt32x4Buffer(intSamples);

  List roundedFloatSamples = floatSamples.map(roundToFloat).toList();
  testFloatBuffer(32, roundedFloatSamples,
                  () => new Float32Buffer(),
                  roundToFloat);
  testFloatBuffer(64, doubleSamples, () => new Float64Buffer(), (x) => x);

  testFloat32x4Buffer(roundedFloatSamples);
}

double roundToFloat(double value) {
  return (new Float32List(1)..[0] = value)[0];
}

typedef int Rounder(int value);

Rounder roundUint(bits) {
  int halfbits = (1 << (bits ~/ 2)) - 1;
  int mask = halfbits | (halfbits << (bits ~/ 2));
  return (int x) => x & mask;
}

Rounder roundInt(bits) {
  int highBit = 1 << (bits - 1);
  int mask = highBit - 1;
  return (int x) => (x & mask) - (x & highBit);
}

int clampUint8(x) => x < 0 ? 0 : x > 255 ? 255 : x;

void testUint(int bits, var buffer) {
  int min = 0;
  Function round = roundUint(bits);
  int max = round(-1);
  test("Uint${bits}Buffer", () {
    testIntBuffer(bits, min, max, buffer, round);
  });
}

void testInt(int bits, var buffer) {
  int min = -(1 << (bits - 1));
  int max = -(min + 1);
  test("Int${bits}Buffer", () {
    testIntBuffer(bits, min, max, buffer, roundInt(bits));
  });
}

const List<int> intSamples = const [
  0x10000000000000001,
  0x10000000000000000,  // 2^64
  0x0ffffffffffffffff,
  0xaaaaaaaaaaaaaaaa,
  0x8000000000000001,
  0x8000000000000000,   // 2^63
  0x7fffffffffffffff,
  0x5555555555555555,
  0x100000001,
  0x100000000,  // 2^32
  0x0ffffffff,
  0xaaaaaaaa,
  0x80000001,
  0x80000000,   // 2^31
  0x7fffffff,
  0x55555555,
  0x10001,
  0x10000,      // 2^16
  0x0ffff,
  0xaaaa,
  0x8001,
  0x8000,       // 2^15
  0x7fff,
  0x5555,
  0x101,
  0x100,        // 2^8
  0x0ff,
  0xaa,
  0x81,
  0x80,         // 2^7
  0x7f,
  0x55,
  0x02,
  0x01,
  0x00
];

// Takes bit-size, min value, max value, function to create a buffer, and
// the rounding that is applied when storing values outside the valid range
// into the buffer.
void testIntBuffer(int bits, int min, int max,
                   create(int length),
                   int round(int)) {
  assert(round(min) == min);
  assert(round(max) == max);
  // All int buffers default to the value 0.
  var buffer = create(0);
  List<int> list = buffer;  // Check the type.
  expect(buffer.length, equals(0));
  var bytes = bits ~/ 8;

  expect(buffer.elementSizeInBytes, equals(bytes));
  expect(buffer.lengthInBytes, equals(0));
  expect(buffer.offsetInBytes, equals(0));

  buffer.add(min);
  expect(buffer.length, equals(1));
  expect(buffer[0], equals(min));

  expect(buffer.elementSizeInBytes, equals(bytes));
  expect(buffer.lengthInBytes, equals(bytes));
  expect(buffer.offsetInBytes, equals(0));

  buffer.length = 0;
  expect(buffer.length, equals(0));

  List samples = intSamples.toList()..addAll(intSamples.map((x) => -x));
  for (int value in samples) {
    int length = buffer.length;
    buffer.add(value);
    expect(buffer.length, equals(length + 1));
    expect(buffer[length], equals(round(value)));
  }
  buffer.addAll(samples);  // Add all the values at once.
  for (int i = 0; i < samples.length; i++) {
    expect(buffer[samples.length + i], equals(buffer[i]));
  }

  // Remove range works and changes length.
  buffer.removeRange(samples.length, buffer.length);
  expect(buffer.length, equals(samples.length));

  // Both values are in `samples`, but equality is performed without rounding.
  expect(buffer.contains(min - 1), isFalse);
  expect(buffer.contains(max + 1), isFalse);
  expect(buffer.contains(round(min - 1)), isTrue);
  expect(buffer.contains(round(max + 1)), isTrue);

  // Accessing the underlying buffer works.
  buffer.length = 2;
  buffer[0] = min;
  buffer[1] = max;
  var byteBuffer = new Uint8List.view(buffer.buffer);
  int byteSize = buffer.elementSizeInBytes;
  for (int i = 0; i < byteSize; i++) {
    int tmp = byteBuffer[i];
    byteBuffer[i] = byteBuffer[byteSize + i];
    byteBuffer[byteSize + i] = tmp;
  }
  expect(buffer[0], equals(max));
  expect(buffer[1], equals(min));
}

const List doubleSamples = const [
  0.0,
  5e-324,                    // Minimal denormal value.
  2.225073858507201e-308,    // Maximal denormal value.
  2.2250738585072014e-308,   // Minimal normal value.
  0.9999999999999999,        // Maximum value < 1.
  1.0,
  1.0000000000000002,        // Minimum value > 1.
  4294967295.0,              // 2^32 -1.
  4294967296.0,              // 2^32.
  4503599627370495.5,        // Maximal fractional value.
  9007199254740992.0,        // Maximal exact value (adding one gets lost).
  1.7976931348623157e+308,   // Maximal value.
  1.0/0.0,                   // Infinity.
  0.0/0.0,                   // NaN.
  0.49999999999999994,       // Round-traps 1-3 (adding 0.5 and rounding towards
  4503599627370497.0,        // minus infinity will not be the same as rounding
  9007199254740991.0         // to nearest with 0.5 rounding up).
];

const List floatSamples = const [
  0.0,
  1.4e-45,          // Minimal denormal value.
  1.1754942E-38,    // Maximal denormal value.
  1.17549435E-38,   // Minimal normal value.
  0.99999994,       // Maximal value < 1.
  1.0,
  1.0000001,        // Minimal value > 1.
  8388607.5,        // Maximal fractional value.
  16777216.0,       // Maximal exact value.
  3.4028235e+38,    // Maximal value.
  1.0/0.0,          // Infinity.
  0.0/0.0,          // NaN.
  0.99999994,       // Round traps 1-3.
  8388609.0,
  16777215.0
];

void doubleEqual(x, y) {
  if (y.isNaN) {
    expect(x.isNaN, isTrue);
  } else {
    if (x != y) {
    }
    expect(x, equals(y));
  }
}

testFloatBuffer(int bitSize, List samples, create(), double round(double v)) {
  test("Float${bitSize}Buffer", () {
    var buffer = create();
    List<double> list = buffer;  // Test type.
    int byteSize = bitSize ~/ 8;

    expect(buffer.length, equals(0));
    buffer.add(0.0);
    expect(buffer.length, equals(1));
    expect(buffer.removeLast(), equals(0.0));
    expect(buffer.length, equals(0));

    for (double value in samples) {
      buffer.add(value);
      doubleEqual(buffer[buffer.length - 1], round(value));
    }
    expect(buffer.length, equals(samples.length));

    buffer.addAll(samples);
    expect(buffer.length, equals(samples.length * 2));
    for (int i = 0; i < samples.length; i++) {
      doubleEqual(buffer[i], buffer[samples.length + i]);
    }

    buffer.removeRange(samples.length, buffer.length);
    expect(buffer.length, equals(samples.length));

    buffer.insertAll(0, samples);
    expect(buffer.length, equals(samples.length * 2));
    for (int i = 0; i < samples.length; i++) {
      doubleEqual(buffer[i], buffer[samples.length + i]);
    }

    buffer.length = samples.length;
    expect(buffer.length, equals(samples.length));

    // TypedData.
    expect(buffer.elementSizeInBytes, equals(byteSize));
    expect(buffer.lengthInBytes, equals(byteSize * buffer.length));
    expect(buffer.offsetInBytes, equals(0));

    // Accessing the buffer works.
    // Accessing the underlying buffer works.
    buffer.length = 2;
    buffer[0] = samples[0];
    buffer[1] = samples[1];
    var bytes = new Uint8List.view(buffer.buffer);
    for (int i = 0; i < byteSize; i++) {
      int tmp = bytes[i];
      bytes[i] = bytes[byteSize + i];
      bytes[byteSize + i] = tmp;
    }
    doubleEqual(buffer[0], round(samples[1]));
    doubleEqual(buffer[1], round(samples[0]));
  });
}

testFloat32x4Buffer(List floatSamples) {
  List float4Samples = [];
  for (int i = 0; i < floatSamples.length - 3; i++) {
    float4Samples.add(new Float32x4(floatSamples[i],
                                    floatSamples[i + 1],
                                    floatSamples[i + 2],
                                    floatSamples[i + 3]));
  }

  void floatEquals(x, y) {
    if (y.isNaN) {
      expect(x.isNaN, isTrue);
    } else {
      expect(x, equals(y));
    }
  }

  void x4Equals(Float32x4 x, Float32x4 y) {
    floatEquals(x.x, y.x);
    floatEquals(x.y, y.y);
    floatEquals(x.z, y.z);
    floatEquals(x.w, y.w);
  }

  test("Float32x4Buffer", () {
    var buffer = new Float32x4Buffer(5);
    List<Float32x4> list = buffer;

    expect(buffer.length, equals(5));
    expect(buffer.elementSizeInBytes, equals(128 ~/ 8));
    expect(buffer.lengthInBytes, equals(5 * 128 ~/ 8));
    expect(buffer.offsetInBytes, equals(0));

    x4Equals(buffer[0], new Float32x4.zero());
    buffer.length = 0;
    expect(buffer.length, equals(0));

    for (var sample in float4Samples) {
      buffer.add(sample);
      x4Equals(buffer[buffer.length - 1], sample);
    }
    expect(buffer.length, equals(float4Samples.length));

    buffer.addAll(float4Samples);
    expect(buffer.length, equals(float4Samples.length * 2));
    for (int i = 0; i < float4Samples.length; i++) {
      x4Equals(buffer[i], buffer[float4Samples.length + i]);
    }

    buffer.removeRange(4, 4 + float4Samples.length);
    for (int i = 0; i < float4Samples.length; i++) {
      x4Equals(buffer[i], float4Samples[i]);
    }

    // Test underlying buffer.
    buffer.length = 1;
    buffer[0] = float4Samples[0];  // Does not contain NaN.

    Float32List floats = new Float32List.view(buffer.buffer);
    expect(floats[0], equals(buffer[0].x));
    expect(floats[1], equals(buffer[0].y));
    expect(floats[2], equals(buffer[0].z));
    expect(floats[3], equals(buffer[0].w));
  });
}

void testInt32x4Buffer(intSamples) {
  test("Int32x4Buffer", () {
    Function round = roundInt(32);
    int bits = 128;
    int bytes = 128 ~/ 8;
    Matcher equals32x4(Int32x4 expected) => new MatchesInt32x4(expected);

    var buffer = new Int32x4Buffer(0);
    List<Int32x4> list = buffer;     // It's a List.
    expect(buffer.length, equals(0));

    expect(buffer.elementSizeInBytes, equals(bytes));
    expect(buffer.lengthInBytes, equals(0));
    expect(buffer.offsetInBytes, equals(0));

    Int32x4 sample = new Int32x4(-0x80000000, -1, 0, 0x7fffffff);
    buffer.add(sample);
    expect(buffer.length, equals(1));
    expect(buffer[0], equals32x4(sample));

    expect(buffer.elementSizeInBytes, equals(bytes));
    expect(buffer.lengthInBytes, equals(bytes));
    expect(buffer.offsetInBytes, equals(0));

    buffer.length = 0;
    expect(buffer.length, equals(0));

    var samples = intSamples
        .where((value) => value == round(value))   // Issue 15130
        .map((value) => new Int32x4(value, -value, ~value, ~-value))
        .toList();
    for (Int32x4 value in samples) {
      int length = buffer.length;
      buffer.add(value);
      expect(buffer.length, equals(length + 1));
      expect(buffer[length], equals32x4(value));
    }

    buffer.addAll(samples);  // Add all the values at once.
    for (int i = 0; i < samples.length; i++) {
      expect(buffer[samples.length + i], equals32x4(buffer[i]));
    }

    // Remove range works and changes length.
    buffer.removeRange(samples.length, buffer.length);
    expect(buffer.length, equals(samples.length));

    // Accessing the underlying buffer works.
    buffer.length = 2;
    buffer[0] = new Int32x4(-80000000, 0x7fffffff, 0, -1);
    var byteBuffer = new Uint8List.view(buffer.buffer);
    int halfBytes = bytes ~/ 2;
    for (int i = 0; i < halfBytes; i++) {
      int tmp = byteBuffer[i];
      byteBuffer[i] = byteBuffer[halfBytes + i];
      byteBuffer[halfBytes + i] = tmp;
    }
    var result = new Int32x4(0, -1, -80000000, 0x7fffffff);
    expect(buffer[0], equals32x4(result));
  });
}

class MatchesInt32x4 extends Matcher {
  Int32x4 result;
  MatchesInt32x4(this.result);
  bool matches(item, Map matchState) {
    if (item is! Int32x4) return false;
    Int32x4 value = item;
    return result.x == value.x && result.y == value.y &&
           result.z == value.z && result.w == value.w;
  }

  Description describe(Description description) =>
      description.add('Int32x4.==');
}
