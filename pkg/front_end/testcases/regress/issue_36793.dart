// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int y = 42;

@y
int x = 1;
@y
int x = 2;

main() {
  print(y);
}