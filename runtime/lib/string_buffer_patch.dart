// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class StringBuffer {
  /** Backing store for collected UTF-16 code units. */
  Uint16List _buffer;
  /** Number of code units collected. */
  int _length = 0;
  /**
   * Collects the approximate maximal magnitude of the added code units.
   *
   * The value of each added code unit is or'ed with this variable, so the
   * most significant bit set in any code unit is also set in this value.
   * If below 256, the string is a Latin-1 string.
   */
  int _codeUnitMagnitude = 0;

  /// Creates the string buffer with an initial content.
  /* patch */ StringBuffer([Object content = ""])
      : _buffer = new Uint16List(16) {
    write(content);
  }

  /* patch */ int get length => _length;

  /// Adds [obj] to the buffer.
  /* patch */ void write(Object obj) {
    String str;
    if (obj is String) {
      str = obj;
    } else {
      // TODO(srdjan): The following four lines could be replaced by
      // '$obj', but apparently this is too slow on the Dart VM.
      str = obj.toString();
      if (str is! String) {
        throw new ArgumentError('toString() did not return a string');
      }
    }
    if (str.isEmpty) return;
    _ensureCapacity(str.length);
    for (int i = 0; i < str.length; i++) {
      int unit = str.codeUnitAt(i);
      _buffer[_length + i] = unit;
      _codeUnitMagnitude |= unit;
    }
    _length += str.length;
  }

  /* patch */ writeCharCode(int charCode) {
    if (charCode <= 0xFFFF) {
      if (charCode < 0) {
        throw new RangeError.range(charCode, 0, 0x10FFFF);
      }
      _ensureCapacity(1);
      _buffer[_length++] = charCode;
      _codeUnitMagnitude |= charCode;
    } else {
      if (charCode > 0x10FFFF) {
        throw new RangeError.range(charCode, 0, 0x10FFFF);
      }
      _ensureCapacity(2);
      int bits = charCode - 0x10000;
      _buffer[_length++] = 0xD800 | (bits >> 10);
      _buffer[_length++] = 0xDC00 | (bits & 0x3FF);
      _codeUnitMagnitude |= 0xFFFF;
    }
  }

  /** Makes the buffer empty. */
  /* patch */ void clear() {
    _length = 0;
    _codeUnitMagnitude = 0;
  }

  /** Returns the contents of buffer as a string. */
  /* patch */ String toString() {
    if (_length == 0) return "";
    bool isLatin1 = _codeUnitMagnitude <= 0xFF;
    return _create(_buffer, _length, isLatin1);
  }

  /** Ensures that the buffer has enough capacity to add n code units. */
  void _ensureCapacity(int n) {
    int requiredCapacity = _length + n;
    if (requiredCapacity > _buffer.length) {
      _grow(requiredCapacity);
    }
  }

  /** Grows the buffer until it can contain [requiredCapacity] entries. */
  void _grow(int requiredCapacity) {
    int newCapacity = _buffer.length;
    do {
      newCapacity *= 2;
    } while (newCapacity < requiredCapacity);
    List<int> newBuffer = new Uint16List(newCapacity);
    newBuffer.setRange(0, _length, _buffer);
    _buffer = newBuffer;
  }

  /**
   * Create a [String] from the UFT-16 code units in buffer.
   */
  static String _create(Uint16List buffer, int length, bool isLatin1)
      native "StringBuffer_createStringFromUint16Array";
}
