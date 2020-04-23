// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int Function() x = () => 42;
int Function(int Function()) y = (int Function() x) => x();
List<int Function()> l = <int Function()>[()=>42, x];
main() {
  Expect.equals(42, y(l[1]));
}
