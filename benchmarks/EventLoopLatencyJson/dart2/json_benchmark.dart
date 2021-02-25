// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:math';
import 'dart:convert';

class JsonRoundTripBenchmark {
  void run() {
    final res = json.decode(jsonData);
    final out = json.encode(res);
    if (out[0] != jsonData[0]) {
      throw 'json conversion error';
    }
  }
}

// Builds around 4.5 MB of json data - big enough so the decoded object graph
// does not fit into new space.
final String jsonData = () {
  final rnd = Random(42);
  dynamic buildTree(int depth) {
    final int coin = rnd.nextInt(1000);
    if (depth == 0) {
      if (coin % 2 == 0) return coin;
      return 'foo-$coin';
    }

    if (coin % 2 == 0) {
      final map = <String, dynamic>{};
      final int length = rnd.nextInt(18);
      for (int i = 0; i < length; ++i) {
        map['bar-$i'] = buildTree(depth - 1);
      }
      return map;
    } else {
      final list = <dynamic>[];
      final int length = rnd.nextInt(18);
      for (int i = 0; i < length; ++i) {
        list.add(buildTree(depth - 1));
      }
      return list;
    }
  }

  return json.encode({'data': buildTree(6)});
}();
