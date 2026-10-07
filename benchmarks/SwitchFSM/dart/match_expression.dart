// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'state_int.dart';

bool match(Uint8List s) {
  int i = 0;

  var state = State.start;

  OUTER:
  while (true) {
    if (i == s.length) break;
    final zero = s[i++] == 48;

    state = switch (state) {
      State.start => zero ? State.a1 : State.extended1,

      // 0xxxxxxx
      //  ^
      State.a1 => State.a2,
      State.a2 => State.a3,
      State.a3 => State.a4,
      State.a4 => State.a5,
      State.a5 => State.a6,
      State.a6 => State.a7,
      State.a7 => State.start,

      State.error => -1,

      // 110xxxxx 10xxxxxx
      //  ^
      // 1110xxxx 10xxxxxx 10xxxxxx
      // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
      State.extended1 => zero ? State.error : State.extended2,
      State.extended2 => zero ? State.two3 : State.extended3,
      State.extended3 => zero ? State.three4 : State.extended4,
      State.extended4 => zero ? State.four5 : State.error,

      State.two3 => State.two4,
      State.two4 => State.two5,
      State.two5 => State.two6,
      State.two6 => State.two7,
      State.two7 => State.last0,

      State.three4 => State.three5,
      State.three5 => State.three6,
      State.three6 => State.three7,
      State.three7 => State.prev0,

      State.four5 => State.four6,
      State.four6 => State.four7,
      State.four7 => State.first0,

      // 10xxxxxx 10xxxxxx 10xxxxxx
      State.first0 => zero ? State.error : State.first1,
      State.first1 => zero ? State.first2 : State.error,
      State.first2 => State.first3,
      State.first3 => State.first4,
      State.first4 => State.first5,
      State.first5 => State.first6,
      State.first6 => State.first7,
      State.first7 => State.prev0,

      // 10xxxxxx 10xxxxxx
      State.prev0 => zero ? State.error : State.prev1,
      State.prev1 => zero ? State.prev2 : State.error,
      State.prev2 => State.prev3,
      State.prev3 => State.prev4,
      State.prev4 => State.prev5,
      State.prev5 => State.prev6,
      State.prev6 => State.prev7,
      State.prev7 => State.last0,

      // 10xxxxxx
      State.last0 => zero ? State.error : State.last1,
      State.last1 => zero ? State.last2 : State.error,
      State.last2 => State.last3,
      State.last3 => State.last4,
      State.last4 => State.last5,
      State.last5 => State.last6,
      State.last6 => State.last7,
      State.last7 => State.start,

      _ => -1,
    };

    if (state == -1) break OUTER;
  }
  return state == State.start;
}
