// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  // Use await for in non-async function.
  var _ = [await for (var i in Stream<int>.empty()) i]; //# 01: compile-time error

  () async {
    // Use await for variable out of scope.
    var _ = [await for (var i in Stream<int>.empty()) 1, i]; //# 02: compile-time error

    // Use await for variable in own initializer.
    var _ = [await for (var i in Stream<Object>.fromIterable([i])) 1]; //# 03: compile-time error
  }();
}
