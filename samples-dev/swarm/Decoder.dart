// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

// TODO(jimhug): Fill out methods, add encoder, move to shared lib.
class Decoder {
  int index;
  String data;

  Decoder(this.data) {
    this.index = 0;
  }

  // Reads numbers in variable-length 7-bit encoding.  This matches the
  // varint encoding used by protobufs except that it only uses 7
  // bits per byte so it can be efficiently passed as UTF8.
  // For more info, see appengine/encoder.py.
  int readInt() {
    var r = 0;
    for (var i = 0;; i++) {
      var v = data.codeUnitAt(index++);
      r |= (v & 0x3F) << (6 * i);
      if ((v & 0x40) == 0) break;
    }
    return r.toInt();
  }

  bool readBool() {
    final ch = data[index++];
    assert(ch == 'T' || ch == 'F');
    return ch == 'T';
  }

  String readString() {
    int len = readInt();
    String s = data.substring(index, index + len);
    index += len;
    return s;
  }
}
