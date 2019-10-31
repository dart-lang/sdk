// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: increment:declared={x}, assigned={x}*/
increment(int x) {
  ++x;
}

/*member: decrement:declared={x}, assigned={x}*/
decrement(int x) {
  --x;
}

/*member: not:declared={b}*/
not(bool b) {
  !b;
}

/*member: binaryNot:declared={x}*/
binaryNot(int x) {
  ~x;
}

/*member: unaryMinus:declared={x}*/
unaryMinus(int x) {
  -x;
}
