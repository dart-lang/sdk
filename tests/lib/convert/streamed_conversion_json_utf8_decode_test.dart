// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:convert';
import 'json_unicode_tests.dart';
import '../../async_helper.dart';

final JSON_UTF8 = JSON.fuse(UTF8);

bool isJsonEqual(o1, o2) {
  if (o1 == o2) return true;
  if (o1 is List && o2 is List) {
    if (o1.length != o2.length) return false;
    for (int i = 0; i < o1.length; i++) {
      if (!isJsonEqual(o1[i], o2[i])) return false;
    }
    return true;
  }
  if (o1 is Map && o2 is Map) {
    if (o1.length != o2.length) return false;
    for (var key in o1.keys) {
      Expect.isTrue(key is String);
      if (!o2.containsKey(key)) return false;
      if (!isJsonEqual(o1[key], o2[key])) return false;
    }
    return true;
  }
  return false;
}

Stream<Object> createStream(List<List<int>> chunks) {
  var controller;
  controller = new StreamController(onListen: () {
    chunks.forEach(controller.add);
    controller.close();
  });
  return controller.stream.transform(JSON_UTF8.decoder);
}

Stream<Object> decode(List<int> bytes) {
  return createStream([bytes]);
}

Stream<Object> decodeChunked(List<int> bytes, int chunkSize) {
  List<List<int>> chunked = <List<int>>[];
  int i = 0;
  while (i < bytes.length) {
    if (i + chunkSize <= bytes.length) {
      chunked.add(bytes.sublist(i, i + chunkSize));
    } else {
      chunked.add(bytes.sublist(i));
    }
    i += chunkSize;
  }
  return createStream(chunked);
}

void checkIsJsonEqual(expected, stream) {
  asyncStart();
  stream.single.then((o) {
    Expect.isTrue(isJsonEqual(expected, o));
    asyncEnd();
  });
}

main() {
  for (var test in JSON_UNICODE_TESTS) {
    var bytes = test[0];
    var o = test[1];
    checkIsJsonEqual(o, decode(bytes));
    checkIsJsonEqual(o, decodeChunked(bytes, 1));
    checkIsJsonEqual(o, decodeChunked(bytes, 2));
    checkIsJsonEqual(o, decodeChunked(bytes, 3));
    checkIsJsonEqual(o, decodeChunked(bytes, 4));
    checkIsJsonEqual(o, decodeChunked(bytes, 5));
  }
}
