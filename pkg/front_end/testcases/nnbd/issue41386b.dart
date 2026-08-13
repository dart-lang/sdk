// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test() {
  var map = {};
  map[0].foo;
  Iterable<String> elements = <String>[];
  var list = new List.from(elements);
  new List.from(elements).forEach((element) => element.foo);
}

main() {}
