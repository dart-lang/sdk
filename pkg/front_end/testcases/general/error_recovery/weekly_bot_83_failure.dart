// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main2() {
  double x = 42;
  x.remainder();
}

main(List<String> args) {
  if (args.length == 42) {
    main2();
  }
}