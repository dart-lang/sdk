// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _LineWrappingStringBuffer {
  _LineWrappingStringBuffer(int this._lineLength) : _sb = new StringBuffer();

  void add(String s) {
    if (_lineLength !== null && _currentLineLength == _lineLength) {
      _sb.add('\r\n');
      _currentLineLength = 0;
    }
    _sb.add(s);
    _currentLineLength++;
  }

  String toString() => _sb.toString();

  int _lineLength;
  StringBuffer _sb;
  int _currentLineLength = 0;
}

class _CryptoUtils {
  static String bytesToHex(List<int> bytes) {
    var result = new StringBuffer();
    for (var part in bytes) {
      result.add('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
    }
    return result.toString();
  }

  static String bytesToBase64(List<int> bytes, [int lineLength]) {
    final table =
        const [ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
                'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
                'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
                'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
                'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
                '8', '9', '+', '/' ];

    var result = new _LineWrappingStringBuffer(lineLength);

    // Encode all full 24-bit blocks.
    var i = 0;
    for (; (i + 2) < bytes.length; i += 3) {
      var b0 = bytes[i] & 0xff;
      var b1 = bytes[i + 1] & 0xff;
      var b2 = bytes[i + 2] & 0xff;
      result.add(table[b0 >> 2]);
      result.add(table[((b0 << 4) | (b1 >> 4)) & 0x3f]);
      result.add(table[((b1 << 2) | (b2 >> 6)) & 0x3f]);
      result.add(table[b2 & 0x3f]);
    }

    // Deal with the last non-full block if any and add padding '='.
    if (i == bytes.length - 1) {
      var b0 = bytes[i] & 0xff;
      result.add(table[b0 >> 2]);
      result.add(table[(b0 << 4) & 0x3f]);
      result.add('=');
      result.add('=');
    } else if (i == bytes.length - 2) {
      var b0 = bytes[i] & 0xff;
      var b1 = bytes[i + 1] & 0xff;
      result.add(table[b0 >> 2]);
      result.add(table[((b0 << 4) | (b1 >> 4)) & 0x3f]);
      result.add(table[(b1 << 2) & 0x3f]);
      result.add('=');
    }

    return result.toString();
  }
}
