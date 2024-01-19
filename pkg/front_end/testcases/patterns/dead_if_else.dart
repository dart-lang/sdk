// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method(bool b1) {
  if (b1 case var b2) {
    print(b2);
  } else {
    print(b1); // This is dead code.
  }
}
