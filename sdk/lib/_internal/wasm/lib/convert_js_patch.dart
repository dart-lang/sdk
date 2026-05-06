// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_error_utils";
import "dart:_internal" show patch, unsafeCast;
import "dart:_js_string_convert";
import "dart:_js_types";
import "dart:_js_helper" show JS, jsStringFromDartString, JSExternWrapperExt;
import "dart:_object_helper";
import "dart:_string";
import "dart:_typed_data";
import "dart:_wasm";

@patch
class _Utf8Decoder {
  @patch
  String? _convertSingleFastPath(List<int> codeUnits, int start, int end) {
    if (codeUnits is JSUint8ArrayImpl) {
      return decodeUtf8JS(codeUnits, start, end, allowMalformed);
    }
  }
}

@patch
class _StringParser {
  @patch
  static WasmArray<WasmI16> stringToCharCodeArray(String string, int end) {
    final externRef = jsStringFromDartString(string).wrappedExternRef;
    final array = WasmArray<WasmI16>(end);
    if (string.length == end) {
      jsStringIntoCharCodeArray(externRef, array, 0.toWasmI32());
    } else {
      for (int i = 0; i < end; ++i) array.write(i, jsCharCodeAt(externRef, i));
    }

    return array;
  }
}

// Assumes the given [string] is a valid float, so it can rely on the implicit
// string to number conversion in JS using `+<string-of-number>`.
@patch
double _parseValidFloat(String string) =>
    JS<double>('(s) => +s', jsStringFromDartString(string).wrappedExternRef);

@patch
String _stringFromCharCodeArray(WasmArray<WasmI16> array, int start, int end) {
  return JSStringImpl.fromCharCodeArray(array, start, end);
}

@patch
String _stringFromAsciiBytes(WasmArray<WasmI8> source, int start, int end) {
  return JSStringImpl.fromAsciiBytes(source, start, end);
}
