// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class StringBuffer {
  List<String> _buffer;
  int _length;

  /// Creates the string buffer with an initial content.
  /* patch */ StringBuffer([Object content = ""]) {
    // TODO(floitsch): remove or rewrite this call to clear. It is currently
    // necessary because the VM doesn't allow default values for fields in
    // patch classes.
    _buffer = new List<String>();
    _length = 0;
    write(content);
  }

  /* patch */ int get length => _length;

  /// Adds [obj] to the buffer.
  /* patch */ void _write(String str) {
    _buffer.add(str);
    _length += str.length;
  }

  /// Clears the string buffer.
  /* patch */ void clear() {
    _buffer = new List<String>();
    _length = 0;
  }

  /// Returns the contents of buffer as a concatenated string.
  /* patch */ String toString() {
    if (_buffer.length == 0) return "";
    if (_buffer.length == 1) return _buffer[0];
    String result = Strings.concatAll(_buffer);
    _buffer.clear();
    _buffer.add(result);
    // Since we track the length at each add operation, there is no
    // need to update it in this function.
    return result;
  }
}
