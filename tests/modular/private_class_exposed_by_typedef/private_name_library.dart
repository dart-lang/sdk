// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Shared code for tests that private names exported publicly via a typedef work
// as expected.
library private;

/// Sentinel values for checking that the correct methods are called.
const int privateNameSentinel = -1;
const int publicNameSentinel = privateNameSentinel + 1;

/// A private class that will be exported via a public typedef.
class _PrivateClass {
  int x;
  _PrivateClass(): x = privateNameSentinel;
  _PrivateClass.named(this.x);
}

class _PrivateClass2 {
  int x;
  _PrivateClass2(): x = privateNameSentinel;
  _PrivateClass2.named(this.x);
}

/// Export the private class publicly.
typedef PublicClass = _PrivateClass;

/// Export the private class publicly via an indirection through another private
/// typedef.
typedef _PrivateTypeDef = _PrivateClass2;
typedef AlsoPublicClass = _PrivateTypeDef;

/// Helper methods to do virtual calls on instances of _PrivateClass in this
/// library context.
int readInstanceField(_PrivateClass other) => other.x;

/// Helper methods to do virtual calls on instances of _PrivateClass in this
/// library context.
int readInstanceField2(_PrivateClass2 other) => other.x;
