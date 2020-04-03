// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library Prefix21Bad;

int badFunction(int x) {
  return x << 1;
}

Function get getValue {
  return badFunction;
}
