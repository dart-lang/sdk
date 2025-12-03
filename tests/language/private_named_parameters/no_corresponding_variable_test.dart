// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A private named parameter must refer to an instance variable with the same
/// private name.

// SharedOptions=--enable-experiment=private-named-parameters

class C {
  C({this._unknown});
  //      ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  // There is a public field with the name, but that isn't what the private
  // name refers to.
  String? unknown;
}

void main() {}
