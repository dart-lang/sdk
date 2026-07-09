// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E {
  element, // The declaration of the element is correct.

  final String foo = "foo"; // Error: attempt to parse the field as an element.
}

test() {
  return E.element; // No error: the element is added to the enum.
}

main() {}
