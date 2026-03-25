// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable-asserts

import "package:expect/expect.dart";

const int _iterations = 10000;
final String _expected = List.generate(
  _iterations,
  (int i) => i.isEven ? "foo " : "bar ",
).join();

void writeFooBar(StringBuffer buffer) {
  for (int i = 0; i < _iterations; i++) {
    buffer.write(i.isEven ? "foo" : "bar");
    buffer.write(" ");
  }
}

void main() {
  final buffer = StringBuffer();

  writeFooBar(buffer);
  buffer.clear();
  writeFooBar(buffer);

  Expect.equals(_expected.length, buffer.length);
  Expect.equals(_expected, buffer.toString());
}
