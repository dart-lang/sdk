// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Shifting {
  operator >>>(other) {
    Box<Box<Box<prefix.Fisk>>> foo = null;
    return other >>> 1;
  }

  operator >>(other) {
    Box<Box<prefix.Fisk>> foo = null;
    return other >> 1;
  }
}
