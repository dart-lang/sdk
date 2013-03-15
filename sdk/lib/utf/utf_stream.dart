// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.utf;

class _HelperStreamController<T> extends StreamController<T> {
  final Function onPauseChanged;

  _HelperStreamController(this.onPauseChanged);

  void onPauseStateChange() {
    onPauseChanged();
  }
}

abstract class _StringDecoder
    extends StreamEventTransformer<List<int>, String> {
  List<int> _carry;
  List<int> _buffer;
  int _replacementChar;

  _StringDecoder(int this._replacementChar);

  void handleData(List<int> bytes, EventSink<String> sink) {
    _buffer = <int>[];
    List<int> carry = _carry;
    _carry = null;
    int pos = 0;
    int available = bytes.length;
    // If we have carry-over data, start from negative index, indicating carry
    // index.
    int goodChars = 0;
    if (carry != null) pos = -carry.length;
    while (pos < available) {
      int currentPos = pos;
      int getNext() {
        if (pos < 0) {
          return carry[pos++ + carry.length];
        } else if (pos < available) {
          return bytes[pos++];
        }
        return null;
      }
      int consumed = _processBytes(getNext);
      if (consumed > 0) {
        goodChars = _buffer.length;
      } else if (consumed == 0) {
        _buffer.length = goodChars;
        if (currentPos < 0) {
          _carry = [];
          _carry.addAll(carry);
          _carry.addAll(bytes);
        } else {
          _carry = bytes.sublist(currentPos);
        }
        break;
      } else {
        // Invalid byte at position pos - 1
        _buffer.length = goodChars;
        _addChar(-1);
        goodChars = _buffer.length;
      }
    }
    if (_buffer.length > 0) {
      // Limit to 'goodChars', if lower than actual charCodes in the buffer.
      sink.add(new String.fromCharCodes(_buffer));
    }
    _buffer = null;
  }

  void handleDone(EventSink<String> sink) {
    if (_carry != null) {
      sink.add(new String.fromCharCodes(
          new List.filled(_carry.length, _replacementChar)));
    }
    sink.close();
  }

  int _processBytes(int getNext());

  void _addChar(int char) {
    if (char > 0x10FFFF || char < 0) char = _replacementChar;
    _buffer.add(char);
  }
}

/**
 * StringTransformer that decodes a stream of UTF-8 encoded bytes.
 */
class Utf8DecoderTransformer extends _StringDecoder {
  Utf8DecoderTransformer(
      [int replacementChar = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT])
    : super(replacementChar);

  int _processBytes(int getNext()) {
    int value = getNext();
    if ((value & 0xFF) != value) return -1;  // Not a byte.
    if ((value & 0x80) == 0x80) {
      int additionalBytes;
      int min;
      if ((value & 0xe0) == 0xc0) {  // 110xxxxx
        value = value & 0x1F;
        additionalBytes = 1;
        min = 0x80;
      } else if ((value & 0xf0) == 0xe0) {  // 1110xxxx
        value = value & 0x0F;
        additionalBytes = 2;
        min = 0x800;
      } else if ((value & 0xf8) == 0xf0) {  // 11110xxx
        value = value & 0x07;
        additionalBytes = 3;
        min = 0x10000;
      } else if ((value & 0xfc) == 0xf8) {  // 111110xx
        value = value & 0x03;
        additionalBytes = 4;
        min = 0x200000;
      } else if ((value & 0xfe) == 0xfc) {  // 1111110x
        value = value & 0x01;
        additionalBytes = 5;
        min = 0x4000000;
      } else {
        return -1;
      }
      for (int i = 0; i < additionalBytes; i++) {
        int next = getNext();
        if (next == null) return 0;  // Not enough chars, reset.
        if ((next & 0xc0) != 0x80 || (next & 0xff) != next) return -1;
        value = value << 6 | (next & 0x3f);
      }
      // Invalid charCode if less then minimum expected.
      if (value < min) value = -1;
      _addChar(value);
      return 1 + additionalBytes;
    }
    _addChar(value);
    return 1;
  }
}


abstract class _StringEncoder
    extends StreamEventTransformer<String, List<int>> {

  void handleData(String data, EventSink<List<int>> sink) {
    sink.add(_processString(data));
  }

  List<int> _processString(String string);
}

/**
 * StringTransformer that UTF-8 encodes a stream of strings.
 */
class Utf8EncoderTransformer extends _StringEncoder {
  List<int> _processString(String string) {
    var bytes = [];
    int pos = 0;
    List<int> codepoints = _utf16CodeUnitsToCodepoints(string.codeUnits);
    int length = codepoints.length;
    for (int i = 0; i < length; i++) {
      int additionalBytes;
      int charCode = codepoints[i];
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
