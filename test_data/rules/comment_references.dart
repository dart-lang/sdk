// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N comment_references`

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
  int z = 0;

  /// Reads [x] and assigns to [z]. #OK
  void read(int x) {}

  /// Writes [y]. #LINT
  void write(int x) {}
}

/// [
/// ^--- Should not crash (#819).
class B {
}

/// A link to [Sha256][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
class C {
}

/// A link to [Sha256](http://tools.ietf.org/html/rfc6234) hash function.
class D {
}

/// A link to [Sha256](http://tools.ietf.org/html/rfc6234 "Some") hash function.
class E {
}

/// A link to [rfc][] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
class F {
}
