// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

bool f(List x) {
  return x.expand((y) {
    // Since y has type dynamic, y.split(',') has type dynamic, so an implicit
    // downcast is needed.  The return context is Iterable<?>.  We should
    // generate an implicit downcast to Iterable<dynamic>.
    return y.split(',');
  }).any((y) => y == 'z');
}

main() {}
