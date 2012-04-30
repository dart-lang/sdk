// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#source("../../../runtime/bin/sha1.dart");

void hexifyHash(List<int> data) {
  Expect.equals(20, data.length);
  StringBuffer sb = new StringBuffer();
  for (int i = 0; i < data.length; i++) {
    String s = data[i].toRadixString(16);
    if (s.length == 1) sb.add("0");
    sb.add(s);
  }
  return sb.toString().toLowerCase();
}

void main() {
  String data;

  data = "";
  Expect.equals("da39a3ee5e6b4b0d3255bfef95601890afd80709",
                hexifyHash(_Sha1._hash(data.charCodes())));

  data = "";
  Expect.equals("db20d957030cd97e7b8ca33f43e065f65c736454",
                hexifyHash(_Sha1._hash("Anders".charCodes())));

  data = "Some random string";
  Expect.equals("f1660e7fa1265e89fd0c2f788c4f44ffaf9208b4",
                hexifyHash(_Sha1._hash(data.charCodes())));

  data = "The quick brown fox jumps over the lazy cog";
  Expect.equals("de9f2c7fd25e1b3afad3e85a0bd17d9b100db4b3",
                hexifyHash(_Sha1._hash(data.charCodes())));

  // Longest message which fits one chunk.
  data = "The quick brown fox jumps over the lazy cog 12345678901";
  Expect.equals("ea413cd9eec1b65502bbf8c322cc026cf01cc994",
                hexifyHash(_Sha1._hash(data.charCodes())));

  // Shortest message which uses two chunks.
  data = "The quick brown fox jumps over the lazy cog 123456789012";
  Expect.equals("3655a0787384d7d7236969da72e42d6dc32c8bb5",
                hexifyHash(_Sha1._hash(data.charCodes())));

  data = "The quick brown fox jumps over the lazy cog 1234567890123";
  Expect.equals("d8b6596a663569e47a5ae23cbc5acc241e0cae24",
                hexifyHash(_Sha1._hash(data.charCodes())));

  // From WebSocket standard.
  data = "dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
  Expect.equals("b37a4f2cc0624f1690f64606cf385945b2bec4ea",
                hexifyHash(_Sha1._hash(data.charCodes())));

  data = "0123456789001234567890012345678900123456789001234567890"
         "0123456789001234567890012345678900123456789001234567890";
  Expect.equals("534e82e5600593484251f42bd4855561a234a14b",
                hexifyHash(_Sha1._hash(data.charCodes())));
}
