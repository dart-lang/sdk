// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum { a }

class Class {
  int method(Enum e) => e.index;
}

main() {
  List list = [];
  if (list.isNotEmpty) {
    new Class().method(null as dynamic);
  }
}
