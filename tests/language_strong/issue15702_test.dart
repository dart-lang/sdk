// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  Amount stake = new Amount(2.5);
  if ((stake.value * 10).toInt() != 25) {
    throw 'Test failed';
  }
}

class Amount {
  num value;
  Amount(this.value);
}
