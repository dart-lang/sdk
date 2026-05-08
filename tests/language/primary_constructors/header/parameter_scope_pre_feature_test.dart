// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.10

// Prior to the primary-constructors feature, formal parameter types of
// primary constructor were not resolved within the body scope of the
// enclosing declaration.

// SharedOptions=--enable-experiment=primary-constructors

extension type ET(int x) {
  static const String int = 'not a type';
}

main() {
  print(ET(0));
  print(ET.int);
}
