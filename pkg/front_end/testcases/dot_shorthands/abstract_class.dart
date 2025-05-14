// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Function instantiation() {
  return .new(); // Error
}

Function tearOff() {
  return .new; // Error
}

void main() async {
  var iter = [1, 2];
  await for (var x in .fromIterable(iter)) { // No error.
    print(x);
  }
}
