// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This should not hit an ASSERT in the inliner that the call site has a
// different number of named arguments.

void other({String something = "ok"}) {
  print(something);
}

void main(List<String> args) {
  Function x = other;
  if (x is void Function(List<String>)) {
    x(args);
  } else {
    x();
  }
}
