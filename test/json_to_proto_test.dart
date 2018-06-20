// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/proto_info_codec.dart';
import 'package:test/test.dart';

main() {
  group('json to proto conversion', () {
    test('hello_world', () {
      final helloWorld = new File('test/hello_world/hello_world.js.info.json');
      final json = jsonDecode(helloWorld.readAsStringSync());
      final decoded = new AllInfoJsonCodec().decode(json);
      final proto = new AllInfoProtoCodec().encode(decoded);

      expect(proto.program.entrypointId, isNotNull);
      expect(proto.program.size, 10324);
      expect(proto.program.compilationMoment.toInt(),
          DateTime.parse("2017-04-17 09:46:41.661617").microsecondsSinceEpoch);
      expect(proto.program.toProtoDuration.toInt(),
          new Duration(milliseconds: 4).inMicroseconds);
      expect(proto.program.dumpInfoDuration.toInt(),
          new Duration(milliseconds: 0).inMicroseconds);
      expect(proto.program.noSuchMethodEnabled, isFalse);
      expect(proto.program.minified, isFalse);
    });
  });
}
