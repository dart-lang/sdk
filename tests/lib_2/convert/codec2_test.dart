// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:expect/expect.dart';

main() {
  final RAW = '["122ç",50,50,231]';
  final ENCODED = const [
    91,
    34,
    49,
    50,
    50,
    195,
    167,
    34,
    44,
    53,
    48,
    44,
    53,
    48,
    44,
    50,
    51,
    49,
    93
  ];
  Expect.listEquals(ENCODED, utf8.encode(RAW));
  Expect.equals(RAW, utf8.decode(ENCODED));

  Expect.listEquals([], utf8.encode(""));
  Expect.equals("", utf8.decode([]));

  final JSON_ENCODED = RAW;
  Expect.equals(JSON_ENCODED, json.encode(["122ç", 50, 50, 231]));
  Expect.listEquals(["122ç", 50, 50, 231], json.decode(JSON_ENCODED));

  // Test that the reviver is passed to the decoder.
  var decoded = json.decode('{"p": 5}', reviver: (dynamic k, dynamic v) {
    if (k == null) return v;
    return v * 2;
  });
  Expect.equals(10, decoded["p"]);
  var jsonWithReviver = new JsonCodec.withReviver((dynamic k, dynamic v) {
    if (k == null) return v;
    return v * 2;
  });
  decoded = jsonWithReviver.decode('{"p": 5}');
  Expect.equals(10, decoded["p"]);

  // Test example from comments.
  final JSON_TO_BYTES = json.fuse(utf8);
  List<int> bytes = JSON_TO_BYTES.encode(["json-object"]);
  decoded = JSON_TO_BYTES.decode(bytes);
  Expect.isTrue(decoded is List);
  Expect.equals("json-object", (decoded as List)[0]);
}
