// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'state_string.dart';

bool match(Uint8List s) {
  int i = 0;

  var state = State.start;

  OUTER:
  while (true) {
    if (i == s.length) break;
    final zero = s[i++] == 48;

    switch (state) {
      case State.start:
        state = zero ? State.a1 : State.extended1;
        break;

      // 0xxxxxxx
      //  ^
      case State.a1:
        state = State.a2;
        break;
      case State.a2:
        state = State.a3;
        break;
      case State.a3:
        state = State.a4;
        break;
      case State.a4:
        state = State.a5;
        break;
      case State.a5:
        state = State.a6;
        break;
      case State.a6:
        state = State.a7;
        break;
      case State.a7:
        state = State.start;
        break;

      case State.error:
        break OUTER;

      // 110xxxxx 10xxxxxx
      //  ^
      // 1110xxxx 10xxxxxx 10xxxxxx
      // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
      case State.extended1:
        state = zero ? State.error : State.extended2;
        break;
      case State.extended2:
        state = zero ? State.two3 : State.extended3;
        break;
      case State.extended3:
        state = zero ? State.three4 : State.extended4;
        break;
      case State.extended4:
        state = zero ? State.four5 : State.error;
        break;

      case State.two3:
        state = State.two4;
        break;
      case State.two4:
        state = State.two5;
        break;
      case State.two5:
        state = State.two6;
        break;
      case State.two6:
        state = State.two7;
        break;
      case State.two7:
        state = State.last0;
        break;

      case State.three4:
        state = State.three5;
        break;
      case State.three5:
        state = State.three6;
        break;
      case State.three6:
        state = State.three7;
        break;
      case State.three7:
        state = State.prev0;
        break;

      case State.four5:
        state = State.four6;
        break;
      case State.four6:
        state = State.four7;
        break;
      case State.four7:
        state = State.first0;
        break;

      // 10xxxxxx 10xxxxxx 10xxxxxx
      case State.first0:
        state = zero ? State.error : State.first1;
        break;
      case State.first1:
        state = zero ? State.first2 : State.error;
        break;
      case State.first2:
        state = State.first3;
        break;
      case State.first3:
        state = State.first4;
        break;
      case State.first4:
        state = State.first5;
        break;
      case State.first5:
        state = State.first6;
        break;
      case State.first6:
        state = State.first7;
        break;
      case State.first7:
        state = State.prev0;
        break;

      // 10xxxxxx 10xxxxxx
      case State.prev0:
        state = zero ? State.error : State.prev1;
        break;
      case State.prev1:
        state = zero ? State.prev2 : State.error;
        break;
      case State.prev2:
        state = State.prev3;
        break;
      case State.prev3:
        state = State.prev4;
        break;
      case State.prev4:
        state = State.prev5;
        break;
      case State.prev5:
        state = State.prev6;
        break;
      case State.prev6:
        state = State.prev7;
        break;
      case State.prev7:
        state = State.last0;
        break;

      // 10xxxxxx
      case State.last0:
        state = zero ? State.error : State.last1;
        break;
      case State.last1:
        state = zero ? State.last2 : State.error;
        break;
      case State.last2:
        state = State.last3;
        break;
      case State.last3:
        state = State.last4;
        break;
      case State.last4:
        state = State.last5;
        break;
      case State.last5:
        state = State.last6;
        break;
      case State.last6:
        state = State.last7;
        break;
      case State.last7:
        state = State.start;
        break;
    }
  }
  return state == State.start;
}
