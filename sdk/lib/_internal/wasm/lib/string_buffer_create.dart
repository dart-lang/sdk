// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

import "dart:typed_data" show Uint16List;

@patch
class StringBuffer {
  @patch
  static String _create(Uint16List buffer, int length, bool isLatin1) {
    if (isLatin1) {
      return _StringBase._createOneByteString(buffer, 0, length);
    } else {
      return _TwoByteString._allocateFromTwoByteList(buffer, 0, length);
    }
  }
}
