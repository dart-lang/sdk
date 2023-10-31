// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper" show JS;

part "class_id.dart";
part "deferred.dart";
part "print_patch.dart";
part "symbol_patch.dart";

// Compilation to Wasm is always fully null safe.
@patch
bool typeAcceptsNull<T>() => null is T;

const bool has63BitSmis = false;

class Lists {
  static void copy(List src, int srcStart, List dst, int dstStart, int count) {
    if (srcStart + count > src.length) {
      throw IterableElementError.tooFew();
    }

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
@patch
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

/// Used to invoke a Dart closure from JS (for microtasks and other callbacks),
/// printing any exceptions that escape.
@pragma("wasm:export", "\$invokeCallback")
void _invokeCallback(void Function() callback) {
  try {
    callback();
  } catch (e, s) {
    print(e);
    print(s);
    rethrow;
  }
}

@pragma("wasm:export", "\$invokeCallback1")
void _invokeCallback1(void Function(dynamic) callback, dynamic arg) {
  try {
    callback(arg);
  } catch (e, s) {
    print(e);
    print(s);
    rethrow;
  }
}

/// Used to invoke the `main` function from JS, printing any exceptions that
/// escape.
@pragma("wasm:export", "\$invokeMain")
void _invokeMain(Function main, List<String> args) {
  try {
    if (main is void Function(List<String>, Null)) {
      main(List.unmodifiable(args), null);
    } else if (main is void Function(List<String>)) {
      main(List.unmodifiable(args));
    } else if (main is void Function()) {
      main();
    } else {
      throw "Could not call main";
    }
  } catch (e, s) {
    print(e);
    print(s);
    rethrow;
  }
}

@pragma("wasm:export", "\$makeStringList")
List<String> _makeStringList() => <String>[];

@pragma("wasm:export", "\$listAdd")
void _listAdd(List<dynamic> list, dynamic item) => list.add(item);

String jsonEncode(String object) => JS<String>(
    "s => stringToDartString(JSON.stringify(stringFromDartString(s)))", object);
