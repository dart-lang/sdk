// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  (x) {
    if (x) {
      return 1;
    } else {
      return;
    }
  };

  void local(x) {
    if (x) {
      return print('');
    } else {
      return;
    }
  }
}

main() {}
