// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper' show JS;
import 'dart:_string';
import 'dart:_wasm';

@patch
@pragma('wasm:prefer-inline')
JSStringImpl jsStringFromDartString(String s) {
  if (s is JSStringImpl) return s;

  return JSStringImpl(JS<WasmExternRef>(r'''
    (s, length) => {
        let result = '';
        let index = 0;
        while (index < length) {
          let chunkLength = Math.min(length - index, 0xFFFF);
          const array = new Array(chunkLength);
          for (let i = 0; i < chunkLength; i++) {
              array[i] = dartInstance.exports.$stringRead(s, index++);
          }
          result += String.fromCharCode(...array);
        }
        return result;
    }
    ''', jsObjectFromDartObject(s), s.length.toWasmI32()));
}

@patch
@pragma('wasm:prefer-inline')
String jsStringToDartString(JSStringImpl s) => JS<String>(r'''
    (s, length) => {
      let range = 0;
      for (let i = 0; i < length; i++) {
        range |= s.codePointAt(i);
      }
      if (range < 256) {
        const dartString = dartInstance.exports.$stringAllocate1(length);
        for (let i = 0; i < length; i++) {
            dartInstance.exports.$stringWrite1(dartString, i, s.codePointAt(i));
        }
        return dartString;
      } else {
        const dartString = dartInstance.exports.$stringAllocate2(length);
        for (let i = 0; i < length; i++) {
            dartInstance.exports.$stringWrite2(dartString, i, s.charCodeAt(i));
        }
        return dartString;
      }
    }
    ''', s.toExternRef, s.length.toWasmI32());
