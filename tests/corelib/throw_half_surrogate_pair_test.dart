// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var trebleClef = "\u{1D11E}";
  if (trebleClef.length != 2) throw "String should be a surrogate pair";
  // These uncaught exceptions should not caush the VM to crash attempting to
  // print a malformed string.
  throw trebleClef[0];  /// 01: runtime error
  throw trebleClef[1];  /// 02: runtime error
}
