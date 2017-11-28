// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_extension;

import "dart-ext:extension/test_extension";

class Cat {
  Cat(this.x);

  num x;

  String toString() => 'cat $x';

  // Implements (a != null) ? a : b using a native C++ function and the API.
  static int ifNull(a, b) native 'TestExtension_IfNull';

  static int throwMeTheBall(ball) native 'TestExtension_ThrowMeTheBall';
}
