// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(List<String> list) {
  String s = "";
  for (s in list) {
    if (s.isNotEmpty) {
      return s;
    }
  }
  return s;
}
