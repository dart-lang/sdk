// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: tryFinally:declared={a, b}, assigned={a, b}*/
tryFinally(int a, int b) {
  try /*declared={c}, assigned={a}*/ {
    a = 0;
    var c;
  } finally /*declared={d}, assigned={b}*/ {
    b = 0;
    var d;
  }
}

/*member: tryCatchFinally:declared={a, b, c, e}, assigned={a, b, c}*/
tryCatchFinally(int a, int b, int c) {
  try /*declared={d}, assigned={a}*/ {
    a = 0;
    var d;
  } on String {
    b = 0;
    var e;
  } finally /*declared={f}, assigned={c}*/ {
    c = 0;
    var f;
  }
}
