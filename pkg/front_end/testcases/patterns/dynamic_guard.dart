// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic guard() => true;

main() {
  var [a] = [5];
  int b;
  [b] = [if (a case == 5 when guard()) 5];
  if (a case == 5 when guard()) {
    a = 6;
  }
  var c = switch (a) {
    int d when guard() => d,
    _ => 0,
  };
  switch (b) {
    case int e when guard():
      print(a);
  }
  var d = {if (a case == 5 when guard()) 5: 6};
}
