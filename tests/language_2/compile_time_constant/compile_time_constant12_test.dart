// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String s = "foo";
const int i = s.length;
const int l = "foo".length + 1;

use(x) => x;

main() {
  use(s);
  use(i);
  use(l);
}
