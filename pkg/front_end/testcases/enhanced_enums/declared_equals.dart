// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  element;

  bool operator==(Object other) => true; // Error.
}

enum E2 {
  element;

  bool operator==(Object other); // Ok.
}

abstract class I3 {
  bool operator==(Object other);
}

enum E3 implements I3 { element } // Ok.

main() {}
