// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class E {
  final int x;
  final int y;
  E() : this.named(),
        this.x = 1;
        this.y = 2;

  E.named() : this.x = 5,
              this.y = 6;
}

main() {}
