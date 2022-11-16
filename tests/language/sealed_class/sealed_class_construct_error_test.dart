// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when we try to construct a sealed class because they should
// be implicitly abstract.

sealed class NotConstructable {}

main() {
  var error = NotConstructable();
  //          ^
  // [cfe] The class 'NotConstructable' is abstract and can't be instantiated.
}
