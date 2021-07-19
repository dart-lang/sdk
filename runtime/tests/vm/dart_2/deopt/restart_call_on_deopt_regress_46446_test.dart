// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--disable-dart-dev --use-slow-path --deoptimize-on-runtime-call-every=3 --optimization-counter-threshold=10 --deterministic

import 'dart:collection';

main() {
  final entry = Entry();

  final list = LinkedList<Entry>();
  for (int i = 0; i < 100; ++i) {
    list.addFirst(entry);
    entry.unlink();
    list.addFirst(entry);
    entry.unlink();
  }
}

class Entry extends LinkedListEntry<Entry> {}
