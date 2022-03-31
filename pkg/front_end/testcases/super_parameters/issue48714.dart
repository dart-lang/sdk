// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Base {
  int value;
  Base(this.value);
}

class Extended extends Base {
  Extended.one(final super.value); // Ok.
  Extended.two(var super.value); // Error.
  Extended.three(const super.value); // Error.
}

main() {}
