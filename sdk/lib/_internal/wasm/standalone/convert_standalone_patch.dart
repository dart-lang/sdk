// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_embedder" as embedder;
import "dart:_internal" show patch, unsafeCast;
import "dart:_string";
import "dart:_string_helper";
import "dart:_wasm";

@patch
class _Utf8Decoder {
  @patch
  String? _convertSingleFastPath(List<int> codeUnits, int start, int end) {
    // Always decode utf-8 in Dart.
    return null;
  }
}

@patch
class _StringParser {
  @patch
  static WasmArray<WasmI16> stringToCharCodeArray(String string, int end) {
    final array = WasmArray<WasmI16>(end);
    if (string.length == end) {
      final externRef = unsafeCast<EmbedderStringImpl>(string).wrappedExternRef;
      embedder.stringToCodeUnits(externRef, array, 0.toWasmI32());
    } else {
      for (int i = 0; i < end; ++i)
        array.write(i, string.codeUnitAtUnchecked(i));
    }

    return array;
  }
}

@patch
double _parseValidFloat(String string) {
  return embedder
      .doubleParseInfallible(
        unsafeCast<EmbedderStringImpl>(string).wrappedExternRef,
      )
      .toDouble();
}

@patch
String _stringFromCharCodeArray(WasmArray<WasmI16> array, int start, int end) {
  return EmbedderStringImpl.fromCharCodeArray(array, start, end);
}

@patch
String _stringFromAsciiBytes(WasmArray<WasmI8> source, int start, int end) {
  return EmbedderStringImpl.fromAsciiBytes(source, start, end);
}
