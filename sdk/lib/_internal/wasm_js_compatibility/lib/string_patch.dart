// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show EfficientLengthIterable, patch, unsafeCast;
import 'dart:_js_helper' as js;
import 'dart:_js_types';
import 'dart:_wasm';
import 'dart:js_interop';
import 'dart:typed_data';

@patch
class String {
  @patch
  factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int? end]) {
    final length = charCodes.length;

    RangeError.checkValueInInterval(start, 0, length);

    if (end != null) {
      RangeError.checkValueInInterval(end, start, length);
    }

    // Skip until `start`.
    final it = charCodes.iterator;
    for (int i = 0; i < start; i++) {
      it.moveNext();
    }

    // The part of the iterable converted to string is collected in a JS typed
    // array, to be able to effciently get subarrays, to pass to
    // `String.fromCharCode.apply`.
    final charCodesLength = (end ?? length) - start;
    final typedArrayLength = charCodesLength * 2;
    final JSUint32ArrayImpl list =
        unsafeCast<JSUint32ArrayImpl>(Uint32List(typedArrayLength));
    int index = 0; // index in `list`.
    end ??= start + charCodesLength;
    for (int i = start; i < end; i++) {
      if (!it.moveNext()) {
        throw RangeError.range(end, start, i);
      }
      final charCode = it.current;
      if (charCode >= 0 && charCode <= 0xffff) {
        list[index++] = charCode;
      } else if (charCode >= 0 && charCode <= 0x10ffff) {
        list[index++] = 0xd800 + ((((charCode - 0x10000) >> 10) & 0x3ff));
        list[index++] = 0xdc00 + (charCode & 0x3ff);
      } else {
        throw RangeError.range(charCode, 0, 0x10ffff);
      }
    }

    // Create JS string from `list`.
    const kMaxApply = 500;
    if (index <= kMaxApply) {
      return _fromCharCodeApplySubarray(list.toExternRef, 0, index.toDouble());
    }

    String result = '';
    for (int i = 0; i < index; i += kMaxApply) {
      final chunkEnd = (i + kMaxApply < index) ? i + kMaxApply : index;
      result += _fromCharCodeApplySubarray(
          list.toExternRef, i.toDouble(), chunkEnd.toDouble());
    }
    return result;
  }

  @patch
  factory String.fromCharCode(int charCode) => _fromCharCode(charCode);

  static String _fromOneByteCharCode(int charCode) => JSStringImpl(js
      .JS<WasmExternRef?>('c => String.fromCharCode(c)', charCode.toDouble()));

  static String _fromTwoByteCharCode(int low, int high) =>
      JSStringImpl(js.JS<WasmExternRef?>('(l, h) => String.fromCharCode(h, l)',
          low.toDouble(), high.toDouble()));

  static String _fromCharCode(int charCode) {
    if (0 <= charCode) {
      if (charCode <= 0xffff) {
        return _fromOneByteCharCode(charCode);
      }
      if (charCode <= 0x10ffff) {
        var bits = charCode - 0x10000;
        var low = 0xDC00 | (bits & 0x3ff);
        var high = 0xD800 | (bits >> 10);
        return _fromTwoByteCharCode(low, high);
      }
    }
    throw RangeError.range(charCode, 0, 0x10ffff);
  }

  static String _fromCharCodeApplySubarray(
          WasmExternRef? charCodes, double index, double end) =>
      JSStringImpl(js.JS<WasmExternRef?>(
          '(c, i, e) => String.fromCharCode.apply(null, c.subarray(i, e))',
          charCodes,
          index,
          end));
}
