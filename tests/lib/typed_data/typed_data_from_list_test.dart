// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

main() {
  var list = new UnmodifiableListView([1, 2]);
  var typed = new Uint8List.fromList(list);
  if (typed[0] != 1 || typed[1] != 2 || typed.length != 2) {
    throw 'Test failed';
  }
}
