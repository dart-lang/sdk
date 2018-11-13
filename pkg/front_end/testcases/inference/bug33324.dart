// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the greatest closure uses 'dynamic' and not Object as
// the top type.

int foo() {
  Function f = (x) => x;
  var l = ["bar"].map(f).toList();
  l.add(42);
  return l.first.length;
}

main() {}
