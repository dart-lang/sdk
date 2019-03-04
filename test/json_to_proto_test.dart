// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';
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

    test('has proper id format', () {
      final helloWorld = new File('test/hello_world/hello_world.js.info.json');
      final json = jsonDecode(helloWorld.readAsStringSync());
      final decoded = new AllInfoJsonCodec().decode(json);
      final proto = new AllInfoProtoCodec().encode(decoded);

      final expectedPrefixes = <InfoKind, String>{};
      for (final kind in InfoKind.values) {
        expectedPrefixes[kind] = kindToString(kind) + '/';
      }

      for (final info in proto.allInfos) {
        final value = info.value;
        if (value.hasLibraryInfo()) {
          expect(value.serializedId,
              startsWith(expectedPrefixes[InfoKind.library]));
        } else if (value.hasClassInfo()) {
          expect(
              value.serializedId, startsWith(expectedPrefixes[InfoKind.clazz]));
        } else if (value.hasFunctionInfo()) {
          expect(value.serializedId,
              startsWith(expectedPrefixes[InfoKind.function]));
        } else if (value.hasFieldInfo()) {
          expect(
              value.serializedId, startsWith(expectedPrefixes[InfoKind.field]));
        } else if (value.hasConstantInfo()) {
          expect(value.serializedId,
              startsWith(expectedPrefixes[InfoKind.constant]));
        } else if (value.hasOutputUnitInfo()) {
          expect(value.serializedId,
              startsWith(expectedPrefixes[InfoKind.outputUnit]));
        } else if (value.hasTypedefInfo()) {
          expect(value.serializedId,
              startsWith(expectedPrefixes[InfoKind.typedef]));
        } else if (value.hasClosureInfo()) {
          expect(value.serializedId,
              startsWith(expectedPrefixes[InfoKind.closure]));
        }
      }
    });
  });
}
