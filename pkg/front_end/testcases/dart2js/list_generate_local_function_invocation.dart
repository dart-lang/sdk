// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  int localFunction(int i) => i * 2;
  new List<int>.generate(10, (i) => localFunction(i));
}
