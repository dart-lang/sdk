// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Returns neither map nor iterable.
int method() => 0;

test() {
  var a = {...method()}; // Error
  var b = {...method(), 0}; // Error
  var c = {...method(), 0: 1}; // Error
}
