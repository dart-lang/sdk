// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mocks of things that Leg cannot read directly.

// TODO(ahe): Remove this file.

void assert(condition) {
  if (condition is Function) condition = condition();
  if (!condition) throw new AssertionError();
}

// TODO(ahe): Not sure ByteArray belongs in the core library.
interface Uint8List extends List default _InternalByteArray {
  Uint8List(int length);
}

class _InternalByteArray {
  factory Uint8List(int length) {
    throw new UnsupportedOperationException("new Uint8List($length)");
  }
}
