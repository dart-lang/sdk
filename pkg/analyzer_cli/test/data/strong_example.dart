// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This produces an error with --strong enabled, but not otherwise.
class MyIterable extends Iterable<String> {
  // Error: invalid override
  Iterator<Object> get iterator => [1, 2, 3].iterator;
}

main() {
  var i = new MyIterable().iterator..moveNext();
  print(i.current);

  // Error: type check failed
  List<String> list = <dynamic>[1, 2, 3];
  print(list);
}
