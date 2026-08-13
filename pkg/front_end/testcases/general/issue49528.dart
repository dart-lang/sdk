// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {}

bool any_bool = true;

final foo = () {
  if (any_bool) {
    return 0;
  } else {
    throw Exception();
  }
}();

final int bar = foo;
