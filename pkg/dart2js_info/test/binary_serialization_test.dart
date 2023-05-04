// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data' show BytesBuilder;

import 'package:dart2js_info/binary_serialization.dart' as binary;
import 'package:dart2js_info/json_info_codec.dart';
import 'package:test/test.dart';

import 'test_shared.dart';

class ByteSink implements Sink<List<int>> {
  BytesBuilder builder = BytesBuilder();

  @override
  void add(List<int> data) => builder.add(data);
  @override
  void close() {}
}

void main() {
  group('json to proto conversion with deferred files', () {
    test('hello_world_deferred', () async {
      var helloWorld = await helloWorldDeferredDumpInfo();
      var json = jsonDecode(helloWorld);
      // Clear toJsonDuration for consistency.
      json['program']['toJsonDuration'] = 0;
      var info = AllInfoJsonCodec().decode(json);

      var sink = ByteSink();
      binary.encode(info, sink);
      var info2 = binary.decode(sink.builder.toBytes());
      var json2 = AllInfoJsonCodec().encode(info2);

      var json1 = AllInfoJsonCodec().encode(info);
      var contents1 = const JsonEncoder.withIndent("  ").convert(json1);
      var contents2 = const JsonEncoder.withIndent("  ").convert(json2);
      expect(contents1 == contents2, isTrue);
    });
  });
}
