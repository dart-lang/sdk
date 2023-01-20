// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to construct an abstract final class.

abstract final class NotConstructable {}

mixin M {}
abstract final class AlsoNotConstructable = Object with M;

main() {
  var error = NotConstructable();
// ^
// [analyzer] unspecified
// [cfe] unspecified
  var error2 = AlsoNotConstructable();
// ^
// [analyzer] unspecified
// [cfe] unspecified
}
