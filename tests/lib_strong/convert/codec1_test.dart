// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:expect/expect.dart';

class MyCodec extends Codec<int, String> {
  const MyCodec();

  final Converter<int, String> encoder = const IntStringConverter();
  final Converter<String, int> decoder = const StringIntConverter();
}

class IntStringConverter extends Converter<int, String> {
  const IntStringConverter();

  String convert(int i) => i.toString();
}

class StringIntConverter extends Converter<String, int> {
  const StringIntConverter();

  int convert(String str) => int.parse(str);
}

class MyCodec2 extends Codec<int, String> {
  const MyCodec2();

  Converter<int, String> get encoder => new IntStringConverter2();
  Converter<String, int> get decoder => new StringIntConverter2();
}

class IntStringConverter2 extends Converter<int, String> {
  String convert(int i) => (i + 99).toString();
}

class StringIntConverter2 extends Converter<String, int> {
  int convert(String str) => int.parse(str) + 400;
}

const TEST_CODEC = const MyCodec();
const TEST_CODEC2 = const MyCodec2();

main() {
  Expect.equals("0", TEST_CODEC.encode(0));
  Expect.equals(5, TEST_CODEC.decode("5"));
  Expect.equals(3, TEST_CODEC.decode(TEST_CODEC.encode(3)));

  Expect.equals("99", TEST_CODEC2.encode(0));
  Expect.equals(405, TEST_CODEC2.decode("5"));
  Expect.equals(499, TEST_CODEC2.decode(TEST_CODEC2.encode(0)));

  var inverted, fused;
  inverted = TEST_CODEC.inverted;
  fused = TEST_CODEC.fuse(inverted);
  Expect.equals(499, fused.encode(499));
  Expect.equals(499, fused.decode(499));

  fused = inverted.fuse(TEST_CODEC);
  Expect.equals("499", fused.encode("499"));
  Expect.equals("499", fused.decode("499"));

  inverted = TEST_CODEC2.inverted;
  fused = TEST_CODEC2.fuse(inverted);
  Expect.equals(499, fused.encode(0));
  Expect.equals(499, fused.decode(0));

  fused = TEST_CODEC.fuse(inverted);
  Expect.equals(405, fused.encode(5));
  Expect.equals(101, fused.decode(2));
}
