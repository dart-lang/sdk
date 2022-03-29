// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data" show Uint8List;

/// The returned string is a [_OneByteString] with uninitialized content.
external String allocateOneByteString(int length);

/// The [string] must be a [_OneByteString]. The [index] must be valid.
external void writeIntoOneByteString(String string, int index, int codePoint);

/// It is assumed that [from] is a native [Uint8List] class and [to] is a
/// [_OneByteString]. The [fromStart] and [toStart] indices together with the
/// [length] must specify ranges within the bounds of the list / string.
void copyRangeFromUint8ListToOneByteString(
    Uint8List from, String to, int fromStart, int toStart, int length) {
  for (int i = 0; i < length; i++) {
    writeIntoOneByteString(to, toStart + i, from[fromStart + i]);
  }
}

/// The returned string is a [_TwoByteString] with uninitialized content.
external String allocateTwoByteString(int length);

/// The [string] must be a [_TwoByteString]. The [index] must be valid.
external void writeIntoTwoByteString(String string, int index, int codePoint);

// String accessors used to perform Dart<->JS string conversion

@pragma("wasm:export", "\$stringLength")
double _stringLength(String string) {
  return string.length.toDouble();
}

@pragma("wasm:export", "\$stringRead")
double _stringRead(String string, double index) {
  return string.codeUnitAt(index.toInt()).toDouble();
}

@pragma("wasm:export", "\$stringAllocate1")
String _stringAllocate1(double length) {
  return allocateOneByteString(length.toInt());
}

@pragma("wasm:export", "\$stringWrite1")
void _stringWrite1(String string, double index, double codePoint) {
  writeIntoOneByteString(string, index.toInt(), codePoint.toInt());
}

@pragma("wasm:export", "\$stringAllocate2")
String _stringAllocate2(double length) {
  return allocateTwoByteString(length.toInt());
}

@pragma("wasm:export", "\$stringWrite2")
void _stringWrite2(String string, double index, double codePoint) {
  writeIntoTwoByteString(string, index.toInt(), codePoint.toInt());
}

const bool has63BitSmis = false;

class Lists {
  static void copy(List src, int srcStart, List dst, int dstStart, int count) {
    // TODO(askesc): Intrinsify for efficient copying
    if (srcStart < dstStart) {
      for (int i = srcStart + count - 1, j = dstStart + count - 1;
          i >= srcStart;
          i--, j--) {
        dst[j] = src[i];
      }
    } else {
      for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
        dst[j] = src[i];
      }
    }
  }
}

// This function can be used to skip implicit or explicit checked down casts in
// the parts of the core library implementation where we know by construction
// the type of a value.
//
// Important: this is unsafe and must be used with care.
external T unsafeCast<T>(Object? v);

// A version of [unsafeCast] that is opaque to the TFA. The TFA knows about the
// [unsafeCast] function and will sharpen the result type with the inferred type
// of the input. When such sharpening is undesirable, this function should be
// used. One such situation is when either the source or destination type is not
// an ordinary Dart type, for instance if it is one of the special Wasm types
// from wasm_types.dart.
external T unsafeCastOpaque<T>(Object? v);

// This function can be used to keep an object alive till that point.
void reachabilityFence(Object? object) {}

// This function can be used to encode native side effects.
external void _nativeEffect(Object object);

// Thomas Wang 64-bit mix.
// https://gist.github.com/badboy/6267743
int mix64(int n) {
  n = (~n) + (n << 21); // n = (n << 21) - n - 1;
  n = n ^ (n >>> 24);
  n = n * 265; // n = (n + (n << 3)) + (n << 8);
  n = n ^ (n >>> 14);
  n = n * 21; // n = (n + (n << 2)) + (n << 4);
  n = n ^ (n >>> 28);
  n = n + (n << 31);
  return n;
}

external int floatToIntBits(double value);
external double intBitsToFloat(int value);
external int doubleToIntBits(double value);
external double intBitsToDouble(int value);

// Exported call stubs to enable JS to call Dart closures. Since all closure
// parameters and returns are boxed (their Wasm type is #Top) the Wasm type of
// the closure will be the same as with all parameters and returns as dynamic.
// Thus, the unsafeCast succeeds, and as long as the passed argumnets have the
// correct types, the argument casts inside the closure will also succeed.

@pragma("wasm:export", "\$call0")
dynamic _callClosure0(dynamic closure) {
  return unsafeCast<dynamic Function()>(closure)();
}

@pragma("wasm:export", "\$call1")
dynamic _callClosure1(dynamic closure, dynamic arg1) {
  return unsafeCast<dynamic Function(dynamic)>(closure)(arg1);
}

@pragma("wasm:export", "\$call2")
dynamic _callClosure2(dynamic closure, dynamic arg1, dynamic arg2) {
  return unsafeCast<dynamic Function(dynamic, dynamic)>(closure)(arg1, arg2);
}

// Schedule a callback from JS via setTimeout.
@pragma("wasm:import", "dart2wasm.scheduleCallback")
external void scheduleCallback(double millis, dynamic Function() callback);
