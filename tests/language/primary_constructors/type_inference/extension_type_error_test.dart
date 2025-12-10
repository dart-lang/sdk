// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that we infer `Object?` for an extension type's representation type if
// the type isn't specified.

// SharedOptions=--enable-experiment=primary-constructors

extension type ET(i);

void main() {
  var et3 = ET3(1);
  if (1 > 2) et3.i.arglebargle;
  //              ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
