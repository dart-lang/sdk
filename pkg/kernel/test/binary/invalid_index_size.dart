// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/binary/ast_from_binary.dart' show ParseError;

import 'utils.dart';

main() {
  Library lib1 = new Library(Uri.parse("foo://bar.dart"));
  Component c1 = new Component(libraries: [lib1]);
  List<int> serialized = serializeComponent(c1);
  // The last 4 bytes is the size entry in the index. Overwrite that with 0's.
  for (int i = serialized.length - 4; i < serialized.length; i++) {
    serialized[i] = 0;
  }
  bool gotExpectedException = false;
  try {
    loadComponentFromBytes(serialized);
    throw "The above line should have thrown.";
  } on ParseError catch (e) {
    if (e.toString().contains("invalid size")) {
      gotExpectedException = true;
    }
  }
  if (!gotExpectedException) {
    throw "Didn't get the right exception!";
  }
}
