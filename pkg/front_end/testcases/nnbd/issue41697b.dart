// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1<S extends num>(S s) {
  var t = s + 1; // ok
}

test2<S extends num?>(S s) {
  var t = s + 1; // error
}

test3<S extends int>(S s) {
  var t = s + 1; // ok
}

test4<S extends int?>(S s) {
  var t = s + 1; // error
}

main() {}
