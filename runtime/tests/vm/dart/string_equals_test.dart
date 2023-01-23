// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verifies that string equal implementation correctly handles strings of
// various lengths.

import 'dart:math';

import "package:expect/expect.dart";

compare(List<int> ints, String s_piece, String t_piece, bool expectedEquality) {
  final s = String.fromCharCodes(ints);
  String s_mid = s + s_piece + s;
  String t_mid = s + t_piece + s;
  Expect.isFalse(identical(s_mid, t_mid));
  Expect.equals(s_mid == t_mid, expectedEquality);
  String s_tail = s + s_piece;
  String t_tail = s + t_piece;
  Expect.isFalse(identical(s_tail, t_tail));
  Expect.equals(s_tail == t_tail, expectedEquality);
  String s_head = s_piece + s;
  String t_head = t_piece + s;
  Expect.isFalse(identical(s_head, t_head));
  Expect.equals(s_head == t_head, expectedEquality);
}

main() {
  const int maxStringLength = 128;
  // OneByteString
  for (int i = 0; i < maxStringLength; i++) {
    final l = List.generate(i, (n) => (Random().nextInt(30) + 40));
    compare(l, 'a', 'b', false);
    compare(l, 'a', 'a', true);
  }
  // TwoByteString
  for (int i = 0; i < maxStringLength; i++) {
    final l = List.generate(i, (n) => (Random().nextInt(1024) + 1024));
    compare(l, String.fromCharCodes(<int>[1042]),
        String.fromCharCodes(<int>[1043]), false);
    compare(l, String.fromCharCodes(<int>[1042]),
        String.fromCharCodes(<int>[1042]), true);
  }
}
