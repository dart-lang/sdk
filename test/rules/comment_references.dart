// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N comment_references`

/// Keywords special cased by the parser should nonetheless lint:
/// [this] #LINT
/// [null] #LINT
/// [true] #LINT
/// [false] #LINT

/// Writes [y]. #LINT
void write(int x) {}

/// [String] is OK.
class A {
  /// But [zap] is not. #LINT
  int z;

  /// Reads [x] and assigns to [z]. #OK
  void read(int x) {}

  /// Writes [y]. #LINT
  void write(int x) {}
}

/// [
/// ^--- Should not crash (#819).
class B {

}
