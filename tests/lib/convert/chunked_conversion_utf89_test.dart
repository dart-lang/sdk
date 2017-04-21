// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';

class MySink extends ChunkedConversionSink<String> {
  final Function _add;
  final Function _close;

  MySink(this._add, this._close);

  void add(x) {
    _add(x);
  }

  void close() {
    _close();
  }
}

main() {
  // Make sure the UTF-8 decoder works eagerly.
  String lastString;
  bool isClosed = false;
  ChunkedConversionSink sink =
      new MySink((x) => lastString = x, () => isClosed = true);
  var byteSink = new Utf8Decoder().startChunkedConversion(sink);
  byteSink.add("abc".codeUnits);
  Expect.equals("abc", lastString);
  byteSink.add([0x61, 0xc3]); // 'a' followed by first part of Î.
  Expect.equals("a", lastString);
  byteSink.add([0x8e]); // second part of Î.
  Expect.equals("Î", lastString);
  Expect.isFalse(isClosed);
  byteSink.close();
  Expect.isTrue(isClosed);
}
