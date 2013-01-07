// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of dart.async;

abstract class _StringDecoder extends _StreamTransformer<List<int>, String> {

  handleData(List<int> bytes, StreamSink<String> sink) {
    var data = _carry;
    data.addAll(bytes);
    _carry = [];
    var buffer = new StringBuffer();
    int pos = 0;
    while (pos < data.length) {
      int currentPos = pos;
      int getNext() {
        if (pos < data.length) {
          return data[pos++];
        }
        return -1;
      }
      _chars = [];
      if (_processByte(data[pos++], getNext)) {
        _chars.forEach(buffer.addCharCode);
      } else {
        _carry = data.getRange(currentPos, data.length - currentPos);
        break;
      }
    }
    sink.add(buffer.toString());
  }

  void handleDone(StreamSink<String> sink) {
    if (!_carry.isEmpty) {
      sink.signalError(new AsyncError(
            new StateError("Unhandled tailing utf8 chars")));
    }
    sink.close();
  }

  bool _processByte(int byte, int getNext());

  void addChar(int char) {
    _chars.add(char);
  }

  List<int> _carry = [];
  List<int> _chars;
}

/**
 * StringTransformer class that decodes a utf8 encoded bytes.
 */
class Utf8DecoderTransformer extends _StringDecoder {
  bool _processByte(int byte, int getNext()) {
    int value = byte & 0xFF;
    if ((value & 0x80) == 0x80) {
      int additionalBytes;
      if ((value & 0xe0) == 0xc0) {  // 110xxxxx
        value = value & 0x1F;
        additionalBytes = 1;
      } else if ((value & 0xf0) == 0xe0) {  // 1110xxxx
        value = value & 0x0F;
        additionalBytes = 2;
      } else {  // 11110xxx
        value = value & 0x07;
        additionalBytes = 3;
      }
      for (int i = 0; i < additionalBytes; i++) {
        int next = getNext();
        if (next < 0) return false;
        value = value << 6 | (next & 0x3F);
      }
    }
    addChar(value);
    return true;
  }
}


abstract class _StringEncoder extends _StreamTransformer<String, List<int>> {
  handleData(String string, StreamSink<List<int>> sink) {
    sink.add(_processString(string));
  }

  List<int> _processString(String string);
}

/**
 * StringTransformer class that utf8 encodes a string.
 */
class Utf8EncoderTransformer extends _StringEncoder {
  List<int> _processString(String string) {
    var bytes = [];
    int pos = 0;
    int length = string.length;
    for (int i = 0; i < length; i++) {
      int additionalBytes;
      int charCode = string.charCodeAt(i);
      if (charCode <= 0x007F) {
        additionalBytes = 0;
        bytes.add(charCode);
      } else if (charCode <= 0x07FF) {
        // 110xxxxx (xxxxx is top 5 bits).
        bytes.add(((charCode >> 6) & 0x1F) | 0xC0);
        additionalBytes = 1;
      } else if (charCode <= 0xFFFF) {
        // 1110xxxx (xxxx is top 4 bits)
        bytes.add(((charCode >> 12) & 0x0F)| 0xE0);
        additionalBytes = 2;
      } else {
        // 11110xxx (xxx is top 3 bits)
        bytes.add(((charCode >> 18) & 0x07) | 0xF0);
        additionalBytes = 3;
      }
      for (int i = additionalBytes; i > 0; i--) {
        // 10xxxxxx (xxxxxx is next 6 bits from the top).
        bytes.add(((charCode >> (6 * (i - 1))) & 0x3F) | 0x80);
      }
      pos += additionalBytes + 1;
    }
    return bytes;
  }
}


