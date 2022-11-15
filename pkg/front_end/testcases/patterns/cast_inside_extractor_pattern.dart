// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int? f;
}

test(dynamic x) {
  switch (x) {
    case C(f: 1 as int):
      break;
  }
}
