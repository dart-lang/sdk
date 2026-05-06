// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder';
import 'dart:_internal' show patch;
import 'dart:_js_helper';
import 'dart:_string';
import 'dart:_wasm';

@patch
class StringBuffer {
  WasmExternRef? _hostBuffer = WasmExternRef.nullRef;

  @patch
  @pragma("wasm:prefer-inline")
  StringBuffer([Object content = '']) {
    _hostBuffer = stringBufferCreate();
    if (content is! String || content.isNotEmpty) {
      write(content);
    }
  }

  @patch
  int get length => stringBufferLength(_hostBuffer).toIntUnsigned();

  @patch
  void write(Object? obj) {
    if (obj is String) {
      _writeString(obj);
    } else {
      _writeString(obj.toString());
    }
  }

  @patch
  void writeCharCode(int charCode) {
    stringBufferWriteCharCode(_hostBuffer, WasmI32.fromInt(charCode));
  }

  @patch
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    final iterator = objects.iterator;
    if (!iterator.moveNext()) return;

    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        _writeString(separator);
        write(iterator.current);
      }
    }
  }

  @patch
  void writeln([Object? obj = '']) {
    write(obj);
    writeCharCode(10 /*\n*/);
  }

  @patch
  void clear() {
    stringBufferClear(_hostBuffer);
  }

  @patch
  String toString() {
    return JSStringImpl.fromRefUnchecked(stringBufferToString(_hostBuffer));
  }

  void _writeString(String str) {
    stringBufferWriteString(
      _hostBuffer,
      jsStringFromDartString(str).wrappedExternRef,
    );
  }
}
