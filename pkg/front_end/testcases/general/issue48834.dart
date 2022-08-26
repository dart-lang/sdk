// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension HashAll on Iterable {
  int hashAll() => 0;
}

extension HashAllList on List {
  int hashAll() => 1;
}

void main() {
  List l = [];
  Iterable i = [];
  print(l.hashAll());
  print(i.hashAll());
}
