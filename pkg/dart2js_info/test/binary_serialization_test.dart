// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/json_info_codec.dart';
import 'package:dart2js_info/binary_serialization.dart' as binary;
import 'package:test/test.dart';

class ByteSink implements Sink<List<int>> {
  BytesBuilder builder = BytesBuilder();

  @override
  add(List<int> data) => builder.add(data);
  @override
  close() {}
}

main() {
  group('json to proto conversion with deferred files', () {
    test('hello_world_deferred', () {
      var uri = Platform.script
          .resolve('hello_world_deferred/hello_world_deferred.js.info.json');
      var helloWorld = File.fromUri(uri);
      var contents = helloWorld.readAsStringSync();
      var json = jsonDecode(contents);
      var info = AllInfoJsonCodec().decode(json);

      var sink = ByteSink();
      binary.encode(info, sink);
      var info2 = binary.decode(sink.builder.toBytes());
      var json2 = AllInfoJsonCodec().encode(info2);

      info.program.toJsonDuration = Duration(milliseconds: 0);
      var json1 = AllInfoJsonCodec().encode(info);
      var contents1 = const JsonEncoder.withIndent("  ").convert(json1);
      var contents2 = const JsonEncoder.withIndent("  ").convert(json2);
      expect(contents1 == contents2, isTrue);
    });
  });
}
